require('dotenv').config();

// F1: Startup guard against test OTP bypass in production
if (process.env.NODE_ENV === 'production' && process.env.TEST_OTP_ENABLED === 'true') {
  console.error('FATAL: TEST_OTP_ENABLED must not be enabled in production.');
  process.exit(1);
}

if (!process.env.GOOGLE_CLIENT_IDS && !process.env.GOOGLE_CLIENT_ID) {
  console.warn('[Startup Warning] GOOGLE_CLIENT_IDS is empty. Google sign-in verification will fail unless configured.');
}

const express = require('express');
const cors = require('cors');
const compression = require('compression');
const helmet = require('helmet');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

// F10: Shared Prisma client
const prisma = require('./lib/prisma');

const { apiLimiter } = require('./middleware/rateLimits');
const { verifyMailConfig } = require('./services/email');
const { deleteImage } = require('./services/storage');
const { calcAge } = require('./utils/age');

const app = express();
const server = http.createServer(app);

// F7: Trust proxy hops default to 1 in production if unset
const trustProxyEnv = process.env.TRUST_PROXY_HOPS;
let trustProxyHops;
if (trustProxyEnv !== undefined && trustProxyEnv !== '') {
  trustProxyHops = parseInt(trustProxyEnv, 10);
} else if (process.env.NODE_ENV === 'production') {
  trustProxyHops = 1;
} else {
  trustProxyHops = 0;
}
if (trustProxyHops > 0) {
  app.set('trust proxy', trustProxyHops);
}
console.log(`[Startup] Effective trust proxy hops: ${trustProxyHops}`);

// F11b: CORS allow-list function (no '*' in production; allow FRONTEND_URL, ADMIN_URL; mobile sends no origin)
const allowedOrigins = process.env.NODE_ENV === 'production'
  ? [process.env.FRONTEND_URL, process.env.ADMIN_URL].filter(Boolean)
  : ['http://localhost:3000', 'http://localhost:3001', '*'];

const corsOriginHandler = function (origin, callback) {
  if (!origin || allowedOrigins.includes('*') || allowedOrigins.indexOf(origin) !== -1) {
    callback(null, true);
  } else {
    callback(new Error('Not allowed by CORS'));
  }
};

// Initialize Socket.io with the same CORS configuration
const io = new Server(server, {
  cors: {
    origin: corsOriginHandler,
    credentials: true,
  }
});
app.set('io', io);

// Security Middleware (single helmet instance)
app.use(helmet());

// Apply global rate limiting to all /api routes (F7: 1200 req / 15 min keyed by user or IP)
app.use('/api/', apiLimiter);

app.use(cors({
  origin: corsOriginHandler,
  credentials: true,
}));
app.use(express.json());
app.use(compression());

// Serve static images uploaded by users
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads'), {
  setHeaders: (res, path, stat) => {
    res.set('X-Content-Type-Options', 'nosniff');
    if (path.endsWith('.webp') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
      // Allow these image types
    } else {
      res.set('Content-Type', 'application/octet-stream'); // Fallback
    }
  }
}));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/journal', require('./routes/journal'));
app.use('/api/match', require('./routes/match'));
app.use('/api/conversations', require('./routes/conversations'));
app.use('/api/community', require('./routes/community'));
app.use('/api/goals', require('./routes/goals'));
app.use('/api/progress', require('./routes/progress'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/config', require('./routes/config'));
app.use('/api/admin', require('./routes/admin'));

app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({ status: 'OK', database: 'Connected' });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', database: 'Disconnected', error: error.message });
  }
});

// Centralized Error Handling Middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message,
  });
});

// Socket.io JWT Auth Middleware
let legacySocketTokenCount = 0;
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  
  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err || !decoded) return next(new Error('Authentication error'));
    
    // F5: Reject any token with a purpose claim
    if (decoded.purpose) {
      return next(new Error('Authentication error'));
    }

    try {
      const user = await prisma.user.findUnique({ where: { id: decoded.id } });
      if (!user) return next(new Error('Authentication error: User not found'));

      // F2: Ban check
      if (user.isBanned) {
        return next(new Error('ACCOUNT_BANNED'));
      }

      // F2: Legacy token check (no tokenVersion)
      // TODO (2026-10-29): Reject legacy tokens without tokenVersion once deploy is older than 7 days.
      if (decoded.tokenVersion === undefined) {
        legacySocketTokenCount++;
        console.warn(`[Socket Auth Warning] Legacy token without tokenVersion detected. Total: ${legacySocketTokenCount}`);
      } else if (decoded.tokenVersion !== user.tokenVersion) {
        return next(new Error('Authentication error: Session expired'));
      }

      if (!user.emailVerified) {
        return next(new Error('EMAIL_NOT_VERIFIED'));
      }
      if (!user.dateOfBirth) {
        return next(new Error('AGE_REQUIRED'));
      }
      const age = calcAge(user.dateOfBirth);
      if (age < 18 || user.underageBlockedAt) {
        return next(new Error('UNDERAGE'));
      }
      socket.user = user;
      next();
    } catch (e) {
      next(new Error('Authentication error: Server error'));
    }
  });
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id, 'User ID:', socket.user.id);
  if (socket.user && socket.user.id) {
    socket.join(socket.user.id);
    socket.join(`user_${socket.user.id}`);
  }

  socket.on('join_conversation', async (conversationId) => {
    try {
      const conv = await prisma.conversation.findUnique({
        where: { id: conversationId },
        include: { match: true }
      });
      if (conv && (conv.match.userAId === socket.user.id || conv.match.userBId === socket.user.id)) {
        socket.join(conversationId);
        console.log(`User ${socket.id} joined conversation ${conversationId}`);
      }
    } catch (e) {
      console.error(e);
    }
  });

  socket.on('send_message', async (data) => {
    try {
      const { conversationId, content } = data;
      const senderId = socket.user.id;
      
      const conv = await prisma.conversation.findUnique({
        where: { id: conversationId },
        include: { match: true }
      });

      if (!conv || (conv.match.userAId !== senderId && conv.match.userBId !== senderId)) {
        return; // Unauthorized
      }

      // Save message to DB
      const message = await prisma.message.create({
        data: { conversationId, senderId, content }
      });
      
      // Award XP for chat
      await prisma.user.update({
        where: { id: senderId },
        data: { xp: { increment: 10 } }
      });

      // Broadcast to room
      io.to(conversationId).emit('receive_message', message);
    } catch (err) {
      console.error('Socket message error:', err);
    }
  });

  // F11b: Ignore data.senderId and use socket.user.id
  socket.on('typing', (data) => {
    socket.to(data.conversationId).emit('user_typing', { senderId: socket.user.id });
  });

  socket.on('request_reveal_identity', async (data) => {
    try {
      const { conversationId } = data;
      const senderId = socket.user.id;
      const conv = await prisma.conversation.findUnique({
        where: { id: conversationId },
        include: { match: { include: { userA: true, userB: true } } }
      });
      if (!conv) return;
      const isUserA = conv.match.userAId === senderId;
      const isUserB = conv.match.userBId === senderId;
      if (!isUserA && !isUserB) return;

      const myUser = isUserA ? conv.match.userA : conv.match.userB;
      const peer = isUserA ? conv.match.userB : conv.match.userA;

      const updateData = isUserA ? { userARevealed: true } : { userBRevealed: true };
      const updatedMatch = await prisma.match.update({
        where: { id: conv.match.id },
        data: updateData
      });

      const isMutuallyRevealed = updatedMatch.userARevealed && updatedMatch.userBRevealed;
      if (isMutuallyRevealed) {
        const revealMsg = `Identity revealed! You are now chatting as ${conv.match.userA.realFirstName || conv.match.userA.displayName || 'Peer'} and ${conv.match.userB.realFirstName || conv.match.userB.displayName || 'Peer'}.`;
        const sysMsg = await prisma.message.create({
          data: { conversationId, senderId, content: `✨ ${revealMsg}` }
        });
        io.to(conversationId).emit('receive_message', sysMsg);
        io.to(conversationId).emit('identity_revealed', {
          conversationId,
          isMutuallyRevealed: true,
          userAFirstName: conv.match.userA.realFirstName,
          userBFirstName: conv.match.userB.realFirstName,
          userADisplayName: conv.match.userA.displayName || conv.match.userA.pseudonym,
          userBDisplayName: conv.match.userB.displayName || conv.match.userB.pseudonym
        });
      } else {
        io.to(conversationId).emit('name_reveal_requested', {
          conversationId,
          requesterId: senderId,
          requesterDisplayName: myUser.displayName || myUser.pseudonym || 'Your match'
        });
      }
    } catch (e) {
      console.error('Socket identity reveal error:', e);
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Cleanup Job for unverified accounts
setInterval(async () => {
  try {
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days
    const unverifiedUsers = await prisma.user.findMany({
      where: {
        emailVerified: false,
        isAnonymous: false,
        createdAt: { lt: cutoff }
      }
    });

    if (unverifiedUsers.length > 0) {
      for (const u of unverifiedUsers) {
        if (u.images && Array.isArray(u.images)) {
          u.images.forEach(img => {
            try { deleteImage(img); } catch (_) {}
          });
        }
      }
      const result = await prisma.user.deleteMany({
        where: {
          id: { in: unverifiedUsers.map(u => u.id) }
        }
      });
      console.log(`🗑️ Cleanup Job: Deleted ${result.count} unverified accounts.`);
    }
  } catch (error) {
    console.error('Cleanup Job Error:', error.message);
  }
}, 12 * 60 * 60 * 1000); // Run every 12 hours

// F4: Worker: every 15 minutes delete expired PendingSignup rows and their image files
async function cleanupExpiredPendingSignups() {
  try {
    const now = new Date();
    const expiredPending = await prisma.pendingSignup.findMany({
      where: {
        expiresAt: { lt: now }
      }
    });

    if (expiredPending.length > 0) {
      for (const p of expiredPending) {
        if (p.images && Array.isArray(p.images)) {
          p.images.forEach(img => {
            try { deleteImage(img); } catch (_) {}
          });
        }
      }
      const result = await prisma.pendingSignup.deleteMany({
        where: {
          id: { in: expiredPending.map(p => p.id) }
        }
      });
      console.log(`🗑️ Cleanup Job: Deleted ${result.count} expired pending signups.`);
    }
  } catch (error) {
    console.error('PendingSignup Cleanup Job Error:', error.message);
  }
}

setInterval(cleanupExpiredPendingSignups, 15 * 60 * 1000);
cleanupExpiredPendingSignups();

// Automated Deletion Job for Accounts with scheduledDeletionDate <= now()
async function processScheduledAccountDeletions() {
  try {
    const now = new Date();
    const expiredUsers = await prisma.user.findMany({
      where: {
        scheduledDeletionDate: {
          lte: now,
        },
      },
      select: {
        id: true,
        images: true,
        email: true,
        pseudonym: true,
        scheduledDeletionDate: true,
      },
    });

    if (expiredUsers.length > 0) {
      console.log(`🗑️ Auto-Delete Job: Found ${expiredUsers.length} accounts ready for permanent deletion.`);
      for (const u of expiredUsers) {
        try {
          if (u.images && Array.isArray(u.images)) {
            u.images.forEach(img => {
              try { deleteImage(img); } catch (_) {}
            });
          }
          await prisma.user.delete({ where: { id: u.id } });
          console.log(`✅ Auto-Delete Job: Permanently deleted account ${u.id} (${u.email || u.pseudonym || 'No Email'}).`);
        } catch (delErr) {
          console.error(`❌ Auto-Delete error for user ${u.id}:`, delErr.message);
        }
      }
    }
  } catch (error) {
    console.error('Scheduled Deletion Job Error:', error.message);
  }
}

// Run on startup, and check every 60 seconds
processScheduledAccountDeletions();
setInterval(processScheduledAccountDeletions, 60 * 1000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, async () => {
  await verifyMailConfig();
  console.log(`Wehere Backend running on port ${PORT}`);
});

// F10: SIGTERM/SIGINT handlers calling prisma.$disconnect()
const gracefulShutdown = async (signal) => {
  console.log(`Received ${signal}. Shutting down server gracefully...`);
  server.close(async () => {
    try {
      await prisma.$disconnect();
      console.log('Prisma disconnected.');
    } catch (err) {
      console.error('Error disconnecting Prisma:', err);
    }
    process.exit(0);
  });
};

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

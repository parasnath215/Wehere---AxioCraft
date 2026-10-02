require('dotenv').config();
const express = require('express');
const cors = require('cors');
const compression = require('compression');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const { PrismaClient } = require('@prisma/client');
const jwt = require('jsonwebtoken');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });
const prisma = new PrismaClient();

const { verifyMailConfig } = require('./services/email');

// Trust proxy for rate limiting behind Nginx
const trustProxyHops = process.env.TRUST_PROXY_HOPS ? parseInt(process.env.TRUST_PROXY_HOPS, 10) : 0;
if (trustProxyHops > 0) {
  app.set('trust proxy', trustProxyHops);
}

// Security Middleware
app.use(helmet());

// Apply rate limiting to all /api routes
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 150, // Limit each IP to 150 requests per window
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', apiLimiter);

const allowedOrigins = process.env.NODE_ENV === 'production' 
  ? [process.env.FRONTEND_URL, process.env.ADMIN_URL].filter(Boolean)
  : ['http://localhost:3000', 'http://localhost:3001', '*']; // Star is for local dev flutter

app.use(cors({
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));
app.use(express.json());
app.use(compression());
app.use(helmet());

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
app.use('/api/sos', require('./routes/sos'));
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
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  
  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err) return next(new Error('Authentication error'));
    
    try {
      const user = await prisma.user.findUnique({ where: { id: decoded.id } });
      if (!user) return next(new Error('Authentication error: User not found'));
      if (decoded.tokenVersion !== undefined && decoded.tokenVersion !== user.tokenVersion) {
        return next(new Error('Authentication error: Session expired'));
      }
      if (!user.emailVerified && !user.isAnonymous) {
        return next(new Error('Authentication error: EMAIL_NOT_VERIFIED'));
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

  socket.on('typing', (data) => {
    socket.to(data.conversationId).emit('user_typing', { senderId: data.senderId });
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
      // In a real app we might want to clean up their uploaded files as well
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

const PORT = process.env.PORT || 3000;
server.listen(PORT, async () => {
  await verifyMailConfig();
  console.log(`Wehere Backend running on port ${PORT}`);
});

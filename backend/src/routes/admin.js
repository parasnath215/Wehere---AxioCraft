const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { adminGuard } = require('../middleware/auth');
const { loginLimiter, adminApiLimiter } = require('../middleware/rateLimits');
const { deleteImage } = require('../services/storage');

// Apply admin router rate limit: 120 req/min per IP
router.use(adminApiLimiter);

// Safe User fields selection excluding password, tokenVersion, and OTP records
const safeUserSelect = {
  id: true,
  email: true,
  username: true,
  phone: true,
  role: true,
  isAnonymous: true,
  pseudonym: true,
  legalFullName: true,
  realFirstName: true,
  displayName: true,
  handle: true,
  nameDisplayPreference: true,
  avatar: true,
  bio: true,
  images: true,
  location: true,
  profession: true,
  lookingFor: true,
  interests: true,
  feelings: true,
  supportTypes: true,
  photoVersion: true,
  xp: true,
  level: true,
  currentStreak: true,
  lastLoginDate: true,
  createdAt: true,
  updatedAt: true,
  isBanned: true,
  emailVerified: true,
  emailVerifiedAt: true,
  scheduledDeletionDate: true,
  deletionRequestedAt: true,
};

// POST /api/admin/login (public, loginLimiter)
router.post('/login', loginLimiter, async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Invalid credentials.' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const user = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });

    if (!user || !user.password || user.role !== 'ADMIN' || !user.emailVerified || user.isBanned) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Invalid credentials.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Invalid credentials.' });
    }

    // Sign JWT with 12h expiry: { id, tokenVersion }
    const token = jwt.sign(
      { id: user.id, tokenVersion: user.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '12h' }
    );

    res.json({ success: true, token });
  } catch (error) {
    next(error);
  }
});

// Guard all subsequent admin routes
router.use(adminGuard);

router.get('/stats', async (req, res, next) => {
  try {
    const totalUsers = await prisma.user.count();
    const activeMatches = await prisma.match.count({ where: { status: 'connected' } });
    const totalMessages = await prisma.message.count();
    const reportedUsers = await prisma.user.count({ where: { reportsReceived: { some: {} } } });

    const recentUsers = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10,
      select: {
        id: true,
        pseudonym: true,
        role: true,
        createdAt: true,
      }
    });

    res.json({
      totalUsers,
      activeMatches,
      totalMessages,
      reportedUsers,
      recentUsers
    });
  } catch (error) {
    next(error);
  }
});

router.get('/users', async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const users = await prisma.user.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: safeUserSelect
    });
    res.json(users);
  } catch (error) {
    next(error);
  }
});

router.put('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, pseudonym, email, scheduledDeletionDate } = req.body;

    let updateDeletionDate = undefined;
    if (scheduledDeletionDate !== undefined) {
      if (!scheduledDeletionDate || scheduledDeletionDate === '') {
        updateDeletionDate = null;
      } else {
        updateDeletionDate = new Date(scheduledDeletionDate);
      }
    }
    
    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(role && { role }),
        ...(pseudonym && { pseudonym }),
        ...(email && { email }),
        ...(updateDeletionDate !== undefined && {
          scheduledDeletionDate: updateDeletionDate,
          deletionRequestedAt: updateDeletionDate ? new Date() : null,
        }),
      },
      select: safeUserSelect
    });
    res.json(user);
  } catch (error) {
    next(error);
  }
});

router.post('/users', async (req, res, next) => {
  try {
    const { email, password, pseudonym, role } = req.body;
    if (!email || !password || !pseudonym) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Missing required fields' });
    }
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: 'CONFLICT', message: 'Email already exists' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        pseudonym,
        role: role || 'USER',
        emailVerified: true
      },
      select: safeUserSelect
    });
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});

router.get('/users/:id/analytics', async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        pseudonym: true,
        role: true,
        createdAt: true,
        lastLoginDate: true,
        isBanned: true,
      }
    });
    
    if (!user) return res.status(404).json({ error: 'VALIDATION_ERROR', message: 'User not found' });

    const totalMatches = await prisma.match.count({
      where: { OR: [{ userAId: id }, { userBId: id }] }
    });

    const activeMatches = await prisma.match.count({
      where: { OR: [{ userAId: id }, { userBId: id }], status: 'connected' }
    });

    const messagesSent = await prisma.message.count({
      where: { senderId: id }
    });

    // Fix 1.5: use journalEntry and userId instead of journal and authorId
    const journalsWritten = await prisma.journalEntry.count({
      where: { userId: id }
    });

    res.json({
      user,
      stats: {
        totalMatches,
        activeMatches,
        messagesSent,
        journalsWritten
      }
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({
      where: { id },
      select: { images: true }
    });
    if (user && user.images && Array.isArray(user.images)) {
      user.images.forEach(img => {
        try { deleteImage(img); } catch (_) {}
      });
    }
    await prisma.user.delete({ where: { id } });
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    next(error);
  }
});

router.get('/matches', async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const matches = await prisma.match.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        userA: { select: { pseudonym: true, email: true } },
        userB: { select: { pseudonym: true, email: true } }
      }
    });
    res.json(matches);
  } catch (error) {
    next(error);
  }
});

// GET /admin/reports
router.get('/reports', async (req, res, next) => {
  try {
    const reports = await prisma.report.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        reporter: { select: { pseudonym: true, email: true } },
        reported: { select: { pseudonym: true, email: true, isBanned: true } }
      }
    });
    res.json(reports);
  } catch (error) {
    next(error);
  }
});

// PUT /admin/users/:id/ban
router.put('/users/:id/ban', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { isBanned } = req.body; // true to ban, false to unban
    
    const updateData = { isBanned: Boolean(isBanned) };
    if (isBanned) {
      updateData.tokenVersion = { increment: 1 };
    }

    const user = await prisma.user.update({
      where: { id },
      data: updateData,
      select: { id: true, pseudonym: true, isBanned: true }
    });
    
    res.json(user);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateAdmin } = require('../middleware/auth');
const bcrypt = require('bcryptjs');

// Apply admin authentication to all routes in this router
router.use(authenticateAdmin);

router.get('/stats', async (req, res) => {
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
      orderBy: { createdAt: 'desc' }
    });
    res.json(users);
  } catch (error) {
    next(error);
  }
});

router.put('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, pseudonym, email } = req.body;
    
    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(role && { role }),
        ...(pseudonym && { pseudonym }),
        ...(email && { email }),
      },
      select: {
        id: true, email: true, pseudonym: true, role: true
      }
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
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(400).json({ error: 'Email already exists' });
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
      select: { id: true, email: true, pseudonym: true, role: true, createdAt: true }
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
    
    if (!user) return res.status(404).json({ error: 'User not found' });

    const totalMatches = await prisma.match.count({
      where: { OR: [{ userAId: id }, { userBId: id }] }
    });

    const activeMatches = await prisma.match.count({
      where: { OR: [{ userAId: id }, { userBId: id }], status: 'connected' }
    });

    const messagesSent = await prisma.message.count({
      where: { senderId: id }
    });

    const journalsWritten = await prisma.journal.count({
      where: { authorId: id }
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
    
    const user = await prisma.user.update({
      where: { id },
      data: { isBanned },
      select: { id: true, pseudonym: true, isBanned: true }
    });
    
    res.json(user);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

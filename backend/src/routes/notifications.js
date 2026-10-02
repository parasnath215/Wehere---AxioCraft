const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');

// List notifications for the user
router.get('/', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 50
    });
    res.json(notifications);
  } catch (error) {
    next(error);
  }
});

// Get unread count
router.get('/unread', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const count = await prisma.notification.count({
      where: { userId: req.user.id, isRead: false }
    });
    res.json({ unreadCount: count });
  } catch (error) {
    next(error);
  }
});

// Mark notification as read
router.put('/:id/read', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const notification = await prisma.notification.updateMany({
      where: { id, userId: req.user.id },
      data: { isRead: true }
    });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

// Mark all as read
router.put('/read-all', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true }
    });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

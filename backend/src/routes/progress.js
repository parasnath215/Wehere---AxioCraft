const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');

router.get('/', authenticateToken, requireVerified, async (req, res) => {
  try {
    const userId = req.user.id;
    let user = await prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true, level: true, currentStreak: true, lastLoginDate: true }
    });
    
    // Update streak logic
    const today = new Date();
    today.setHours(0,0,0,0);
    const lastLogin = user.lastLoginDate ? new Date(user.lastLoginDate) : null;
    if (lastLogin) lastLogin.setHours(0,0,0,0);

    let streakUpdate = user.currentStreak;
    if (!lastLogin) {
      streakUpdate = 1;
    } else {
      const diffTime = Math.abs(today - lastLogin);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
      if (diffDays === 1) {
        streakUpdate += 1;
      } else if (diffDays > 1) {
        streakUpdate = 1;
      }
    }

    if (!lastLogin || lastLogin.getTime() !== today.getTime()) {
      await prisma.user.update({
        where: { id: userId },
        data: { currentStreak: streakUpdate, lastLoginDate: new Date() }
      });
      user.currentStreak = streakUpdate;
    }

    // Calculate weekly progress (days active this week)
    const startOfWeek = new Date();
    startOfWeek.setHours(0,0,0,0);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay()); // Sunday
    
    const moodsThisWeek = await prisma.dailyMood.findMany({
      where: {
        userId,
        createdAt: { gte: startOfWeek }
      },
      select: { createdAt: true }
    });
    
    // Unique days this week
    const activeDays = new Set(moodsThisWeek.map(m => new Date(m.createdAt).toDateString())).size;

    res.json({ ...user, weeklyProgress: activeDays });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET today's mood
router.get('/mood/today', authenticateToken, requireVerified, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0,0,0,0);
    
    const mood = await prisma.dailyMood.findFirst({
      where: {
        userId: req.user.id,
        createdAt: { gte: today }
      },
      orderBy: { createdAt: 'desc' }
    });
    
    res.json({ mood: mood ? mood.mood : null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST today's mood
router.post('/mood', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { mood } = req.body;
    if (!mood) return res.status(400).json({ error: 'Mood is required' });

    const today = new Date();
    today.setHours(0,0,0,0);

    // Update if exists today, else create
    const existing = await prisma.dailyMood.findFirst({
      where: {
        userId: req.user.id,
        createdAt: { gte: today }
      }
    });

    let savedMood;
    if (existing) {
      savedMood = await prisma.dailyMood.update({
        where: { id: existing.id },
        data: { mood }
      });
    } else {
      savedMood = await prisma.dailyMood.create({
        data: {
          mood,
          userId: req.user.id
        }
      });
      // Increment streak logic here (simplified)
      const updatedUser = await prisma.user.update({
        where: { id: req.user.id },
        data: { currentStreak: { increment: 1 } }
      });
      await prisma.notification.create({
        data: {
          type: 'progress',
          title: 'Daily Streak Maintained! 🔥',
          body: `Great job! You are on a ${updatedUser.currentStreak}-day streak. Keep it up!`,
          userId: req.user.id
        }
      });
    }

    res.json(savedMood);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { evaluateStreak } = require('../services/streak');

router.get('/', authenticateToken, requireVerified, async (req, res) => {
  try {
    const userId = req.user.id;
    let user = await prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true, level: true, currentStreak: true, lastLoginDate: true }
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    // Update streak according to 24h + 12h window rule
    const streakResult = evaluateStreak(user);
    if (streakResult.shouldUpdate) {
      await prisma.user.update({
        where: { id: userId },
        data: {
          currentStreak: streakResult.currentStreak,
          lastLoginDate: streakResult.lastLoginDate,
        }
      });
      user.currentStreak = streakResult.currentStreak;
      user.lastLoginDate = streakResult.lastLoginDate;
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
      // Evaluate streak according to 24h + 12h rule
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        select: { currentStreak: true, lastLoginDate: true }
      });
      if (user) {
        const streakResult = evaluateStreak(user);
        if (streakResult.shouldUpdate) {
          await prisma.user.update({
            where: { id: req.user.id },
            data: {
              currentStreak: streakResult.currentStreak,
              lastLoginDate: streakResult.lastLoginDate,
            }
          });
        }
      }
    }

    res.json(savedMood);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { z } = require('zod');

const journalSchema = z.object({
  content: z.string().min(1),
  moodScore: z.number().int().min(1).max(5),
  category: z.string().optional(),
  isPrivate: z.boolean().default(true),
});

router.post('/create', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { content, moodScore, category, isPrivate } = journalSchema.parse(req.body);
    const userId = req.user.id;
    
    const result = await prisma.$transaction(async (tx) => {
      const entry = await tx.journalEntry.create({
        data: { content, moodScore, category, isPrivate, userId }
      });
      
      const user = await tx.user.update({
        where: { id: userId },
        data: {
          xp: { increment: 25 },
          currentStreak: { increment: 1 }
        }
      });
      return { entry, user: { xp: user.xp, currentStreak: user.currentStreak } };
    });

    res.status(201).json(result);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

router.get('/', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const entries = await prisma.journalEntry.findMany({
      where: { userId },
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });
    res.json(entries);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

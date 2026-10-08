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
      
      if (!isPrivate) {
        await tx.communityPost.create({
          data: {
            topic: category || 'Journal',
            content: content,
            authorId: userId
          }
        });
      }
      
      const user = await tx.user.update({
        where: { id: userId },
        data: {
          xp: { increment: 25 }
        }
      });
      await tx.notification.create({
        data: {
          type: 'progress',
          title: 'Journal Entry Complete! 📝',
          body: `You earned 25 XP and are on a ${user.currentStreak}-day streak!`,
          userId: userId
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

const updateJournalSchema = z.object({
  content: z.string().min(1).optional(),
  moodScore: z.number().int().min(1).max(5).optional(),
  category: z.string().optional(),
  isPrivate: z.boolean().optional(),
});

router.put('/:id', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const data = updateJournalSchema.parse(req.body);
    const userId = req.user.id;
    const entryId = req.params.id;
    
    // Ensure entry belongs to user
    const entry = await prisma.journalEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.userId !== userId) return res.status(404).json({ error: 'Entry not found' });
    
    const updated = await prisma.$transaction(async (tx) => {
      const u = await tx.journalEntry.update({
        where: { id: entryId },
        data
      });
      
      // Sync with community post
      if (data.isPrivate === false && entry.isPrivate === true) {
        // Just made public
        await tx.communityPost.create({
          data: {
            topic: u.category || 'Journal',
            content: u.content,
            authorId: userId
          }
        });
      } else if (data.isPrivate === true && entry.isPrivate === false) {
        // Just made private
        await tx.communityPost.deleteMany({
          where: {
            authorId: userId,
            content: entry.content
          }
        });
      }
      
      return u;
    });
    
    res.json(updated);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

router.delete('/:id', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const entryId = req.params.id;
    
    // Ensure entry belongs to user
    const entry = await prisma.journalEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.userId !== userId) return res.status(404).json({ error: 'Entry not found' });
    
    await prisma.$transaction(async (tx) => {
      await tx.journalEntry.delete({ where: { id: entryId } });
      if (!entry.isPrivate) {
        await tx.communityPost.deleteMany({
          where: {
            authorId: userId,
            content: entry.content
          }
        });
      }
    });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

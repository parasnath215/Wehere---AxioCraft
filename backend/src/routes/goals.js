const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { z } = require('zod');

const goalSchema = z.object({
  title: z.string().min(1).max(100),
  subtitle: z.string().optional(),
  categoryColor: z.string().optional(),
});

// GET /goals - Get all goals for the user
router.get('/', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const goals = await prisma.wellnessGoal.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });
    res.json(goals);
  } catch (error) {
    next(error);
  }
});

// POST /goals - Create a new goal
router.post('/', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { title, subtitle, categoryColor } = goalSchema.parse(req.body);
    const userId = req.user.id;

    const result = await prisma.$transaction(async (tx) => {
      const newGoal = await tx.wellnessGoal.create({
        data: {
          title,
          subtitle: subtitle || 'Daily wellness practice',
          categoryColor: categoryColor || '0xFF5E4BEE',
          progress: 0.1,
          userId,
        }
      });

      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: 40 } }
      });

      return newGoal;
    });

    res.status(201).json(result);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

// PUT /goals/:id/toggle - Toggle goal completion status
router.put('/:id/toggle', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const goal = await prisma.wellnessGoal.findFirst({
      where: { id, userId }
    });

    if (!goal) return res.status(404).json({ error: 'Goal not found' });

    const newStatus = !goal.isCompleted;
    
    const result = await prisma.$transaction(async (tx) => {
      const updatedGoal = await tx.wellnessGoal.update({
        where: { id },
        data: { 
          isCompleted: newStatus,
          progress: newStatus ? 1.0 : 0.5
        }
      });

      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: newStatus ? 50 : -50 } }
      });

      return updatedGoal;
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

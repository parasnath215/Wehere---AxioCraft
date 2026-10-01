const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken } = require('../middleware/auth');
const { z } = require('zod');

const swipeSchema = z.object({
  targetUserId: z.string().uuid(),
  action: z.enum(['connect', 'pass']),
});

router.get('/discover', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Fetch users not already matched and not self
    const existingMatches = await prisma.match.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] }
    });
    
    const matchedUserIds = existingMatches.map(m => m.userAId === userId ? m.userBId : m.userAId);
    matchedUserIds.push(userId); // Exclude self

    const potentialMatches = await prisma.user.findMany({
      where: {
        id: { notIn: matchedUserIds }
      },
      take: 20
    });
    
    res.json(potentialMatches);
  } catch (error) {
    next(error);
  }
});

router.post('/swipe', authenticateToken, async (req, res, next) => {
  try {
    const { targetUserId, action } = swipeSchema.parse(req.body);
    const userId = req.user.id;
    
    if (action === 'connect') {
      const result = await prisma.$transaction(async (tx) => {
        const match = await tx.match.create({
          data: {
            userAId: userId,
            userBId: targetUserId,
            status: 'connected',
            matchScore: Math.floor(Math.random() * 16) + 82 
          }
        });
        
        const conversation = await tx.conversation.create({
          data: { matchId: match.id }
        });
        
        await tx.user.update({
          where: { id: userId },
          data: { xp: { increment: 50 } }
        });

        return { match, conversation };
      });
      
      return res.status(200).json(result);
    }
    
    res.status(200).json({ message: 'Passed' });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

module.exports = router;

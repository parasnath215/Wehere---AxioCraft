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
    
    // Fetch users already swiped by this user
    const swipes = await prisma.swipe.findMany({
      where: { swiperId: userId },
      select: { swipedId: true }
    });
    
    // Fetch blocks
    const blocks = await prisma.block.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] }
    });
    
    const excludedUserIds = swipes.map(s => s.swipedId);
    blocks.forEach(b => {
      excludedUserIds.push(b.blockerId === userId ? b.blockedId : b.blockerId);
    });
    excludedUserIds.push(userId); // Exclude self

    const potentialMatches = await prisma.user.findMany({
      where: {
        id: { notIn: excludedUserIds },
        isBanned: false
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
    
    const isRight = action === 'connect';

    // Record the swipe
    await prisma.swipe.upsert({
      where: {
        swiperId_swipedId: { swiperId: userId, swipedId: targetUserId }
      },
      update: { isRight },
      create: { swiperId: userId, swipedId: targetUserId, isRight }
    });

    if (isRight) {
      // Check if target user already swiped right on us
      const mutualSwipe = await prisma.swipe.findUnique({
        where: {
          swiperId_swipedId: { swiperId: targetUserId, swipedId: userId }
        }
      });

      if (mutualSwipe && mutualSwipe.isRight) {
        // IT'S A MATCH!
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
          
          await tx.user.update({
            where: { id: targetUserId },
            data: { xp: { increment: 50 } }
          });

          return { match, conversation, isMatch: true };
        });
        
        return res.status(200).json(result);
      }
    }
    
    res.status(200).json({ isMatch: false });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

module.exports = router;

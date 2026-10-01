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

router.get('/discover', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const cursor = req.query.cursor;
    
    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { interests: true, supportTypes: true }
    });

    // Fetch users already swiped by this user
    const swipes = await prisma.swipe.findMany({
      where: { swiperId: userId },
      select: { swipedId: true }
    });
    
    // Fetch blocks
    const blocks = await prisma.block.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] }
    });

    // Fetch existing matches
    const existingMatches = await prisma.match.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] }
    });
    
    const excludedUserIds = swipes.map(s => s.swipedId);
    blocks.forEach(b => {
      excludedUserIds.push(b.blockerId === userId ? b.blockedId : b.blockerId);
    });
    existingMatches.forEach(m => {
      excludedUserIds.push(m.userAId === userId ? m.userBId : m.userAId);
    });
    excludedUserIds.push(userId); // Exclude self

    const matches = await prisma.user.findMany({
      where: {
        id: { notIn: excludedUserIds },
        isBanned: false,
        pseudonym: { not: null }
      },
      select: {
        id: true, isAnonymous: true, pseudonym: true, bio: true, images: true, 
        location: true, interests: true, supportTypes: true, xp: true, level: true, updatedAt: true
      }
    });
    
    const THREE_DAYS_AGO = Date.now() - (3 * 24 * 60 * 60 * 1000);
    let scoredMatches = [];

    for (const u of matches) {
      if (u.images.length < 2) continue; // Minimum photos requirement

      const sharedInterests = u.interests.filter(i => currentUser.interests.includes(i));
      const sharedSupport = u.supportTypes.filter(s => currentUser.supportTypes.includes(s));
      
      let score = (sharedInterests.length * 2) + (sharedSupport.length * 2);
      if (new Date(u.updatedAt).getTime() > THREE_DAYS_AGO) {
        score += 1; // Small bonus for recent activity
      }
      
      scoredMatches.push({ ...u, score, sharedInterests });
    }

    // Sort by score DESC, id DESC for stable ties
    scoredMatches.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return b.id.localeCompare(a.id);
    });

    let startIndex = 0;
    if (cursor) {
      const idx = scoredMatches.findIndex(m => m.id === cursor);
      if (idx !== -1) {
        startIndex = idx + 1;
      }
    }

    const paginated = scoredMatches.slice(startIndex, startIndex + 20);
    const nextCursor = paginated.length === 20 ? paginated[19].id : null;

    const formattedMatches = paginated.map(u => {
      const { score, sharedInterests, updatedAt, ...rest } = u;
      
      // Return only shared interests
      rest.interests = sharedInterests;
      
      if (rest.isAnonymous) {
        rest.pseudonym = "Anonymous";
        rest.images = [];
        rest.location = null;
      }
      return rest;
    });

    res.json({ matches: formattedMatches, nextCursor });
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

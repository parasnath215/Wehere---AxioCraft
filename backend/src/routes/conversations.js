const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');

// List conversations for the logged in user
router.get('/', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    const conversations = await prisma.conversation.findMany({
      where: {
        match: {
          OR: [{ userAId: userId }, { userBId: userId }]
        }
      },
      include: {
        match: {
          include: {
            userA: { select: { id: true, pseudonym: true, images: true, isAnonymous: true } },
            userB: { select: { id: true, pseudonym: true, images: true, isAnonymous: true } }
          }
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 50 // Fetch recent to count unread
        }
      },
      orderBy: { updatedAt: 'desc' }
    });

    // Format output to simplify frontend
    const formatted = conversations.map(c => {
      const peer = c.match.userAId === userId ? c.match.userB : c.match.userA;
      
      let peerName = peer.pseudonym || 'Anonymous';
      let peerAvatar = (peer.images && peer.images.length > 0) ? peer.images[0] : null;
      
      if (peer.isAnonymous) {
        peerName = 'Anonymous';
        peerAvatar = '/uploads/default-avatar.png';
      }

      return {
        id: c.id,
        peerId: peer.id,
        peerName,
        peerAvatar,
        peerAnonymous: peer.isAnonymous,
        lastMessage: c.messages.length > 0 ? c.messages[0].content : null,
        lastMessageTime: c.messages.length > 0 ? c.messages[0].createdAt : c.updatedAt,
        unreadCount: c.messages.filter(m => !m.isRead && m.senderId !== userId).length,
      };
    });

    res.json(formatted);
  } catch (error) {
    next(error);
  }
});

// Get message history for a specific conversation
router.get('/:id/messages', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify membership
    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: { match: true }
    });

    if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
    if (conversation.match.userAId !== userId && conversation.match.userBId !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' }
    });

    res.json(messages);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

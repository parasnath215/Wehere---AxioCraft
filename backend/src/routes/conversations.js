const express = require('express');
const router = express.Router();
const prisma = require('../lib/prisma');
const { authenticateToken, requireVerified, requireAdult } = require('../middleware/auth');

// Apply authentication, email verification, and 18+ requirement to all conversation routes
router.use(authenticateToken, requireVerified, requireAdult);

// List conversations for the logged in user
router.get('/', async (req, res, next) => {
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
            userA: { 
              select: { 
                id: true, pseudonym: true, displayName: true, realFirstName: true, 
                handle: true, username: true, images: true, isAnonymous: true, nameDisplayPreference: true 
              } 
            },
            userB: { 
              select: { 
                id: true, pseudonym: true, displayName: true, realFirstName: true, 
                handle: true, username: true, images: true, isAnonymous: true, nameDisplayPreference: true 
              } 
            }
          }
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 50 // Fetch recent to count unread
        }
      },
      orderBy: { updatedAt: 'desc' }
    });

    // Format output with Progressive Identity Disclosure
    const formatted = conversations.map(c => {
      const isUserA = c.match.userAId === userId;
      const peer = isUserA ? c.match.userB : c.match.userA;
      const myUser = isUserA ? c.match.userA : c.match.userB;

      const userARevealed = c.match.userARevealed || false;
      const userBRevealed = c.match.userBRevealed || false;
      const myRevealed = isUserA ? userARevealed : userBRevealed;
      const peerRevealed = isUserA ? userBRevealed : userARevealed;
      const isMutuallyRevealed = userARevealed && userBRevealed;
      
      const peerDisplayName = peer.displayName || peer.pseudonym || 'Anonymous';
      let peerName = peerDisplayName;
      let peerRealFirstName = null;

      // Reveal real first name ONLY if mutually consented or peer opted for public first name
      if (isMutuallyRevealed && peer.realFirstName && peer.realFirstName.trim().length > 0) {
        peerRealFirstName = peer.realFirstName.trim();
        peerName = `${peerRealFirstName} (@${peerDisplayName})`;
      } else if (peer.nameDisplayPreference === 'FIRST_NAME_PUBLIC' && peer.realFirstName) {
        peerName = peer.realFirstName.trim();
      }
      
      let peerAvatar = (peer.images && peer.images.length > 0) ? peer.images[0] : null;
      
      if (peer.isAnonymous) {
        peerName = 'Anonymous';
        peerRealFirstName = null;
        peerAvatar = '/uploads/default-avatar.png';
      }

      return {
        id: c.id,
        matchId: c.match.id,
        peerId: peer.id,
        peerName,
        peerDisplayName,
        peerRealFirstName, // strictly null unless isMutuallyRevealed is true
        peerHandle: peer.handle || peer.username,
        peerAvatar,
        peerAnonymous: peer.isAnonymous,
        disclosure: {
          user_a_revealed: userARevealed,
          user_b_revealed: userBRevealed,
          is_mutually_revealed: isMutuallyRevealed,
          my_revealed: myRevealed,
          peer_revealed: peerRevealed
        },
        myRevealed,
        peerRevealed,
        isMutuallyRevealed,
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

// Get disclosure state for a specific conversation
router.get('/:id/disclosure', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: {
        match: {
          include: {
            userA: { select: { id: true, displayName: true, pseudonym: true, realFirstName: true, handle: true, username: true, nameDisplayPreference: true } },
            userB: { select: { id: true, displayName: true, pseudonym: true, realFirstName: true, handle: true, username: true, nameDisplayPreference: true } }
          }
        }
      }
    });

    if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
    if (conversation.match.userAId !== userId && conversation.match.userBId !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const isUserA = conversation.match.userAId === userId;
    const peer = isUserA ? conversation.match.userB : conversation.match.userA;
    const myUser = isUserA ? conversation.match.userA : conversation.match.userB;

    const userARevealed = conversation.match.userARevealed || false;
    const userBRevealed = conversation.match.userBRevealed || false;
    const myRevealed = isUserA ? userARevealed : userBRevealed;
    const peerRevealed = isUserA ? userBRevealed : userARevealed;
    const isMutuallyRevealed = userARevealed && userBRevealed;

    const peerDisplayName = peer.displayName || peer.pseudonym || 'Anonymous';
    let peerName = peerDisplayName;
    let peerRealFirstName = null;

    if (isMutuallyRevealed && peer.realFirstName && peer.realFirstName.trim().length > 0) {
      peerRealFirstName = peer.realFirstName.trim();
      peerName = `${peerRealFirstName} (@${peerDisplayName})`;
    } else if (peer.nameDisplayPreference === 'FIRST_NAME_PUBLIC' && peer.realFirstName) {
      peerName = peer.realFirstName.trim();
    }

    res.json({
      conversationId: id,
      matchId: conversation.match.id,
      isMutuallyRevealed,
      myRevealed,
      peerRevealed,
      peerDisplayName,
      peerRealFirstName, // Zero leak: null unless isMutuallyRevealed is true
      peerHandle: peer.handle || peer.username,
      peerName,
      myRealFirstName: myUser.realFirstName || null
    });
  } catch (error) {
    next(error);
  }
});

// Trigger Identity Reveal (Exchange First Names)
router.post('/:id/reveal-name', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { realFirstName } = req.body;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: {
        match: {
          include: {
            userA: true,
            userB: true
          }
        }
      }
    });

    if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
    const isUserA = conversation.match.userAId === userId;
    const isUserB = conversation.match.userBId === userId;
    if (!isUserA && !isUserB) {
      return res.status(403).json({ error: 'Access denied' });
    }

    let myUser = isUserA ? conversation.match.userA : conversation.match.userB;
    const peer = isUserA ? conversation.match.userB : conversation.match.userA;

    // Check or save real first name if passed
    if (realFirstName && realFirstName.trim().length > 0) {
      myUser = await prisma.user.update({
        where: { id: userId },
        data: { realFirstName: realFirstName.trim() }
      });
    }

    if (!myUser.realFirstName || myUser.realFirstName.trim().length === 0) {
      return res.status(400).json({ 
        error: 'FIRST_NAME_REQUIRED', 
        message: 'Please set your first name to share it with your match.' 
      });
    }

    const updateData = isUserA ? { userARevealed: true } : { userBRevealed: true };
    const updatedMatch = await prisma.match.update({
      where: { id: conversation.match.id },
      data: updateData,
      include: {
        userA: true,
        userB: true
      }
    });

    const isMutuallyRevealed = updatedMatch.userARevealed && updatedMatch.userBRevealed;
    const io = req.app.get('io');

    if (isMutuallyRevealed) {
      const uAFirst = updatedMatch.userA.realFirstName || updatedMatch.userA.displayName || 'Peer';
      const uBFirst = updatedMatch.userB.realFirstName || updatedMatch.userB.displayName || 'Peer';
      const revealMsg = `Identity revealed! You are now chatting as ${uAFirst} and ${uBFirst}.`;
      
      const sysMsg = await prisma.message.create({
        data: { conversationId: id, senderId: userId, content: `✨ ${revealMsg}` }
      });

      if (io) {
        io.to(id).emit('receive_message', sysMsg);
        io.to(id).emit('identity_revealed', {
          conversationId: id,
          isMutuallyRevealed: true,
          userAFirstName: updatedMatch.userA.realFirstName,
          userBFirstName: updatedMatch.userB.realFirstName,
          userADisplayName: updatedMatch.userA.displayName || updatedMatch.userA.pseudonym,
          userBDisplayName: updatedMatch.userB.displayName || updatedMatch.userB.pseudonym
        });
      }
    } else {
      if (io) {
        io.to(id).emit('name_reveal_requested', {
          conversationId: id,
          requesterId: userId,
          requesterDisplayName: myUser.displayName || myUser.pseudonym || 'Your match'
        });
      }
    }

    const peerDisplayName = peer.displayName || peer.pseudonym || 'Anonymous';
    let peerName = peerDisplayName;
    let peerRealFirstName = null;
    if (isMutuallyRevealed && peer.realFirstName) {
      peerRealFirstName = peer.realFirstName.trim();
      peerName = `${peerRealFirstName} (@${peerDisplayName})`;
    }

    res.json({
      success: true,
      isMutuallyRevealed,
      myRevealed: true,
      peerRevealed: isUserA ? updatedMatch.userBRevealed : updatedMatch.userARevealed,
      peerDisplayName,
      peerRealFirstName,
      peerName,
      message: isMutuallyRevealed 
        ? 'Real first names exchanged successfully!' 
        : `Offer sent! Waiting for ${peerDisplayName} to accept.`
    });
  } catch (error) {
    next(error);
  }
});

// Decline or Keep Anonymous
router.post('/:id/decline-reveal', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: { match: true }
    });

    if (!conversation) return res.status(404).json({ error: 'Conversation not found' });
    if (conversation.match.userAId !== userId && conversation.match.userBId !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Reset reveal offer to keep anonymous
    await prisma.match.update({
      where: { id: conversation.match.id },
      data: {
        userARevealed: false,
        userBRevealed: false
      }
    });

    const io = req.app.get('io');
    if (io) {
      io.to(id).emit('name_reveal_declined', { conversationId: id, declinerId: userId });
    }

    res.json({ success: true, message: 'Identity kept anonymous.' });
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

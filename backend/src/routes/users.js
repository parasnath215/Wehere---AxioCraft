const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');
const multer = require('multer');
const { z } = require('zod');
const { processAndSaveImage, deleteImage } = require('../services/storage');
const { validateDisplayName, sanitizeHandle } = require('../services/identityFilter');

const MAX_PHOTOS = 6;
const MIN_PHOTOS = 2;

const upload = multer({ 
  storage: multer.memoryStorage(), 
  limits: { fileSize: 5 * 1024 * 1024 }
});

const updateProfileSchema = z.object({
  pseudonym: z.string().max(50).optional(),
  displayName: z.string().max(50).optional(),
  realFirstName: z.string().max(50).optional().nullable(),
  legalFullName: z.string().max(100).optional().nullable(),
  handle: z.string().max(30).optional().nullable(),
  nameDisplayPreference: z.enum(['DISPLAY_NAME_ONLY', 'FIRST_NAME_PUBLIC']).optional(),
  bio: z.string().max(500).optional(),
  location: z.string().max(100).optional(),
  profession: z.string().max(100).optional(),
  interests: z.array(z.string()).max(10).optional(),
  feelings: z.array(z.string()).max(10).optional(),
  supportTypes: z.array(z.string()).max(5).optional(),
  isAnonymous: z.boolean().optional(),
}).strict();

// GET /users/me - Get current user profile
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true, email: true, pseudonym: true, displayName: true, realFirstName: true,
        legalFullName: true, handle: true, nameDisplayPreference: true, images: true, xp: true, isAnonymous: true,
        bio: true, location: true, profession: true, interests: true, feelings: true, supportTypes: true, emailVerified: true,
        scheduledDeletionDate: true
      }
    });
    if (!user) return res.status(401).json({ error: 'User not found (Session invalid)' });
    res.json({
      ...user,
      displayName: user.displayName || user.pseudonym,
      name: (user.nameDisplayPreference === 'FIRST_NAME_PUBLIC' && user.realFirstName) 
        ? user.realFirstName 
        : (user.displayName || user.pseudonym || 'User'),
      avatarUrl: user.images.length > 0 ? user.images[0] : null
    });
  } catch (error) {
    next(error);
  }
});

// PUT /users/me - Update profile
router.put('/me', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const data = updateProfileSchema.parse(req.body);

    if (data.displayName || data.pseudonym) {
      const aliasToCheck = data.displayName || data.pseudonym;
      const validation = validateDisplayName(aliasToCheck);
      if (!validation.isValid) {
        return res.status(400).json({ error: validation.error });
      }
      data.displayName = validation.cleaned;
      data.pseudonym = validation.cleaned;
    }

    if (data.handle) {
      data.handle = sanitizeHandle(data.handle);
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data,
      select: {
        id: true, pseudonym: true, displayName: true, realFirstName: true, legalFullName: true,
        handle: true, nameDisplayPreference: true, images: true, bio: true, location: true, profession: true,
        interests: true, feelings: true, supportTypes: true, isAnonymous: true
      }
    });

    res.json({
      ...updatedUser,
      displayName: updatedUser.displayName || updatedUser.pseudonym,
      name: (updatedUser.nameDisplayPreference === 'FIRST_NAME_PUBLIC' && updatedUser.realFirstName) 
        ? updatedUser.realFirstName 
        : (updatedUser.displayName || updatedUser.pseudonym || 'User'),
      avatarUrl: updatedUser.images.length > 0 ? updatedUser.images[0] : null
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

// POST /users/me/photos - Append photo
router.post('/me/photos', authenticateToken, requireVerified, upload.single('photo'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No photo provided' });

    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (user.images.length >= MAX_PHOTOS) {
      return res.status(400).json({ error: `Maximum of ${MAX_PHOTOS} photos allowed` });
    }

    const savedUrl = await processAndSaveImage(req.file.buffer);

    const updated = await prisma.user.update({
      where: { id: user.id, photoVersion: user.photoVersion },
      data: {
        images: { push: savedUrl },
        photoVersion: { increment: 1 }
      },
      select: { images: true }
    });

    res.json({ images: updated.images });
  } catch (error) {
    if (error.code === 'P2025') return res.status(409).json({ error: 'Concurrent update detected, please retry' });
    next(error);
  }
});

// PUT /users/me/photos/order
router.put('/me/photos/order', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { images } = req.body;
    if (!Array.isArray(images)) return res.status(400).json({ error: 'images array required' });

    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    
    // Validate exact permutation
    const currentSet = new Set(user.images);
    const newSet = new Set(images);
    if (images.length !== user.images.length || currentSet.size !== newSet.size || [...currentSet].some(url => !newSet.has(url))) {
      return res.status(400).json({ error: 'Invalid ordered list. Must be an exact permutation of current photos.' });
    }

    const updated = await prisma.user.update({
      where: { id: user.id, photoVersion: user.photoVersion },
      data: {
        images: images,
        photoVersion: { increment: 1 }
      },
      select: { images: true }
    });

    res.json({ images: updated.images });
  } catch (error) {
    if (error.code === 'P2025') return res.status(409).json({ error: 'Concurrent update detected, please retry' });
    next(error);
  }
});

// DELETE /users/me/photos
router.delete('/me/photos', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { url } = req.body;
    if (!url) return res.status(400).json({ error: 'url required' });

    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    
    if (!user.images.includes(url)) {
      return res.status(404).json({ error: 'Photo not found' });
    }
    
    if (user.images.length <= MIN_PHOTOS) {
      return res.status(400).json({ error: `Minimum of ${MIN_PHOTOS} photos required` });
    }

    const newImages = user.images.filter(img => img !== url);

    const updated = await prisma.user.update({
      where: { id: user.id, photoVersion: user.photoVersion },
      data: {
        images: newImages,
        photoVersion: { increment: 1 }
      },
      select: { images: true }
    });

    // Only delete file if DB update succeeds
    deleteImage(url);

    res.json({ images: updated.images });
  } catch (error) {
    if (error.code === 'P2025') return res.status(409).json({ error: 'Concurrent update detected, please retry' });
    next(error);
  }
});


// POST /users/:id/block
router.post('/:id/block', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const blockerId = req.user.id;
    
    await prisma.block.create({
      data: { blockerId, blockedId: targetUserId }
    });
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

// POST /users/:id/report
router.post('/:id/report', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const reporterId = req.user.id;
    const { reason, description, photoUrl } = req.body;
    
    // Ensure photoUrl belongs to target user if provided
    if (photoUrl) {
      const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
      if (!targetUser || !targetUser.images.includes(photoUrl)) {
        return res.status(400).json({ error: 'photoUrl does not belong to the user' });
      }
    }

    await prisma.report.create({
      data: {
        reporterId,
        reportedId: targetUserId,
        reason,
        description,
        reportedPhotoUrl: photoUrl || null
      }
    });
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

// DELETE /users/me - Schedule account deletion with 30-day grace period
router.delete('/me', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const scheduledDeletionDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        scheduledDeletionDate,
        deletionRequestedAt: now,
      },
      select: {
        id: true,
        email: true,
        scheduledDeletionDate: true,
      }
    });

    res.json({
      success: true,
      message: 'Account scheduled for deletion in 30 days. To continue from where you left, just log in before the scheduled date.',
      scheduledDeletionDate: user.scheduledDeletionDate,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

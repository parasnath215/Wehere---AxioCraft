const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '../../public/uploads');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname)}`);
  }
});
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type.'));
  }
};
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 }, fileFilter });

// GET /users/me - Get current user profile
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        pseudonym: true,
        images: true,
        xp: true,
        isAnonymous: true,
        bio: true,
        location: true,
        interests: true,
        feelings: true,
        supportTypes: true,
        lookingFor: true,
      }
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    next(error);
  }
});

// PUT /users/me - Update profile
router.put('/me', authenticateToken, upload.single('avatar'), async (req, res, next) => {
  try {
    const { pseudonym, bio, location, lookingFor } = req.body;
    const dataToUpdate = {};
    
    if (pseudonym !== undefined) dataToUpdate.pseudonym = pseudonym;
    if (bio !== undefined) dataToUpdate.bio = bio;
    if (location !== undefined) dataToUpdate.location = location;
    if (lookingFor !== undefined) dataToUpdate.lookingFor = lookingFor;

    if (req.file) {
      const newAvatarUrl = `/uploads/${req.file.filename}`;
      // In a real app we might delete the old image or add to array.
      // Assuming images[0] is the main avatar for simplicity.
      const currentUser = await prisma.user.findUnique({ where: { id: req.user.id }});
      let newImages = currentUser.images || [];
      if (newImages.length > 0) {
        newImages[0] = newAvatarUrl;
      } else {
        newImages.push(newAvatarUrl);
      }
      dataToUpdate.images = newImages;
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: dataToUpdate,
      select: {
        id: true,
        pseudonym: true,
        images: true,
        bio: true,
        location: true,
        lookingFor: true,
      }
    });

    res.json(updatedUser);
  } catch (error) {
    next(error);
  }
});

// POST /users/:id/block - Block a user
router.post('/:id/block', authenticateToken, async (req, res, next) => {
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

// POST /users/:id/report - Report a user
router.post('/:id/report', authenticateToken, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const reporterId = req.user.id;
    const { reason, description } = req.body;
    
    await prisma.report.create({
      data: {
        reporterId,
        reportedId: targetUserId,
        reason,
        description
      }
    });
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

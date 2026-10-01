const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const { z } = require('zod');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middleware/auth');

const prisma = new PrismaClient();

// Configure Multer for local uploads
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
    cb(new Error('Invalid file type. Only JPEG, PNG, and WebP are allowed.'));
  }
};

const upload = multer({ 
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max size
  fileFilter 
});

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  pseudonym: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

// Anonymous Signup
router.post('/anonymous', async (req, res) => {
  try {
    const user = await prisma.user.create({
      data: {
        isAnonymous: true,
      },
    });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Email/Password Signup (Multipart with Images)
router.post('/signup', upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'At least 2 profile images are required.' });
    }

    const { email, password, pseudonym } = signupSchema.parse(req.body);
    const imagePaths = req.files.map(f => `/uploads/${f.filename}`);

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        pseudonym: pseudonym || 'Anonymous',
        images: imagePaths,
        isAnonymous: false,
      },
    });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, images: user.images } });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    if (error.code === 'P2002') return res.status(400).json({ error: 'Email already exists' });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) return res.status(400).json({ error: 'Invalid credentials' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(400).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, role: user.role } });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Fake OTP Request
router.post('/otp/request', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });
    
    // In a real app, integrate Twilio/SendGrid here based on ENV var.
    // For now, auto-approve or return a mock token.
    res.json({ message: 'OTP sent successfully (mock)', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Fake OTP Verify
router.post('/otp/verify', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP required' });
    
    if (otp === '123456') { // Mock OTP
      res.json({ message: 'OTP verified successfully', success: true });
    } else {
      res.status(400).json({ error: 'Invalid OTP' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Complete Onboarding
router.put('/onboarding', authenticate, async (req, res) => {
  try {
    const { name, location, interests, feelings, supportTypes, isAnonymous } = req.body;
    const userId = req.user.id; // from authenticate middleware

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        pseudonym: name,
        location: location,
        interests: interests || [],
        feelings: feelings || [],
        supportTypes: supportTypes || [],
        isAnonymous: isAnonymous || false,
      },
    });

    res.json({ message: 'Onboarding completed', user: updatedUser });
  } catch (error) {
    console.error('Onboarding Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');
const { z } = require('zod');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { sendEmail } = require('../services/email');
const { processAndSaveImage } = require('../services/storage');

const prisma = new PrismaClient();

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } 
});

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+={}\[\]|\\:;"'<>,.?/~`]).{8,}$/;
const signupSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().regex(passwordRegex, 'Password must be at least 8 characters, contain 1 uppercase, 1 lowercase, and 1 special character.'),
  pseudonym: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().min(1, 'Identifier is required'),
  password: z.string(),
});

const otpRequestLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  handler: (req, res) => {
    res.status(429).json({ error: 'Too many requests from this IP.', cooldown: 3600 });
  }
});

function generateOtp() {
  if (process.env.TEST_OTP_ENABLED === 'true') {
    return '123456';
  }
  return crypto.randomInt(100000, 999999).toString();
}

async function sendOtpEmail(email, code, purpose) {
  const subject = purpose === 'verify_email' ? 'Verify your Wehere email' : 'Reset your Wehere password';
  const text = `Your 6-digit code is: ${code}. It expires in 10 minutes.\nIf you didn't request this, ignore it.`;
  const html = `<p>Your 6-digit code is: <strong>${code}</strong></p><p>It expires in 10 minutes.</p><p><small>If you didn't request this, ignore it.</small></p>`;
  await sendEmail({ to: email, subject, text, html });
}

// Anonymous Signup
router.post('/anonymous', async (req, res) => {
  try {
    const user = await prisma.user.create({
      data: { isAnonymous: true },
    });
    const token = jwt.sign({ id: user.id, role: user.role, tokenVersion: user.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Email/Password Signup (Multipart with Images)
router.post('/signup', upload.array('images', 6), async (req, res) => {
  try {
    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'At least 2 profile images are required.' });
    }
    const { email, password, pseudonym } = signupSchema.parse(req.body);
    
    const imagePaths = await Promise.all(req.files.map(f => processAndSaveImage(f.buffer)));
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

    const token = jwt.sign({ id: user.id, role: user.role, tokenVersion: user.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '7d' });
    
    // Automatically generate and send the first OTP silently
    try {
      const code = generateOtp();
      const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(code).digest('hex');
      await prisma.otpRecord.create({
        data: {
          purpose: 'verify_email',
          codeHash,
          expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 min
          userId: user.id,
        }
      });
      await sendOtpEmail(email, code, 'verify_email');
    } catch (e) {
      console.error('Failed to send initial OTP on signup:', e.message);
    }

    res.json({ token, user: { id: user.id, email: user.email, images: user.images, emailVerified: user.emailVerified } });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'Validation failed', details: error.errors });
    if (error.code === 'P2002') return res.status(400).json({ error: 'Email already exists' });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Login
router.post('/login', rateLimit({ windowMs: 15*60*1000, max: 10 }), async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);

    const user = await prisma.user.findFirst({ 
      where: {
        OR: [
          { email },
          { username: email },
          { pseudonym: email }
        ]
      } 
    });
    if (!user || !user.password) return res.status(400).json({ error: 'Invalid credentials' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(400).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, role: user.role, tokenVersion: user.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, role: user.role, emailVerified: user.emailVerified } });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'Validation failed', details: error.errors });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// OTP Request (Resend or Forgot Password)
router.post('/otp/request', otpRequestLimiter, async (req, res) => {
  try {
    const { email, purpose = 'verify_email' } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });
    if (!['verify_email', 'reset_password'].includes(purpose)) {
      return res.status(400).json({ error: 'Invalid purpose' });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    // Always return a success response to prevent email enumeration
    const genericResponse = { message: 'If the email exists, a code was sent.', success: true, cooldown: 60 };

    if (!user) return res.json(genericResponse);

    // Cooldown check (60s)
    const recentOtp = await prisma.otpRecord.findFirst({
      where: { userId: user.id, purpose },
      orderBy: { createdAt: 'desc' }
    });

    if (recentOtp && (Date.now() - recentOtp.createdAt.getTime()) < 60000) {
      return res.status(429).json({ error: 'Please wait 60 seconds before requesting a new code.', cooldown: Math.ceil(60 - (Date.now() - recentOtp.createdAt.getTime())/1000) });
    }

    // Invalidate previous OTPs for this purpose
    await prisma.otpRecord.updateMany({
      where: { userId: user.id, purpose, usedAt: null },
      data: { usedAt: new Date() } // Mark unused as invalidated
    });

    const code = generateOtp();
    const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(code).digest('hex');

    await prisma.otpRecord.create({
      data: {
        purpose,
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 min
        userId: user.id,
      }
    });

    await sendOtpEmail(email, code, purpose);
    res.json(genericResponse);
  } catch (error) {
    console.error('OTP Request Error:', error.message);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// OTP Verify (Email Verification)
router.post('/otp/verify', authenticateToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const userId = req.user.id;
    if (!otp) return res.status(400).json({ error: 'OTP required' });

    const record = await prisma.otpRecord.findFirst({
      where: { userId, purpose: 'verify_email', usedAt: null },
      orderBy: { createdAt: 'desc' }
    });

    if (!record) return res.status(400).json({ error: 'No active OTP found. Please request a new one.' });
    if (record.attempts >= 5) return res.status(400).json({ error: 'Too many failed attempts. Please request a new code.' });
    if (new Date() > record.expiresAt) return res.status(400).json({ error: 'Code expired. Please request a new one.' });

    const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(otp).digest('hex');
    
    if (record.codeHash !== codeHash) {
      await prisma.otpRecord.update({ where: { id: record.id }, data: { attempts: record.attempts + 1 } });
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Success
    await prisma.$transaction([
      prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      prisma.user.update({ where: { id: userId }, data: { emailVerified: true, emailVerifiedAt: new Date() } })
    ]);

    res.json({ message: 'Email verified successfully', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Reset Password Verify
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: 'Valid email, OTP, and new password (min 6 chars) required.' });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(400).json({ error: 'Invalid request' });

    const record = await prisma.otpRecord.findFirst({
      where: { userId: user.id, purpose: 'reset_password', usedAt: null },
      orderBy: { createdAt: 'desc' }
    });

    if (!record) return res.status(400).json({ error: 'No active OTP found. Please request a new one.' });
    if (record.attempts >= 5) return res.status(400).json({ error: 'Too many failed attempts. Please request a new code.' });
    if (new Date() > record.expiresAt) return res.status(400).json({ error: 'Code expired. Please request a new one.' });

    const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(otp).digest('hex');
    
    if (record.codeHash !== codeHash) {
      await prisma.otpRecord.update({ where: { id: record.id }, data: { attempts: record.attempts + 1 } });
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Success
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.$transaction([
      prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      prisma.user.update({ where: { id: user.id }, data: { password: hashedPassword, tokenVersion: user.tokenVersion + 1 } })
    ]);

    res.json({ message: 'Password reset successfully', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const onboardingSchema = z.object({
  name: z.string().max(50).optional(),
  location: z.string().max(100).optional(),
  interests: z.array(z.string()).max(10).optional(),
  feelings: z.array(z.string()).max(10).optional(),
  supportTypes: z.array(z.string()).max(5).optional(),
  isAnonymous: z.boolean().optional(),
});

// Complete Onboarding
router.put('/onboarding', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { name, location, interests, feelings, supportTypes, isAnonymous } = onboardingSchema.parse(req.body);
    const userId = req.user.id; 

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
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'Validation failed', details: error.errors });
    console.error('Onboarding Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Change Password
router.post('/change-password', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.password) return res.status(400).json({ error: 'Cannot change password for this account' });

    const validPassword = await bcrypt.compare(currentPassword, user.password);
    if (!validPassword) return res.status(400).json({ error: 'Invalid current password' });
    if (newPassword.length < 6) return res.status(400).json({ error: 'New password must be at least 6 characters' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword, tokenVersion: user.tokenVersion + 1 }
    });

    res.json({ message: 'Password updated successfully', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;

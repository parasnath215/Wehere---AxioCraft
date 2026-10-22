const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { z } = require('zod');
const multer = require('multer');
const { OAuth2Client } = require('google-auth-library');

const googleClient = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID || '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com'
);

// F10: Shared Prisma client
const prisma = require('../lib/prisma');

const {
  signupLimiter,
  otpVerifyLimiter,
  otpRequestLimiter,
  resetPasswordLimiter,
  loginLimiter,
} = require('../middleware/rateLimits');
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { sendEmail } = require('../services/email');
const { processAndSaveImage, deleteImage } = require('../services/storage');
const { evaluateStreak } = require('../services/streak');
const { validateDisplayName, sanitizeHandle } = require('../services/identityFilter');
const { parseDob, calcAge } = require('../utils/age');
const { passwordSchema } = require('../utils/password');

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } 
});

const signupSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: passwordSchema,
  pseudonym: z.string().optional(),
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().min(1, 'Email is required'),
  password: z.string().min(1, 'Password is required'),
});

// F1: generateOtp() returns '123456' ONLY when TEST_OTP_ENABLED === 'true' && NODE_ENV !== 'production'
function generateOtp() {
  if (process.env.TEST_OTP_ENABLED === 'true' && process.env.NODE_ENV !== 'production') {
    return '123456';
  }
  return crypto.randomInt(100000, 1000000).toString();
}

async function sendOtpEmail(email, code, purpose) {
  const subject = purpose === 'verify_email' ? 'Verify your Wehere email' : 'Reset your Wehere password';
  const text = `Your 6-digit code is: ${code}. It expires in 10 minutes.\nIf you didn't request this, ignore it.`;
  const html = `<p>Your 6-digit code is: <strong>${code}</strong></p><p>It expires in 10 minutes.</p><p><small>If you didn't request this, ignore it.</small></p>`;
  await sendEmail({ to: email, subject, text, html });
}

// F4: Email/Password Signup (Multipart with Images)
// Creates a PendingSignup row in the database; returns a minimal signupToken
router.post('/signup', signupLimiter, upload.array('images', 6), async (req, res) => {
  try {
    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'At least 2 profile images are required.' });
    }
    const { email, password, pseudonym, phone } = signupSchema.parse(req.body);
    const normalizedEmail = email.trim().toLowerCase();
    const rawPhone = phone && phone.trim().length > 0 ? phone.trim() : null;
    const normalizedPhone = rawPhone ? rawPhone.replace(/[^\d+]/g, '') : null;

    // Check if user already exists and is verified
    const existingUser = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });

    if (existingUser && existingUser.emailVerified) {
      return res.status(409).json({ error: 'CONFLICT', message: 'This email is already registered and verified. Please log in.' });
    }

    // Delete any stale unverified User record
    if (existingUser && !existingUser.emailVerified) {
      await prisma.user.deleteMany({
        where: { email: normalizedEmail, emailVerified: false }
      });
    }

    // Delete any existing PendingSignup row for that email and purge its stored images
    const existingPending = await prisma.pendingSignup.findUnique({
      where: { email: normalizedEmail }
    });
    if (existingPending) {
      if (existingPending.images && Array.isArray(existingPending.images)) {
        existingPending.images.forEach(img => {
          try { deleteImage(img); } catch (_) {}
        });
      }
      await prisma.pendingSignup.delete({
        where: { id: existingPending.id }
      });
    }

    const imagePaths = await Promise.all(req.files.map(f => processAndSaveImage(f.buffer)));
    const hashedPassword = await bcrypt.hash(password, 10);

    // Ensure pseudonym is unique among verified users
    let desiredPseudonym = (pseudonym && pseudonym.trim().length > 0) ? pseudonym.trim() : 'user';
    let uniqueHandle = desiredPseudonym;
    let handleExists = await prisma.user.findFirst({
      where: {
        OR: [
          { pseudonym: uniqueHandle },
          { username: uniqueHandle }
        ],
        emailVerified: true
      }
    });

    while (handleExists) {
      uniqueHandle = `${desiredPseudonym}_${crypto.randomInt(1000, 9999)}`;
      handleExists = await prisma.user.findFirst({
        where: {
          OR: [
            { pseudonym: uniqueHandle },
            { username: uniqueHandle }
          ],
          emailVerified: true
        }
      });
    }

    // Generate OTP and bcrypt hash
    const code = generateOtp();
    const codeHash = await bcrypt.hash(code, 10);

    // Save pending signup row with 10 min expiry
    const pending = await prisma.pendingSignup.create({
      data: {
        email: normalizedEmail,
        phone: normalizedPhone || null,
        passwordHash: hashedPassword,
        pseudonym: uniqueHandle,
        images: imagePaths,
        codeHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      }
    });

    // Return signupToken containing ONLY purpose and pendingId
    const signupToken = jwt.sign(
      {
        purpose: 'pending_signup',
        pendingId: pending.id,
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    try {
      await sendOtpEmail(normalizedEmail, code, 'verify_email');
    } catch (e) {
      console.error('Failed to send initial OTP on signup:', e.message);
    }

    res.json({
      success: true,
      pendingVerification: true,
      signupToken,
      message: 'Verification code sent to your email.'
    });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'VALIDATION_ERROR', message: error.errors[0]?.message || 'Validation failed' });
    if (error.code === 'P2002') return res.status(409).json({ error: 'CONFLICT', message: 'Email already exists' });
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// F3 & F8: Login by normalized EMAIL ONLY; returns 401 INVALID_CREDENTIALS on bad credentials
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const normalizedEmail = email.trim().toLowerCase();

    const user = await prisma.user.findFirst({ 
      where: { email: normalizedEmail } 
    });
    if (!user || !user.password) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' });
    }

    // F2: Ban check
    if (user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    // F5: Enforce email verification before logging in
    if (!user.emailVerified && !user.isAnonymous) {
      await prisma.otpRecord.updateMany({
        where: { userId: user.id, purpose: 'verify_email', usedAt: null },
        data: { usedAt: new Date() }
      });

      const code = generateOtp();
      const codeHash = await bcrypt.hash(code, 10);
      await prisma.otpRecord.create({
        data: {
          purpose: 'verify_email',
          codeHash,
          expiresAt: new Date(Date.now() + 10 * 60 * 1000),
          userId: user.id,
        }
      });
      if (user.email) {
        await sendOtpEmail(user.email, code, 'verify_email');
      }

      // F5: 15-minute token with purpose: 'verify_email'
      const token = jwt.sign(
        { id: user.id, purpose: 'verify_email' },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
      );
      return res.status(403).json({
        error: 'EMAIL_NOT_VERIFIED',
        message: 'Please verify your email before logging in. A new verification code has been sent to your email.',
        token,
        email: user.email,
        user: { id: user.id, email: user.email, emailVerified: false }
      });
    }

    // Check if account was scheduled for deletion
    if (user.scheduledDeletionDate) {
      const now = new Date();
      if (now.getTime() >= new Date(user.scheduledDeletionDate).getTime()) {
        await prisma.user.delete({ where: { id: user.id } });
        if (user.images) user.images.forEach(deleteImage);
        return res.status(410).json({
          error: 'ACCOUNT_DELETED',
          message: 'This account was permanently deleted after the 30-day grace period.'
        });
      } else {
        await prisma.user.update({
          where: { id: user.id },
          data: {
            scheduledDeletionDate: null,
            deletionRequestedAt: null,
          }
        });
        user.scheduledDeletionDate = null;
        user.deletionRequestedAt = null;
      }
    }

    // Evaluate streak on login
    const streakResult = evaluateStreak(user);
    if (streakResult.shouldUpdate) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          currentStreak: streakResult.currentStreak,
          lastLoginDate: streakResult.lastLoginDate,
        }
      });
      user.currentStreak = streakResult.currentStreak;
      user.lastLoginDate = streakResult.lastLoginDate;
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, tokenVersion: user.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        emailVerified: user.emailVerified,
        currentStreak: user.currentStreak
      }
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' });
    }
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /auth/google - Social login with Google ID token
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Google idToken is required' });
    }

    // Verify token with Google
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: [
          '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com',
          '477223765836-s04n00edhkkoj7hlkc76qqs52iotkfa0.apps.googleusercontent.com',
          process.env.GOOGLE_CLIENT_ID,
        ].filter(Boolean),
      });
      payload = ticket.getPayload();
    } catch (verifyErr) {
      console.error('Google token verification failed:', verifyErr.message);
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid or expired Google token.' });
    }

    const { sub: googleId, email, name, picture } = payload;
    if (!email) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Google account has no email address.' });
    }
    const normalizedEmail = email.trim().toLowerCase();

    // Find existing user by googleId or email
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { googleId },
          { email: normalizedEmail },
        ]
      }
    });

    // F2: Ban check
    if (user && user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    // F12: Underage blocked check
    if (user && user.underageBlockedAt) {
      return res.status(403).json({
        error: 'UNDERAGE',
        message: 'You must be at least 18 years old to use Wehere.',
      });
    }

    // If user doesn't exist, create them
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: normalizedEmail,
          googleId,
          pseudonym: name || 'Explorer',
          displayName: name,
          avatar: picture,
          emailVerified: true,
          emailVerifiedAt: new Date(),
          role: 'USER',
        }
      });
    } else {
      // Link googleId or update email verification if needed
      const updateData = {};
      if (!user.googleId) updateData.googleId = googleId;
      if (!user.emailVerified) {
        updateData.emailVerified = true;
        updateData.emailVerifiedAt = new Date();
      }
      if (user.scheduledDeletionDate) {
        updateData.scheduledDeletionDate = null;
        updateData.deletionRequestedAt = null;
      }
      if (Object.keys(updateData).length > 0) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: updateData,
        });
      }
    }

    // Evaluate streak
    const streakResult = evaluateStreak(user);
    if (streakResult && streakResult.shouldUpdate) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          currentStreak: streakResult.currentStreak,
          lastLoginDate: streakResult.lastLoginDate,
        }
      });
      user.currentStreak = streakResult.currentStreak;
      user.lastLoginDate = streakResult.lastLoginDate;
    }

    // Issue 7-day session token (with no purpose claim)
    const token = jwt.sign(
      { id: user.id, role: user.role, tokenVersion: user.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        pseudonym: user.pseudonym,
        displayName: user.displayName,
        avatar: user.avatar,
        images: user.images || [],
        interests: user.interests || [],
        emailVerified: user.emailVerified,
        currentStreak: user.currentStreak,
        dateOfBirth: user.dateOfBirth,
      },
      requiresDob: !user.dateOfBirth,
    });
  } catch (error) {
    console.error('Google auth error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /auth/google/check - Check if Google account already exists in DB
router.post('/google/check', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Google idToken is required' });
    }

    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: [
          '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com',
          '477223765836-s04n00edhkkoj7hlkc76qqs52iotkfa0.apps.googleusercontent.com',
          process.env.GOOGLE_CLIENT_ID,
        ].filter(Boolean),
      });
      payload = ticket.getPayload();
    } catch (verifyErr) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid Google token' });
    }

    const { sub: googleId, email, name, picture } = payload;
    const normalizedEmail = (email || '').trim().toLowerCase();

    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { googleId },
          ...(normalizedEmail ? [{ email: normalizedEmail }] : []),
        ]
      }
    });

    res.json({
      success: true,
      exists: !!existingUser,
      email: normalizedEmail,
      name,
      picture,
    });
  } catch (err) {
    console.error('google/check error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /auth/register-google - Direct registration with Google verification (skips OTP)
router.post('/register-google', signupLimiter, upload.array('images', 6), async (req, res) => {
  try {
    const { idToken, pseudonym, password, phone } = req.body;
    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Google idToken is required' });
    }

    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'At least 2 profile images are required.' });
    }

    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: [
          '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com',
          '477223765836-s04n00edhkkoj7hlkc76qqs52iotkfa0.apps.googleusercontent.com',
          process.env.GOOGLE_CLIENT_ID,
        ].filter(Boolean),
      });
      payload = ticket.getPayload();
    } catch (verifyErr) {
      console.error('Google token verification failed in register-google:', verifyErr.message);
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid or expired Google token.' });
    }

    const { sub: googleId, email, name, picture } = payload;
    if (!email) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Google account has no email address.' });
    }
    const normalizedEmail = email.trim().toLowerCase();

    // Check if user already exists
    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { googleId },
          { email: normalizedEmail }
        ]
      }
    });

    if (existing) {
      return res.status(409).json({ error: 'CONFLICT', message: 'An account with this email already exists. Please log in.' });
    }

    const imagePaths = await Promise.all(req.files.map(f => processAndSaveImage(f.buffer)));

    let hashedPassword = null;
    if (password && typeof password === 'string' && password.trim().length > 0) {
      hashedPassword = await bcrypt.hash(password.trim(), 10);
    }

    let desiredPseudonym = (pseudonym && pseudonym.trim().length > 0) ? pseudonym.trim() : (name || 'Explorer');
    let uniqueHandle = desiredPseudonym;
    let handleExists = await prisma.user.findFirst({
      where: {
        OR: [
          { pseudonym: uniqueHandle },
          { username: uniqueHandle }
        ],
        emailVerified: true
      }
    });
    while (handleExists) {
      uniqueHandle = `${desiredPseudonym}_${crypto.randomInt(1000, 9999)}`;
      handleExists = await prisma.user.findFirst({
        where: {
          OR: [
            { pseudonym: uniqueHandle },
            { username: uniqueHandle }
          ],
          emailVerified: true
        }
      });
    }

    const user = await prisma.user.create({
      data: {
        email: normalizedEmail,
        googleId,
        password: hashedPassword,
        pseudonym: uniqueHandle,
        displayName: name || desiredPseudonym,
        avatar: imagePaths[0] || picture,
        images: imagePaths,
        phone: phone ? phone.trim() : null,
        emailVerified: true,
        emailVerifiedAt: new Date(),
        role: 'USER',
      }
    });

    const token = jwt.sign(
      { id: user.id, role: user.role, tokenVersion: user.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        pseudonym: user.pseudonym,
        displayName: user.displayName,
        avatar: user.avatar,
        images: user.images,
        emailVerified: user.emailVerified,
        currentStreak: user.currentStreak,
        dateOfBirth: user.dateOfBirth,
      },
      requiresDob: !user.dateOfBirth,
    });
  } catch (error) {
    console.error('register-google error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /auth/apple - Social login with Apple
router.post('/apple', async (req, res) => {
  try {
    const { identityToken, appleId: clientAppleId, email: clientEmail, givenName, familyName } = req.body;
    if (!identityToken || typeof identityToken !== 'string') {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Apple identityToken is required' });
    }

    const decoded = jwt.decode(identityToken, { complete: true });
    if (!decoded || !decoded.payload) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid Apple identity token.' });
    }

    const { sub: appleId, email: tokenEmail } = decoded.payload;
    const finalEmail = (tokenEmail || clientEmail || '').trim().toLowerCase();
    const finalAppleId = appleId || clientAppleId;

    if (!finalAppleId) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Apple user identifier not found.' });
    }

    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { appleId: finalAppleId },
          ...(finalEmail ? [{ email: finalEmail }] : []),
        ]
      }
    });

    if (user && user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    if (user && user.underageBlockedAt) {
      return res.status(403).json({
        error: 'UNDERAGE',
        message: 'You must be at least 18 years old to use Wehere.',
      });
    }

    const displayName = (givenName || familyName) ? `${givenName || ''} ${familyName || ''}`.trim() : 'Apple User';

    if (!user) {
      user = await prisma.user.create({
        data: {
          email: finalEmail || `${finalAppleId}@privaterelay.appleid.com`,
          appleId: finalAppleId,
          pseudonym: displayName || 'Explorer',
          displayName,
          emailVerified: true,
          emailVerifiedAt: new Date(),
          role: 'USER',
        }
      });
    } else {
      const updateData = {};
      if (!user.appleId) updateData.appleId = finalAppleId;
      if (!user.emailVerified) {
        updateData.emailVerified = true;
        updateData.emailVerifiedAt = new Date();
      }
      if (Object.keys(updateData).length > 0) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: updateData,
        });
      }
    }

    const streakResult = evaluateStreak(user);
    if (streakResult && streakResult.shouldUpdate) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          currentStreak: streakResult.currentStreak,
          lastLoginDate: streakResult.lastLoginDate,
        }
      });
      user.currentStreak = streakResult.currentStreak;
      user.lastLoginDate = streakResult.lastLoginDate;
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, tokenVersion: user.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        pseudonym: user.pseudonym,
        displayName: user.displayName,
        emailVerified: user.emailVerified,
        currentStreak: user.currentStreak,
      },
      requiresDob: !user.dateOfBirth,
    });
  } catch (error) {
    console.error('Apple auth error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// F3: OTP Request (Resend or Forgot Password)
// Always responds exactly { success: true, message: 'If the account exists, a code was sent to the registered email.', cooldown: 60 }
router.post('/otp/request', otpRequestLimiter, async (req, res) => {
  try {
    const { email, purpose = 'verify_email', signupToken } = req.body;
    let authHeaderToken = null;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      authHeaderToken = req.headers.authorization.split(' ')[1];
    }
    const tokenToUse = signupToken || authHeaderToken;

    // F4: Handle pending signup OTP resend
    if (tokenToUse) {
      try {
        const decoded = jwt.verify(tokenToUse, process.env.JWT_SECRET);
        if (decoded.purpose === 'pending_signup') {
          const pending = await prisma.pendingSignup.findUnique({
            where: { id: decoded.pendingId }
          });
          if (pending) {
            const code = generateOtp();
            const codeHash = await bcrypt.hash(code, 10);
            await prisma.pendingSignup.update({
              where: { id: pending.id },
              data: {
                codeHash,
                attempts: 0,
                expiresAt: new Date(Date.now() + 10 * 60 * 1000),
              }
            });

            await sendOtpEmail(pending.email, code, 'verify_email');
            return res.json({
              success: true,
              message: 'If the account exists, a code was sent to the registered email.',
              cooldown: 60
            });
          }
        } else if (decoded.purpose === 'verify_email') {
          // F5: Unverified user OTP resend
          const user = await prisma.user.findUnique({ where: { id: decoded.id } });
          if (user) {
            if (user.isBanned) {
              return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
            }

            const recentOtp = await prisma.otpRecord.findFirst({
              where: { userId: user.id, purpose: 'verify_email' },
              orderBy: { createdAt: 'desc' }
            });

            if (recentOtp && (Date.now() - recentOtp.createdAt.getTime()) < 60000) {
              return res.status(429).json({
                error: 'RATE_LIMITED',
                message: 'If the account exists, a code was sent to the registered email.',
                cooldown: Math.ceil(60 - (Date.now() - recentOtp.createdAt.getTime()) / 1000)
              });
            }

            await prisma.otpRecord.updateMany({
              where: { userId: user.id, purpose: 'verify_email', usedAt: null },
              data: { usedAt: new Date() }
            });

            const code = generateOtp();
            const codeHash = await bcrypt.hash(code, 10);
            await prisma.otpRecord.create({
              data: {
                purpose: 'verify_email',
                codeHash,
                expiresAt: new Date(Date.now() + 10 * 60 * 1000),
                userId: user.id,
              }
            });

            await sendOtpEmail(user.email, code, 'verify_email');
            return res.json({
              success: true,
              message: 'If the account exists, a code was sent to the registered email.',
              cooldown: 60
            });
          }
        }
      } catch (err) {
        // Fall through to regular email handling
      }
    }

    if (!email) {
      return res.json({
        success: true,
        message: 'If the account exists, a code was sent to the registered email.',
        cooldown: 60
      });
    }

    // F3: Identify user by normalized EMAIL ONLY
    const normalizedEmail = email.trim().toLowerCase();
    const user = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });

    const genericSuccess = {
      success: true,
      message: 'If the account exists, a code was sent to the registered email.',
      cooldown: 60
    };

    if (!user || !user.email) {
      return res.json(genericSuccess);
    }

    if (user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    // Cooldown check (60s)
    const recentOtp = await prisma.otpRecord.findFirst({
      where: { userId: user.id, purpose },
      orderBy: { createdAt: 'desc' }
    });

    if (recentOtp && (Date.now() - recentOtp.createdAt.getTime()) < 60000) {
      return res.status(429).json({
        error: 'RATE_LIMITED',
        message: 'If the account exists, a code was sent to the registered email.',
        cooldown: Math.ceil(60 - (Date.now() - recentOtp.createdAt.getTime()) / 1000)
      });
    }

    await prisma.otpRecord.updateMany({
      where: { userId: user.id, purpose, usedAt: null },
      data: { usedAt: new Date() }
    });

    const code = generateOtp();
    const codeHash = await bcrypt.hash(code, 10);

    await prisma.otpRecord.create({
      data: {
        purpose,
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        userId: user.id,
      }
    });

    await sendOtpEmail(user.email, code, purpose);
    res.json(genericSuccess);
  } catch (error) {
    console.error('OTP Request Error:', error.message);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// F4 & F5: OTP Verify (Email Verification)
router.post('/otp/verify', otpVerifyLimiter, async (req, res) => {
  try {
    const { otp, signupToken } = req.body;
    let authHeaderToken = null;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      authHeaderToken = req.headers.authorization.split(' ')[1];
    }
    const tokenToUse = signupToken || authHeaderToken;

    if (!otp) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'OTP required' });

    // 1. Pending Signup Flow (F4)
    if (tokenToUse) {
      try {
        const decoded = jwt.verify(tokenToUse, process.env.JWT_SECRET);
        if (decoded.purpose === 'pending_signup') {
          const pending = await prisma.pendingSignup.findUnique({
            where: { id: decoded.pendingId }
          });

          if (!pending) {
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
          }

          // Expired → delete row + images and return VALIDATION_ERROR
          if (new Date() > pending.expiresAt) {
            if (pending.images && Array.isArray(pending.images)) {
              pending.images.forEach(img => { try { deleteImage(img); } catch (_) {} });
            }
            await prisma.pendingSignup.delete({ where: { id: pending.id } }).catch(() => {});
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
          }

          // Attempts >= 5 → delete row + images and return VALIDATION_ERROR
          if (pending.attempts >= 5) {
            if (pending.images && Array.isArray(pending.images)) {
              pending.images.forEach(img => { try { deleteImage(img); } catch (_) {} });
            }
            await prisma.pendingSignup.delete({ where: { id: pending.id } }).catch(() => {});
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
          }

          const isValid = await bcrypt.compare(otp.trim(), pending.codeHash);
          if (!isValid) {
            const updatedPending = await prisma.pendingSignup.update({
              where: { id: pending.id },
              data: { attempts: { increment: 1 } }
            });

            if (updatedPending.attempts >= 5) {
              if (pending.images && Array.isArray(pending.images)) {
                pending.images.forEach(img => { try { deleteImage(img); } catch (_) {} });
              }
              await prisma.pendingSignup.delete({ where: { id: pending.id } }).catch(() => {});
              return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
            }
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid OTP code.' });
          }

          // Correct code: create User and delete PendingSignup row in ONE transaction
          const now = new Date();
          const [user] = await prisma.$transaction([
            prisma.user.create({
              data: {
                email: pending.email,
                phone: pending.phone || null,
                password: pending.passwordHash,
                pseudonym: pending.pseudonym,
                username: pending.pseudonym,
                images: pending.images || [],
                isAnonymous: false,
                emailVerified: true,
                emailVerifiedAt: now,
                currentStreak: 0,
                lastLoginDate: now,
              }
            }),
            prisma.pendingSignup.delete({
              where: { id: pending.id }
            })
          ]);

          const authToken = jwt.sign(
            { id: user.id, role: user.role, tokenVersion: user.tokenVersion },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
          );

          return res.status(201).json({
            success: true,
            message: 'Email verified and account created successfully!',
            token: authToken,
            user: {
              id: user.id,
              email: user.email,
              phone: user.phone,
              pseudonym: user.pseudonym,
              images: user.images,
              role: user.role,
              emailVerified: true
            }
          });
        }
      } catch (jwtErr) {
        if (!authHeaderToken) {
          return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid or expired session. Please start registration again.' });
        }
      }
    }

    // 2. Existing user flow (e.g. unverified login flow)
    if (!tokenToUse) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Unauthorized' });
    }

    let decodedAuth;
    try {
      decodedAuth = jwt.verify(tokenToUse, process.env.JWT_SECRET);
    } catch (e) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session invalid' });
    }

    const userId = decodedAuth.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session invalid' });

    // F2: Ban check
    if (user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    const record = await prisma.otpRecord.findFirst({
      where: { userId, purpose: 'verify_email', usedAt: null },
      orderBy: { createdAt: 'desc' }
    });

    if (!record) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'No active OTP found. Please request a new one.' });
    if (record.usedAt || new Date() > record.expiresAt) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
    }
    if (record.attempts >= 5) {
      if (!record.usedAt) {
        await prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } });
      }
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
    }

    const isValid = await bcrypt.compare(otp.trim(), record.codeHash);
    if (!isValid) {
      const newAttempts = record.attempts + 1;
      const updateData = { attempts: newAttempts };
      if (newAttempts >= 5) {
        updateData.usedAt = new Date();
      }
      await prisma.otpRecord.update({ where: { id: record.id }, data: updateData });
      if (newAttempts >= 5) {
        return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
      }
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid OTP code.' });
    }

    // Success for existing user
    const [_, updatedUser] = await prisma.$transaction([
      prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      prisma.user.update({ where: { id: userId }, data: { emailVerified: true, emailVerifiedAt: new Date() } })
    ]);

    const authToken = jwt.sign(
      { id: updatedUser.id, role: updatedUser.role, tokenVersion: updatedUser.tokenVersion },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Email verified successfully',
      success: true,
      token: authToken,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        phone: updatedUser.phone,
        pseudonym: updatedUser.pseudonym,
        role: updatedUser.role,
        emailVerified: true
      }
    });
  } catch (error) {
    console.error('OTP verify error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// F3, F8 & F9: Reset Password Verify
router.post('/reset-password', resetPasswordLimiter, async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Email, OTP, and new password are required.' });
    }

    // F9: Validate password against passwordSchema
    const parsedPassword = passwordSchema.safeParse(newPassword);
    if (!parsedPassword.success) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: parsedPassword.error.errors[0]?.message || 'Invalid password format.' });
    }

    // F3: Normalized EMAIL ONLY
    const normalizedEmail = email.trim().toLowerCase();
    const user = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });
    if (!user) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid request' });

    // F2: Ban check
    if (user.isBanned) {
      return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
    }

    const record = await prisma.otpRecord.findFirst({
      where: { userId: user.id, purpose: 'reset_password', usedAt: null },
      orderBy: { createdAt: 'desc' }
    });

    if (!record) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'No active OTP found. Please request a new one.' });
    if (record.usedAt || new Date() > record.expiresAt) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
    }
    if (record.attempts >= 5) {
      if (!record.usedAt) {
        await prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } });
      }
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
    }

    const isValid = await bcrypt.compare(otp.trim(), record.codeHash);
    if (!isValid) {
      const newAttempts = record.attempts + 1;
      const updateData = { attempts: newAttempts };
      if (newAttempts >= 5) {
        updateData.usedAt = new Date();
      }
      await prisma.otpRecord.update({ where: { id: record.id }, data: updateData });
      if (newAttempts >= 5) {
        return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
      }
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid OTP code.' });
    }

    // Success: update password and increment tokenVersion (F9)
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.$transaction([
      prisma.otpRecord.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      prisma.user.update({
        where: { id: user.id },
        data: {
          password: hashedPassword,
          tokenVersion: { increment: 1 }
        }
      })
    ]);

    res.json({ message: 'Password reset successfully', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const onboardingSchema = z.object({
  name: z.string().max(50).optional(),
  displayName: z.string().max(50).optional(),
  realFirstName: z.string().max(50).optional().nullable(),
  legalFullName: z.string().max(100).optional().nullable(),
  handle: z.string().max(30).optional().nullable(),
  nameDisplayPreference: z.enum(['DISPLAY_NAME_ONLY', 'FIRST_NAME_PUBLIC']).optional(),
  location: z.string().max(100).optional(),
  profession: z.string().max(100).optional(),
  interests: z.array(z.string()).max(10).optional(),
  feelings: z.array(z.string()).max(10).optional(),
  supportTypes: z.array(z.string()).max(5).optional(),
  isAnonymous: z.boolean().optional(),
  dateOfBirth: z.string().optional(),
});

// Complete Onboarding (F12: underage handling)
router.put('/onboarding', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { 
      name, displayName, realFirstName, legalFullName, handle, nameDisplayPreference,
      location, profession, interests, feelings, supportTypes, isAnonymous, dateOfBirth
    } = onboardingSchema.parse(req.body);
    const userId = req.user.id; 

    // F12: If user already flagged as underage, return 403 immediately without parsing
    if (req.user.underageBlockedAt) {
      return res.status(403).json({ error: 'UNDERAGE', message: 'You must be at least 18 years old to use Wehere.' });
    }

    let dobToSave;
    if (!req.user.dateOfBirth) {
      if (!dateOfBirth) {
        return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Date of birth is required.' });
      }
      const parsedDob = parseDob(dateOfBirth);
      if (!parsedDob) {
        return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid date of birth. Must be YYYY-MM-DD.' });
      }
      const age = calcAge(parsedDob);
      if (age < 18) {
        // F12: Set underageBlockedAt, do not store dateOfBirth, return 403
        await prisma.user.update({
          where: { id: userId },
          data: { underageBlockedAt: new Date() }
        });
        return res.status(403).json({ error: 'UNDERAGE', message: 'You must be at least 18 years old to use Wehere.' });
      }
      dobToSave = parsedDob;
    }

    const finalAlias = (displayName && displayName.trim().length > 0) 
      ? displayName.trim() 
      : ((name && name.trim().length > 0) ? name.trim() : 'Peer');

    // Filter profanity / triggers
    const aliasValidation = validateDisplayName(finalAlias);
    if (!aliasValidation.isValid) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: aliasValidation.error });
    }

    const cleanHandle = handle ? sanitizeHandle(handle) : undefined;
    const cleanRealFirstName = realFirstName ? realFirstName.trim() : undefined;
    const cleanLegalFullName = legalFullName ? legalFullName.trim() : undefined;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        pseudonym: finalAlias,
        displayName: finalAlias,
        realFirstName: cleanRealFirstName,
        legalFullName: cleanLegalFullName,
        handle: cleanHandle,
        nameDisplayPreference: nameDisplayPreference || 'DISPLAY_NAME_ONLY',
        location: location,
        profession: profession || undefined,
        interests: interests || [],
        feelings: feelings || [],
        supportTypes: supportTypes || [],
        isAnonymous: isAnonymous || false,
        ...(dobToSave ? { dateOfBirth: dobToSave } : {}),
      },
    });

    res.json({ message: 'Onboarding completed', user: updatedUser });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'VALIDATION_ERROR', message: error.errors[0]?.message || 'Validation failed' });
    console.error('Onboarding Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// F8 & F9: Change Password
router.post('/change-password', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Current password and new password are required.' });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.password) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Cannot change password for this account' });

    const validPassword = await bcrypt.compare(currentPassword, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Current password is incorrect.' });
    }

    const parsedPassword = passwordSchema.safeParse(newPassword);
    if (!parsedPassword.success) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: parsedPassword.error.errors[0]?.message || 'Invalid new password format.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: {
        password: hashedPassword,
        tokenVersion: { increment: 1 }
      }
    });

    res.json({ message: 'Password updated successfully', success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;

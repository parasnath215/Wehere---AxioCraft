const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { z } = require('zod');
const multer = require('multer');
// F10: Shared Prisma client
const prisma = require('../lib/prisma');
const { verifySocialToken } = require('../services/socialAuth');
const {
  assertAccountAllowed,
  isOnboardingComplete,
  serializeAuthUser,
  completeLogin,
} = require('../services/authSession');

const {
  signupLimiter,
  otpVerifyLimiter,
  otpRequestLimiter,
  resetPasswordLimiter,
  loginLimiter,
  socialLimiter,
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

    // Call assertAccountAllowed after password check (A4)
    assertAccountAllowed(user);

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
      }
    }

    return await completeLogin(res, user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' });
    }
    if (error.code === 'ACCOUNT_BANNED' || error.code === 'UNDERAGE') {
      return res.status(error.status || 403).json({ error: error.code, message: error.message });
    }
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /api/auth/social/check
router.post('/social/check', socialLimiter, async (req, res) => {
  try {
    const { provider, idToken, nonce, givenName, familyName } = req.body || {};
    if (!provider || !idToken) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'provider and idToken are required' });
    }

    let profile;
    try {
      profile = await verifySocialToken({ provider, idToken, nonce, givenName, familyName });
    } catch (tokenErr) {
      return res.status(tokenErr.statusCode || 401).json({
        error: tokenErr.code || 'INVALID_CREDENTIALS',
        message: tokenErr.message || 'Invalid social credentials',
      });
    }

    const normalizedProvider = provider.trim().toLowerCase();
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          ...(normalizedProvider === 'google' ? [{ googleId: profile.subject }] : []),
          ...(normalizedProvider === 'apple' ? [{ appleId: profile.subject }] : []),
          ...(profile.email ? [{ email: profile.email }] : []),
        ]
      }
    });

    if (existingUser) {
      if (existingUser.isBanned) {
        return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
      }
      if (existingUser.underageBlockedAt) {
        return res.status(403).json({ error: 'UNDERAGE', message: 'You must be at least 18 years old to use Wehere.' });
      }
    }

    res.json({
      success: true,
      exists: Boolean(existingUser),
      profile: {
        email: (existingUser ? existingUser.email : null) || profile.email,
        emailVerified: profile.emailVerified,
        name: (existingUser ? (existingUser.displayName || existingUser.pseudonym) : null) || profile.name || '',
        givenName: profile.givenName || '',
        familyName: profile.familyName || '',
        pictureUrl: profile.pictureUrl || null,
        locale: profile.locale || null,
      }
    });
  } catch (err) {
    console.error('social/check error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /api/auth/social/login - Login existing user via social provider
router.post('/social/login', socialLimiter, async (req, res) => {
  try {
    const { provider, idToken, nonce } = req.body || {};
    if (!provider || !idToken) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'provider and idToken are required' });
    }

    let profile;
    try {
      profile = await verifySocialToken({ provider, idToken, nonce });
    } catch (tokenErr) {
      return res.status(tokenErr.statusCode || 401).json({
        error: tokenErr.code || 'INVALID_CREDENTIALS',
        message: tokenErr.message || 'Invalid social credentials',
      });
    }

    const normalizedProvider = (provider || '').trim().toLowerCase();
    const subjectField = normalizedProvider === 'google' ? 'googleId' : 'appleId';

    // 1. Look up by provider subject first
    let user = await prisma.user.findFirst({
      where: { [subjectField]: profile.subject }
    });

    if (!user && profile.email) {
      // 2. If none, look up by verified email
      user = await prisma.user.findFirst({
        where: { email: profile.email }
      });

      if (user) {
        // If that user already has a DIFFERENT subject for the same provider -> 409 CONFLICT
        if (user[subjectField] && user[subjectField] !== profile.subject) {
          return res.status(409).json({
            error: 'CONFLICT',
            message: `This account is already linked to a different ${normalizedProvider === 'google' ? 'Google' : 'Apple'} account.`
          });
        }

        // Link the provider subject to the user
        const updateData = { [subjectField]: profile.subject };
        if (!user.emailVerified) {
          updateData.emailVerified = true;
          updateData.emailVerifiedAt = new Date();
        }
        user = await prisma.user.update({
          where: { id: user.id },
          data: updateData,
        });
      }
    }

    if (!user) {
      return res.status(404).json({
        error: 'ACCOUNT_NOT_FOUND',
        message: 'No account found. Please register first.'
      });
    }

    return await completeLogin(res, user);
  } catch (err) {
    if (err.code === 'ACCOUNT_BANNED' || err.code === 'UNDERAGE' || err.code === 'ACCOUNT_DELETED') {
      return res.status(err.status || 403).json({ error: err.code, message: err.message });
    }
    console.error('social/login error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// POST /api/auth/social/register - Register new user via social provider with images
router.post('/social/register', signupLimiter, upload.array('images', 6), async (req, res) => {
  try {
    const { provider, idToken, nonce, pseudonym, password, phone, givenName, familyName } = req.body || {};
    if (!provider || !idToken) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'provider and idToken are required' });
    }

    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'At least 2 profile images are required.' });
    }

    let profile;
    try {
      profile = await verifySocialToken({ provider, idToken, nonce, givenName, familyName });
    } catch (tokenErr) {
      return res.status(tokenErr.statusCode || 401).json({
        error: tokenErr.code || 'INVALID_CREDENTIALS',
        message: tokenErr.message || 'Invalid social credentials',
      });
    }

    const normalizedProvider = (provider || '').trim().toLowerCase();
    const subjectField = normalizedProvider === 'google' ? 'googleId' : 'appleId';

    if (normalizedProvider === 'apple' && !profile.email) {
      return res.status(400).json({
        error: 'VALIDATION_ERROR',
        message: 'Apple account did not provide an email address'
      });
    }

    // Account-linking rule: look up by provider subject first (googleId/appleId); only if none, look up by the provider-verified email.
    let existingUser = await prisma.user.findFirst({
      where: { [subjectField]: profile.subject }
    });

    if (!existingUser && profile.email) {
      existingUser = await prisma.user.findFirst({
        where: { email: profile.email }
      });
    }

    if (existingUser) {
      return res.status(409).json({
        error: 'CONFLICT',
        message: 'An account with this email already exists. Please log in.'
      });
    }

    // Password validation: If password is given validate it with the shared passwordSchema and do NOT trim() it; if absent store null.
    let hashedPassword = null;
    if (password !== undefined && password !== null && password !== '') {
      const parsed = passwordSchema.safeParse(password);
      if (!parsed.success) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: parsed.error.errors[0]?.message || 'Invalid password'
        });
      }
      hashedPassword = await bcrypt.hash(password, 10);
    }

    // pseudonym = unique(pseudonym) (reuse the existing unique-suffix logic)
    let desiredPseudonym = (pseudonym && pseudonym.trim().length > 0)
      ? pseudonym.trim()
      : ((profile.name && profile.name.trim().length > 0) ? profile.name.trim() : 'Explorer');

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

    const imagePaths = await Promise.all(req.files.map(f => processAndSaveImage(f.buffer)));

    const finalRealFirstName = (givenName && givenName.trim().length > 0) ? givenName.trim() : (profile.givenName || null);
    const finalLegalFullName = [givenName, familyName].filter(Boolean).join(' ').trim() || profile.name || null;
    const finalDisplayName = (pseudonym && pseudonym.trim().length > 0) ? pseudonym.trim() : uniqueHandle;

    const user = await prisma.user.create({
      data: {
        email: profile.email,
        [subjectField]: profile.subject,
        password: hashedPassword,
        pseudonym: uniqueHandle,
        displayName: finalDisplayName,
        realFirstName: finalRealFirstName,
        legalFullName: finalLegalFullName,
        avatar: imagePaths[0],
        images: imagePaths,
        phone: phone && phone.trim().length > 0 ? phone.trim() : null,
        emailVerified: true,
        emailVerifiedAt: new Date(),
        role: 'USER',
      }
    });

    return await completeLogin(res, user, { created: true });
  } catch (err) {
    if (err.code === 'ACCOUNT_BANNED' || err.code === 'UNDERAGE') {
      return res.status(err.status || 403).json({ error: err.code, message: err.message });
    }
    console.error('social/register error:', err);
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

          return await completeLogin(res, user, { created: true });
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

    return await completeLogin(res, updatedUser);
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

    // Ban check & underage check
    assertAccountAllowed(user);

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
    if (error.code === 'ACCOUNT_BANNED' || error.code === 'UNDERAGE') {
      return res.status(error.status || 403).json({ error: error.code, message: error.message });
    }
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
});

// Complete Onboarding
router.put('/onboarding', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { 
      name, displayName, realFirstName, legalFullName, handle, nameDisplayPreference,
      location, profession, interests, feelings, supportTypes, isAnonymous
    } = onboardingSchema.parse(req.body);
    const userId = req.user.id; 

    // Underage check
    if (req.user.underageBlockedAt) {
      return res.status(403).json({ error: 'UNDERAGE', message: 'You must be at least 18 years old to use Wehere.' });
    }

    // DOB check
    if (!req.user.dateOfBirth) {
      return res.status(403).json({ error: 'AGE_REQUIRED', message: 'Date of birth is required before completing onboarding.' });
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
      },
    });

    res.json({ message: 'Onboarding completed', user: serializeAuthUser(updatedUser) });
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

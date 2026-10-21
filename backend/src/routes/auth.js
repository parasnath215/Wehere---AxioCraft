const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');
const { z } = require('zod');
const multer = require('multer');
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
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().min(1, 'Identifier is required'),
  password: z.string(),
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


// Email/Password Signup (Multipart with Images)
// NOTE: Account is NOT created until email OTP is verified!
router.post('/signup', signupLimiter, upload.array('images', 6), async (req, res) => {
  try {
    if (!req.files || req.files.length < 2) {
      return res.status(400).json({ error: 'At least 2 profile images are required.' });
    }
    const { email, password, pseudonym, phone } = signupSchema.parse(req.body);
    const normalizedEmail = email.toLowerCase().trim();
    const rawPhone = phone && phone.trim().length > 0 ? phone.trim() : null;
    const normalizedPhone = rawPhone ? rawPhone.replace(/[^\d+]/g, '') : null;

    // Check if user already exists and is verified
    const existingUser = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });

    if (existingUser && existingUser.emailVerified) {
      return res.status(400).json({ error: 'This email is already registered and verified. Please log in.' });
    }

    if (normalizedPhone) {
      const existingPhoneUser = await prisma.user.findFirst({
        where: {
          phone: normalizedPhone,
          emailVerified: true
        }
      });
      if (existingPhoneUser) {
        return res.status(400).json({ error: 'This phone number is already registered and verified. Please log in.' });
      }
      // Clean up any stale unverified record with this phone number
      await prisma.user.deleteMany({
        where: { phone: normalizedPhone, emailVerified: false }
      });
    }

    // Clean up any stale unverified record for this email
    if (existingUser && !existingUser.emailVerified) {
      await prisma.user.deleteMany({
        where: { email: normalizedEmail, emailVerified: false }
      });
    }

    const imagePaths = await Promise.all(req.files.map(f => processAndSaveImage(f.buffer)));
    const hashedPassword = await bcrypt.hash(password, 10);

    // Ensure handle/pseudonym is unique among verified users
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

    // Generate OTP
    const code = generateOtp();
    const codeHash = await bcrypt.hash(code, 10);

    // Create a secure pending signup token (15 min validity)
    const signupToken = jwt.sign(
      {
        purpose: 'pending_signup',
        email: normalizedEmail,
        phone: normalizedPhone || null,
        hashedPassword,
        pseudonym: uniqueHandle,
        images: imagePaths,
        codeHash,
        expiresAt: Date.now() + 10 * 60 * 1000, // 10 min
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    try {
      await sendOtpEmail(normalizedEmail, code, 'verify_email');
    } catch (e) {
      console.error('Failed to send initial OTP on signup:', e.message);
    }

    // Notice: NO user record is created in the database yet!
    // The account ID will only be created after the OTP is verified.
    res.json({
      success: true,
      pendingVerification: true,
      signupToken,
      email: normalizedEmail,
      pseudonym: uniqueHandle,
      message: 'Verification code sent to your email.'
    });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'Validation failed', details: error.errors });
    if (error.code === 'P2002') return res.status(400).json({ error: 'Email already exists' });
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Login
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const rawIdentifier = email.trim();
    const normalizedIdentifier = rawIdentifier.toLowerCase();
    const digitsOnly = rawIdentifier.replace(/[^\d+]/g, '');

    const user = await prisma.user.findFirst({ 
      where: {
        OR: [
          { email: normalizedIdentifier },
          { username: normalizedIdentifier },
          { pseudonym: normalizedIdentifier },
          ...(digitsOnly ? [{ phone: digitsOnly }, { phone: rawIdentifier }] : [{ phone: rawIdentifier }])
        ]
      } 
    });
    if (!user || !user.password) return res.status(400).json({ error: 'Invalid credentials' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(400).json({ error: 'Invalid credentials' });

    // Enforce email verification before logging in
    if (!user.emailVerified && !user.isAnonymous) {
      await prisma.otpRecord.updateMany({
        where: { userId: user.id, purpose: 'verify_email', usedAt: null },
        data: { usedAt: new Date() }
      });

      const code = generateOtp();
      const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(code).digest('hex');
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

      const token = jwt.sign({ id: user.id, role: user.role, tokenVersion: user.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '7d' });
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
        // Grace period expired (30 days): permanently delete account
        await prisma.user.delete({ where: { id: user.id } });
        if (user.images) user.images.forEach(deleteImage);
        return res.status(410).json({
          error: 'ACCOUNT_DELETED',
          message: 'This account was permanently deleted after the 30-day grace period.'
        });
      } else {
        // User logged in before calculated date (+30 days): restore account!
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

    const token = jwt.sign({ id: user.id, role: user.role, tokenVersion: user.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, role: user.role, emailVerified: user.emailVerified, currentStreak: user.currentStreak } });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: 'Validation failed', details: error.errors });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// OTP Request (Resend or Forgot Password)
router.post('/otp/request', otpRequestLimiter, async (req, res) => {
  try {
    const { email, purpose = 'verify_email', signupToken } = req.body;

    // Handle pending signup OTP resend
    if (signupToken) {
      try {
        const decoded = jwt.verify(signupToken, process.env.JWT_SECRET);
        if (decoded.purpose === 'pending_signup') {
          const code = generateOtp();
          const codeHash = await bcrypt.hash(code, 10);
          const newSignupToken = jwt.sign(
            {
              ...decoded,
              codeHash,
              expiresAt: Date.now() + 10 * 60 * 1000,
            },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
          );

          await sendOtpEmail(decoded.email, code, 'verify_email');
          return res.json({
            message: 'A new verification code has been sent.',
            success: true,
            signupToken: newSignupToken,
            cooldown: 60
          });
        }
      } catch (err) {
        return res.status(400).json({ error: 'Session expired. Please start registration again.' });
      }
    }

    if (!email) return res.status(400).json({ error: 'Email or phone number is required' });
    if (!['verify_email', 'reset_password'].includes(purpose)) {
      return res.status(400).json({ error: 'Invalid purpose' });
    }

    const rawInput = email.trim();
    const normalizedInput = rawInput.toLowerCase();
    const digitsOnly = rawInput.replace(/[^\d+]/g, '');

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: normalizedInput },
          { username: normalizedInput },
          { pseudonym: normalizedInput },
          ...(digitsOnly ? [{ phone: digitsOnly }, { phone: rawInput }] : [{ phone: rawInput }])
        ]
      }
    });

    // Always return a success response to prevent enumeration, include user email if available
    const genericResponse = { 
      message: 'If the account exists, a code was sent to the registered email.', 
      success: true, 
      cooldown: 60,
      email: user?.email || rawInput
    };

    if (!user || !user.email) return res.json(genericResponse);

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
    const codeHash = await bcrypt.hash(code, 10);

    await prisma.otpRecord.create({
      data: {
        purpose,
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 min
        userId: user.id,
      }
    });

    await sendOtpEmail(user.email, code, purpose);
    res.json(genericResponse);
  } catch (error) {
    console.error('OTP Request Error:', error.message);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// OTP Verify (Email Verification)
// NOTE: For pending signups, the User account is created HERE after verifying OTP!
router.post('/otp/verify', otpVerifyLimiter, async (req, res) => {
  try {
    const { otp, signupToken } = req.body;
    let authHeaderToken = null;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      authHeaderToken = req.headers.authorization.split(' ')[1];
    }
    const tokenToUse = signupToken || authHeaderToken;

    if (!otp) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'OTP required' });

    // 1. Pending Signup Flow: Verify OTP and create User record now
    if (tokenToUse) {
      try {
        const decoded = jwt.verify(tokenToUse, process.env.JWT_SECRET);
        if (decoded.purpose === 'pending_signup') {
          if (Date.now() > decoded.expiresAt) {
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' });
          }

          const isValid = await bcrypt.compare(otp.trim(), decoded.codeHash);
          if (!isValid) {
            return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid OTP code.' });
          }

          // Check if an account was verified with this email in the meantime
          const existingVerified = await prisma.user.findFirst({
            where: { email: decoded.email, emailVerified: true }
          });
          if (existingVerified) {
            return res.status(409).json({ error: 'CONFLICT', message: 'This email is already registered.' });
          }

          // Clean up any stale unverified record
          await prisma.user.deleteMany({
            where: { email: decoded.email, emailVerified: false }
          });
          if (decoded.phone) {
            await prisma.user.deleteMany({
              where: { phone: decoded.phone, emailVerified: false }
            });
          }

          const now = new Date();
          const user = await prisma.user.create({
            data: {
              email: decoded.email,
              phone: decoded.phone || null,
              password: decoded.hashedPassword,
              pseudonym: decoded.pseudonym,
              username: decoded.pseudonym,
              images: decoded.images || [],
              isAnonymous: false,
              emailVerified: true,
              emailVerifiedAt: now,
              currentStreak: 0,
              lastLoginDate: now,
            }
          });

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

    // 2. Existing user flow (e.g. unverified user login flow)
    if (!authHeaderToken) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Unauthorized' });
    }

    let decodedAuth;
    try {
      decodedAuth = jwt.verify(authHeaderToken, process.env.JWT_SECRET);
    } catch (e) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session invalid' });
    }

    const userId = decodedAuth.id;
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

// Reset Password Verify
router.post('/reset-password', resetPasswordLimiter, async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Valid email/phone, OTP, and new password (min 6 chars) required.' });
    }

    const rawInput = email.trim();
    const normalizedInput = rawInput.toLowerCase();
    const digitsOnly = rawInput.replace(/[^\d+]/g, '');

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: normalizedInput },
          { username: normalizedInput },
          { pseudonym: normalizedInput },
          ...(digitsOnly ? [{ phone: digitsOnly }, { phone: rawInput }] : [{ phone: rawInput }])
        ]
      }
    });
    if (!user) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Invalid request' });

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

// Complete Onboarding
router.put('/onboarding', authenticateToken, requireVerified, async (req, res) => {
  try {
    const { 
      name, displayName, realFirstName, legalFullName, handle, nameDisplayPreference,
      location, profession, interests, feelings, supportTypes, isAnonymous, dateOfBirth
    } = onboardingSchema.parse(req.body);
    const userId = req.user.id; 

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

const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');
const { calcAge } = require('../utils/age');
const { evaluateStreak } = require('./streak');
const { deleteImage } = require('./storage');

function assertAccountAllowed(user) {
  if (!user) return;
  if (user.isBanned) {
    const err = new Error('This account has been suspended.');
    err.code = 'ACCOUNT_BANNED';
    err.status = 403;
    throw err;
  }
  if (user.underageBlockedAt) {
    const err = new Error('You must be at least 18 years old to use Wehere.');
    err.code = 'UNDERAGE';
    err.status = 403;
    throw err;
  }
}

function isOnboardingComplete(user) {
  return Boolean(user && user.location) && Array.isArray(user?.interests) && user.interests.length > 0;
}

function serializeAuthUser(user) {
  if (!user) return null;
  const age = user.dateOfBirth ? calcAge(user.dateOfBirth) : null;
  const needsDob = user.dateOfBirth == null;
  const onboardingCompleted = isOnboardingComplete(user);

  let avatar = user.avatar || null;
  if (!avatar && Array.isArray(user.images) && user.images.length > 0) {
    avatar = user.images[0];
  }

  return {
    id: user.id,
    email: user.email,
    role: user.role,
    pseudonym: user.pseudonym,
    displayName: user.displayName || user.pseudonym || null,
    avatar,
    images: Array.isArray(user.images) ? user.images : [],
    age,
    needsDob,
    onboardingCompleted,
    emailVerified: Boolean(user.emailVerified),
    currentStreak: user.currentStreak || 0,
  };
}

async function completeLogin(res, user, { created } = {}) {
  assertAccountAllowed(user);

  if (user.scheduledDeletionDate) {
    const now = new Date();
    if (now.getTime() >= new Date(user.scheduledDeletionDate).getTime()) {
      await prisma.user.delete({ where: { id: user.id } });
      if (user.images && Array.isArray(user.images)) {
        user.images.forEach(deleteImage);
      }
      const err = new Error('This account was permanently deleted after the 30-day grace period.');
      err.code = 'ACCOUNT_DELETED';
      err.status = 410;
      throw err;
    }
  }

  let accountRestored = false;
  if (user.scheduledDeletionDate || user.deletionRequestedAt) {
    user = await prisma.user.update({
      where: { id: user.id },
      data: {
        scheduledDeletionDate: null,
        deletionRequestedAt: null,
      }
    });
    accountRestored = true;
  }

  const streakResult = evaluateStreak(user);
  if (streakResult && streakResult.shouldUpdate) {
    user = await prisma.user.update({
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

  const serialized = serializeAuthUser(user);

  res.json({
    success: true,
    token,
    user: serialized,
    needsDob: serialized.needsDob,
    onboardingCompleted: serialized.onboardingCompleted,
    ...(accountRestored ? { accountRestored: true } : {}),
    ...(created ? { created: true } : {}),
  });
}

module.exports = {
  assertAccountAllowed,
  isOnboardingComplete,
  serializeAuthUser,
  completeLogin,
};

const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');

const createStandardLimiter = ({ windowMs, max, message, keyGenerator }) => {
  const options = {
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      res.status(429).json({
        error: 'RATE_LIMITED',
        message: message || 'Too many requests. Please try again later.'
      });
    }
  };

  if (keyGenerator) {
    options.keyGenerator = keyGenerator;
  }

  return rateLimit(options);
};

// 5 per hour per IP
const signupLimiter = createStandardLimiter({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: 'Too many signup attempts. Please try again in an hour.'
});

// 10 per 15 min per IP
const otpVerifyLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Too many OTP verification attempts. Please try again later.'
});

// 5 per 15 min per IP
const otpRequestIpLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many OTP requests from this IP. Please try again later.'
});

// 3 per 10 min per email
const emailOtpRequests = new Map();

function otpRequestEmailLimiter(req, res, next) {
  let email = req.body?.email;
  if (!email && req.body?.signupToken) {
    try {
      const decoded = jwt.decode(req.body.signupToken);
      if (decoded && decoded.email) email = decoded.email;
    } catch (_) {}
  }

  if (!email) return next();

  const key = String(email).trim().toLowerCase();
  const now = Date.now();
  const windowMs = 10 * 60 * 1000;
  const max = 3;

  const timestamps = (emailOtpRequests.get(key) || []).filter(t => now - t < windowMs);
  if (timestamps.length >= max) {
    return res.status(429).json({
      error: 'RATE_LIMITED',
      message: 'Too many OTP requests for this email. Please wait before requesting another code.'
    });
  }

  timestamps.push(now);
  emailOtpRequests.set(key, timestamps);
  next();
}

// Periodic cleanup of stale email rate-limit entries
if (typeof setInterval !== 'undefined') {
  setInterval(() => {
    const now = Date.now();
    const windowMs = 10 * 60 * 1000;
    for (const [key, timestamps] of emailOtpRequests.entries()) {
      const active = timestamps.filter(t => now - t < windowMs);
      if (active.length === 0) {
        emailOtpRequests.delete(key);
      } else {
        emailOtpRequests.set(key, active);
      }
    }
  }, 10 * 60 * 1000).unref();
}

const otpRequestLimiter = [otpRequestIpLimiter, otpRequestEmailLimiter];

// 5 per 15 min per IP
const resetPasswordLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many password reset attempts. Please try again later.'
});

// 10 per 15 min per IP
const loginLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Too many login attempts. Please try again later.'
});

// 10 per hour per IP (user reporting)
const reportLimiter = createStandardLimiter({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: 'Too many reports submitted. Please wait before submitting another report.'
});

// 20 per hour per user ID (community posts)
const communityLimiter = createStandardLimiter({
  windowMs: 60 * 60 * 1000,
  max: 20,
  keyGenerator: (req) => req.user?.id || req.ip,
  message: 'Too many community posts submitted. Please wait before posting again.'
});

// 120 requests per minute per IP for admin API
const adminApiLimiter = createStandardLimiter({
  windowMs: 60 * 1000,
  max: 120,
  message: 'Too many admin requests. Please try again later.'
});

module.exports = {
  signupLimiter,
  otpVerifyLimiter,
  otpRequestLimiter,
  resetPasswordLimiter,
  loginLimiter,
  reportLimiter,
  communityLimiter,
  adminApiLimiter,
};

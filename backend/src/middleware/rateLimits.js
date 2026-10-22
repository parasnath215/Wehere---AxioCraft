const rateLimit = require('express-rate-limit');
const { ipKeyGenerator } = require('express-rate-limit');
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

// Global API limiter: 1200 per 15 min, keyed by auth user id when valid token exists, otherwise IP
const apiLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 1200,
  keyGenerator: (req) => {
    if (req.user?.id) return `user:${req.user.id}`;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded && decoded.id && !decoded.purpose) {
          return `user:${decoded.id}`;
        }
      } catch (_) {}
    }
    return ipKeyGenerator(req.ip || '');
  },
  message: 'Too many requests. Please try again later.'
});

// 20 per hour per IP (signupLimiter)
const signupLimiter = createStandardLimiter({
  windowMs: 60 * 60 * 1000,
  max: 20,
  message: 'Too many signup attempts. Please try again in an hour.'
});

// 60 per 15 min per IP (otpVerifyLimiter)
const otpVerifyLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 60,
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

// Login limiter: key = ip + ':' + lowercase(email), 10 per 15 min, plus loose per-IP cap of 100 per 15 min
const loginIpCapLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many login attempts from this IP. Please try again later.'
});

const loginAccountLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  keyGenerator: (req) => {
    const ip = ipKeyGenerator(req.ip || '');
    const email = String(req.body?.email || '').trim().toLowerCase();
    return `${ip}:${email}`;
  },
  message: 'Too many login attempts for this account. Please try again later.'
});

const loginLimiter = [loginIpCapLimiter, loginAccountLimiter];

// Admin login limiter: separate limiter (5 per 15 min per ip + email)
const adminLoginLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => {
    const ip = ipKeyGenerator(req.ip || '');
    const email = String(req.body?.email || '').trim().toLowerCase();
    return `${ip}:${email}`;
  },
  message: 'Too many admin login attempts. Please try again later.'
});

// DOB limiter: 10 per hour per user on PUT /api/users/me/dob
const dobLimiter = createStandardLimiter({
  windowMs: 60 * 60 * 1000,
  max: 10,
  keyGenerator: (req) => {
    if (req.user?.id) return `dob:${req.user.id}`;
    return ipKeyGenerator(req.ip || '');
  },
  message: 'Too many date of birth updates. Please try again later.'
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
  keyGenerator: (req) => req.user?.id ? `user:${req.user.id}` : ipKeyGenerator(req.ip || ''),
  message: 'Too many community posts submitted. Please wait before posting again.'
});

// 120 requests per minute per IP for admin API
const adminApiLimiter = createStandardLimiter({
  windowMs: 60 * 1000,
  max: 120,
  message: 'Too many admin requests. Please try again later.'
});

// 30 per 15 min per IP (socialLimiter)
const socialLimiter = createStandardLimiter({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: 'Too many social authentication requests. Please try again later.'
});

module.exports = {
  apiLimiter,
  signupLimiter,
  otpVerifyLimiter,
  otpRequestLimiter,
  resetPasswordLimiter,
  loginLimiter,
  adminLoginLimiter,
  dobLimiter,
  reportLimiter,
  communityLimiter,
  adminApiLimiter,
  socialLimiter,
};

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../lib/prisma');

function checkApiKey(providedKey, expectedKey) {
  if (!providedKey || !expectedKey) return false;
  const providedBuffer = Buffer.from(String(providedKey));
  const expectedBuffer = Buffer.from(String(expectedKey));
  if (providedBuffer.length !== expectedBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(providedBuffer, expectedBuffer);
}

let legacyTokenCount = 0;

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) {
    return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Authentication required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Token invalid or expired' });
    }

    // F5: Reject any token that carries a purpose claim
    if (decoded.purpose) {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Token invalid for this endpoint' });
    }
    
    try {
      const user = await prisma.user.findUnique({
        where: { id: decoded.id }
      });
      
      if (!user) return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session invalid' });

      // F2: Ban check
      if (user.isBanned) {
        return res.status(403).json({ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
      }
      
      // F2: Legacy token check (no tokenVersion)
      // TODO (2026-10-29): Reject legacy tokens without tokenVersion once deploy is older than 7 days.
      if (decoded.tokenVersion === undefined) {
        legacyTokenCount++;
        console.warn(`[Auth Warning] Legacy token without tokenVersion detected. Total: ${legacyTokenCount}`);
      } else if (decoded.tokenVersion !== user.tokenVersion) {
        return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session expired. Please log in again.' });
      }
      
      req.user = user;
      next();
    } catch (e) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });
}

function requireVerified(req, res, next) {
  if (!req.user || req.user.emailVerified !== true) {
    return res.status(403).json({ error: 'EMAIL_NOT_VERIFIED', message: 'Email verification required.' });
  }
  next();
}

function adminGuard(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  const expectedKey = process.env.INTERNAL_API_KEY;

  if (!checkApiKey(apiKey, expectedKey)) {
    return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Invalid internal API key.' });
  }

  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Admin access required.' });
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    // F11: adminGuard requires purpose === 'admin'
    if (err || !decoded || decoded.purpose !== 'admin') {
      return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Admin access required.' });
    }

    try {
      const user = await prisma.user.findUnique({
        where: { id: decoded.id }
      });

      if (!user || user.role !== 'ADMIN' || user.isBanned) {
        return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Admin access required.' });
      }

      if (decoded.tokenVersion !== undefined && decoded.tokenVersion !== user.tokenVersion) {
        return res.status(401).json({ error: 'TOKEN_INVALID', message: 'Session expired. Please log in again.' });
      }

      req.user = user;
      next();
    } catch (e) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });
}

function requireAdult(req, res, next) {
  // F12: Check if user is already underage blocked
  if (req.user?.underageBlockedAt) {
    return res.status(403).json({
      error: 'UNDERAGE',
      message: 'You must be at least 18 years old to access this feature.'
    });
  }

  if (!req.user || !req.user.dateOfBirth) {
    return res.status(403).json({
      error: 'AGE_REQUIRED',
      message: 'Date of birth is required to access this feature.'
    });
  }

  const { calcAge } = require('../utils/age');
  const age = calcAge(req.user.dateOfBirth);
  if (age < 18) {
    return res.status(403).json({
      error: 'UNDERAGE',
      message: 'You must be at least 18 years old to access this feature.'
    });
  }

  next();
}

// Keep authenticateAdmin as an alias to adminGuard for backwards compatibility
const authenticateAdmin = adminGuard;

module.exports = { authenticateToken, requireVerified, adminGuard, authenticateAdmin, requireAdult };

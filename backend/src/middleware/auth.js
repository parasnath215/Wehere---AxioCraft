const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err) return res.sendStatus(403);
    
    try {
      const user = await prisma.user.findUnique({
        where: { id: decoded.id }
      });
      
      if (!user) return res.status(401).json({ error: 'Session invalid' });
      
      // Check token version to invalidate old sessions
      if (decoded.tokenVersion !== undefined && decoded.tokenVersion !== user.tokenVersion) {
        return res.status(401).json({ error: 'Session expired. Please log in again.' });
      }
      
      req.user = user;
      next();
    } catch (e) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });
}

function requireVerified(req, res, next) {
  if (!req.user.emailVerified && !req.user.isAnonymous) {
    return res.status(403).json({ error: 'EMAIL_NOT_VERIFIED' });
  }
  next();
}

function authenticateAdmin(req, res, next) {
  // Internal Microservice Bypass for Server Components
  const apiKey = req.headers['x-api-key'];
  if (apiKey && apiKey === process.env.INTERNAL_API_KEY) {
    return next();
  }

  authenticateToken(req, res, () => {
    if (req.user && req.user.role === 'ADMIN') {
      next();
    } else {
      res.status(403).json({ error: 'Access denied. Super Admin role required.' });
    }
  });
}

module.exports = { authenticateToken, requireVerified, authenticateAdmin };

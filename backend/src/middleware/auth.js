const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

function authenticateAdmin(req, res, next) {
  // Internal Microservice Bypass for Server Components
  const apiKey = req.headers['x-api-key'];
  if (apiKey && apiKey === process.env.INTERNAL_API_KEY) {
    return next();
  }

  authenticateToken(req, res, () => {
    // Note: To support JWT admins in the future, we must add role to the JWT payload during login
    if (req.user && req.user.role === 'ADMIN') {
      next();
    } else {
      res.status(403).json({ error: 'Access denied. Super Admin role required.' });
    }
  });
}

module.exports = { authenticateToken, authenticateAdmin };

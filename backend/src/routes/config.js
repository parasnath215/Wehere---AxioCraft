const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// GET /config/options
router.get('/options', async (req, res, next) => {
  try {
    const options = await prisma.configOption.findMany({
      orderBy: { order: 'asc' }
    });

    const interests = options.filter(o => o.type === 'INTEREST').map(o => ({ id: o.id, label: o.label }));
    const feelings = options.filter(o => o.type === 'FEELING').map(o => ({ id: o.id, label: o.label }));
    const supportTypes = options.filter(o => o.type === 'SUPPORT_TYPE').map(o => ({ id: o.id, label: o.label }));

    res.json({
      options: {
        interests,
        feelings,
        supportTypes
      },
      limits: {
        minPhotos: 2,
        maxPhotos: 6,
        bioMaxLength: 500,
        maxInterests: 5,
        maxFeelings: 5,
        maxSupportTypes: 2,
        locationMaxLength: 100,
        pseudonymMaxLength: 50
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

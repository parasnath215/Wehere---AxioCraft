const express = require('express');
const router = express.Router();

router.get('/resources', (req, res) => {
  res.json({
    helplines: [
      { name: 'National Suicide & Crisis Lifeline', contact: '988', type: 'Call/Text' },
      { name: 'Vandrevala Foundation', contact: '+91 9999 666 555', type: 'Call' },
      { name: 'Crisis Text Line', contact: 'Text HOME to 741741', type: 'Text' },
      { name: 'AASRA Helpline', contact: '+91 98204 66726', type: 'Call' }
    ]
  });
});

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireVerified } = require('../middleware/auth');
const { z } = require('zod');

const contactSchema = z.object({
  name: z.string().min(1).max(50),
  phone: z.string().min(1).max(20),
  relationship: z.string().min(1).max(50),
});

router.get('/contacts', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const contacts = await prisma.emergencyContact.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });
    res.json(contacts);
  } catch (error) {
    next(error);
  }
});

router.post('/contacts', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { name, phone, relationship } = contactSchema.parse(req.body);
    const contact = await prisma.emergencyContact.create({
      data: { name, phone, relationship, userId: req.user.id }
    });
    res.status(201).json(contact);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

router.delete('/contacts/:id', authenticateToken, requireVerified, async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.emergencyContact.deleteMany({
      where: { id, userId: req.user.id }
    });
    res.json({ message: 'Deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

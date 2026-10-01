const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken } = require('../middleware/auth');
const { z } = require('zod');

const postSchema = z.object({
  topic: z.string().min(1).max(100),
  content: z.string().min(1).max(2000),
});

const commentSchema = z.object({
  text: z.string().min(1).max(1000),
});

router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    
    const topic = req.query.topic;
    const whereClause = topic && topic !== 'All' ? { topic: topic } : {};

    const posts = await prisma.communityPost.findMany({
      where: whereClause,
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        author: {
          select: { id: true, pseudonym: true, images: true, isAnonymous: true }
        },
        _count: {
          select: { comments: true }
        }
      }
    });

    res.json(posts);
  } catch (error) {
    next(error);
  }
});

router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const { topic, content } = postSchema.parse(req.body);
    const userId = req.user.id;

    const result = await prisma.$transaction(async (tx) => {
      const newPost = await tx.communityPost.create({
        data: { topic, content, authorId: userId },
        include: {
          author: { select: { id: true, pseudonym: true, images: true, isAnonymous: true } },
          _count: { select: { comments: true } }
        }
      });

      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: 75 } }
      });

      return newPost;
    });

    res.status(201).json(result);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

router.get('/:id/comments', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const comments = await prisma.comment.findMany({
      where: { postId: id },
      orderBy: { createdAt: 'asc' },
      include: {
        author: { select: { id: true, pseudonym: true, images: true, isAnonymous: true } }
      }
    });

    res.json(comments);
  } catch (error) {
    next(error);
  }
});

router.post('/:id/comments', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text } = commentSchema.parse(req.body);
    const userId = req.user.id;

    const result = await prisma.$transaction(async (tx) => {
      const newComment = await tx.comment.create({
        data: { text, postId: id, authorId: userId },
        include: {
          author: { select: { id: true, pseudonym: true, images: true, isAnonymous: true } }
        }
      });

      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: 20 } }
      });

      return newComment;
    });

    res.status(201).json(result);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
    next(error);
  }
});

module.exports = router;

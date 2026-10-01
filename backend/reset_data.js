const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  if (process.env.NODE_ENV === 'production') {
    console.error('ERROR: Cannot run seed script in production!');
    process.exit(1);
  }

  console.log('Resetting database for QA/Testing...');

  // Clean up all data in reverse order of dependencies
  await prisma.postLike.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.communityPost.deleteMany();
  await prisma.message.deleteMany();
  await prisma.conversation.deleteMany();
  await prisma.match.deleteMany();
  await prisma.journalEntry.deleteMany();
  await prisma.wellnessGoal.deleteMany();
  await prisma.emergencyContact.deleteMany();
  await prisma.swipe.deleteMany();
  await prisma.block.deleteMany();
  await prisma.report.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.dailyMood.deleteMany();
  await prisma.user.deleteMany();
  await prisma.configOption.deleteMany();

  console.log('Database cleared.');

  // Seed Config Options
  const interests = ['Mental Health', 'Personal Growth', 'Relationships'];
  const feelings = ['Lonely', 'Burnout', 'Anxious', 'Hopeful'];
  const supportTypes = ['Someone to Talk To', 'Emotional Support'];
  
  for (const label of interests) {
    await prisma.configOption.create({ data: { type: 'INTEREST', label } });
  }
  for (const label of feelings) {
    await prisma.configOption.create({ data: { type: 'FEELING', label } });
  }
  for (const label of supportTypes) {
    await prisma.configOption.create({ data: { type: 'SUPPORT_TYPE', label } });
  }

  // Fetch created UUIDs for config
  const configs = await prisma.configOption.findMany();
  const interestIds = configs.filter(c => c.type === 'INTEREST').map(c => c.id);
  const feelingIds = configs.filter(c => c.type === 'FEELING').map(c => c.id);

  // Seed Admin User
  const adminPass = await bcrypt.hash('supersecureadmin', 10);
  await prisma.user.create({
    data: {
      email: 'admin@wehere.com',
      password: adminPass,
      role: 'ADMIN',
      pseudonym: 'Admin'
    }
  });

  // Seed Users
  const userPass = await bcrypt.hash('password123', 10);
  
  // 1. Tester Account (Main user for QA)
  const tester = await prisma.user.create({
    data: {
      email: 'tester@wehere.com',
      password: userPass,
      role: 'USER',
      pseudonym: 'QA Tester',
      location: 'San Francisco, CA',
      bio: 'Ready to test!',
      interests: interestIds,
      feelings: feelingIds,
      supportTypes: [],
      xp: 500,
      level: 2,
    }
  });

  // 2. Peer User
  const peer = await prisma.user.create({
    data: {
      email: 'peer@wehere.com',
      password: userPass,
      role: 'USER',
      pseudonym: 'Helpful Peer',
      location: 'New York, NY',
      bio: 'Here to listen.',
      interests: interestIds.slice(0, 1),
      xp: 1200,
      level: 4,
    }
  });

  // Create a match and conversation
  const match = await prisma.match.create({
    data: {
      userAId: tester.id,
      userBId: peer.id,
      status: 'connected',
      matchScore: 95
    }
  });

  const conversation = await prisma.conversation.create({
    data: { matchId: match.id }
  });

  // Seed chat history
  await prisma.message.create({
    data: {
      conversationId: conversation.id,
      senderId: peer.id,
      content: 'Hi! So glad we connected. How are you feeling today?'
    }
  });

  await prisma.message.create({
    data: {
      conversationId: conversation.id,
      senderId: tester.id,
      content: 'Hey! Im doing alright, just testing the waters.'
    }
  });

  // Seed community posts
  await prisma.communityPost.create({
    data: {
      authorId: peer.id,
      topic: 'General Discussion',
      content: 'Does anyone else feel overwhelmed on Mondays?',
      likesCount: 5
    }
  });

  console.log('Seed data inserted successfully.');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

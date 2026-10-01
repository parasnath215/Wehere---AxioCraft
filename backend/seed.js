const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Seeding dummy data...");
  const user1 = await prisma.user.create({
    data: { email: 'admin@wehere.com', pseudonym: '@super_admin', role: 'ADMIN' }
  });
  const user2 = await prisma.user.create({
    data: { pseudonym: '@calm_sea', role: 'USER' }
  });
  const user3 = await prisma.user.create({
    data: { pseudonym: '@gentle_breeze', role: 'USER' }
  });

  const match = await prisma.match.create({
    data: { userAId: user2.id, userBId: user3.id, status: 'connected' }
  });

  const conversation = await prisma.conversation.create({
    data: { matchId: match.id }
  });

  await prisma.message.create({
    data: { conversationId: conversation.id, senderId: user2.id, content: 'Hello!' }
  });
  await prisma.message.create({
    data: { conversationId: conversation.id, senderId: user3.id, content: 'Hi there!' }
  });
  console.log("Seed complete.");
}
main().catch(console.error).finally(() => prisma.$disconnect());

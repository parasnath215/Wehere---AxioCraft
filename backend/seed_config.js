const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const interests = [
    'Mental Health',
    'Personal Growth',
    'Relationships',
    'Education',
    'Career',
    'Mindfulness',
    'Health & Fitness',
    'Hobbies',
    'Others'
  ];

  const feelings = [
    'Just Need Someone to Talk To',
    'Relationship Issues',
    'Friendship Issues',
    'Study Pressure',
    'Financial Stress',
    'Feeling Down',
    'Low Confidence',
    'Major Life Changes',
    'Grief / Loss',
    'Frustrated / Angry',
    'Feeling Lost',
    'Looking for Motivation'
  ];

  const supportTypes = [
    'Someone to Talk To',
    'New Friends',
    'Emotional Support',
    'Accountability Partner',
    'Motivation & Positivity'
  ];

  console.log('Seeding config options...');

  await prisma.configOption.deleteMany();

  let order = 0;
  for (const label of interests) {
    await prisma.configOption.create({
      data: { type: 'INTEREST', label, order: order++ }
    });
  }

  order = 0;
  for (const label of feelings) {
    await prisma.configOption.create({
      data: { type: 'FEELING', label, order: order++ }
    });
  }

  order = 0;
  for (const label of supportTypes) {
    await prisma.configOption.create({
      data: { type: 'SUPPORT_TYPE', label, order: order++ }
    });
  }

  console.log('Done seeding.');
}

main().catch(e => {
  console.error(e);
  process.exit(1);
}).finally(async () => {
  await prisma.$disconnect();
});

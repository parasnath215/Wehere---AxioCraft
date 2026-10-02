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
    'Other'
  ];

  const feelings = [
    'Lonely',
    'Anxious',
    'Stressed',
    'Heartbroken',
    'Career Pressure',
    'Family Issues',
    'Overwhelmed',
    'Burnout',
    'Self Growth'
  ];

  const supportTypes = [
    'Someone to Talk To',
    'New Friends',
    'Emotional Support',
    'Accountability Partner',
    'Motivation & Positivity'
  ];

  console.log('Seeding config options...');

  let order = 0;
  for (const label of interests) {
    await prisma.configOption.upsert({
      where: { label_type: { label, type: 'INTEREST' } },
      update: {},
      create: { type: 'INTEREST', label, order: order++ }
    });
  }

  order = 0;
  for (const label of feelings) {
    await prisma.configOption.upsert({
      where: { label_type: { label, type: 'FEELING' } },
      update: {},
      create: { type: 'FEELING', label, order: order++ }
    });
  }

  order = 0;
  for (const label of supportTypes) {
    await prisma.configOption.upsert({
      where: { label_type: { label, type: 'SUPPORT_TYPE' } },
      update: {},
      create: { type: 'SUPPORT_TYPE', label, order: order++ }
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

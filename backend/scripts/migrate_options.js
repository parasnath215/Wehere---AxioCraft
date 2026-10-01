const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { v4: uuidv4 } = require('uuid');

const DEFAULT_INTERESTS = [
  'Mental Health', 'Personal Growth', 'Relationships', 
  'Education', 'Career', 'Mindfulness', 
  'Health & Fitness', 'Hobbies', 'Other'
];

const DEFAULT_FEELINGS = [
  'Lonely', 'Anxious', 'Stressed', 'Heartbroken', 
  'Career Pressure', 'Family Issues', 'Overwhelmed', 
  'Burnout', 'Self Growth'
];

const DEFAULT_SUPPORT = [
  'Someone to Talk To', 'New Friends', 'Emotional Support', 
  'Accountability Partner', 'Motivation & Positivity'
];

async function generateMapping() {
  const mapping = {
    INTEREST: {},
    FEELING: {},
    SUPPORT_TYPE: {}
  };

  DEFAULT_INTERESTS.forEach(label => mapping.INTEREST[label] = uuidv4());
  DEFAULT_FEELINGS.forEach(label => mapping.FEELING[label] = uuidv4());
  DEFAULT_SUPPORT.forEach(label => mapping.SUPPORT_TYPE[label] = uuidv4());

  return mapping;
}

async function previewMapping() {
  const mapping = await generateMapping();
  console.log('--- PREVIEW OF MAPPING ---');
  console.log(JSON.stringify(mapping, null, 2));
  console.log('--------------------------');
  return mapping;
}

async function runMigration(mapping) {
  // First, create the ConfigOptions
  for (const [type, labels] of Object.entries(mapping)) {
    let order = 0;
    for (const [label, id] of Object.entries(labels)) {
      await prisma.configOption.create({
        data: { id, type, label, order: order++ }
      });
    }
  }
  
  // Then migrate users
  const users = await prisma.user.findMany();
  let migrated = 0;
  for (const user of users) {
    const newInterests = user.interests.map(label => mapping.INTEREST[label] || label);
    const newFeelings = user.feelings.map(label => mapping.FEELING[label] || label);
    const newSupport = user.supportTypes.map(label => mapping.SUPPORT_TYPE[label] || label);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        interests: newInterests,
        feelings: newFeelings,
        supportTypes: newSupport
      }
    });
    migrated++;
  }
  
  console.log(`Migrated ${migrated} users.`);
}

if (process.argv.includes('--preview')) {
  previewMapping().then(() => process.exit(0));
} else if (process.argv.includes('--run')) {
  previewMapping().then(runMigration).then(() => {
    console.log('Migration complete');
    process.exit(0);
  });
}

module.exports = { previewMapping, runMigration };

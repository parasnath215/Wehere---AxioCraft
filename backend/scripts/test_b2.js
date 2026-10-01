const axios = require('axios');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { v4: uuidv4 } = require('uuid');

const BASE_URL = 'http://localhost:3000/api';

async function generateUsers() {
  const users = [];
  const options = await prisma.configOption.findMany();
  const interests = options.filter(o => o.type === 'INTEREST').map(o => o.id);
  const support = options.filter(o => o.type === 'SUPPORT_TYPE').map(o => o.id);

  if (interests.length < 3 || support.length < 3) {
    console.error("Please run migrate_options.js first to populate config options");
    process.exit(1);
  }

  // Create Base User (Me)
  users.push({
    email: `me_${Date.now()}@example.com`,
    pseudonym: 'Me',
    images: ['img1.webp', 'img2.webp'],
    interests: [interests[0], interests[1]],
    supportTypes: [support[0]],
  });

  // User 1: High overlap (2 interests, 1 support = score 6)
  users.push({
    email: `u1_${Date.now()}@example.com`,
    pseudonym: 'User1_High',
    images: ['img1.webp', 'img2.webp'],
    interests: [interests[0], interests[1]],
    supportTypes: [support[0]],
    updatedAt: new Date(Date.now() - 100000) // very recent, +1 = score 7
  });

  // User 2: Medium overlap (1 interest, 0 support = score 2)
  users.push({
    email: `u2_${Date.now()}@example.com`,
    pseudonym: 'User2_Med',
    images: ['img1.webp', 'img2.webp'],
    interests: [interests[0], interests[2]],
    supportTypes: [support[1]],
    updatedAt: new Date(Date.now() - 100000) // very recent, +1 = score 3
  });

  // User 3: Low overlap (0 interest, 0 support = score 0)
  users.push({
    email: `u3_${Date.now()}@example.com`,
    pseudonym: 'User3_Low',
    images: ['img1.webp', 'img2.webp'],
    interests: [interests[2]],
    supportTypes: [support[1]],
    updatedAt: new Date(Date.now() - 100000) // +1 = score 1
  });

  // User 4: Incomplete (1 image = should be excluded)
  users.push({
    email: `u4_${Date.now()}@example.com`,
    pseudonym: 'User4_Inc',
    images: ['img1.webp'],
    interests: [interests[0]],
    supportTypes: [support[0]],
  });

  const createdUsers = [];
  for (const u of users) {
    const created = await prisma.user.create({ data: u });
    createdUsers.push(created);
  }

  return createdUsers;
}

async function runB2Tests() {
  const users = await generateUsers();
  const me = users[0];

  // Let's create a token for me (normally via auth, we'll just mock jwt for quick DB test or use the actual endpoint)
  const jwt = require('jsonwebtoken');
  const token = jwt.sign({ id: me.id, role: me.role }, process.env.JWT_SECRET || 'wehere_super_secret_key_123', { expiresIn: '7d' });

  console.log("--- B2 DISCOVER RANKING TEST ---");
  const res = await axios.get(`${BASE_URL}/match/discover`, {
    headers: { Authorization: `Bearer ${token}` }
  });

  const matches = res.data.matches;
  
  console.log(`Returned ${matches.length} matches.`);
  matches.forEach(m => {
    console.log(`- ${m.pseudonym}: Shared Interests count = ${m.interests.length}`);
  });

  // Verify order
  let isSorted = true;
  for (let i = 0; i < matches.length - 1; i++) {
    // If the first is User3 and second is User1, it's out of order (assuming high scores first)
    // Note: this relies on the specific test data names.
    // User1_High should be before User2_Med
    const order = ['User1_High', 'User2_Med', 'User3_Low'];
    const idx1 = order.indexOf(matches[i].pseudonym);
    const idx2 = order.indexOf(matches[i+1].pseudonym);
    if (idx1 > idx2 && idx1 !== -1 && idx2 !== -1) {
      isSorted = false;
    }
  }
  
  console.log("Ranking order correct:", isSorted ? "PASS" : "FAIL");

  // Verify exclusions
  const hasUser4 = matches.some(m => m.pseudonym === 'User4_Inc');
  console.log("Excluded User4 (< 2 photos):", !hasUser4 ? "PASS" : "FAIL");
  
  // Verify privacy
  const hasFeelings = matches.some(m => m.feelings !== undefined);
  console.log("Privacy (no feelings returned):", !hasFeelings ? "PASS" : "FAIL");

  const hasEmail = matches.some(m => m.email !== undefined);
  console.log("Privacy (no email returned):", !hasEmail ? "PASS" : "FAIL");

  console.log("Test finished.");
  process.exit(0);
}

runB2Tests().catch(console.error);

/**
 * Script: backend/scripts/create-admin.js
 * Purpose: One-off utility to seed the initial ADMIN user from environment variables.
 * Usage:
 *   ADMIN_EMAIL="admin@example.com" ADMIN_PASSWORD="SecurePassword123!" node scripts/create-admin.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const { passwordSchema } = require('../src/utils/password');

const prisma = new PrismaClient();

async function main() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    console.error('Error: ADMIN_EMAIL and ADMIN_PASSWORD environment variables are required.');
    process.exit(1);
  }

  // F11 safeguard: refuse to run with password that fails passwordSchema
  const passwordValidation = passwordSchema.safeParse(password);
  if (!passwordValidation.success) {
    console.error('Error: ADMIN_PASSWORD fails password policy: ' + (passwordValidation.error.errors[0]?.message || 'Invalid password'));
    process.exit(1);
  }

  const normalizedEmail = email.trim().toLowerCase();
  const hashedPassword = await bcrypt.hash(password, 10);

  const existingUser = await prisma.user.findFirst({
    where: { email: normalizedEmail }
  });

  if (existingUser) {
    console.log(`Updating existing user ${normalizedEmail} to role ADMIN...`);
    const updated = await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        role: 'ADMIN',
        password: hashedPassword,
        emailVerified: true,
        emailVerifiedAt: new Date(),
        isBanned: false,
      }
    });
    console.log(`User ${updated.email} updated to ADMIN successfully (ID: ${updated.id}).`);
  } else {
    console.log(`Creating new ADMIN user for ${normalizedEmail}...`);
    const created = await prisma.user.create({
      data: {
        email: normalizedEmail,
        password: hashedPassword,
        role: 'ADMIN',
        pseudonym: 'Admin',
        emailVerified: true,
        emailVerifiedAt: new Date(),
        isAnonymous: false,
      }
    });
    console.log(`Admin user created successfully (ID: ${created.id}).`);
  }
}

main()
  .catch((e) => {
    console.error('Failed to create/update admin user:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

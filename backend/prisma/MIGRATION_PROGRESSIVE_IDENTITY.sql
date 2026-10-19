-- Progressive Identity Disclosure Migration
-- Step 1: Create NameDisplayPreference Enum
DO $$ BEGIN
    CREATE TYPE "NameDisplayPreference" AS ENUM ('DISPLAY_NAME_ONLY', 'FIRST_NAME_PUBLIC');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Step 2: Alter User Table
ALTER TABLE "User" 
ADD COLUMN IF NOT EXISTS "legalFullName" TEXT,
ADD COLUMN IF NOT EXISTS "realFirstName" TEXT,
ADD COLUMN IF NOT EXISTS "displayName" TEXT,
ADD COLUMN IF NOT EXISTS "handle" TEXT,
ADD COLUMN IF NOT EXISTS "nameDisplayPreference" "NameDisplayPreference" NOT NULL DEFAULT 'DISPLAY_NAME_ONLY';

CREATE UNIQUE INDEX IF NOT EXISTS "User_handle_key" ON "User"("handle");

-- Step 3: Backfill displayName and handle from existing pseudonym and username
UPDATE "User" SET "displayName" = "pseudonym" WHERE "displayName" IS NULL AND "pseudonym" IS NOT NULL;
UPDATE "User" SET "handle" = "username" WHERE "handle" IS NULL AND "username" IS NOT NULL;

-- Step 4: Alter Match Table for Progressive Identity Revelation
ALTER TABLE "Match"
ADD COLUMN IF NOT EXISTS "userARevealed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS "userBRevealed" BOOLEAN NOT NULL DEFAULT false;

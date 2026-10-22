-- AlterTable
ALTER TABLE "User" ADD COLUMN     "underageBlockedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "PendingSignup" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "passwordHash" TEXT NOT NULL,
    "pseudonym" TEXT NOT NULL,
    "images" TEXT[],
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PendingSignup_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PendingSignup_email_key" ON "PendingSignup"("email");

-- CreateIndex
CREATE INDEX "PendingSignup_expiresAt_idx" ON "PendingSignup"("expiresAt");


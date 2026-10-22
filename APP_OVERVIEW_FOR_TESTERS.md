# Wehere Application Overview for QA Testers

Welcome to the Wehere QA team! This document provides a high-level overview of the application features, architecture, and expected behaviors to guide your testing efforts.

## Application Architecture

The Wehere ecosystem consists of three main components:
1. **Flutter Mobile App:** Cross-platform (iOS/Android) frontend that users interact with.
2. **Node/Express Backend:** REST API and WebSocket server handling business logic, data storage (PostgreSQL via Prisma), and real-time chat.
3. **Next.js Admin Panel:** Web dashboard for moderators and admins to review reports, matches, and app analytics.

## Core User Flows to Test

### 1. Onboarding & Registration
- Users can sign up via Email/Password or proceed Anonymously.
- **Anonymous Mode:** Does not require email but restricts certain profile fields.
- **Email Registration:** Requires 2 profile photos and basic bio data.
- **OTP Verification:** The code `123456` works only on a QA server started with `NODE_ENV=staging` and `TEST_OTP_ENABLED=true`; never on production.

### 2. Discovery & Match Deck (Tinder-style)
- The Home/Discover screen presents a deck of peer profiles.
- **Swipe Logic:** Swipe right (Heart) to connect, left (Pass) to discard.
- **Super Support (Star):** Instantly connects and sends an automated icebreaker message.
- Matches only trigger when one user swipes right and the backend confirms a connection, or immediately if using a Super Support.

### 3. Real-Time Chat (WebSocket)
- Active matches move to the Chat inbox.
- Chat supports text messages and "voice notes" (simulated currently as a UI placeholder).
- **Safety Feature (Crisis Keyword Detection):** Sending messages with trigger words like `suicide` or `self-harm` flags the conversation and surfaces the SOS intervention UI.
- Users can report and block peers from within the chat screen.

### 4. Wellness Tools (Journaling & Mood)
- Daily mood check-ins (1-5 scale mapped to emotions).
- Private text-based journaling with category tagging.
- Gamification (XP & Streaks) updates upon saving a journal entry or swiping.

### 5. Community Feed
- A global forum where users can post discussions anonymously or with their pseudonym.
- Supports liking and commenting.

### 6. Admin Panel (Moderation)
- Requires login using admin credentials.
- Admins can view aggregate app statistics.
- Admins can moderate user reports and manage users (bans, deletions, roles).

## Known Technical Constraints (DO NOT FAIL QA FOR THESE)
1. **Voice Notes:** Voice notes are simulated UI blocks and do not actually record audio.
2. **Email OTP Gateway:** In staging/testing, `123456` works when `TEST_OTP_ENABLED=true` and `NODE_ENV=staging`. In production, real transactional email delivery is enforced.
3. **Admin Panel Metrics:** Some charts and metrics on the admin panel dashboard may display placeholder zeros or static layouts.

## References
- Refer to `docs/PRD.md` for strict feature requirements.
- Refer to `docs/openapi.yaml` for API endpoint contracts.
- Refer to `README_TESTING.md` for environment setup.

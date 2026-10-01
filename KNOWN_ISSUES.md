# Known Issues & Tech Debt

This document outlines incomplete features, fake placeholders, and integration issues discovered during the pre-QA phase.

## 🔴 Backend Issues

1. **Age and Profile Demographics Not Persisted**
   - **Severity:** Medium
   - **Details:** The `User` model in `prisma/schema.prisma` does not have an `age` field. The frontend sends age data, but the backend drops it. Consequently, the Flutter app hard-codes `age: 18` or `age: 24` on profile responses in `app_state.dart`.

2. **No Real Email/SMS Gateway for OTP**
   - **Severity:** High
   - **Details:** `auth.js` has a `/otp/request` endpoint that returns a mock success message, and a `/otp/verify` endpoint that hardcodes `123456` if `TEST_OTP_ENABLED` is set. There is no real Twilio/SendGrid integration yet.

3. **Missing Journal Gratitude Support**
   - **Severity:** Low
   - **Details:** The frontend `JournalEntry` model has a `gratitude` field, but the backend `JournalEntry` schema does not. Data sent to gratitude is lost.

4. **Dynamic Server Usage Error in Admin Panel**
   - **Severity:** Low
   - **Details:** Building the Next.js admin panel via `npm run build` throws Next.js dynamic server usage errors on API routes because they try to fetch live data during static generation.

## 🟡 Frontend Issues

1. **Empty State Avatars**
   - **Severity:** Low
   - **Details:** Placeholder avatar URLs in `app_state.dart` were replaced with empty strings. The UI might show blank spaces or image loading errors instead of a proper default fallback icon.

2. **Voice Notes are Faked**
   - **Severity:** Medium
   - **Details:** Sending a voice note in the chat screen adds a hardcoded text message: `Voice note (X s)`. There is no actual audio recording or playback implemented.

3. **Tinder Swipe Logic is Partially Optimistic**
   - **Severity:** Low
   - **Details:** The frontend decrements its local `_cards` deck before the backend responds. If the network request fails, the local state and backend state desync.

## 🔵 Integration Issues

1. **Anonymous Mode vs Signup**
   - **Severity:** Medium
   - **Details:** Clicking "Stay Anonymous" on signup correctly creates a backend record via `/auth/anonymous` but the UI flows heavily expect users to provide an avatar and name later in onboarding. The backend `images` requirement might conflict with Anonymous users if they try to edit their profile later without an image.

## 🔒 Security

1. **Leaked Git Credentials in History**
   - **Severity:** CRITICAL
   - **Details:** The git history contains previous iterations of `.env` files and `deploy.js` scripts containing real credentials.
   - **Action Required:** The following MUST BE ROTATED before making this repository public:
     - VPS SSH Root Password (`Axio********`)
     - Backend `JWT_SECRET` (`wehere_s**********`)
     - Admin Panel `INTERNAL_API_KEY` (`wehere_s**********`)
     - Docker Compose Database Credentials (`supersecureadmin`)

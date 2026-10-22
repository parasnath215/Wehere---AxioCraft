# Production Hardening Changelog: Wehere

This document records the exact, verified code and architecture modifications across every hardening phase of the Wehere ecosystem.

---

## Phase 1 — Launch Blockers: Security and Safety

### 1.1 HTTPS / WSS Client Configuration
- **Mobile Client**:
  - Centralized base URL in `AppConstants.apiBaseUrl` via `String.fromEnvironment('API_URL')`.
  - Removed all occurrences of hardcoded IP `http://200.97.165.22:4000/api`.
  - Added startup safety guard in `main.dart`: in release mode (`kReleaseMode`), the app terminates with a `StateError` if `apiBaseUrl` does not begin with `https://`.
  - Debug builds fall back dynamically to `http://10.0.2.2:4000/api` on Android emulators and `http://localhost:4000/api` on other platforms.
  - Socket.IO connection URL is derived dynamically from `apiBaseUrl` (stripping `/api`), automatically choosing `wss://` or `ws://`.
- **Platform Manifests**:
  - Android: Removed `android:usesCleartextTraffic="true"` from `android/app/src/main/AndroidManifest.xml`. Created a debug-only flavor manifest `android/app/src/debug/AndroidManifest.xml` enabling cleartext traffic exclusively for local development.
  - iOS: Removed `NSAllowsArbitraryLoads` from `ios/Runner/Info.plist`; enabled `NSAllowsLocalNetworking = true` for local simulator testing.
- **Runbook**:
  - Created [docs/ops/HTTPS_SETUP.md](file:///e:/Websites/Wehere/docs/ops/HTTPS_SETUP.md) detailing Nginx reverse proxy configuration, Let's Encrypt (Certbot) TLS setup, WebSocket upgrade headers, and release build flags.

### 1.2 Remove Anonymous Login Bypass
- **Backend (`backend/src/routes/auth.js`)**:
  - Permanently deleted the route `POST /api/auth/anonymous`.
  - Enforced `req.user.emailVerified === true` strictly in `requireVerified` middleware (`backend/src/middleware/auth.js`), removing the anonymous bypass. Unverified requests receive HTTP 403 `{ error: 'EMAIL_NOT_VERIFIED' }`.
- **User Model**:
  - The `isAnonymous` database column and profile "hide my identity" preference are preserved strictly as a public pseudonym/alias display preference, not an authentication bypass.

### 1.3 Rate Limits & OTP Lockout
- **Middleware (`backend/src/middleware/rateLimits.js`)**:
  - Created centralized rate limiters using `express-rate-limit`:
    - `signupLimiter`: 5 per hour per IP.
    - `otpVerifyLimiter`: 10 per 15 min per IP.
    - `otpRequestLimiter`: 5 per 15 min per IP + sliding window in-memory limiter capping at 3 requests per 10 min per email address.
    - `resetPasswordLimiter`: 5 per 15 min per IP.
    - `loginLimiter`: 10 per 15 min per IP.
    - `reportLimiter`: 10 per hour per IP.
    - `communityLimiter`: 20 per hour per user ID.
    - `adminApiLimiter`: 120 per minute per IP across all `/api/admin` routes.
- **Brute-Force OTP Lockout**:
  - In `backend/src/routes/auth.js`, every failed OTP check increments `OtpRecord.attempts`.
  - If `attempts >= 5`, the record is marked consumed (`usedAt = now()`) and locked out with HTTP 400 `{ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' }`.
  - Secure verification using `bcrypt.compare`; plaintext OTP codes are never logged or exposed.

### 1.4 Admin Panel Security & Next.js Authentication
- **Backend Guard (`adminGuard`)**:
  - Replaced legacy authorization on all `/api/admin/*` routes with `adminGuard`.
  - Enforces timing-safe comparison on `x-api-key == process.env.INTERNAL_API_KEY` using `crypto.timingSafeEqual` with buffer length validation.
  - Verifies standard Bearer JWT token, requires `req.user.role === 'ADMIN'`, and rejects banned users.
  - Added public `POST /api/admin/login` (email + password, bcrypt verification, ADMIN check, returning a 12-hour session JWT).
  - Explicit Prisma `safeUserSelect` projection applied across all user retrieval/modification routes in `backend/src/routes/admin.js`, guaranteeing `password`, `tokenVersion`, and OTP records are never leaked.
  - Banning a user (`PUT /api/admin/users/:id/ban`) increments `tokenVersion`, instantly revoking their active mobile and admin sessions.
- **Admin Panel (`admin-panel/`)**:
  - Created Next.js 15 route `src/app/login/page.tsx` with a server action verifying credentials against `POST /api/admin/login`.
  - Stores session JWT in an `httpOnly`, `sameSite=lax`, `secure` (in production) cookie named `admin_token` (max age 12h).
  - Created `src/middleware.ts` redirecting unauthenticated requests to `/login`.
  - Created centralized `adminFetch` in `src/lib/api.ts` passing `x-api-key` and Bearer token, automatically clearing the session cookie and redirecting to `/login` on HTTP 401.
  - Added header logout action and button.
  - Created one-off admin creation script `backend/scripts/create-admin.js`.

### 1.5 Fix Admin Analytics Crash
- **Backend (`backend/src/routes/admin.js`)**:
  - Fixed typo in user analytics handler: changed `prisma.journal.count({ where: { authorId: id } })` to `prisma.journalEntry.count({ where: { userId: id } })`.

### 1.6 Server-Side Date of Birth & 18+ Adulthood Guard
- **Prisma Schema (`backend/prisma/schema.prisma`)**:
  - Added `dateOfBirth DateTime?` to `User` model.
  - Created SQL migration `backend/prisma/migrations/20261022000000_add_date_of_birth/migration.sql`.
- **Backend Utilities & Middleware**:
  - Created `backend/src/utils/age.js` exporting `calcAge(dob, now)` and `parseDob(str)` (validates `YYYY-MM-DD`, rejects future dates, invalid dates, or age > 100).
  - Created `requireAdult` middleware: rejects missing DOB with HTTP 403 `{ error: 'AGE_REQUIRED' }` and age < 18 with HTTP 403 `{ error: 'UNDERAGE' }`.
  - Applied `requireAdult` to `/api/match/*`, `/api/conversations/*`, `/api/community/*`, and Socket.IO connection handshake.
  - `PUT /api/auth/onboarding` accepts `dateOfBirth` and rejects age < 18.
  - Added `PUT /api/users/me/dob` for existing users without DOB.
  - `PUT /api/users/me` strictly rejects `dateOfBirth` and `age` mutations.
  - `GET /api/users/me` returns computed `age` and `needsDob: boolean`. Discovery feed excludes users under 18 or with null DOB.
- **Flutter Client**:
  - Onboarding step 1 requires valid DOB and sends formatted `YYYY-MM-DD`. Removed local persistence of `user_age` and `user_dob`.
  - In `EditProfileScreen`, age is rendered as verified read-only text without edit controls.
  - Added `DobGateScreen` (`lib/screens/auth/dob_gate_screen.dart`, route `AppRoutes.dobGate`), routed dynamically when `auth.needsDob == true`.

### 1.7 Token Storage Fallback
- **Flutter Storage Helper (`lib/core/utils/storage_helper.dart`)**:
  - Plaintext fallback to `SharedPreferences` for `jwt_token` is restricted strictly to `kDebugMode`.
  - In release builds, if `FlutterSecureStorage` throws an exception, it returns `null` or rethrows, ensuring credentials are never saved unencrypted on disk.

### 1.8 API Client Error Handling & Interceptor
- **Flutter Networking (`lib/core/network/api_client.dart`)**:
  - Extracted pure function `shouldForceLogout(status, path, code)`: returns `true` only for 401 on non-`/auth/` routes or 403 `ACCOUNT_BANNED`.
  - 403 `EMAIL_NOT_VERIFIED` broadcasts `AuthEvent.emailNotVerified`.
  - 403 `AGE_REQUIRED` broadcasts `AuthEvent.ageRequired` (setting `needsDob = true` and presenting `DobGateScreen`).
  - Auth validation errors (wrong password, invalid OTP) on `/auth/*` routes are passed to callers without wiping tokens or forcing navigation.

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
    - `signupLimiter`: 20 per hour per IP.
    - `otpVerifyLimiter`: 60 per 15 min per IP.
    - `otpRequestLimiter`: 5 per 15 min per IP + sliding window in-memory limiter capping at 3 requests per 10 min per email address.
    - `resetPasswordLimiter`: 5 per 15 min per IP.
    - `loginLimiter`: Composite limiter: IP cap of 100 per 15 min + account limiter of 10 per 15 min per IP + email.
    - `adminLoginLimiter`: Separate limiter of 5 per 15 min per IP + email.
    - `dobLimiter`: 10 per hour per user on `PUT /api/users/me/dob`.
    - `reportLimiter`: 10 per hour per IP.
    - `communityLimiter`: 20 per hour per user ID.
    - `adminApiLimiter`: 120 per minute per IP across all `/api/admin` routes.
- **Brute-Force OTP Lockout**:
  - In `backend/src/routes/auth.js`, every failed OTP check increments `attempts`.
  - If `attempts >= 5`, the record is locked and the server responds with HTTP 400 `{ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' }`.
  - Secure verification using `bcrypt.compare`; plaintext OTP codes are never stored or logged.

### 1.4 Admin Panel Security & Next.js Authentication
- **Backend Guard (`adminGuard`)**:
  - Replaced legacy authorization on all `/api/admin/*` routes with `adminGuard`.
  - Enforces timing-safe comparison on `x-api-key == process.env.INTERNAL_API_KEY` using `crypto.timingSafeEqual` with buffer length validation.
  - Verifies standard Bearer JWT token, requires `req.user.role === 'ADMIN'`, purpose claim `purpose === 'admin'`, and rejects banned users.
  - Added public `POST /api/admin/login` (email + password, bcrypt verification, ADMIN check, returning a 12-hour session JWT with `purpose: 'admin'`).
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
  - Added `dateOfBirth DateTime?` and `underageBlockedAt DateTime?` to `User` model.
  - Created baseline SQL migrations `0_init`, `20261022000000_add_date_of_birth`, and `20261022100000_pending_signup_and_underage_blocked`.
- **Backend Utilities & Middleware**:
  - Created `backend/src/utils/age.js` exporting `calcAge(dob, now)` and `parseDob(str)` (validates `YYYY-MM-DD`, rejects future dates, invalid dates, or age > 100).
  - Created `requireAdult` middleware: rejects missing DOB with HTTP 403 `{ error: 'AGE_REQUIRED' }` and age < 18 or `underageBlockedAt` with HTTP 403 `{ error: 'UNDERAGE' }`.
  - Applied `requireAdult` to `/api/match/*`, `/api/conversations/*`, `/api/community/*`, and Socket.IO connection handshake.
  - `PUT /api/auth/onboarding` accepts `dateOfBirth` and rejects age < 18 (setting `underageBlockedAt`).
  - Added `PUT /api/users/me/dob` for existing users without DOB.
  - `PUT /api/users/me` strictly rejects `dateOfBirth` and `age` mutations.
  - `GET /api/users/me` returns computed `age` and `needsDob: boolean`. Discovery feed excludes users under 18 or with null DOB.
- **Flutter Client**:
  - Onboarding step 1 requires valid DOB and sends formatted `YYYY-MM-DD`. Removed local persistence of `user_age` and `user_dob`.
  - In `EditProfileScreen`, age is rendered as self-declared read-only text without edit controls.
  - Added `DobGateScreen` (`lib/screens/auth/dob_gate_screen.dart`, route `AppRoutes.dobGate`), routed dynamically when `auth.needsDob == true`.

### 1.7 Token Storage Fallback
- **Flutter Storage Helper (`lib/core/utils/storage_helper.dart`)**:
  - Plaintext fallback to `SharedPreferences` for `jwt_token` is restricted strictly to `kDebugMode`.
  - In release builds, if `FlutterSecureStorage` throws an exception, it returns `null` or rethrows, ensuring credentials are never saved unencrypted on disk.

### 1.8 API Client Error Handling & Interceptor
- **Flutter Networking (`lib/core/network/api_client.dart`)**:
  - Extracted pure function `shouldForceLogout(status, path, code)`: returns `true` only when `(status == 401 && (code == 'TOKEN_INVALID' || code == 'TOKEN_EXPIRED')) || (status == 403 && code == 'ACCOUNT_BANNED')`.
  - 403 `EMAIL_NOT_VERIFIED` broadcasts `AuthEvent.emailNotVerified`.
  - 403 `AGE_REQUIRED` broadcasts `AuthEvent.ageRequired` (setting `needsDob = true` and presenting `DobGateScreen`).
  - Auth validation errors (wrong password, invalid OTP) on `/auth/*` routes are passed to callers without wiping tokens or forcing navigation.

---

## Phase 1 Fix Pass (Hardening Revisions F1 – F15)

- **F1 (Remove Production OTP Bypass)**:
  - `generateOtp()` returns `'123456'` ONLY when `process.env.TEST_OTP_ENABLED === 'true' && process.env.NODE_ENV !== 'production'`. Otherwise `crypto.randomInt(100000, 1000000).toString()`.
  - Added startup guard in `backend/src/server.js`: if `NODE_ENV === 'production' && TEST_OTP_ENABLED === 'true'`, exits immediately with fatal error.
  - Removed `TEST_OTP_ENABLED` from `docker-compose.yml`. Configured `TEST_OTP_ENABLED=false` in `backend/.env.example`.
  - Updated `README_TESTING.md` and `APP_OVERVIEW_FOR_TESTERS.md` documentation.
- **F2 (Ban Enforcement Across Stack)**:
  - Enforced `user.isBanned` checks returning 403 `{ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' }` in `POST /api/auth/login`, `authenticateToken`, `/otp/verify`, and `/reset-password`.
  - Socket handshake rejects banned users with `ACCOUNT_BANNED`.
  - Admin ban route (`PUT /api/admin/users/:id/ban`) increments `tokenVersion: { increment: 1 }` and disconnects all live sockets belonging to that user ID via `io.fetchSockets()`.
  - Added warning counter and 7-day TODO log for legacy tokens missing `tokenVersion`.
- **F3 (Privacy & Normalised Email Login)**:
  - `/api/auth/otp/request` always responds `{ success: true, message: 'If the account exists, a code was sent to the registered email.', cooldown: 60 }` with no `email` field returned.
  - Login, `/otp/request`, and `/reset-password` identify users by normalised email only (`email.trim().toLowerCase()`). Removed lookup by pseudonym, username, or phone.
  - `User.pseudonym` is strictly display-only.
  - Flutter login field and forgot-password dialog updated to "Email".
- **F4 (Pending Signups Stored Outside JWT)**:
  - Added `PendingSignup` Prisma model (`id`, `email`, `phone`, `passwordHash`, `pseudonym`, `images`, `codeHash`, `attempts`, `expiresAt`, `createdAt`).
  - `POST /api/auth/signup` normalises email, checks conflict, purges stale pending rows and images, creates `PendingSignup`, and returns a minimal 15-minute `signupToken` containing ONLY `{ purpose: 'pending_signup', pendingId }`.
  - `/api/auth/otp/verify` checks code against `PendingSignup.codeHash`, enforces 5-attempt lockout, creates `User` and deletes `PendingSignup` in a single transaction on success.
  - Added background cleanup worker in `server.js` running every 15 minutes to delete expired pending signups and purge their image files.
- **F5 (Unverified Login & Purpose Segregation)**:
  - In `POST /api/auth/login` for unverified accounts, OTP is hashed with `bcrypt.hash(code, 10)` (matching `/otp/verify`).
  - 403 `EMAIL_NOT_VERIFIED` returns 15-minute token `{ id, purpose: 'verify_email' }`.
  - `authenticateToken` strictly rejects any token with a `purpose` claim with 401 `TOKEN_INVALID`.
- **F6 (Docker, Secrets & Migrations)**:
  - Removed all hardcoded secrets from `docker-compose.yml`, using `${VAR}` substitution.
  - Created root `.env.example` with placeholders.
  - Added PostgreSQL healthcheck and `depends_on: condition: service_healthy`.
  - Bound uploads volume `uploads:/app/public/uploads` matching `server.js` static directory.
  - Created baseline migration `0_init/migration.sql` from git commit `0f943d8`. Migration sequence: `0_init` → `20261022000000_add_date_of_birth` → `20261022100000_pending_signup_and_underage_blocked`.
  - Docker compose command updated to `npx prisma migrate deploy && npm start`. Removed `--accept-data-loss` everywhere.
  - Excluded `reset_data.js`, `seed.js`, and `scripts/` in `backend/.dockerignore`.
- **F7 (Rate Limiting Realignment)**:
  - Global `apiLimiter` adjusted to 1200 per 15 min, keyed by authenticated user ID or normalized client IP.
  - `TRUST_PROXY_HOPS` defaults to 1 in production if unset; startup logs effective hops.
  - `loginLimiter`: composite of IP cap (100 / 15 min) and IP+email key (10 / 15 min).
  - Created dedicated `adminLoginLimiter` (5 per 15 min per IP+email).
  - `signupLimiter`: 20/hr per IP; `otpVerifyLimiter`: 60/15m per IP; `dobLimiter`: 10/hr per user.
  - Custom key generators utilize `ipKeyGenerator` from `express-rate-limit`.
- **F8 (Status Codes & Force Logout)**:
  - Wrong login email/password returns 401 `{ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' }`.
  - Wrong current password in change-password returns 400 `{ error: 'VALIDATION_ERROR', message: 'Current password is incorrect.' }`.
  - Admin login returns `INVALID_CREDENTIALS` on credential failure.
  - Flutter `shouldForceLogout`: returns true only on 401 (`TOKEN_INVALID` or `TOKEN_EXPIRED`) or 403 `ACCOUNT_BANNED`. Removed `/auth/` exclusion rule.
  - Flutter login screen displays server error message on `INVALID_CREDENTIALS` without logging out or clearing state.
- **F9 (Unified Password Policy)**:
  - Created `backend/src/utils/password.js` exporting zod `passwordSchema` (8+ characters, at least 1 uppercase, 1 lowercase, 1 special character).
  - Applied schema across signup, reset-password, change-password, and admin creation.
  - Updated Flutter validation and messages to the identical policy.
  - Token versions incremented atomically via `tokenVersion: { increment: 1 }`.
- **F10 (Shared Prisma Client)**:
  - Created `backend/src/lib/prisma.js` exporting single shared `PrismaClient` instance, replacing `new PrismaClient()` across all routes, middleware, and services.
  - Added graceful `SIGTERM` and `SIGINT` handlers in `server.js` invoking `prisma.$disconnect()`.
- **F11 (Admin Panel Hardening)**:
  - `admin-panel/src/middleware.ts`: removed `pathname.includes('.')` bypass. Enforced strict allowlist for public static extensions.
  - Zod validation and email normalisation enforced on `PUT /api/admin/users/:id` and `POST /api/admin/users`.
  - `GET /api/admin/users` returns `{ users, total, pages }`. Updated admin panel consuming pages.
  - Admin JWT payload carries `{ id, tokenVersion, purpose: 'admin' }`; `adminGuard` requires `purpose === 'admin'`.
  - Added password validation safeguards to `backend/scripts/create-admin.js`.
- **F11b (Socket.IO & CORS Hardening)**:
  - Socket.IO CORS configuration uses Express allowlist handler (mobile allowed without origin; in production restricted to `FRONTEND_URL` and `ADMIN_URL`).
  - Removed duplicate `app.use(helmet())`.
  - Socket typing handler ignores client-provided `senderId` and binds `socket.user.id`.
- **F12 (Underage Lockout & DOB Gate)**:
  - Added `User.underageBlockedAt DateTime?`. Setting age < 18 sets timestamp, leaves `dateOfBirth` null, and responds 403 `UNDERAGE`.
  - Flutter `DobGateScreen` refetches `/users/me`, runs `fetchBackendData()`, and reconnects Socket.IO upon successful DOB submission.
  - Purged legacy `user_age` and `user_dob` keys from storage on app launch in `main.dart`.
  - Replaced "verified" terminology with "self-declared" in UI and documentation.
- **F13 (Repo Hygiene)**:
  - Untracked `node_modules/`, `skills-lock.json`, and temporary artifacts from git index using `git rm -r --cached`.
  - Configured comprehensive `.gitignore`.
- **F14 (Documentation Corrections)**:
  - Architecture documents updated to reflect 7-day session JWT lifetimes, `PendingSignup` table, email-only auth, 23 app screens, and 63 verified backend endpoints.
- **F15 (Verification)**:
  - Syntax check, Prisma validation, Flutter analyzer (0 errors), and Next.js admin panel production build verified.

---

## Phase 2 — Social Auth Unification, Single DOB Gate & Underage Hardening (Tasks A1–A10)

### 2.1 Backend Social Auth & Token Verification (A1, A2)
- **Deleted Insecure Apple Route**: Removed legacy `POST /api/auth/apple` which relied on `jwt.decode()` without signature checks and trusted body claims.
- **Unified Social Auth Service (`backend/src/services/socialAuth.js`)**:
  - `verifySocialToken({ provider, idToken, nonce, givenName, familyName, appleKeyGetter })`: Returns a normalised profile `{ provider, subject, email, emailVerified, name, givenName, familyName, pictureUrl, locale }` or throws 401 `INVALID_CREDENTIALS`.
  - **Google**: Verifies `idToken` using `google-auth-library` (`OAuth2Client`) against comma-separated `GOOGLE_CLIENT_IDS` env var. Requires `email_verified === true`. Upgrades Google avatar URL from `=s96-c` to high-resolution `=s512-c`.
  - **Apple**: Verifies `idToken` using `jwks-rsa` public keys (`https://appleid.apple.com/auth/keys`, cached) with `jsonwebtoken` algorithms `['RS256']`, issuer `https://appleid.apple.com`, and audience from `APPLE_CLIENT_IDS`. Strictly validates SHA-256 hash match: `payload.nonce === sha256(rawNonce)`. Uses verified claims (`sub`, `email`, `email_verified`). Injectable `appleKeyGetter` allows isolated unit testing.
- **Unified Endpoints (`backend/src/routes/auth.js`)**:
  - `POST /api/auth/social/check`: Pre-validates token claims and determines if user exists. Blocked minors return 403 `UNDERAGE`, banned users return 403 `ACCOUNT_BANNED`, invalid tokens return 401 `INVALID_CREDENTIALS`. Rate limited by `socialLimiter` (30/15m per IP).
  - `POST /api/auth/social/login`: Logs in existing accounts only. Returns 404 `ACCOUNT_NOT_FOUND` if user does not exist (never creates phantom users). Seamlessly links provider subject if user exists with verified email.
  - `POST /api/auth/social/register`: Multipart registration with 2–6 images. Validates optional un-trimmed password against shared `passwordSchema`. Creates verified account (`emailVerified: true`), maps private names (`realFirstName`, `legalFullName`), and establishes 7-day session.
  - Deleted legacy routes: `/google`, `/google/check`, `/register-google`, `/apple`.

### 2.2 Auth Session Service & Serializer (A3)
- **Created `backend/src/services/authSession.js`**:
  - `assertAccountAllowed(user)`: Throws 403 `ACCOUNT_BANNED` if `user.isBanned`, or 403 `UNDERAGE` if `user.underageBlockedAt`. Used in login, social auth, reset password, and `authenticateToken` middleware.
  - `isOnboardingComplete(user)`: Evaluates `Boolean(user.location) && Array.isArray(user.interests) && user.interests.length > 0`.
  - `serializeAuthUser(user)`: Serializes user into `{ id, email, role, pseudonym, displayName, avatar, images, age, needsDob, onboardingCompleted, emailVerified, currentStreak }`. Never exposes raw `dateOfBirth`.
  - `completeLogin(res, user, { created })`: Validates account permissions, auto-restores scheduled deletion accounts (clearing deletion dates and setting `accountRestored: true`), evaluates daily streaks, signs 7-day session JWT `{ id, role, tokenVersion }`, and returns standardized response envelope.
  - Replaced legacy `requiresDob` field with `needsDob` across all API responses and Flutter client readers.

### 2.3 Single Date of Birth Entry & Permanent Underage Blocking (A4)
- **`PUT /api/auth/onboarding`**: Completely removed `dateOfBirth` from schema and handler. Rejects with 403 `AGE_REQUIRED` if `user.dateOfBirth == null`, or 403 `UNDERAGE` if `user.underageBlockedAt` is set.
- **`PUT /api/users/me/dob`**: The single endpoint for DOB entry.
  - Retains calendar date validation (YYYY-MM-DD, non-future, max age 100) and idempotent `alreadySet: true` behavior.
  - Under 18: In an atomic transaction, sets `underageBlockedAt = now`, deletes all uploaded photos via `deleteImage`, purges `images = []`, `avatar = null`, `bio = null`, `interests = []`, nullifies `displayName`, increments `tokenVersion`, and disconnects live user sockets via `io.fetchSockets()`. Responds 403 `UNDERAGE`.
  - Email `/login` now invokes `assertAccountAllowed` so blocked minors cannot log in.

### 2.4 Flutter Target Flow Contract & Single Route Decision (A5, A6)
- **Centralized Route Navigation**:
  - Implemented pure function `resolveNextRoute({ isAuthenticated, emailVerified, needsDob, onboardingCompleted })` and `AuthNotifier.nextRoute()`.
  - Created `AuthNotifier.navigateAfterAuth(context)` using `pushNamedAndRemoveUntil` and resetting tab index.
  - Removed all duplicated if/else routing branches from `login_screen.dart`, `signup_screen.dart`, `otp_verification_screen.dart`, `dob_gate_screen.dart`, and `splash_screen.dart`.
- **Underage Quarantine Screen (`AppRoutes.underage` / `/auth/underage`)**:
  - Created `UnderageBlockedScreen` with `PopScope(canPop: false)`, clear messaging, and a Close button.
  - `ApiClient` emits `AuthEvent.underage` on HTTP 403 `UNDERAGE`; `AuthNotifier.handleUnderage()` clears all credentials, signs out of Google, resets `AppState`, and navigates to the underage screen.
- **`DobGateScreen`**:
  - Rewritten with title "Your date of birth", typed input date picker (`dd/mm/yyyy`), formatted date display (`14 Mar 2001`), and confirmation dialog.
  - Removed local age calculation shortcut; always defers enforcement to `PUT /users/me/dob`.
  - On 403 `UNDERAGE` $\rightarrow$ calls `handleUnderage()`. On success/409 $\rightarrow$ calls `refreshSession()` and `navigateAfterAuth()`.
- **`OnboardingFlowScreen`**:
  - Stripped all date-of-birth and age inputs, controllers, formatters, and free-text year parsing from step 1.
  - Purged legacy draft keys `onboarding_draft_dob` and `onboarding_draft_age`.
  - Prefills `_firstNameController` from server `realFirstName` and `_nameController` from `displayName`.

### 2.5 Unified Social Login in Flutter (A7, A8, A9)
- **Social Auth Service (`lib/services/social_auth_service.dart`)**:
  - `signInWithGoogle()`: Uses `GoogleSignIn` with `serverClientId = AppConstants.googleServerClientId`.
  - `signInWithApple()`: Generates 32-character cryptographically secure raw nonce, computes SHA-256 hex digest, and requests credentials via `SignInWithApple.getAppleIDCredential`.
- **`AuthNotifier.continueWithProvider()`**:
  - Single social entry point. Calls `POST /auth/social/check`, then executes `socialLogin()` if user exists or forwards `SocialRegistrationData` to `signup_screen.dart` if new.
  - Handles 403 `UNDERAGE` and `ACCOUNT_BANNED` explicitly. Failed checks never treat users as new.
- **`SignUpScreen` Social Auto-Fill**:
  - Email field locked and marked with "Verified by Google" / "Verified by Apple" badge.
  - Password marked optional: `"Optional: set a password to also log in with email"`.
  - Display name prefilled from provider `givenName` (fallback: first word of name) gated by `AppConstants.useProviderNameAsDisplayName`.
  - Slot 1 profile photo downloaded from provider high-res URL with caption `"From your Google account"`.
  - Private real names (`givenName`, `familyName`) forwarded to server for mutual identity reveal.
  - If locale begins with `hi`, stored in `suggested_locale`.
- **Google People API (A9, Default OFF)**:
  - Added `AppConstants.googlePeopleApi` flag. When enabled, queries `https://people.googleapis.com/v1/people/me` using isolated Dio instance for DOB and phone suggestions.


# Authentication & Security Architecture: Wehere

## 1. Authentication Lifecycle & Session Management

### Session Flow & Token Issuance
1. **Registration Handshake (`/api/auth/signup`)**:
   - Protected by `signupLimiter` (5 requests per hour per IP) via [backend/src/middleware/rateLimits.js](file:///e:/Websites/Wehere/backend/src/middleware/rateLimits.js).
   - During registration, the user submits credentials and photos (minimum 2 photos).
   - The backend does **not** issue a full session JWT. Instead, it creates an unverified account (`emailVerified: false`) and returns a temporary `signupToken` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)).
   - A 6-digit numeric OTP is generated, hashed with bcrypt, and emailed to the user with a 10-minute expiry window ([backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js)).
2. **OTP Verification Handshake (`/api/auth/otp/verify`)**:
   - Protected by `otpVerifyLimiter` (10 per 15 min per IP).
   - User inputs the 6-digit PIN.
   - **Brute-Force Lockout**: On every failed OTP verification attempt, `OtpRecord.attempts` is incremented. When `attempts >= 5`, the OTP record is locked (`usedAt = now()`) and the server responds with HTTP 400 `{ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' }`.
   - Codes are compared using `bcrypt.compare`; plaintext OTPs are never stored or logged.
   - Upon verification, the user's `emailVerified` flag is set to `true`, and the server returns a production session JWT signed with `JWT_SECRET` containing `{ id: user.id, tokenVersion: user.tokenVersion }` with a 30-day expiration.
3. **Login Handshake (`/api/auth/login`)**:
   - Rate-limited to 10 attempts per 15 minutes per IP address via `loginLimiter`.
   - If the account has `emailVerified: false`, the server responds with HTTP 403 Forbidden and `{ error: 'EMAIL_NOT_VERIFIED' }`. The app intercepts this and transitions `AuthStatus` to `unverified` to prompt for OTP entry.
4. **No Anonymous Bypass (Hardened)**:
   - The legacy `POST /api/auth/anonymous` endpoint has been permanently deleted.
   - `requireVerified` middleware strictly checks `req.user.emailVerified === true` with no exceptions.
   - `isAnonymous` in the database is strictly a user display preference (alias/pseudonym display mode), not an authentication state.
5. **18+ Date of Birth Requirement (`requireAdult`)**:
   - All users must verify they are 18 or older.
   - `requireAdult` middleware is enforced on `/api/match`, `/api/conversations`, `/api/community`, and Socket.IO handshakes:
     - Missing Date of Birth: HTTP 403 `{ error: 'AGE_REQUIRED' }`. Flutter maps this to `AuthEvent.ageRequired` and redirects to `DobGateScreen`.
     - Age < 18: HTTP 403 `{ error: 'UNDERAGE' }`.
   - Onboarding step 1 requires valid DOB (YYYY-MM-DD) and rejects age < 18.
   - Existing accounts without DOB can submit via `PUT /api/users/me/dob`. Once set, DOB is immutable for users.
6. **Admin Authentication (`adminGuard` & `/api/admin/login`)**:
   - Public endpoint `POST /api/admin/login` (email + password, 12-hour JWT expiry).
   - `adminGuard` protects all `/api/admin/*` routes, enforcing:
     1. Header `x-api-key` matches `process.env.INTERNAL_API_KEY` using `crypto.timingSafeEqual` with length checking.
     2. Valid Bearer JWT (`authenticateToken`).
     3. User role `ADMIN` and not banned.
   - Admin router is globally rate-limited to 120 requests/minute per IP.
   - Banning a user immediately increments `tokenVersion`, revoking all active sessions.
   - Next.js 15 admin panel authenticates via `/login` and stores the token in an `httpOnly`, `sameSite=lax`, `secure` (in production) cookie named `admin_token`.

### Token Storage Strategy
- **Primary Mechanism**: Hardware-backed encrypted storage via `FlutterSecureStorage` (iOS Keychain / Android Keystore) under the key `'jwt_token'` ([storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart)).
- **Fallback Mechanism**: Plaintext fallback to `SharedPreferences` is restricted strictly to `kDebugMode`. In release builds, if `FlutterSecureStorage` throws an exception, it is rethrown or returns `null` (treating the user as logged out).
- **Token Injection**: The `ApiClient` interceptor reads `'jwt_token'` from storage on every HTTP request and attaches `Authorization: Bearer <token>`.
- **WebSocket Auth**: [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart) supplies the JWT in the Socket.IO handshake auth dictionary: `auth: {'token': token}`.

### Token Invalidation & Logout
- **Client-Side Logout**: [AuthNotifier.logout()](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart) purges `'jwt_token'`, `'user_id'`, and `'user_email'` from `FlutterSecureStorage` and `SharedPreferences`.
- **Server-Side Token Revocation**: The `User` database model includes a `tokenVersion` counter (`@default(0)`). When a user changes their password, requests account deletion, or is banned by an admin, `tokenVersion` is incremented. The JWT middleware immediately rejects previous tokens even if their lifetime has not elapsed.
- **Granular Error Interception (`shouldForceLogout`)**:
  - Only HTTP 401 on non-`/auth/` paths or HTTP 403 with `ACCOUNT_BANNED` purges tokens and triggers `AuthEvent.loggedOut`.
  - HTTP 403 `EMAIL_NOT_VERIFIED` broadcasts `AuthEvent.emailNotVerified`.
  - HTTP 403 `AGE_REQUIRED` broadcasts `AuthEvent.ageRequired`.
  - Credential errors or wrong OTP on `/auth/*` endpoints do not log the user out or wipe pending state.

---

## 2. Device Permissions Matrix

| Platform | Permission Identifier | Declaration Location | Actual Usage in Code | User Prompt Rationale | Security / Privacy Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Android** | `android.permission.INTERNET` | [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L2) | Required for all HTTP and WebSocket network traffic. | Implicit (Normal permission). | Safe and mandatory. |
| **Android** | Camera & Gallery | Implicit via `image_picker` (System Photo Picker intent) | Mandatory 2-photo signup upload, profile photo grid, journal photo attachment. | System photo picker sheet. | Compliant on Android 13+ (no broad storage permission needed). |
| **Android** | Cleartext Traffic | [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/debug/AndroidManifest.xml) | Disabled in main manifest; enabled only in debug flavor override. | Development local testing (`10.0.2.2`). | Enforced HTTPS in release builds. |
| **Android** | Telephone Dialing | Implicit via `url_launcher` | Dialing crisis numbers (`14416`, `112`) on SOS screen. | Opens system dialer with prefilled number. | Safe (does not call without user confirmation). |
| **iOS** | `NSCameraUsageDescription` | [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) | Invoked by `image_picker` for photo capture. | "Wehere uses the camera so you can take profile photos." | Compliant. |
| **iOS** | `NSPhotoLibraryUsageDescription` | [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) | Invoked by `image_picker` for photo selection. | "Wehere needs access to your photos so you can choose profile pictures." | Compliant. |
| **iOS** | `NSAppTransportSecurity` | [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) | `NSAllowsLocalNetworking = true`; `NSAllowsArbitraryLoads` removed. | Local development networking. | Enforced HTTPS in production. |
| **Both** | Location Permission | **None requested** | Uses structured dropdown menus ([IndianLocations](file:///e:/Websites/Wehere/lib/core/constants/indian_locations.dart)). | Avoids intrusive GPS background tracking. | Privacy-enhancing design decision. |
| **Both** | Push Notifications | In-app alerts | In-app notification polling used instead of native background daemon. | Privacy-first polling. | Safe. |

---

## 3. Environment Variables & Secret Ingestion

All secrets and environment variables are referenced by variable name only:

### Flutter Mobile App
- `API_URL`: Defined at compile time via `--dart-define=API_URL=https://...` ([app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart)).
  - Startup Guard in `main.dart`: In release builds (`kReleaseMode`), throws `StateError` if `API_URL` does not begin with `https://`.
  - Debug fallbacks: `http://10.0.2.2:4000/api` on Android, `http://localhost:4000/api` elsewhere.
  - Socket URL: Derived dynamically from `apiBaseUrl` by stripping `/api` (scheme determines `ws` vs `wss`).

### Node.js Backend (`backend/.env`)
- `PORT`: HTTP and WebSocket listening port (default: `4000`).
- `DATABASE_URL`: PostgreSQL connection string with authentication credentials.
- `JWT_SECRET`: High-entropy symmetric secret key used to sign and verify user JWTs.
- `INTERNAL_API_KEY`: High-entropy secret key required by `adminGuard` for administrative operations.
- `FRONTEND_URL` / `ADMIN_URL`: CORS allowed origin domains.
- `TRUST_PROXY_HOPS`: Integer setting for Express `trust proxy` behind Nginx load balancers (default: `1` in production).
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`: Mail credentials for OTP delivery.

### Next.js Admin Panel (`admin-panel/.env.local`)
- `API_URL`: Backend base URL used by server-side React components (default: `http://localhost:4000`).
- `INTERNAL_API_KEY`: Shared secret key passed in `x-api-key` header to authenticate admin queries. Never exposed to client components.

---

## 4. Security Audit & Remediation Status

### Hardened Vulnerabilities (Phase 1 Completed)

#### 1. Insecure Cleartext HTTP Traffic across Public Internet
- **Previous Status**: Production used hardcoded raw IP `http://200.97.165.22:4000/api` with cleartext allowances.
- **Resolution**:
  - Hardcoded IP completely removed from mobile client and backend.
  - Base URL centralized in `AppConstants.apiBaseUrl` using compile-time `API_URL`.
  - Release startup guard added in `main.dart` rejecting non-HTTPS URLs.
  - `android:usesCleartextTraffic="true"` removed from main `AndroidManifest.xml` and isolated into `debug/AndroidManifest.xml`.
  - iOS `NSAllowsArbitraryLoads` removed; `NSAllowsLocalNetworking = true` added.
  - Step-by-step Nginx + Let's Encrypt (certbot) setup documented in `docs/ops/HTTPS_SETUP.md`.

#### 2. SharedPreferences Fallback Plaintext Exposure
- **Previous Status**: When `FlutterSecureStorage` threw exceptions, JWT was written to plaintext `SharedPreferences`.
- **Resolution**: Fallback in `StorageHelper` is strictly gated to `kDebugMode`. In release builds, exceptions fail securely and return `null`, preventing disk exfiltration on rooted/jailbroken devices.

#### 3. Anonymous Login Bypass
- **Previous Status**: `POST /api/auth/anonymous` permitted unverified anonymous sessions to bypass email checks.
- **Resolution**: Route deleted; `requireVerified` enforces `emailVerified === true` without exception. `isAnonymous` is strictly a profile alias display setting.

#### 4. Missing Rate Limiting and OTP Lockout
- **Previous Status**: No attempt lockout on OTP verification; endpoints vulnerable to brute force.
- **Resolution**: Added `backend/src/middleware/rateLimits.js` with rate limiters across signup, OTP request/verify, login, password reset, user reports, and community posts. Added 5-attempt lockout on OTP verification.

#### 5. Unauthenticated Admin Panel & Unrestricted Endpoints
- **Previous Status**: Admin routes lacked user authentication, rate limiting, and safe user data projection.
- **Resolution**: Added `adminGuard` with timing-safe API key comparison, Bearer token verification, and ADMIN role check. Added `POST /api/admin/login` (12h JWT). Next.js admin panel now requires `/login` with an `httpOnly` secure cookie. Explicit Prisma `safeUserSelect` excludes passwords and tokens.

### Outstanding Tasks (Subsequent Phases)
- **Token Refresh Rotation**: Phase 2 introduces short-lived access tokens (60m) paired with rotating refresh tokens (`RefreshToken` table).
- **Encrypted Journals at Rest**: Phase 7 introduces AES-256-GCM encryption for journal content.

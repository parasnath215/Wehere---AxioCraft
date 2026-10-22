# Authentication & Security Architecture: Wehere

## 1. Authentication Lifecycle & Session Management

### Session Flow & Token Issuance
1. **Registration Handshake (`/api/auth/signup`)**:
   - Protected by `signupLimiter` (20 requests per hour per IP) via [backend/src/middleware/rateLimits.js](file:///e:/Websites/Wehere/backend/src/middleware/rateLimits.js).
   - During registration, the user submits credentials and photos (minimum 2 photos).
   - The backend does **not** create a database `User`. Instead, it stores pending registration data in `PendingSignup` (including hashed password, image URLs, bcrypt OTP hash, and 10-minute expiry) and returns a minimal `signupToken` containing ONLY `{ purpose: 'pending_signup', pendingId }` with a 15-minute expiration. Hashes and images are never placed in JWTs.
   - A 6-digit numeric OTP is generated (or `123456` if `TEST_OTP_ENABLED === 'true' && NODE_ENV !== 'production'`) and emailed to the user ([backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js)). In production, test OTP is strictly prohibited; if enabled, the server terminates at startup.
2. **OTP Verification Handshake (`/api/auth/otp/verify`)**:
   - Protected by `otpVerifyLimiter` (60 per 15 min per IP).
   - User inputs the 6-digit PIN with either `signupToken` or authentication header.
   - **Pending Signup Creation**: If verifying a pending signup, the code is checked via `bcrypt.compare`. If expired or attempts >= 5, the pending row and uploaded images are deleted. On valid code, the `User` is created and `PendingSignup` row is deleted within a single database transaction.
   - **Brute-Force Lockout**: On every failed OTP verification attempt, attempts counter is incremented. When `attempts >= 5`, the OTP record or pending signup is invalidated and the server responds with HTTP 400 `{ error: 'VALIDATION_ERROR', message: 'Code expired. Request a new one.' }`.
   - Upon verification, the server returns a production session JWT signed with `JWT_SECRET` containing `{ id: user.id, role: user.role, tokenVersion: user.tokenVersion }` with a **7-day expiration**.
3. **Login Handshake (`/api/auth/login`)**:
   - Rate-limited via `loginLimiter` (key = `ip + ':' + lowercase(email)`, 10 per 15 min, with loose 100 per 15 min IP cap).
   - Identifies users by normalised **EMAIL ONLY** (`email.trim().toLowerCase()`).
   - If credentials do not match, returns HTTP 401 `{ error: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' }`.
   - If user is banned (`user.isBanned`), returns HTTP 403 `{ error: 'ACCOUNT_BANNED', message: 'This account has been suspended.' }`.
   - If the account has `emailVerified: false`, the OTP is stored using `bcrypt.hash(code, 10)` and the server returns HTTP 403 `{ error: 'EMAIL_NOT_VERIFIED' }` with a 15-minute verification token `{ id, purpose: 'verify_email' }`.
   - `authenticateToken` strictly rejects any token carrying a `purpose` claim with HTTP 401 `{ error: 'TOKEN_INVALID' }`.
4. **OTP Resend / Request (`/api/auth/otp/request`)**:
   - Accepts normalised email or `signupToken`/`verify_email` token.
   - Always responds with `{ success: true, message: 'If the account exists, a code was sent to the registered email.', cooldown: 60 }`. It **never** returns an `email` field to prevent user enumeration.
5. **No Anonymous Bypass & Display-Only Pseudonym**:
   - The legacy `POST /api/auth/anonymous` endpoint has been permanently deleted.
   - `requireVerified` middleware strictly checks `req.user.emailVerified === true`.
   - `User.pseudonym` is display-only: nothing authenticates with it.
6. **18+ Date of Birth Requirement (`requireAdult` & Underage Locking)**:
   - All users must self-declare their date of birth to confirm they are 18 or older.
   - `User.underageBlockedAt DateTime?` tracks underage violations. If `/auth/onboarding` or `/users/me/dob` receives a date indicating age < 18, `underageBlockedAt` is set to `new Date()`, the submitted date is not stored, and HTTP 403 `{ error: 'UNDERAGE' }` is returned.
   - While `underageBlockedAt` is set, both endpoints and `requireAdult` return HTTP 403 `{ error: 'UNDERAGE' }` without parsing dates.
   - `requireAdult` middleware is enforced on `/api/match`, `/api/conversations`, `/api/community`, and Socket.IO handshakes:
     - Missing Date of Birth: HTTP 403 `{ error: 'AGE_REQUIRED' }`. Flutter maps this to `AuthEvent.ageRequired` and redirects to `DobGateScreen`.
     - Underage: HTTP 403 `{ error: 'UNDERAGE' }`.
   - `PUT /api/users/me/dob` has a rate limit of 10 requests/hour per user (`dobLimiter`). Once set, DOB is immutable for users.
7. **Admin Authentication (`adminGuard` & `/api/admin/login`)**:
   - Public endpoint `POST /api/admin/login` protected by `adminLoginLimiter` (5 per 15 min per IP + email). Returns `INVALID_CREDENTIALS` on credential failure. Signs a 12-hour JWT `{ id, tokenVersion, purpose: 'admin' }`.
   - `adminGuard` requires `req.headers['x-api-key'] === process.env.INTERNAL_API_KEY` (timing-safe check), valid token with `decoded.purpose === 'admin'`, and `req.user.role === 'ADMIN'`. Normal user tokens cannot pass even if role is changed.
   - Banning a user (`PUT /api/admin/users/:id/ban`) increments `tokenVersion: { increment: 1 }` and disconnects all live sockets belonging to that user ID via `io.fetchSockets()`.
   - Admin router rate-limited to 120 requests/minute per IP (`adminApiLimiter`).

### Token Storage Strategy
- **Primary Mechanism**: Hardware-backed encrypted storage via `FlutterSecureStorage` (iOS Keychain / Android Keystore) under the key `'jwt_token'` ([storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart)).
- **Fallback Mechanism**: Plaintext fallback to `SharedPreferences` is restricted strictly to `kDebugMode`. In release builds, if `FlutterSecureStorage` throws an exception, it is rethrown or returns `null` (treating the user as logged out).
- **Legacy Cleanup**: On app launch before `runApp`, legacy keys `user_age` and `user_dob` are purged from both `FlutterSecureStorage` and `SharedPreferences`.
- **Token Injection**: The `ApiClient` interceptor reads `'jwt_token'` from storage on every HTTP request and attaches `Authorization: Bearer <token>`.
- **WebSocket Auth**: [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart) supplies the JWT in the Socket.IO handshake auth dictionary: `auth: {'token': token}`. Sockets check `user.isBanned` and reject banned users with `ACCOUNT_BANNED`.

### Token Invalidation & Logout
- **Client-Side Logout**: [AuthNotifier.logout()](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart) purges `'jwt_token'`, `'user_id'`, and `'user_email'` from `FlutterSecureStorage` and `SharedPreferences`.
- **Server-Side Token Revocation**: The `User` database model includes a `tokenVersion` counter (`@default(0)`). When a user changes their password, requests account deletion, or is banned by an admin, `tokenVersion` is incremented. The JWT middleware immediately rejects previous tokens even if their lifetime has not elapsed.
- **Granular Error Interception (`shouldForceLogout`)**:
  - Pure function `shouldForceLogout(status, path, code)` returns `true` only when:
    `(status == 401 && (code == 'TOKEN_INVALID' || code == 'TOKEN_EXPIRED')) || (status == 403 && code == 'ACCOUNT_BANNED')`.
  - The legacy `/auth/` path exclusion rule has been removed, ensuring revoked tokens on `/auth/onboarding` and `/auth/change-password` properly force logout.
  - HTTP 403 `EMAIL_NOT_VERIFIED` broadcasts `AuthEvent.emailNotVerified`.
  - HTTP 403 `AGE_REQUIRED` broadcasts `AuthEvent.ageRequired`.
  - Credential errors (401 `INVALID_CREDENTIALS`) on `/auth/login` do not log the user out or clear state; the login screen renders the server error message.

---

## 2. Device Permissions Matrix

| Platform | Permission Identifier | Declaration Location | Actual Usage in Code | User Prompt Rationale | Security / Privacy Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Android** | `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` | `AndroidManifest.xml` | Photo selection via `image_picker` for onboarding & profile photos | "Allow Wehere to access photos to select profile pictures" | Minimal scope, image-only |
| **Android** | `CAMERA` | `AndroidManifest.xml` | Camera capture via `image_picker` | "Allow Wehere to take profile pictures" | Runtime prompt |
| **iOS** | `NSPhotoLibraryUsageDescription` | `Info.plist` | Photo selection via `image_picker` | "Wehere needs access to your photos to upload profile pictures." | Compliant description |
| **iOS** | `NSCameraUsageDescription` | `Info.plist` | Camera capture | "Wehere needs access to your camera to take profile pictures." | Compliant description |
| **Android** | `CALL_PHONE` | `AndroidManifest.xml` | Immediate one-tap dialing on SOS emergency help screen | "Wehere needs permission to dial emergency hotlines directly in crisis situations." | High-risk; isolated to SOS module |

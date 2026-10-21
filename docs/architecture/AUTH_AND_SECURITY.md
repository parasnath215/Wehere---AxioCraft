# Authentication & Security Architecture: Wehere

## 1. Authentication Lifecycle & Session Management

### Session Flow & Token Issuance
1. **Registration Handshake (`/api/auth/signup`)**:
   - During registration, the user submits credentials and photos.
   - The backend does **not** issue a full session JWT. Instead, it creates an unverified account (`emailVerified: false`) and returns a temporary `signupToken` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L201)).
   - A 6-digit numeric OTP is generated, hashed with bcrypt, and emailed to the user with a 10-minute expiry window ([backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js#L140)).
2. **OTP Verification Handshake (`/api/auth/otp/verify`)**:
   - User inputs the 6-digit PIN.
   - Upon verification, the user's `emailVerified` flag is set to `true`, and the server returns a production session JWT signed with `JWT_SECRET` containing `{ id: user.id, tokenVersion: user.tokenVersion }` with a 30-day expiration ([backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js#L465)).
3. **Login Handshake (`/api/auth/login`)**:
   - Rate-limited to 10 attempts per 15 minutes per IP address.
   - If the account has `emailVerified: false`, the server responds with HTTP 403 Forbidden and `{ error: 'EMAIL_NOT_VERIFIED' }`. The app intercepts this and transitions `AuthStatus` to `unverified` to prompt for OTP entry.

### Token Storage Strategy
- **Primary Mechanism**: Hardware-backed encrypted storage via `FlutterSecureStorage` (iOS Keychain / Android Keystore) under the key `'jwt_token'` ([storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L6)).
- **Fallback Mechanism**: If `FlutterSecureStorage` throws a `PlatformException` (a common failure mode on unsigned iOS Simulators), the helper falls back to saving the token in plaintext inside `SharedPreferences` ([storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L13)).
- **Token Injection**: The `ApiClient` interceptor reads `'jwt_token'` from storage on every HTTP request and attaches `Authorization: Bearer <token>`.
- **WebSocket Auth**: [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L998) supplies the JWT in the Socket.IO handshake auth dictionary: `auth: {'token': token}`.

### Token Invalidation & Logout
- **Client-Side Logout**: [AuthNotifier.logout()](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L338) purges `'jwt_token'`, `'user_id'`, `'user_email'`, `'user_age'`, and `'user_dob'` from both `FlutterSecureStorage` and `SharedPreferences`.
- **Server-Side Token Revocation**: The `User` database model includes a `tokenVersion` counter (`@default(0)`). When a user changes their password, requests account deletion, or is banned by an admin, `tokenVersion` is incremented. The JWT middleware immediately rejects previous tokens even if their 30-day lifetime has not elapsed ([backend/src/middleware/auth.js](file:///e:/Websites/Wehere/backend/src/middleware/auth.js#L26)).
- **Automatic Expiry Interception**: If any API endpoint returns HTTP 401 or HTTP 403 (unauthorized/invalid token), the interceptor in [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L32) deletes `'jwt_token'` and broadcasts `AuthEvent.loggedOut`, forcing an immediate redirect to `LoginScreen`.

---

## 2. Device Permissions Matrix

| Platform | Permission Identifier | Declaration Location | Actual Usage in Code | User Prompt Rationale | Security / Privacy Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Android** | `android.permission.INTERNET` | [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L2) | Required for all HTTP and WebSocket network traffic. | Implicit (Normal permission). | Safe and mandatory. |
| **Android** | Camera & Gallery | Implicit via `image_picker` (System Photo Picker intent) | Mandatory 2-photo signup upload, profile photo grid, journal photo attachment. | System photo picker sheet. | Compliant on Android 13+ (no broad storage permission needed). |
| **Android** | Telephone Dialing | Implicit via `url_launcher` | Dialing crisis numbers (`14416`, `112`) on SOS screen. | Opens system dialer with prefilled number. | Safe (does not call without user confirmation). |
| **iOS** | `NSCameraUsageDescription` | **MISSING in Info.plist** | Invoked by `image_picker` for photo capture. | Will crash or be rejected during App Store review. | **CRITICAL DEFECT**: Must be added to [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist). |
| **iOS** | `NSPhotoLibraryUsageDescription` | **MISSING in Info.plist** | Invoked by `image_picker` for photo selection. | Will crash or be rejected during App Store review. | **CRITICAL DEFECT**: Must be added to [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist). |
| **iOS** | `NSMicrophoneUsageDescription` | **MISSING in Info.plist** | Chat screen allows voice notes (`sendVoiceNote`). | Will crash when audio capture is engaged. | **CRITICAL DEFECT**: Must be added if native mic capture is wired. |
| **Both** | Location Permission | **None requested** | Uses structured dropdown menus ([IndianLocations](file:///e:/Websites/Wehere/lib/core/constants/indian_locations.dart)). | Avoids intrusive GPS background tracking. | Privacy-enhancing design decision. |
| **Both** | Push Notifications | UI simulation only | Push notification toggles in onboarding. | Native FCM/APNs permission request is not yet implemented. | In-app notification polling used instead. |

---

## 3. Environment Variables & Secret Ingestion

All secrets and environment variables are referenced by variable name only:

### Flutter Mobile App
- `API_URL`: Defined at compile time via `--dart-define=API_URL=...` ([app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart#L2), [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L15)).
  - Fallback default: `http://200.97.165.22:4000/api`.

### Node.js Backend (`backend/.env`)
- `PORT`: HTTP and WebSocket listening port (default: `4000`).
- `DATABASE_URL`: PostgreSQL connection string with authentication credentials.
- `JWT_SECRET`: High-entropy symmetric secret key used to sign and verify user JWTs.
- `FRONTEND_URL` / `ADMIN_URL`: CORS allowed origin domains.
- `TRUST_PROXY_HOPS`: Integer setting for Express `trust proxy` behind Nginx load balancers.
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`: Mail credentials for OTP delivery.
- `INTERNAL_API_KEY`: Shared secret header (`x-api-key`) protecting `/api/admin` routes from unauthorized access by third parties.

### Next.js Admin Panel (`admin-panel/.env.local`)
- `API_URL`: Backend base URL used by server-side React components (default: `http://backend:4000`).
- `INTERNAL_API_KEY`: API key passed in `x-api-key` header to authenticate admin queries.

---

## 4. Security Audit & Risk Evaluation

### Critical Vulnerabilities & High Risks

#### 1. Insecure Cleartext HTTP Traffic across Public Internet
- **Evidence**:
  - `android:usesCleartextTraffic="true"` in [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L6).
  - `NSAllowsArbitraryLoads: true` in [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L44).
  - Production base URL is raw unencrypted HTTP: `http://200.97.165.22:4000/api` ([app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart#L2)).
- **Impact**: **HIGH**. Passwords, OTP codes, sensitive mental wellness reflections, and personal photos are transmitted unencrypted over public Wi-Fi networks and cellular carriers. An attacker on the same network can intercept JWT tokens and user data via packet sniffing.
- **Remediation**: Obtain an SSL/TLS certificate (e.g. Let's Encrypt), configure HTTPS/WSS on the backend Nginx proxy, update `apiBaseUrl` to `https://...`, and remove cleartext allowances.

#### 2. SharedPreferences Fallback Exposes JWT in Plaintext
- **Evidence**:
  - [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L24) catches `PlatformException` from `FlutterSecureStorage` and writes `jwt_token` directly to `SharedPreferences`.
- **Impact**: **MEDIUM-HIGH**. On rooted Android devices or jailbroken iOS devices, `SharedPreferences` files are stored in unencrypted XML/plist files on disk, making token exfiltration trivial.
- **Remediation**: Restrict the fallback to debug builds only (`if (kDebugMode)`), or implement client-side encryption using AES before persisting to `SharedPreferences`.

#### 3. Missing Token Refresh Mechanism (Indefinite Replay Window)
- **Evidence**:
  - JWT tokens are issued with a 30-day expiration window (`expiresIn: '30d'`).
  - There is no sliding refresh token architecture (`/api/auth/refresh`).
- **Impact**: **MEDIUM**. If a user's device is compromised, an attacker has a 30-day window of access unless `tokenVersion` is manually bumped.
- **Remediation**: Transition to short-lived access tokens (15–60 minutes) paired with an HTTP-only secure refresh token stored in `FlutterSecureStorage`.

#### 4. Missing Rate Limiting on Internal Admin Endpoints
- **Evidence**:
  - In [backend/src/routes/admin.js](file:///e:/Websites/Wehere/backend/src/routes/admin.js), admin endpoints rely on `INTERNAL_API_KEY` header verification or direct database access without IP-based rate limiting or MFA.
- **Impact**: **MEDIUM**. Brute-force guessing of the admin API key could allow an attacker to dump user analytics, ban users, or trigger account purges.
- **Remediation**: Apply strict rate limiting (`express-rate-limit`) to `/api/admin` routes and enforce IP allowlisting.

#### 5. Local Hardcoded File Path in Production Widget
- **Evidence**:
  - [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L222):
    ```dart
    Image.file(File('C:/Users/paras/.gemini/antigravity-ide/brain/c9c48a6d-ac50-45a1-a810-711e54db919d/premium_wellness_hero_1790365307319.jpg'))
    ```
- **Impact**: **LOW (Functional Crash / Cosmetic Failure)**. On any external device, this file will not exist, resulting in broken asset errors.
- **Remediation**: Replace with a bundled asset path in `pubspec.yaml` (e.g. `assets/images/premium_wellness_hero.jpg`).

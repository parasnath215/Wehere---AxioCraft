# Wehere Authentication & Account Lifecycle Architecture

This technical specification provides an end-to-end reference for all authentication, registration, social login, account creation, age gating, and administrative access mechanisms in the Wehere platform.

---

## 1. High-Level System Architecture & Flow Tree

The following diagram illustrates the complete routing and decision tree for users interacting with the authentication system:

```mermaid
graph TD
    A[App Launch / Splash Screen] --> B{Authenticated?}
    B -- Yes --> C{Needs DOB Gate?}
    C -- Yes --> D[DobGateScreen /auth/dob-gate]
    C -- No --> E{Onboarding Completed?}
    E -- Yes --> F[Main App Shell /main]
    E -- No --> G[Onboarding Wizard /onboarding/wizard]
    
    B -- No --> H[LoginScreen /auth/login]

    %% Login Screen Options
    H --> I[Input Email & Password]
    H --> J[Continue with Google]
    H --> K[Continue with Apple]
    H --> L[Navigate to Sign Up Screen]
    H --> M[Forgot Password Flow]

    %% Standard Email Login
    I --> N{POST /api/auth/login}
    N -- Invalid Credentials --> H
    N -- Banned User --> O[Show Banned Dialog / Logout]
    N -- Email Unverified --> P[Redirect to OtpScreen /auth/otp]
    N -- Success 200 --> C

    %% Google Flow (Login Screen)
    J --> Q[Google SDK signIn]
    Q --> R{POST /api/auth/google/check}
    R -- Exists: True --> S[POST /api/auth/google]
    S --> C
    R -- Exists: False --> T[Auto-fill Google Data & Forward to SignUpScreen]

    %% Sign Up Screen Flow
    L --> U[SignUpScreen /auth/signup]
    T --> U
    U --> V{Google Verified?}
    
    %% Path 1: Standard Sign Up
    V -- No --> W[Fill Name, Email, Password, Phone, 2+ Photos]
    W --> X[POST /api/auth/signup]
    X --> Y[Created PendingSignup in DB + Send 6-Digit Email OTP]
    Y --> Z[OtpVerificationScreen /auth/otp]
    Z --> AA{POST /api/auth/otp/verify}
    AA -- Success --> AB[Convert Pending to Verified User + Issue 7d JWT]
    AB --> G

    %% Path 2: Google Verified Sign Up
    V -- Yes --> AC[Auto-filled Name, Email locked, Avatar downloaded]
    AC --> AD[User adds 2nd Photo, Password, Phone, Terms]
    AD --> AE[POST /api/auth/register-google]
    AE --> AF[Verify Google ID Token + Create Verified User + Issue 7d JWT]
    AF -- Skip OTP Completely --> C
```

---

## 2. Core Security & Authentication Principles

1. **Stateless JWT Tokens**:
   - User sessions are governed by 7-day HMAC-SHA256 JWT tokens containing `{ id, role, tokenVersion }`.
   - Admin sessions use separate 12-hour tokens tagged with `{ id, tokenVersion, purpose: 'admin' }`.
   - Revocation is instantaneous across all active devices via atomic increments to `user.tokenVersion`.
2. **Zero Plaintext Passwords**:
   - Passwords must meet strict entropy requirements (minimum 8 characters, at least 1 uppercase letter, 1 lowercase letter, and 1 special symbol).
   - All passwords are encrypted with `bcrypt` (cost factor 10).
3. **Production OTP Hardening**:
   - Production OTPs are strictly cryptographic 6-digit random integers generated using `crypto.randomInt(100000, 1000000)`.
   - Hardcoded test codes (e.g. `123456`) are forbidden in production; any attempt to run with `TEST_OTP_ENABLED=true` in `NODE_ENV=production` immediately triggers a fatal startup crash.
4. **Rate Limiting & Anti-Abuse**:
   - Signup: 15 requests/hour per IP.
   - Login: 10 attempts/15 minutes per IP.
   - OTP Requests: 5 requests/hour per IP with a minimum 60-second cooldown.
   - Admin Login: 5 requests/15 minutes per IP.

---

## 3. Standard Email & Password Registration Flow

### 3.1 Step-by-Step Overview
Standard registration uses a two-stage transactional pattern to ensure that unverified accounts cannot pollute the main user table or claim pseudonyms.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Flutter as Flutter App (SignUpScreen)
    participant API as Backend (/api/auth)
    participant DB as PostgreSQL
    participant Mail as SMTP Service

    User->>Flutter: Enter Name, Email, Password, Phone & 2+ Photos
    Flutter->>API: POST /api/auth/signup (multipart/form-data)
    Note over API: Validates inputs, email format, password complexity, & >=2 images
    API->>API: Generate 6-digit OTP & bcrypt hash
    API->>DB: Upsert PendingSignup (10 min TTL, passwordHash, codeHash, images)
    API->>Mail: sendOtpEmail(email, otpCode, 'verify_email')
    API-->>Flutter: 200 OK { success: true, pendingVerification: true, signupToken }
    Flutter->>User: Route to OtpVerificationScreen (starts 60s countdown)
    User->>Flutter: Enter 6-digit code
    Flutter->>API: POST /api/auth/otp/verify { email, code, signupToken }
    API->>DB: Validate PendingSignup codeHash & expiration
    API->>DB: CREATE User (emailVerified: true) + DELETE PendingSignup
    API-->>Flutter: 200 OK { success: true, token: JWT, user: {...} }
    Flutter->>User: Route to Onboarding Wizard
```

### 3.2 Technical Implementation Details
* **Route**: `POST /api/auth/signup`
* **Form Data**:
  - `email` (string, validated by Zod)
  - `password` (string, validated by `passwordSchema`)
  - `pseudonym` (optional string; if taken, suffixed with random 4-digit integer)
  - `phone` (optional string)
  - `images` (array of `multipart/form-data` files, minimum 2 required)
* **PendingSignup Entity (`prisma/schema.prisma`)**:
  - Stores `email`, `passwordHash`, `codeHash`, `attempts` (locked at 5), and `expiresAt` (10 minutes).
  - Stored temporary photos are automatically cleaned up if a signup is cancelled or renewed.
* **Verification Route**: `POST /api/auth/otp/verify`
  - Validates `bcrypt.compare(code, pending.codeHash)`.
  - Promotes user to persistent `User` record with `role: 'USER'`, `emailVerified: true`, and `emailVerifiedAt: new Date()`.
  - Generates 7-day session token.

---

## 4. Google Social Authentication & Registration

The Google integration supports both seamless login for existing users and instant, OTP-exempt onboarding for new users.

### 4.1 Decision Tree for Google Authentication

```mermaid
flowchart TD
    Start([User clicks 'Continue with Google']) --> SDK[GoogleSignIn.signIn]
    SDK --> Token[Retrieve Google idToken & User Metadata]
    Token --> CheckAPI[POST /api/auth/google/check]
    
    CheckAPI --> UserExists{Account Exists in DB?}
    
    UserExists -- Yes --> DirectLogin[POST /api/auth/google]
    DirectLogin --> IssueJWT[Issue 7-Day Session JWT]
    IssueJWT --> CheckDOB{requiresDob == true?}
    CheckDOB -- Yes --> DobGate[Route to DobGateScreen]
    CheckDOB -- No --> CheckOnboarding{Onboarding complete?}
    CheckOnboarding -- Yes --> MainApp[Route to Main App]
    CheckOnboarding -- No --> Wizard[Route to Onboarding Wizard]

    UserExists -- No --> Prefill[Navigate to SignUpScreen with GoogleUserData]
    Prefill --> AutoFill[Auto-fill Name & Email, Download Avatar into slot 1]
    AutoFill --> LockEmail[Set _isGoogleVerified = true & Lock Email input]
    LockEmail --> UserFillsRemaining[User adds 2nd photo, sets password, optional phone]
    UserFillsRemaining --> SubmitReg[Click 'Create ID & Continue']
    SubmitReg --> RegisterAPI[POST /api/auth/register-google]
    RegisterAPI --> VerifyToken[Server verifies idToken with Google OAuth2Client]
    VerifyToken --> CreateUser[Create User directly: emailVerified: true]
    CreateUser --> DirectSession[Issue 7-Day Session JWT]
    DirectSession --> SkipOTP[Skip OtpVerificationScreen Completely]
    SkipOTP --> DobGate
```

### 4.2 Endpoint Details

#### A. Pre-Check Endpoint: `POST /api/auth/google/check`
* **Purpose**: Determine if the Google account or email is already registered without creating orphaned records.
* **Payload**: `{ idToken: string }`
* **Backend Processing**:
  - Validates `idToken` using `googleClient.verifyIdToken({ audience: [CLIENT_ID] })`.
  - Searches database for matching `googleId` or normalized `email`.
* **Response**:
  ```json
  {
    "success": true,
    "exists": true | false,
    "email": "user@gmail.com",
    "name": "Jane Doe",
    "picture": "https://lh3.googleusercontent.com/..."
  }
  ```

#### B. Direct Social Login: `POST /api/auth/google`
* **Purpose**: Authenticate existing users.
* **Payload**: `{ idToken: string }`
* **Backend Processing**:
  - Verifies token.
  - Checks if user is banned (`isBanned`) or underage-locked (`underageBlockedAt`).
  - Auto-heals legacy accounts: links `googleId` and marks `emailVerified: true`.
  - Calculates daily login streaks (`evaluateStreak`).
  - Returns `requiresDob: !user.dateOfBirth`.

#### C. Google-Verified Registration: `POST /api/auth/register-google`
* **Purpose**: Onboard brand new Google users without requiring email OTP verification.
* **Payload** (`multipart/form-data`):
  - `idToken`: Google JWT
  - `pseudonym`: Chosen or auto-filled display name
  - `password`: Optional or user-entered password (enabling dual login mode)
  - `phone`: Optional phone number
  - `images`: 2 to 6 image files (includes downloaded Google photo + user-provided photos)
* **Execution**:
  - Re-verifies `idToken` server-side against Google's public keys.
  - Ensures at least 2 profile photos are provided.
  - Hashes user password with `bcrypt` (if provided).
  - Directly creates `User` with `emailVerified: true` and `role: 'USER'`.
  - Issues 7-day session token, skipping `PendingSignup` and `OtpRecord` entirely.

---

## 5. Apple Social Authentication Flow

* **Route**: `POST /api/auth/apple`
* **Payload**:
  ```json
  {
    "identityToken": "JWT from Apple Sign-In",
    "appleId": "Apple sub identifier",
    "email": "user@privaterelay.appleid.com",
    "givenName": "Jane",
    "familyName": "Doe"
  }
  ```
* **Processing**:
  - Decodes Apple JWT and verifies subject match.
  - Queries user by `appleId` or `email`.
  - If new user: Provisions verified account with private relay email or real email.
  - If existing user: Associates `appleId`, activates `emailVerified = true`.
  - Evaluates streaks and issues 7-day session token.

---

## 6. Password Reset Lifecycle

The password recovery workflow prevents user enumeration attacks and enforces single-use token invalidation:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Flutter as App / Web
    participant API as /api/auth
    participant Mail as SMTP
    participant DB as Database

    User->>Flutter: Enter Email on Forgot Password Screen
    Flutter->>API: POST /api/auth/otp/request { email, purpose: 'reset_password' }
    API->>API: Always return 200 OK (Prevents user enumeration)
    opt If User Exists
        API->>DB: Store OtpRecord (purpose: 'reset_password', 10m expiry)
        API->>Mail: Send Password Reset Code
    end
    API-->>Flutter: 200 OK { success: true, cooldown: 60 }
    
    User->>Flutter: Enter 6-digit Code
    Flutter->>API: POST /api/auth/otp/verify { email, code, purpose: 'reset_password' }
    API->>DB: Verify codeHash & Mark OtpRecord used
    API-->>Flutter: 200 OK { success: true, resetToken: JWT (15m expiry) }
    
    User->>Flutter: Enter New Password & Confirm Password
    Flutter->>API: POST /api/auth/password/reset { resetToken, newPassword }
    Note over API: Verifies resetToken purpose === 'reset_password'
    API->>DB: Hash new password + Increment tokenVersion
    Note over DB: All prior sessions on all devices are now invalidated
    API-->>Flutter: 200 OK { success: true, message: 'Password reset successful' }
    Flutter->>User: Route to LoginScreen
```

---

## 7. Age Gate & Date of Birth Enforcement (`DobGateScreen`)

Wehere strictly enforces an 18+ age limit. Date of birth is self-declared once and cannot be modified by the user afterwards.

### 7.1 Backend Rules (`PUT /api/users/me/dob`)
1. **Underage Check**:
   - If user's age $< 18$:
     - Immediately writes `underageBlockedAt: new Date()` to the database.
     - Leaves `dateOfBirth: null` to avoid storing minor data.
     - Returns HTTP 403 `UNDERAGE`.
     - App immediately clears credentials and logs the user out.
2. **Idempotency**:
   - If `user.dateOfBirth != null` already:
     - Returns HTTP 200 OK `{ success: true, alreadySet: true, age, message: 'Date of birth is already set.' }`.
     - Prevents UI blocking loops when navigating through authentication gates.
3. **Valid Declaration**:
   - Parses `YYYY-MM-DD`. If age $\ge 18$, stores `dateOfBirth` and returns 200 OK.

### 7.2 Frontend Handling (`lib/screens/auth/dob_gate_screen.dart`)
* The screen checks `auth.needsDob`.
* On submit:
  - Calls `apiClient.put('/users/me/dob', data: { 'dateOfBirth': formatted })`.
  - On 200 OK (or 409 fallback):
    - Sets `auth.setNeedsDob(false)`.
    - Refreshes current user state.
    - If onboarding is completed $\rightarrow$ navigates to `AppRoutes.main`.
    - If onboarding is pending $\rightarrow$ navigates to `AppRoutes.onboarding`.

---

## 8. Admin Panel Authentication

The Admin Panel (`admin-panel/`) uses a separate, elevated authentication pipeline:

```mermaid
flowchart LR
    Browser[Next.js Admin Panel /login] --> ServerAction[loginAction in actions.ts]
    ServerAction --> BackendAPI[POST /api/admin/login]
    
    BackendAPI --> VerifyAdmin{role === 'ADMIN' && emailVerified && !isBanned?}
    VerifyAdmin -- No --> Deny[Return 401 INVALID_CREDENTIALS]
    VerifyAdmin -- Yes --> SignAdminJWT[Sign JWT: purpose: 'admin', 12h expiry]
    
    SignAdminJWT --> SetCookie[Set HTTP-only Cookie: admin_token]
    SetCookie --> Redirect[Redirect to / Dashboard]
    Redirect --> Guard[Middleware & adminGuard validate purpose === 'admin']
```

* **Backend Guard**: `adminGuard` in [backend/src/middleware/auth.js](file:///e:/Websites/Wehere/backend/src/middleware/auth.js) ensures regular user tokens (even valid 7-day tokens) cannot access `/api/admin/*` routes.
* **Session Cookie**: Stored as an HTTP-only, SameSite=Lax cookie valid for 12 hours.

---

## 9. Comprehensive API Endpoint Reference Table

| Method | Endpoint | Protection | Rate Limit | Request Body | Success Response | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Public | 15 / hr | Multipart: `email`, `password`, `pseudonym`, `phone`, `images` (min 2) | `200 OK` `{ success, pendingVerification, signupToken }` | `VALIDATION_ERROR`, `CONFLICT` |
| `POST` | `/api/auth/otp/verify` | Public | 10 / min | `{ email, code, signupToken, purpose }` | `200 OK` `{ success, token, user }` | `INVALID_CODE`, `EXPIRED_CODE`, `MAX_ATTEMPTS` |
| `POST` | `/api/auth/otp/request` | Public | 5 / hr | `{ email, purpose, signupToken }` | `200 OK` `{ success, message, cooldown }` | `RATE_LIMITED` |
| `POST` | `/api/auth/login` | Public | 10 / 15m | `{ email, password }` | `200 OK` `{ success, token, user, requiresDob }` | `INVALID_CREDENTIALS`, `ACCOUNT_BANNED`, `EMAIL_NOT_VERIFIED` |
| `POST` | `/api/auth/google/check` | Public | - | `{ idToken }` | `200 OK` `{ success, exists, email, name, picture }` | `VALIDATION_ERROR`, `INVALID_CREDENTIALS` |
| `POST` | `/api/auth/google` | Public | - | `{ idToken }` | `200 OK` `{ success, token, user, requiresDob }` | `INVALID_CREDENTIALS`, `ACCOUNT_BANNED`, `UNDERAGE` |
| `POST` | `/api/auth/register-google`| Public | 15 / hr | Multipart: `idToken`, `pseudonym`, `password`, `phone`, `images` (min 2) | `200 OK` `{ success, token, user, requiresDob }` | `VALIDATION_ERROR`, `CONFLICT`, `INVALID_CREDENTIALS` |
| `POST` | `/api/auth/apple` | Public | - | `{ identityToken, appleId, email, givenName, familyName }` | `200 OK` `{ success, token, user, requiresDob }` | `VALIDATION_ERROR`, `INVALID_CREDENTIALS` |
| `PUT` | `/api/users/me/dob` | `Bearer JWT` | 10 / hr | `{ dateOfBirth: 'YYYY-MM-DD' }` | `200 OK` `{ success, age, alreadySet, message }` | `VALIDATION_ERROR`, `UNDERAGE` |
| `POST` | `/api/admin/login` | Public | 5 / 15m | `{ email, password }` | `200 OK` `{ success, token }` | `INVALID_CREDENTIALS` |

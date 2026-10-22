# Backend API Reference & Flutter Feature Mapping

The Wehere backend is an Express.js REST and Socket.IO real-time server located in the `backend/` directory. This document catalogs every route, middleware guard, request/response contract, and which Flutter mobile feature or Admin panel view utilizes each endpoint.

---

## 1. Authentication Middleware & Security Guards

All backend routes are guarded by standard middleware declared in [backend/src/middleware/auth.js](file:///e:/Websites/Wehere/backend/src/middleware/auth.js) and [backend/src/middleware/rateLimits.js](file:///e:/Websites/Wehere/backend/src/middleware/rateLimits.js):
- **`authenticateToken(req, res, next)`**: Extracts the `Authorization: Bearer <token>` header, verifies the signature with `JWT_SECRET`, checks `tokenVersion` against the database to enforce revocation, and sets `req.user`. **Rejects any token carrying a `purpose` claim** with HTTP 401 `{ error: 'TOKEN_INVALID' }`. Rejects banned users with HTTP 403 `{ error: 'ACCOUNT_BANNED' }`.
- **`requireVerified(req, res, next)`**: Strictly ensures `req.user.emailVerified === true`. Rejects with HTTP 403 Forbidden `{ error: 'EMAIL_NOT_VERIFIED', message: 'Please verify your email address.' }`. (No anonymous bypass).
- **`requireAdult(req, res, next)`**: Ensures user has verified their date of birth and is at least 18 years old:
  - If `underageBlockedAt != null` or `calcAge(dateOfBirth) < 18`: Rejects with HTTP 403 `{ error: 'UNDERAGE', message: 'You must be at least 18 years old.' }`.
  - If `dateOfBirth == null`: Rejects with HTTP 403 `{ error: 'AGE_REQUIRED', message: 'Date of birth is required.' }`.
  - Applied to `/api/match/*`, `/api/conversations/*`, `/api/community/*`, and Socket.IO handshake.
- **`adminGuard(req, res, next)`**: Protects all `/api/admin/*` endpoints:
  1. Header `x-api-key` matches `INTERNAL_API_KEY` using `crypto.timingSafeEqual` with length checking.
  2. Valid Bearer JWT with `purpose === 'admin'`.
  3. User role equals `ADMIN` and user is not banned.
- **Rate Limiters (`middleware/rateLimits.js`)**:
  - `apiLimiter`: 1200 per 15 min across `/api/*`, keyed by authenticated user ID or normalized client IP.
  - `signupLimiter`: 20 per hour per IP.
  - `otpVerifyLimiter`: 60 per 15 min per IP.
  - `otpRequestLimiter`: 5 per 15 min per IP + 3 per 10 min per email address.
  - `resetPasswordLimiter`: 5 per 15 min per IP.
  - `loginLimiter`: Composite of 100/15m per IP and 10/15m per IP+email.
  - `adminLoginLimiter`: 5 per 15 min per IP+email.
  - `dobLimiter`: 10 per hour per user on `PUT /api/users/me/dob`.
  - `reportLimiter`: 10 per hour per IP.
  - `communityLimiter`: 20 per hour per user.
  - `adminApiLimiter`: 120 per minute per IP.

---

## 2. Exhaustive Backend Endpoints Reference (63 Endpoints)

### A. Authentication & Onboarding Routes (`/api/auth`)
Mounted from [backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body / Form | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Public | `signupLimiter` (20/hr) | Multipart form: `email`, `password`, `pseudonym`, `phone` (opt), `images` (2–6 files) | `200 OK { success, signupToken, message }` (Creates `PendingSignup`) | [SignUpScreen](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart) (Registration) |
| `POST` | `/api/auth/login` | Public | `loginLimiter` (10/15m/acc) | `{ email, password }` (email only) | `200 OK { token, user }` (7-day session token) | [LoginScreen](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart) (Credential Login) |
| `POST` | `/api/auth/otp/request`| Public | `otpRequestLimiter` | `{ email, purpose?, signupToken? }` | `200 OK { success, message, cooldown }` (Never returns email) | [LoginScreen](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart), [OtpVerificationScreen](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) |
| `POST` | `/api/auth/otp/verify` | Public (or `signupToken`) | `otpVerifyLimiter` (60/15m, 5-attempt lockout) | `{ otp, signupToken? }` | `200/201 OK { success, token, user }` (7-day session token) | [OtpVerificationScreen](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) (Email Verification) |
| `POST` | `/api/auth/reset-password`| Public | `resetPasswordLimiter` (5/15m) | `{ email, otp, newPassword }` | `200 OK { success, message }` | [ResetPasswordScreen](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart) (Password Recovery) |
| `PUT` | `/api/auth/onboarding` | `authenticateToken`, `requireVerified` | Standard | `{ name, displayName, realFirstName, handle, nameDisplayPreference, location, profession, interests, feelings, supportTypes, isAnonymous, dateOfBirth? }` | `200 OK { success, user }` | [OnboardingFlowScreen](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart) (Wizard; enforces 18+) |
| `POST` | `/api/auth/change-password`| `authenticateToken`, `requireVerified` | Standard | `{ currentPassword, newPassword }` | `200 OK { success, message }` | [ProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) (Account Settings) |

---

### B. User Profile & Moderation Routes (`/api/users`)
Mounted from [backend/src/routes/users.js](file:///e:/Websites/Wehere/backend/src/routes/users.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body / Form | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/users/me` | `authenticateToken` | Standard | None | `200 OK { id, email, pseudonym, realFirstName, images, interests, age, needsDob, ... }` | `AuthNotifier.initializeSession()`, `AppState.fetchCurrentUser()` |
| `PUT` | `/api/users/me` | `authenticateToken`, `requireVerified` | Standard | `{ bio, pseudonym, location, profession, nameDisplayPreference, isAnonymous }` (rejects `dateOfBirth` / `age`) | `200 OK { success, user }` | [EditProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart) |
| `PUT` | `/api/users/me/dob` | `authenticateToken`, `requireVerified` | `dobLimiter` (10/hr) | `{ dateOfBirth: 'YYYY-MM-DD' }` | `200 OK { success, age, message }` | [DobGateScreen](file:///e:/Websites/Wehere/lib/screens/auth/dob_gate_screen.dart) (Self-declared DOB; 18+ enforced; 409 if already set) |
| `POST` | `/api/users/me/photos`| `authenticateToken`, `requireVerified` | Standard | Multipart: `photo` (Single file) | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `PUT` | `/api/users/me/photos/order`| `authenticateToken`, `requireVerified` | Standard | `{ images: string[] }` | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `DELETE` | `/api/users/me/photos`| `authenticateToken`, `requireVerified` | Standard | `{ url: string }` | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `POST` | `/api/users/:id/block`| `authenticateToken`, `requireVerified` | Standard | None | `200 OK { success: true }` | [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart), Chat Safety Menu |
| `POST` | `/api/users/:id/report`| `authenticateToken`, `requireVerified` | `reportLimiter` (10/hr) | `{ reason, description?, photoUrl? }` | `200 OK { success: true }` | [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart), Chat Safety Menu |
| `DELETE` | `/api/users/me` | `authenticateToken`, `requireVerified` | Standard | None | `200 OK { message, scheduledDeletionDate }` | [ProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) (Schedules deletion in 30 days) |

---

### C. Discovery & Matching Routes (`/api/match`)
Mounted from [backend/src/routes/match.js](file:///e:/Websites/Wehere/backend/src/routes/match.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/match/discover` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK MatchCard[]` | [DiscoverSwipeScreen](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) |
| `POST` | `/api/match/swipe` | `authenticateToken`, `requireVerified`, `requireAdult` | `{ targetUserId, action: 'connect' \| 'pass' }` | `200 OK { isMatch, matchId? }` | [DiscoverSwipeScreen](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) |
| `POST` | `/api/match/super-support` | `authenticateToken`, `requireVerified`, `requireAdult` | `{ targetUserId }` | `200 OK { isMatch: true, matchId }` | [DiscoverSwipeScreen](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) |
| `GET` | `/api/match/status/:targetUserId` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { status: 'none' \| 'pending' \| 'connected' }` | [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart) |

---

### D. Chat & Conversations Routes (`/api/conversations`)
Mounted from [backend/src/routes/conversations.js](file:///e:/Websites/Wehere/backend/src/routes/conversations.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/conversations` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK Conversation[]` | [ChatListScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_list_screen.dart) |
| `GET` | `/api/conversations/:id/messages` | `authenticateToken`, `requireVerified`, `requireAdult` | Query: `limit`, `cursor` | `200 OK Message[]` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/messages` | `authenticateToken`, `requireVerified`, `requireAdult` | `{ content }` | `201 Created Message` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/reveal` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { success: true }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/accept-reveal` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { success: true, isMutuallyRevealed }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/leave` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { success: true }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |

---

### E. Mental Wellness & Journaling Routes (`/api/journal`)
Mounted from [backend/src/routes/journal.js](file:///e:/Websites/Wehere/backend/src/routes/journal.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/journal/create` | `authenticateToken`, `requireVerified` | `{ content, moodScore, category?, isPrivate }` | `201 Created JournalEntry` | [NewJournalScreen](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) |
| `GET` | `/api/journal/history` | `authenticateToken`, `requireVerified` | Query: `month`, `year` | `200 OK JournalEntry[]` | [JournalHomeScreen](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) |
| `GET` | `/api/journal/:id` | `authenticateToken`, `requireVerified` | None | `200 OK JournalEntry` | [JournalHomeScreen](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) |
| `PUT` | `/api/journal/:id` | `authenticateToken`, `requireVerified` | `{ content, moodScore, category? }` | `200 OK JournalEntry` | [NewJournalScreen](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) |
| `DELETE` | `/api/journal/:id` | `authenticateToken`, `requireVerified` | None | `200 OK { success: true }` | [JournalHomeScreen](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) |

---

### F. Crisis Support & SOS Routes (`/api/sos`)
Mounted from [backend/src/routes/sos.js](file:///e:/Websites/Wehere/backend/src/routes/sos.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/sos/contacts` | `authenticateToken`, `requireVerified` | None | `200 OK EmergencyContact[]` | [ManageContactsScreen](file:///e:/Websites/Wehere/lib/screens/sos/manage_contacts_screen.dart) |
| `POST` | `/api/sos/contacts` | `authenticateToken`, `requireVerified` | `{ name, phone, relationship }` | `201 Created EmergencyContact` | [ManageContactsScreen](file:///e:/Websites/Wehere/lib/screens/sos/manage_contacts_screen.dart) |
| `DELETE` | `/api/sos/contacts/:id` | `authenticateToken`, `requireVerified` | None | `200 OK { success: true }` | [ManageContactsScreen](file:///e:/Websites/Wehere/lib/screens/sos/manage_contacts_screen.dart) |
| `POST` | `/api/sos/trigger` | `authenticateToken`, `requireVerified` | `{ latitude?, longitude?, note? }` | `200 OK { success: true, dispatchedTo: number }` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |
| `GET` | `/api/sos/helplines` | Public | Query: `state?` | `200 OK Helpline[]` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |
| `POST` | `/api/sos/helplines` | `adminGuard` | `{ name, number, hours, languages, tags }` | `201 Created Helpline` | Admin Helpline Management |
| `POST` | `/api/sos/track-call` | `authenticateToken` | `{ helplineNumber }` | `200 OK { success: true }` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |

---

### G. Community Feed Routes (`/api/community`)
Mounted from [backend/src/routes/community.js](file:///e:/Websites/Wehere/backend/src/routes/community.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/community/feed` | `authenticateToken`, `requireVerified`, `requireAdult` | Standard | Query: `topic`, `cursor` | `200 OK CommunityPost[]` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community/posts` | `authenticateToken`, `requireVerified`, `requireAdult` | `communityLimiter` (20/hr) | `{ topic, content, isAnonymous }` | `201 Created CommunityPost` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community/posts/:id/like` | `authenticateToken`, `requireVerified`, `requireAdult` | Standard | None | `200 OK { liked: boolean, likesCount }` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `GET` | `/api/community/posts/:id/comments` | `authenticateToken`, `requireVerified`, `requireAdult` | Standard | None | `200 OK Comment[]` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community/posts/:id/comments` | `authenticateToken`, `requireVerified`, `requireAdult` | Standard | `{ content, isAnonymous }` | `201 Created Comment` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |

---

### H. Wellness Goals & Progress Routes (`/api/goals` & `/api/progress`)
Mounted from [backend/src/routes/goals.js](file:///e:/Websites/Wehere/backend/src/routes/goals.js) and [backend/src/routes/progress.js](file:///e:/Websites/Wehere/backend/src/routes/progress.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/goals` | `authenticateToken`, `requireVerified` | None | `200 OK WellnessGoal[]` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `POST` | `/api/goals` | `authenticateToken`, `requireVerified` | `{ title, subtitle?, categoryColor? }` | `201 Created WellnessGoal` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `PUT` | `/api/goals/:id/progress` | `authenticateToken`, `requireVerified` | `{ progress: number }` | `200 OK WellnessGoal` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `DELETE` | `/api/goals/:id` | `authenticateToken`, `requireVerified` | None | `200 OK { success: true }` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `GET` | `/api/progress` | `authenticateToken`, `requireVerified` | None | `200 OK { xp, level, currentStreak, milestones }` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `POST` | `/api/progress/milestones/unlock` | `authenticateToken`, `requireVerified` | `{ milestoneId }` | `200 OK { milestone, xpAwarded }` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |

---

### I. In-App Notifications & Config Routes (`/api/notifications` & `/api/config`)
Mounted from [backend/src/routes/notifications.js](file:///e:/Websites/Wehere/backend/src/routes/notifications.js) and [backend/src/routes/config.js](file:///e:/Websites/Wehere/backend/src/routes/config.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/notifications` | `authenticateToken`, `requireVerified` | None | `200 OK Notification[]` | `AppState.fetchNotifications()`, Top Bar Bell |
| `PUT` | `/api/notifications/:id/read` | `authenticateToken`, `requireVerified` | None | `200 OK { success: true }` | Notification Tap Action |
| `GET` | `/api/config/options` | Public | None | `200 OK { interests, feelings, supportTypes }` | Onboarding Flow, Profile Editor |

---

### J. Admin Panel Routes (`/api/admin`)
Mounted from [backend/src/routes/admin.js](file:///e:/Websites/Wehere/backend/src/routes/admin.js). Consumed exclusively by `admin-panel/`. Rate-limited to 120 req/min via `adminApiLimiter`.

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Admin View) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/admin/login` | Public (`adminLoginLimiter`) | `{ email, password }` | `200 OK { token }` (12-hour expiry, `purpose: 'admin'`) | [Admin Login Page](file:///e:/Websites/Wehere/admin-panel/src/app/login/page.tsx) |
| `GET` | `/api/admin/stats` | `adminGuard` | None | `{ totalUsers, activeMatches, totalMessages, reportedUsers, recentUsers }` | [Overview Dashboard](file:///e:/Websites/Wehere/admin-panel/src/app/page.tsx) |
| `GET` | `/api/admin/users` | `adminGuard` | Query: `page`, `limit` | `{ users: User[], total, pages }` (`safeUserSelect`) | Admin Users Table |
| `POST` | `/api/admin/users` | `adminGuard` | `{ email, password, pseudonym, role }` | `201 Created User` | Admin User Creator |
| `PUT` | `/api/admin/users/:id` | `adminGuard` | `{ role?, pseudonym?, email?, scheduledDeletionDate? }` | `200 OK User` | Admin User Editor |
| `PUT` | `/api/admin/users/:id/ban` | `adminGuard` | `{ isBanned: boolean }` | `200 OK { id, pseudonym, isBanned }` (increments `tokenVersion` & disconnects sockets) | User Moderation Action |
| `DELETE` | `/api/admin/users/:id` | `adminGuard` | None | `200 OK { message: "User deleted" }` | Hard Deletion |
| `GET` | `/api/admin/users/:id/analytics` | `adminGuard` | None | `{ user, stats: { totalMatches, activeMatches, messagesSent, journalsWritten } }` | User Analytics Detail |
| `GET` | `/api/admin/matches` | `adminGuard` | Query: `page`, `limit` | `200 OK Match[]` | Matches Audit Table |
| `GET` | `/api/admin/reports` | `adminGuard` | None | `200 OK Report[]` with reporter & reported details | Moderation Queue |

---

### K. Health & Diagnostics (`/health`)
Mounted in [backend/src/server.js](file:///e:/Websites/Wehere/backend/src/server.js).

| Method | Endpoint | Auth Required | Response Payload | Consumed By |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/health` | Public | `200 OK { status: 'OK', database: 'Connected' }` | Docker compose healthcheck & uptime probes |

---

## 3. Real-Time WebSocket Server Architecture

Mounted in [backend/src/server.js](file:///e:/Websites/Wehere/backend/src/server.js) using `socket.io`.

### Handshake & Authentication
Every incoming WebSocket connection must supply a valid JWT token in its handshake packet and must pass adulthood and ban verification:
```javascript
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    // Rejects tokens with purpose claim
    // Rejects banned users (ACCOUNT_BANNED)
    // Validates tokenVersion, emailVerified, and dateOfBirth >= 18 (and no underageBlockedAt)
    socket.user = user;
    next();
  });
});
```

### Events Matrix

| Event Name | Direction | Payload Structure | Action & Database Side-Effect |
| :--- | :--- | :--- | :--- |
| `join_conversation` | Client -> Server | `conversationId` (`string`) | Validates that `socket.user.id` is either `userAId` or `userBId` in the match; adds socket to room. |
| `send_message` | Client -> Server | `{ conversationId, content }` | Persists new `Message` in PostgreSQL, awards +10 XP to sender, broadcasts `receive_message` to room. |
| `typing` | Client -> Server | `{ conversationId }` | Emits `user_typing` with `socket.user.id` to the other participant in the room. |
| `request_reveal_identity` | Client -> Server | `{ conversationId }` | Flags `userARevealed` or `userBRevealed` in `Match`. If both revealed: creates celebration system message and emits `identity_revealed`. Otherwise emits `name_reveal_requested`. |
| `receive_message` | Server -> Client | `Message` object | Ingested by `AppState.messages[peerId]`; updates unread counts and UI chat bubble. |
| `user_typing` | Server -> Client | `{ senderId: socket.user.id }` | Sets `AppState._typingStatus[peerId] = true` with auto-reset timer. |
| `identity_revealed` | Server -> Client | `{ conversationId, isMutuallyRevealed, userAFirstName, userBFirstName }` | Updates `peer.isMutuallyRevealed = true` and unlocks real names in chat header. |
| `name_reveal_requested` | Server -> Client | `{ conversationId, requesterId, requesterDisplayName }` | Renders mutual name reveal invitation banner in peer's chat screen. |

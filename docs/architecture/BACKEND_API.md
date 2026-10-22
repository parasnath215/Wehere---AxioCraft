# Backend API Reference & Flutter Feature Mapping

The Wehere backend is an Express.js REST and Socket.IO real-time server located in the `backend/` directory. This document catalogs every route, middleware guard, request/response contract, and which Flutter mobile feature or Admin panel view utilizes each endpoint.

---

## 1. Authentication Middleware & Security Guards

All backend routes are guarded by standard middleware declared in [backend/src/middleware/auth.js](file:///e:/Websites/Wehere/backend/src/middleware/auth.js) and [backend/src/middleware/rateLimits.js](file:///e:/Websites/Wehere/backend/src/middleware/rateLimits.js):
- **`authenticateToken(req, res, next)`**: Extracts the `Authorization: Bearer <token>` header, verifies the signature with `JWT_SECRET`, checks `tokenVersion` against the database to enforce revocation, and sets `req.user`.
- **`requireVerified(req, res, next)`**: Strictly ensures `req.user.emailVerified === true`. Rejects with HTTP 403 Forbidden `{ error: 'EMAIL_NOT_VERIFIED', message: 'Please verify your email address.' }`. (No anonymous bypass).
- **`requireAdult(req, res, next)`**: Ensures user has verified their date of birth and is at least 18 years old:
  - If `dateOfBirth == null`: Rejects with HTTP 403 `{ error: 'AGE_REQUIRED', message: 'Date of birth is required.' }`.
  - If `calcAge(dateOfBirth) < 18`: Rejects with HTTP 403 `{ error: 'UNDERAGE', message: 'You must be at least 18 years old.' }`.
  - Applied to `/api/match/*`, `/api/conversations/*`, `/api/community/*`, and Socket.IO handshake.
- **`adminGuard(req, res, next)`**: Protects all `/api/admin/*` endpoints:
  1. Header `x-api-key` matches `INTERNAL_API_KEY` using `crypto.timingSafeEqual` with length checking.
  2. Valid Bearer JWT (`authenticateToken`).
  3. User role equals `ADMIN` and user is not banned.
- **Rate Limiters (`middleware/rateLimits.js`)**:
  - `signupLimiter`: 5 per hour per IP.
  - `otpVerifyLimiter`: 10 per 15 min per IP.
  - `otpRequestLimiter`: 5 per 15 min per IP, and maximum 3 per 10 min per email address.
  - `resetPasswordLimiter`: 5 per 15 min per IP.
  - `loginLimiter`: 10 per 15 min per IP.
  - `reportLimiter`: 10 per hour per IP.
  - `communityLimiter`: 20 per hour per user.
  - `adminApiLimiter`: 120 per minute per IP.

---

## 2. Exhaustive Backend Endpoints Reference

### A. Authentication & Onboarding Routes (`/api/auth`)
Mounted from [backend/src/routes/auth.js](file:///e:/Websites/Wehere/backend/src/routes/auth.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body / Form | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Public | `signupLimiter` (5/hr) | Multipart form: `email`, `password`, `pseudonym`, `phone` (opt), `images` (2–6 files) | `200 OK { success, signupToken, message }` | [SignUpScreen](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart) (Registration) |
| `POST` | `/api/auth/login` | Public | `loginLimiter` (10/15m) | `{ email, password }` | `200 OK { token, user }` | [LoginScreen](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart) (Credential Login) |
| `POST` | `/api/auth/otp/request`| Public | `otpRequestLimiter` (5/15m IP, 3/10m email) | `{ email, purpose }` (`'verify_email'` or `'reset_password'`) | `200 OK { success, email }` | [LoginScreen](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart), [OtpVerificationScreen](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) |
| `POST` | `/api/auth/otp/verify` | Public (Optionally `signupToken`) | `otpVerifyLimiter` (10/15m, 5-attempt lockout) | `{ otp, signupToken? }` | `200 OK { success, token, user }` | [OtpVerificationScreen](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) (Email Verification) |
| `POST` | `/api/auth/reset-password`| Public | `resetPasswordLimiter` (5/15m) | `{ email, otp, newPassword }` | `200 OK { success, message }` | [ResetPasswordScreen](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart) (Password Recovery) |
| `PUT` | `/api/auth/onboarding` | `authenticateToken`, `requireVerified` | Standard | `{ name, displayName, realFirstName, handle, nameDisplayPreference, location, profession, interests, feelings, supportTypes, isAnonymous, dateOfBirth? }` | `200 OK { success, user }` | [OnboardingFlowScreen](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart) (5-Step Wizard; enforces 18+) |
| `POST` | `/api/auth/change-password`| `authenticateToken`, `requireVerified` | Standard | `{ currentPassword, newPassword }` | `200 OK { success, message }` | [ProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) (Account Settings) |

---

### B. User Profile & Moderation Routes (`/api/users`)
Mounted from [backend/src/routes/users.js](file:///e:/Websites/Wehere/backend/src/routes/users.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body / Form | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/users/me` | `authenticateToken` | Standard | None | `200 OK { id, email, pseudonym, realFirstName, images, interests, age, needsDob, ... }` | `AuthNotifier.initializeSession()`, `AppState.fetchCurrentUser()` |
| `PUT` | `/api/users/me` | `authenticateToken`, `requireVerified` | Standard | `{ bio, pseudonym, location, profession, nameDisplayPreference, isAnonymous }` (rejects `dateOfBirth` / `age`) | `200 OK { success, user }` | [EditProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart) |
| `PUT` | `/api/users/me/dob` | `authenticateToken`, `requireVerified` | Standard | `{ dateOfBirth: 'YYYY-MM-DD' }` | `200 OK { success, age, user }` | [DobGateScreen](file:///e:/Websites/Wehere/lib/screens/auth/dob_gate_screen.dart) (Existing users without DOB; 18+ enforced; 409 if already set) |
| `POST` | `/api/users/me/photos`| `authenticateToken`, `requireVerified` | Standard | Multipart: `photo` (Single file) | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `PUT` | `/api/users/me/photos/order`| `authenticateToken`, `requireVerified` | Standard | `{ images: string[] }` | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `DELETE` | `/api/users/me/photos`| `authenticateToken`, `requireVerified` | Standard | `{ photoUrl: string }` | `200 OK { success, images }` | [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) |
| `POST` | `/api/users/:id/block`| `authenticateToken`, `requireVerified` | Standard | None | `200 OK { success: true }` | [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart), Chat Safety Menu |
| `POST` | `/api/users/:id/report`| `authenticateToken`, `requireVerified` | `reportLimiter` (10/hr) | `{ reason, description?, reportedPhotoUrl? }` | `200 OK { success: true, reportId }` | [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart), Chat Safety Menu |
| `DELETE` | `/api/users/me` | `authenticateToken`, `requireVerified` | Standard | None | `200 OK { message, scheduledDeletionDate }` | [ProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) (Schedules deletion in 7 days) |

---

### C. Discovery & Matching Routes (`/api/match`)
Mounted from [backend/src/routes/match.js](file:///e:/Websites/Wehere/backend/src/routes/match.js).

| Method | Endpoint | Auth Required | Request Body / Query | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/match/discover` | `authenticateToken`, `requireVerified`, `requireAdult` | Query params: `page`, `limit` | `200 OK MatchCard[]` (Computes `age`, filters out null DOB / under 18 and blocked peers) | [DiscoverSwipeScreen](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) |
| `POST` | `/api/match/swipe` | `authenticateToken`, `requireVerified`, `requireAdult` | `{ targetUserId: string, isRight: boolean }` | `200 OK { isMatch: boolean, match?, conversationId? }` | [DiscoverSwipeScreen](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) |

---

### D. Conversations & Identity Disclosure Routes (`/api/conversations`)
Mounted from [backend/src/routes/conversations.js](file:///e:/Websites/Wehere/backend/src/routes/conversations.js).

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/conversations` | `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK Conversation[]` with peer profiles & last message | [ChatListScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_list_screen.dart) |
| `GET` | `/api/conversations/:id/messages`| `authenticateToken`, `requireVerified`, `requireAdult` | Query: `limit`, `before` | `200 OK Message[]` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `GET` | `/api/conversations/:id/disclosure`| `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { isMutuallyRevealed, myRevealed, peerRevealed, peerFirstName }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/reveal-name`| `authenticateToken`, `requireVerified`, `requireAdult` | `{ realFirstName? }` | `200 OK { success, isMutuallyRevealed, userAFirstName, userBFirstName }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |
| `POST` | `/api/conversations/:id/decline-reveal`| `authenticateToken`, `requireVerified`, `requireAdult` | None | `200 OK { success: true }` | [ChatConversationScreen](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) |

---

### E. Private Journaling Routes (`/api/journal`)
Mounted from [backend/src/routes/journal.js](file:///e:/Websites/Wehere/backend/src/routes/journal.js).

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/journal` | `authenticateToken`, `requireVerified` | Query: `page`, `limit` | `200 OK JournalEntry[]` | [JournalHomeScreen](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) |
| `POST` | `/api/journal/create` | `authenticateToken`, `requireVerified` | `{ content, moodScore, category, isPrivate }` | `201 Created JournalEntry` (+20 XP awarded) | [NewJournalScreen](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) |
| `PUT` | `/api/journal/:id` | `authenticateToken`, `requireVerified` | `{ content, moodScore, category, isPrivate }` | `200 OK JournalEntry` | [NewJournalScreen](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) |
| `DELETE` | `/api/journal/:id` | `authenticateToken`, `requireVerified` | None | `200 OK { message: "Journal entry deleted" }` | [JournalHomeScreen](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) |

---

### F. Progress, Mood & Gamification Routes (`/api/progress` & `/api/goals`)
Mounted from [backend/src/routes/progress.js](file:///e:/Websites/Wehere/backend/src/routes/progress.js) and [backend/src/routes/goals.js](file:///e:/Websites/Wehere/backend/src/routes/goals.js).

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/progress` | `authenticateToken`, `requireVerified` | None | `200 OK { currentStreak, weeklyProgress, xp, level }` | [HomeScreen](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart), [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `GET` | `/api/progress/mood/today`| `authenticateToken`, `requireVerified` | None | `200 OK { mood: string }` | [HomeScreen](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart) |
| `POST` | `/api/progress/mood` | `authenticateToken`, `requireVerified` | `{ mood: string }` | `200 OK { success: true, streak: int }` (+15 XP) | [HomeScreen](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart) |
| `GET` | `/api/goals` | `authenticateToken`, `requireVerified` | None | `200 OK WellnessGoal[]` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `POST` | `/api/goals` | `authenticateToken`, `requireVerified` | `{ title, subtitle, categoryColor }` | `201 Created WellnessGoal` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |
| `PUT` | `/api/goals/:id/toggle`| `authenticateToken`, `requireVerified` | None | `200 OK WellnessGoal` (+10 XP) | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |

---

### G. Community Feed Routes (`/api/community`)
Mounted from [backend/src/routes/community.js](file:///e:/Websites/Wehere/backend/src/routes/community.js).

| Method | Endpoint | Auth Required | Rate Limit | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/community` | `authenticateToken`, `requireVerified`, `requireAdult` | Standard | Query: `topic`, `page`, `limit` | `200 OK CommunityPost[]` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community` | `authenticateToken`, `requireVerified`, `requireAdult` | `communityLimiter` (20/hr) | `{ topic, content }` | `201 Created CommunityPost` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community/:id/like`| `authenticateToken`, `requireVerified`, `requireAdult` | Standard | None | `200 OK { success, likesCount }` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `GET` | `/api/community/:id/comments`| `authenticateToken`, `requireVerified`, `requireAdult` | Standard | None | `200 OK Comment[]` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |
| `POST` | `/api/community/:id/comments`| `authenticateToken`, `requireVerified`, `requireAdult` | Standard | `{ commentText }` | `201 Created Comment` | [CommunityScreen](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) |

---

### H. Emergency SOS Routes (`/api/sos`)
Mounted from [backend/src/routes/sos.js](file:///e:/Websites/Wehere/backend/src/routes/sos.js).

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/sos/resources` | Public | None | `200 OK Helpline[]` | Crisis Directory Fallback |
| `GET` | `/api/sos/contacts` | `authenticateToken`, `requireVerified` | None | `200 OK EmergencyContact[]` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |
| `POST` | `/api/sos/contacts` | `authenticateToken`, `requireVerified` | `{ name, phone, relationship }` | `201 Created EmergencyContact` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |
| `DELETE` | `/api/sos/contacts/:id`| `authenticateToken`, `requireVerified` | None | `200 OK { message: "Contact deleted" }` | [SosHelpScreen](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) |

---

### I. In-App Notifications & Configuration
Mounted from [backend/src/routes/notifications.js](file:///e:/Websites/Wehere/backend/src/routes/notifications.js) and [backend/src/routes/config.js](file:///e:/Websites/Wehere/backend/src/routes/config.js).

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Feature / Screen) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/config/options` | Public | None | `{ options: { interests, feelings, supportTypes }, limits: ConfigLimits }` | [OnboardingFlowScreen](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart), [EditProfileScreen](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart) |
| `GET` | `/api/notifications` | `authenticateToken`, `requireVerified` | None | `200 OK Notification[]` | In-app alerts bell |
| `GET` | `/api/notifications/unread`| `authenticateToken`, `requireVerified` | None | `200 OK { unreadCount: int }` | In-app notification badge |
| `PUT` | `/api/notifications/read-all`| `authenticateToken`, `requireVerified` | None | `200 OK { success: true }` | [ProgressDashboardScreen](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) |

---

### J. Admin Panel Routes (`/api/admin`)
Mounted from [backend/src/routes/admin.js](file:///e:/Websites/Wehere/backend/src/routes/admin.js). Consumed exclusively by `admin-panel/`. Entire router rate-limited to 120 req/min via `adminApiLimiter`.

| Method | Endpoint | Auth Required | Request Body | Response Payload | Consumed By (Admin View) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/admin/login` | Public (`loginLimiter`) | `{ email, password }` | `200 OK { token }` (12-hour expiry) | [Admin Login Page](file:///e:/Websites/Wehere/admin-panel/src/app/login/page.tsx) |
| `GET` | `/api/admin/stats` | `adminGuard` | None | `{ totalUsers, activeMatches, totalMessages, reportedUsers, recentUsers }` | [Overview Dashboard](file:///e:/Websites/Wehere/admin-panel/src/app/page.tsx) |
| `GET` | `/api/admin/users` | `adminGuard` | Query: `search`, `page`, `limit` | `{ users: User[], total, pages }` (`safeUserSelect`) | Admin Users Table |
| `POST` | `/api/admin/users` | `adminGuard` | `{ email, password, pseudonym, role }` | `201 Created User` | Admin User Creator |
| `PUT` | `/api/admin/users/:id` | `adminGuard` | `{ role, pseudonym, email, scheduledDeletionDate }` | `200 OK User` | Admin User Editor |
| `PUT` | `/api/admin/users/:id/ban` | `adminGuard` | `{ isBanned: boolean }` | `200 OK { id, pseudonym, isBanned }` (increments `tokenVersion`) | User Moderation Action |
| `DELETE` | `/api/admin/users/:id` | `adminGuard` | None | `200 OK { message: "User deleted" }` | Hard Deletion |
| `GET` | `/api/admin/users/:id/analytics` | `adminGuard` | None | `{ user, stats: { totalMatches, activeMatches, messagesSent, journalsWritten } }` | User Analytics Detail |
| `GET` | `/api/admin/matches` | `adminGuard` | Query: `page`, `limit` | `200 OK Match[]` | Matches Audit Table |
| `GET` | `/api/admin/reports` | `adminGuard` | None | `200 OK Report[]` with reporter & reported details | Moderation Queue |

---

## 3. Real-Time WebSocket Server Architecture

Mounted in [backend/src/server.js](file:///e:/Websites/Wehere/backend/src/server.js) using `socket.io`.

### Handshake & Authentication
Every incoming WebSocket connection must supply a valid JWT token in its handshake packet and must pass adulthood verification:
```javascript
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    // Validates tokenVersion, emailVerified, and dateOfBirth >= 18
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
| `typing` | Client -> Server | `{ conversationId, senderId }` | Emits `user_typing` to the other participant in the room. |
| `request_reveal_identity` | Client -> Server | `{ conversationId }` | Flags `userARevealed` or `userBRevealed` in `Match`. If both revealed: creates celebration system message and emits `identity_revealed`. Otherwise emits `name_reveal_requested`. |
| `receive_message` | Server -> Client | `Message` object | Ingested by `AppState.messages[peerId]`; updates unread counts and UI chat bubble. |
| `user_typing` | Server -> Client | `{ senderId }` | Sets `AppState._typingStatus[peerId] = true` with auto-reset timer. |
| `identity_revealed` | Server -> Client | `{ conversationId, isMutuallyRevealed, userAFirstName, userBFirstName }` | Updates `peer.isMutuallyRevealed = true` and unlocks real names in chat header. |
| `name_reveal_requested` | Server -> Client | `{ conversationId, requesterId, requesterDisplayName }` | Renders mutual name reveal invitation banner in peer's chat screen. |

# PART 3: BACKEND (Node.js) ROUTES
## 1. Route Inventory
| Method | Path | File | Auth? | Role check? | Ownership check? | DB Operations |
|--------|------|------|-------|-------------|------------------|---------------|
| POST | `/auth/register` | `auth.js` | No | No | No | `prisma.user.create` |
| POST | `/auth/login` | `auth.js` | No | No | No | `prisma.user.findUnique` |
| POST | `/auth/verify-otp` | `auth.js` | No | No | No | `prisma.user.update` |
| POST | `/auth/forgot-password` | `auth.js` | No | No | No | None (Fake) |
| GET | `/users/me` | `users.js` | Yes | No | Yes (Token ID) | `prisma.user.findUnique` |
| PUT | `/users/me` | `users.js` | Yes | No | Yes (Token ID) | `prisma.user.update` |
| POST | `/users/:id/block` | `users.js` | Yes | No | No | `prisma.block.create` |
| POST | `/users/:id/report` | `users.js` | Yes | No | No | `prisma.report.create` |
| GET | `/match/profiles` | `match.js` | Yes | No | Yes | `prisma.user.findMany` (excluding swiped/blocked) |
| POST | `/match/swipe` | `match.js` | Yes | No | Yes | `prisma.swipe.upsert`, `prisma.match.create` |
| GET | `/conversations` | `conversations.js` | Yes | No | Yes | `prisma.match.findMany` |
| GET | `/conversations/:id/messages` | `conversations.js` | Yes | No | Yes | `prisma.message.findMany` |
| GET | `/community` | `community.js` | No | No | No | `prisma.communityPost.findMany` |
| POST | `/community` | `community.js` | Yes | No | Yes (Token ID) | `prisma.communityPost.create` |
| POST | `/community/:id/like` | `community.js` | Yes | No | No | `prisma.postLike.upsert` |
| POST | `/community/:id/comments` | `community.js` | Yes | No | No | `prisma.communityComment.create` |
| GET | `/goals` | `goals.js` | Yes | No | Yes | `prisma.wellnessGoal.findMany` |
| POST | `/goals` | `goals.js` | Yes | No | Yes | `prisma.wellnessGoal.create` |
| PUT | `/goals/:id/toggle` | `goals.js` | Yes | No | Yes | `prisma.wellnessGoal.update` |
| GET | `/journal` | `journal.js` | Yes | No | Yes | `prisma.journalEntry.findMany` |
| POST | `/journal` | `journal.js` | Yes | No | Yes | `prisma.journalEntry.create` |
| GET | `/progress` | `progress.js` | Yes | No | Yes | `prisma.user.findUnique` |
| GET | `/sos/contacts` | `sos.js` | Yes | No | Yes | `prisma.emergencyContact.findMany` |
| POST | `/sos/contacts` | `sos.js` | Yes | No | Yes | `prisma.emergencyContact.create` |
| DELETE | `/sos/contacts/:id` | `sos.js` | Yes | No | Yes | `prisma.emergencyContact.delete` |
| GET | `/notifications` | `notifications.js` | Yes | No | Yes | `prisma.notification.findMany` |
| PUT | `/notifications/:id/read` | `notifications.js` | Yes | No | Yes | `prisma.notification.updateMany` |
| PUT | `/notifications/read-all` | `notifications.js` | Yes | No | Yes | `prisma.notification.updateMany` |
| GET | `/admin/stats` | `admin.js` | Yes (Admin) | Yes | N/A | `prisma.user/match/message.count` |
| GET | `/admin/users` | `admin.js` | Yes (Admin) | Yes | N/A | `prisma.user.findMany` |
| PUT | `/admin/users/:id/ban` | `admin.js` | Yes (Admin) | Yes | N/A | `prisma.user.update` |
| GET | `/admin/reports` | `admin.js` | Yes (Admin) | Yes | N/A | `prisma.report.findMany` |
| GET | `/admin/matches` | `admin.js` | Yes (Admin) | Yes | N/A | `prisma.match.findMany` |

## 2. File Uploads (Multer Config)
File: `backend/src/routes/users.js` lines 10-28
- **Allowed Types**: `image/jpeg, image/png, image/webp`
- **Size Limit**: 5MB
- **Location**: Disk storage at `../../public/uploads`
- **Output URL**: `/uploads/{filename}` stored in DB.

## 3. Realtime Chat Socket.io
File: `backend/src/server.js`
- **JWT Verification**: Yes, `io.use()` checks token from `socket.handshake.auth.token`.
- **Rooms**: Yes, users join `room_${matchId}` via `join_conversation` event.
- **Persistence**: Emitting `send_message` triggers `prisma.message.create` and then `io.to(matchId).emit('receive_message')`.

Findings count: 35 | Not found/unverified items: 0

---

# PART 4: FLUTTER FRONTEND
## 1. Screen Inventory
| Screen | Navigation | Data Source | Real / Fake |
|--------|------------|-------------|-------------|
| `login_screen.dart` | `/login` | API | Real |
| `signup_screen.dart` | `/signup` | API | Real |
| `otp_verification_screen.dart` | `/verify-otp` | API | Real |
| `onboarding_flow_screen.dart` | `/onboarding` | Local State -> API | Real (updates via PUT /me) |
| `home_screen.dart` | Tab 0 | API | Real |
| `discover_swipe_screen.dart` | Tab 1 | API | Real |
| `chat_list_screen.dart` | Tab 2 | API | Real |
| `chat_conversation_screen.dart` | Push `/chat/:id` | API / Socket | Real (Socket.io) + One fake timer for Voice Notes |
| `journal_home_screen.dart` | Tab 3 | API | Real |
| `progress_dashboard_screen.dart` | Tab 4 | API | Real |
| `profile_screen.dart` | Drawer | API | Real |
| `sos_help_screen.dart` | Header | API | Real |

## 2. Hardcoded / Fake Data Trace
1. **Voice Note Simulation**: `app_state.dart:643` has a `Timer` to simulate a voice note reply:
   ```dart
   Timer(const Duration(milliseconds: 1800), () {
     final replyMsg = ChatMessage(text: "Hearing your voice...", isMine: false);
   })
   ```
2. **Campus/Corporate Loading Screen**: `campus_corporate_screen.dart:60` uses `Future.delayed(Duration(milliseconds: 900))` to simulate joining a network.

## 3. API Client & Auth Header
File: `lib/state/auth_notifier.dart` & `lib/state/app_state.dart`
- Uses `dio` HTTP client.
- Auth tokens are stored in `FlutterSecureStorage`.
- `ApiClient` intercepts requests to attach `Authorization: Bearer <token>`.

Findings count: 22 | Not found/unverified items: 0

---

# PART 6: END-TO-END CONNECTION MATRIX

| Feature | Frontend Calls API | API Route Exists | DB Model Exists | Data Persists | Admin Visibility | Status |
|---------|--------------------|------------------|-----------------|---------------|------------------|--------|
| Signup / Login | Yes | Yes | Yes | Yes | Yes | **WORKING** |
| OTP Verification | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Onboarding (Interests/Bio) | Yes | Yes | Yes | Yes | Yes | **WORKING** |
| Profile Photo Upload | Yes | Yes | Yes | Yes | Yes | **WORKING** |
| Discover & Swipe | Yes | Yes | Yes | Yes | Yes (Matches) | **WORKING** |
| Mutual Match Logic | Yes | Yes | Yes | Yes | Yes | **WORKING** |
| Live Chat (Socket) | Yes | Yes | Yes | Yes | Yes (Messages) | **WORKING** |
| Notifications | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Community Feed | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Post Likes / Comments | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Journal (Private) | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Goals / Progress | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| SOS Emergency Contacts | Yes | Yes | Yes | Yes | N/A | **WORKING** |
| Report / Block | Yes | Yes | Yes | Yes | Yes | **WORKING** |
| Voice Notes | No | No | No | No | N/A | **FAKE** |

### Top Breaks in the Chain
1. **Voice Notes**: Pushing a voice note still triggers a local dummy `Timer` in `app_state.dart` to simulate a response. Audio files are not uploaded to the backend.
2. **Campus/Corporate Institutional Login**: Entirely UI based right now with a fake `Future.delayed` spinner.
3. **Forgot Password**: The API route exists but relies on a dummy `/verify-otp` with hardcoded fallback since it doesn't hook up to an actual SMTP/Email provider.

Findings count: 18 | Not found/unverified items: 0

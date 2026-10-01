# PHASE 0: BACKEND CONTRACT

## AUTHENTICATION (`/api/auth`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| POST | `/register` | No | `{ email: string(req), password: string(req), pseudonym: string, isAnonymous: boolean }` | `{ token, user }` | Checks if email exists. Passwords hashed via bcrypt. |
| POST | `/login` | No | `{ email: string(req), password: string(req) }` | `{ token, user }` | 401 if invalid. Returns JWT token. |
| POST | `/verify-otp` | No | `{ email: string, otp: string }` | `{ success, user }` | Currently just verifies dummy OTP '123456'. |
| POST | `/forgot-password` | No | `{ email: string }` | `{ message: "OTP sent" }` | Returns a dummy success message. |

## USERS (`/api/users`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/me` | Yes | None | `User` object | Excludes password hash. |
| PUT | `/me` | Yes | Form-data: `avatar` (file), `pseudonym`, `bio`, `location`, `lookingFor` | Updated `User` | Multer limit 5MB, handles image upload saving to `/uploads`. |
| POST | `/:id/block` | Yes | Param: `id` | `{ success }` | Creates a `Block` relation. |
| POST | `/:id/report` | Yes | Param: `id`, Body: `{ reason: string, description: string }` | `{ success }` | Creates a `Report`. |

## DISCOVERY & MATCHES (`/api/match`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/profiles` | Yes | None | `User[]` | Excludes already swiped, blocked, or self. |
| POST | `/swipe` | Yes | `{ targetUserId: string(req), isRight: boolean(req) }` | `{ match: boolean, conversationId?: string }` | Upserts `Swipe`. If mutual right, creates `Match` & `Conversation`. |

## CHAT & CONVERSATIONS (`/api/conversations`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/` | Yes | None | `Match[]` (includes `conversation`, `userA`, `userB`) | Returns user's active conversations. |
| GET | `/:id/messages` | Yes | Param: `id` (conversationId) | `Message[]` | Verifies user is part of the conversation. |

## COMMUNITY (`/api/community`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/` | No | None | `CommunityPost[]` | Includes author details, like count, comment count. |
| POST | `/` | Yes | `{ topic: string(req), content: string(req) }` | `CommunityPost` | Topic min 1, content min 1. |
| POST | `/:id/like` | Yes | Param: `id` | `{ success }` | Upserts `PostLike`, toggles state if already liked. |
| POST | `/:id/comments` | Yes | Param: `id`, Body: `{ text: string(req) }` | `Comment` | Appends comment to post. |

## WELLNESS GOALS (`/api/goals`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/` | Yes | None | `WellnessGoal[]` | |
| POST | `/` | Yes | `{ title: string(req), subtitle: string, categoryColor: string }` | `WellnessGoal` | Title max 100 chars. Increments XP by 40. |
| PUT | `/:id/toggle` | Yes | Param: `id` | `WellnessGoal` | Toggles `isCompleted` and adjusts XP. |

## JOURNAL (`/api/journal`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/` | Yes | None | `JournalEntry[]` | Only returns user's own entries. |
| POST | `/` | Yes | `{ content: string, moodScore: number, category: string, isPrivate: boolean }` | `JournalEntry` | |

## SOS & NOTIFICATIONS (`/api/sos`, `/api/notifications`)
| Method | Endpoint | Auth Required | Body/Params | Response | Validation / Notes |
|--------|----------|---------------|-------------|----------|--------------------|
| GET | `/sos/contacts` | Yes | None | `EmergencyContact[]` | |
| POST | `/sos/contacts` | Yes | `{ name: string, phone: string, relationship: string }` | `EmergencyContact` | |
| DELETE| `/sos/contacts/:id` | Yes | Param: `id` | `{ message }` | Verifies ownership before deleting. |
| GET | `/notifications` | Yes | None | `Notification[]` | |
| PUT | `/notifications/:id/read` | Yes | Param: `id` | `{ success }` | |
| PUT | `/notifications/read-all`| Yes | None | `{ success }` | |

## SOCKET.IO EVENTS
| Event | Direction | Payload | Validation / Notes |
|-------|-----------|---------|--------------------|
| `connection` | Server <- Client | Header/Query: `auth.token` | Token is verified. User joins personal room `user_${id}`. |
| `join_conversation` | Server <- Client | `matchId` (string) | Verifies membership, joins socket to `room_${matchId}`. |
| `send_message` | Server <- Client | `{ matchId, text, senderId }` | Validates membership. Saves to DB `Message`, broadcasts. |
| `receive_message` | Server -> Client | `Message` object | Sent to all clients in `room_${matchId}`. |
| `user_typing` | Server <-> Client | `{ matchId, isTyping }` | Broadcast to room excluding sender. |

## BACKEND PROBLEMS / GAPS NOTICED
1. **OTP is Hardcoded**: `/verify-otp` does not actually send emails/SMS; it accepts "123456" unconditionally for everyone.
2. **Missing Endpoint**: There is no endpoint for fetching campus/corporate (institutional) setups.
3. **No Voice Notes**: `Message` model has `content: String` but no fields for audio URLs, duration, or a specific endpoint for uploading audio securely.
4. **No Pagination on Profiles**: `/match/profiles` and others do not seem to implement limits/cursors heavily, could be an issue at scale.
5. **No Password Reset Implementation**: The `/forgot-password` route just says "OTP sent" but there is no endpoint to submit a new password using an OTP.

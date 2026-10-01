# Phase 0: Production Readiness Audit Report

## 1. Architecture Overview
- **Frontend (Flutter)**: Entirely mocked. The app state (`lib/state/app_state.dart` and `auth_notifier.dart`) uses hardcoded dummy data. No API calls are made to the backend.
- **Admin Panel (Next.js)**: Server Components fetch data from the backend using an `INTERNAL_API_KEY`. However, there is **zero frontend authentication/session management**. Anyone who can access the Next.js app can view all users and matches.
- **Backend (Node.js/Express + Prisma + SQLite)**: Provides REST API endpoints and Socket.io for chat.
- **Root Website Server (`server.js`)**: A basic static file server running on port 8080.

## 2. API Endpoints Contract
| Method | Path | Auth Required? | Roles? | Input Validation | Note |
|---|---|---|---|---|---|
| POST | `/api/auth/anonymous` | No | None | None | |
| POST | `/api/auth/signup` | No | None | None (Checks email/pass existence) | |
| POST | `/api/auth/login` | No | None | None | |
| GET | `/api/journal/` | Yes (JWT) | None | N/A | No pagination |
| POST | `/api/journal/create` | Yes (JWT) | None | None | Mass assignment risk |
| GET | `/api/match/discover` | Yes (JWT) | None | N/A | No pagination |
| POST | `/api/match/swipe` | Yes (JWT) | None | None | |
| GET | `/api/progress/` | Yes (JWT) | None | N/A | |
| GET | `/api/sos/resources` | No | None | N/A | |
| GET | `/api/admin/stats` | Yes (Internal Key) | ADMIN* | N/A | *JWT Admin check is broken |
| GET | `/api/admin/users` | Yes (Internal Key) | ADMIN* | N/A | No pagination |
| GET | `/api/admin/matches` | Yes (Internal Key) | ADMIN* | N/A | No pagination |

## 3. Environment Variables & Secrets
**Backend (`backend/.env`)** - *Checked into version control!*
- `PORT=3000`
- `DATABASE_URL="file:./dev.db"` (SQLite used instead of Postgres)
- `JWT_SECRET="wehere_super_secret_key_123"` **(CRITICAL: Hardcoded & Weak)**
- `INTERNAL_API_KEY="wehere_super_secret_admin_key_2026"` **(CRITICAL: Hardcoded & Exposed)**
- *Missing:* `FRONTEND_URL` (Used in CORS config but undefined), `NODE_ENV`

**Admin Panel (`admin-panel/.env.local`)** - *Checked into version control!*
- `INTERNAL_API_KEY="wehere_super_secret_admin_key_2026"`
- `NEXT_PUBLIC_API_URL="http://localhost:3000"`

## 4. Dependencies
- **NPM Audit**: `0 vulnerabilities` found in both backend and admin-panel.
- **Unused/Suspicious**: Dependencies look standard, but there is no validation library (like Zod or Joi) installed in the backend. 

## 5. Risk Findings & Dead Code
### CRITICAL
1. **Frontend App is 100% Mocked**: The Flutter app does not talk to the backend. Features like login, matching, and journals are entirely simulated in local state.
2. **Admin Panel has No Authentication**: There is no login screen for the admin panel. Anyone who navigates to it can view all user PII and matches.
3. **Broken Backend Admin Auth**: `backend/src/middleware/auth.js` checks for `req.user.role === 'ADMIN'`. However, `auth.js` routes only sign the JWT with `{ id: user.id }`. `req.user.role` is always undefined. The only way to access admin routes is via the `INTERNAL_API_KEY` backdoor bypass.
4. **Hardcoded Secrets in Repo**: Real API keys and JWT secrets are committed to the codebase. They must be rotated/removed immediately.

### HIGH
1. **No Input Validation**: Endpoints read `req.body` directly without sanitization or schema validation, exposing the app to NoSQL/SQL injection and Mass Assignment attacks.
2. **CORS Misconfiguration**: Backend CORS defaults to `*` because `NODE_ENV` is not set. Socket.io also explicitly allows `*`.
3. **Database**: The app uses SQLite (`dev.db`). This will lock and fail under production concurrency. Needs migration to PostgreSQL.

### MEDIUM
1. **Unbounded Queries**: Endpoints like `/api/admin/users` and `/api/journal/` lack pagination and will crash the server as data grows.
2. **Error Handling**: Missing a centralized error-handling middleware. `error.message` is returned directly to the client, leaking internal stack/DB traces.
3. **Rate Limiting**: A global rate limiter is present, but `/auth/*` endpoints lack strict brute-force protection.
4. **Socket.io Security**: No authentication is enforced on the WebSocket connection.

### LOW
1. **Dead/Duplicate Code**: The root directory has a `server.js` meant to serve static files (`website/`, `preview/`), which seems disconnected from the main application architecture.
2. **Fake Success Handlers**: The admin UI buttons (like "Add User" or "Edit") are purely cosmetic.

## Next Steps (Phase 1)
Please review this report. Once approved, I will proceed to **Phase 1: Connections & Integration**, which includes ripping out mock data in the Flutter app, fixing the API contracts, setting up Zod validation, and connecting the frontend to the real backend.

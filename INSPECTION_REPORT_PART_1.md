# PART 1: PROJECT OVERVIEW & STRUCTURE

## 1. Folder Tree (3 levels deep)
### Frontend (Flutter)
```
/ (Root)
├── lib/
│   ├── core/
│   │   ├── constants/ (e.g., app_constants.dart)
│   │   ├── theme/
│   │   └── utils/
│   ├── models/ (e.g., community_post.dart, notification.dart)
│   ├── screens/ (auth, chat, discovery, home, journal, onboarding, profile, progress)
│   ├── state/ (e.g., app_state.dart, auth_notifier.dart)
│   └── widgets/ (chat, discovery, shared)
├── assets/
│   ├── mockups/
│   └── images/
└── android/, ios/, web/ (Standard Flutter platform folders)
```

### Backend (Node.js)
```
/backend/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── middleware/ (auth.js)
│   ├── routes/ (admin.js, auth.js, community.js, conversations.js, goals.js, journal.js, match.js, notifications.js, progress.js, sos.js, users.js)
│   └── server.js
└── seed.js
```

### Admin Panel (Next.js)
```
/admin-panel/
├── app/ (Assumed Next.js App Router structure)
├── public/
├── .next/
├── next.config.ts
└── tailwind.config.ts / postcss.config.mjs
```

## 2. App Tech Stacks
| App | Framework | Language | State Management | HTTP Client | Key Packages | Commands |
|-----|-----------|----------|------------------|-------------|--------------|----------|
| **Frontend** | Flutter (3.x) | Dart | `provider` | `dio` | `socket_io_client`, `flutter_secure_storage`, `shared_preferences`, `image_picker` | `flutter run`, `flutter build apk` |
| **Backend** | Express 4.18 | JS (Node) | N/A | N/A | `@prisma/client`, `socket.io`, `jsonwebtoken`, `bcryptjs`, `multer`, `zod`, `helmet`, `express-rate-limit` | `npm run start`, `npm run dev`, `npm run db:push` |
| **Admin** | Next.js 16.3 | TS/JS (React 19) | React State | `fetch` (likely) | `tailwindcss` | `npm run dev`, `npm run build`, `npm run start` |

## 3. Package Analysis
- **Suspicious/Outdated**: Flutter SDK is listed as `>=3.0.0 <4.0.0` but `provider: ^6.1.2` and `socket_io_client: ^3.1.6` are standard. Next.js is oddly versioned as `16.3.6` (Next.js is currently on v14/v15, v16 doesn't exist officially unless it's a canary/beta). React is `19.2.8` (which is a future/RC version). 
- **Duplicates**: None found in package files.

## 4. Configuration Files
- **Backend**:
  - `Dockerfile` is present.
  - `.env.example` outlines required environment variables for development.
  - `docker-compose.yml` configures the stack (likely Postgres + Node).
  - `prisma/schema.prisma` is the single source of truth for DB config.
- **Admin**:
  - `Dockerfile` is present.
  - `next.config.ts`, `postcss.config.mjs`, `eslint.config.mjs` for build tools.
  - `.env.example` and `.env.local` present.
- **Frontend**:
  - `pubspec.yaml` contains all config. No `.env` handling out of the box (uses `--dart-define=API_URL=...` at build time).

## 5. Environment Variables
| Variable | Location | Used In Code | Defined In .env.example | Status |
|----------|----------|--------------|-------------------------|--------|
| `API_URL` | Frontend | Yes (`--dart-define`) | N/A | Passed via build command |
| `PORT` | Backend | UNABLE TO VERIFY YET | Yes (`3000`) | Standard |
| `DATABASE_URL` | Backend | Prisma Schema | Yes | Standard |
| `JWT_SECRET` | Backend | `auth.js`, `server.js` | Yes | Required for Auth |
| `INTERNAL_API_KEY` | Backend | UNABLE TO VERIFY YET | Yes | Used for Admin-Backend auth |
| `FRONTEND_URL` | Backend | CORS Config (likely) | Yes | Standard |
| `ADMIN_URL` | Backend | CORS Config (likely) | Yes | Standard |
| `NEXT_PUBLIC_API_URL` | Admin | API calls | Yes | Next.js public variable |
| `ADMIN_USER` | Admin | UNABLE TO VERIFY YET | Yes | Hardcoded auth config |
| `ADMIN_PASSWORD` | Admin | UNABLE TO VERIFY YET | Yes | Hardcoded auth config |

## 6. Git Status
- **Current Branch**: `feature/backend-integration`
- **Tracked Secrets**: `.env` is explicitly ignored by `backend/.gitignore` and `admin-panel/.gitignore`. No secrets are currently tracked in git tree. `admin-panel/.env.local` is present locally but ignored by git.

Findings count: 18 | Not found/unverified items: 3

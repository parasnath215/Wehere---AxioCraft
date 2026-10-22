# Wehere Architecture Documentation: Master Index

This directory contains the exhaustive technical audit and architectural blueprints for the **Wehere** mobile ecosystem, comprising the Flutter mobile client (`lib/`), the Node.js/Express real-time WebSocket backend (`backend/`), and the Next.js administrative control panel (`admin-panel/`).

---

## 1. Executive Architecture Summary

```text
+---------------------------------------------------------------------------------------+
|                                    WEHERE ECOSYSTEM                                   |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|   FLUTTER CLIENT (Android / iOS)                     NODE.JS / EXPRESS BACKEND        |
|   +----------------------------+                     +----------------------------+   |
|   | 64 Dart Source Files       |                     | REST API (43 Endpoints)    |   |
|   | Provider State Management  |                     | Socket.IO WebSockets       |   |
|   | Material 3 + Custom Tokens | <--- HTTPS/WSS ---> | Rate Limiting & Helmet     |   |
|   | SecureStorage (Keychain)   |                     | Background Cleanup Workers |   |
|   +----------------------------+                     +--------------+-------------+   |
|                                                                     |                 |
|   NEXT.JS ADMIN PANEL                                               | Prisma ORM      |
|   +----------------------------+                                    v                 |
|   | Next.js 15 App Router      |                         POSTGRESQL DATABASE          |
|   | Tailwind CSS + React 19    | <--- Internal API Key - +------------------------+   |
|   | Moderation & Analytics     |                         | 17 Models & Cascade FKs|   |
|   +----------------------------+                         +------------------------+   |
+---------------------------------------------------------------------------------------+
```

### Key Architectural Characteristics
1. **Frontend Architecture (`lib/`)**:
   - Built on **Flutter 3.x** and **Dart 3.x** ([pubspec.yaml](file:///e:/Websites/Wehere/pubspec.yaml#L7)).
   - Follows a **Feature-Layered Pattern** with two central reactive state machines:
     - [AuthNotifier](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart): Session lifecycle, token encryption, OTP verification, and onboarding gating.
     - [AppState](file:///e:/Websites/Wehere/lib/state/app_state.dart): Central domain orchestrator managing discovery swiping, real-time WebSocket chats, journal reflections, mood streaks, wellness goals, and gamification XP.
   - Screen hierarchy is managed by a persistent bottom navigation shell ([MainNavigationShell](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart)) using `IndexedStack` to preserve state across 5 tabs: Home, Explore/Discovery, Journal, Chats, and Profile.
2. **Backend Architecture (`backend/`)**:
   - Built with **Node.js**, **Express.js**, and **Socket.IO** ([server.js](file:///e:/Websites/Wehere/backend/src/server.js)).
   - Data access is mediated by **Prisma ORM** ([schema.prisma](file:///e:/Websites/Wehere/backend/prisma/schema.prisma)) connecting to PostgreSQL with 17 relational models.
   - Features automated background workers for unverified account purges (12h cycle) and 7-day scheduled account deletions (60s cycle).
3. **Admin Architecture (`admin-panel/`)**:
   - Built on **Next.js 15** with React Server Components consuming backend admin routes via internal API key headers (`x-api-key`).

---

## 2. Master Documentation Index

| # | Document File Link | Primary Scope & Contents |
| :---: | :--- | :--- |
| **01** | [OVERVIEW.md](file:///e:/Websites/Wehere/docs/architecture/OVERVIEW.md) | High-level platform purpose, complete pubspec dependency audit, architectural evaluation, full `lib/` directory tree, and run/build/release guides. |
| **02** | [SCREENS_AND_NAVIGATION.md](file:///e:/Websites/Wehere/docs/architecture/SCREENS_AND_NAVIGATION.md) | Complete inventory of all 22 screens, Navigator route names, protected authentication guards, modal sheets, and a Mermaid navigation flow diagram. |
| **03** | [FEATURES.md](file:///e:/Websites/Wehere/docs/architecture/FEATURES.md) | Deep technical breakdown of all 18 user-facing features: widgets, state holders, APIs called, local storage keys, and step-by-step execution flows. |
| **04** | [FUNCTIONS_REFERENCE.md](file:///e:/Websites/Wehere/docs/architecture/FUNCTIONS_REFERENCE.md) | Exhaustive class and function catalog across every Dart file in `lib/`: inputs, outputs, callers, and audit of unused/duplicate code. |
| **05** | [STATE_MANAGEMENT.md](file:///e:/Websites/Wehere/docs/architecture/STATE_MANAGEMENT.md) | Detailed analysis of Provider architecture, `AuthNotifier` vs. `AppState` property matrices, and reactive state flow Mermaid diagrams. |
| **06** | [DATA_AND_API_LAYER.md](file:///e:/Websites/Wehere/docs/architecture/DATA_AND_API_LAYER.md) | Dio HTTP client setup, interceptors, all 42 REST endpoints, storage keys, and 5 Mermaid sequence diagrams for critical flows. |
| **07** | [AUTH_AND_SECURITY.md](file:///e:/Websites/Wehere/docs/architecture/AUTH_AND_SECURITY.md) | Authentication lifecycle, JWT storage, permissions matrix, environment variable audit, and 5 prioritized security vulnerabilities. |
| **08** | [PLATFORM_AND_BUILD.md](file:///e:/Websites/Wehere/docs/architecture/PLATFORM_AND_BUILD.md) | Android Gradle and Manifest setup, iOS Info.plist privacy audit, native plugins, signing, and background services status. |
| **09** | [DEPENDENCY_MAP.md](file:///e:/Websites/Wehere/docs/architecture/DEPENDENCY_MAP.md) | Architectural layer hierarchy rules, structural Mermaid dependency diagram, and architectural coupling smell analysis. |
| **10** | [ISSUES_AND_GAPS.md](file:///e:/Websites/Wehere/docs/architecture/ISSUES_AND_GAPS.md) | Senior audit of fake/mocked data, runtime bugs, performance bottlenecks, dead code, and a prioritized P0–P3 remediation roadmap. |
| **11** | [BACKEND_API.md](file:///e:/Websites/Wehere/docs/architecture/BACKEND_API.md) | Backend route reference for all endpoints, middleware security rules, Admin panel API mapping, and Socket.IO WebSocket event matrix. |
| **12** | [DATABASE.md](file:///e:/Websites/Wehere/docs/architecture/DATABASE.md) | Complete PostgreSQL Prisma schema specification: 17 models, column constraints, indexes, ER diagram, and Flutter feature mappings. |
| **13** | [CHANGELOG_FIXES.md](file:///e:/Websites/Wehere/docs/architecture/CHANGELOG_FIXES.md) | Phase-by-phase implementation changelog of production hardening fixes, migrations, and architecture changes. |
| **14** | [AUTH_LOGIN_REGISTRATION_FLOW.md](file:///e:/Websites/Wehere/docs/architecture/AUTH_LOGIN_REGISTRATION_FLOW.md) | Exhaustive technical specification and visual decision trees for all Login, Social Login (Google & Apple), Registration, OTP, DOB Age-Gate, and Admin flows. |

---

## 3. Immediate Action Items & Phase 1 Status

Priorities from Phase 1 of Production Hardening:
1. **[COMPLETED] Backend Admin Route Crash**: In [backend/src/routes/admin.js](file:///e:/Websites/Wehere/backend/src/routes/admin.js), corrected `prisma.journal.count` to `prisma.journalEntry.count({ where: { userId: id } })`.
2. **[COMPLETED] Enforce HTTPS / WSS**: Dynamic `API_URL` environment variable support added; release mode startup guard requires HTTPS; cleartext disabled in main manifest. Runbook at [docs/ops/HTTPS_SETUP.md](file:///e:/Websites/Wehere/docs/ops/HTTPS_SETUP.md).
3. **[COMPLETED] Admin Panel Hardening**: `adminGuard` timing-safe check, `POST /api/admin/login`, Next.js middleware + httpOnly cookie authentication, 120 req/min rate limit.
4. **[COMPLETED] 18+ Date of Birth Guard**: Schema migration, `requireAdult` middleware, and `DobGateScreen` added.
5. **[PENDING Phase 6] iOS Keystore & Asset Path**: Add release signing and replace local Windows image path in subscription sheet.

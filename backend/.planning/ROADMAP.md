# Wehere Backend Roadmap

## Proposed Roadmap

**4 phases** | **16 requirements mapped** | All v1 requirements covered ✓

| # | Phase | Goal | Requirements |
|---|-------|------|--------------|
| 1 | Infrastructure & API Setup | Initialize Node.js/Express, Docker, PostgreSQL, Prisma, and JWT Auth. | REQ-AUTH-1, REQ-AUTH-2, REQ-INFRA-1, REQ-INFRA-2 |
| 2 | Data Modeling & REST API | Build the database schema (Prisma) and CRUD endpoints for profiles, journals, and matching. | REQ-AUTH-3, REQ-MATCH-1, REQ-MATCH-2, REQ-MATCH-3, REQ-JOURNAL-1, REQ-JOURNAL-2 |
| 3 | WebSockets & Realtime Chat | Implement Socket.io for live messaging and notifications. | REQ-CHAT-1, REQ-CHAT-2, REQ-CHAT-3 |
| 4 | Razorpay Integration | Expose webhooks and API routes to handle secure payments and subscription upgrades. | REQ-PAY-1, REQ-PAY-2, REQ-PAY-3 |

### Phase Details

**Phase 1: Infrastructure & API Setup**
Goal: Establish the base Dockerized Node.js environment and JWT authentication.
Requirements: REQ-AUTH-1, REQ-AUTH-2, REQ-INFRA-1, REQ-INFRA-2
Success criteria:
1. `docker-compose up` successfully starts a PostgreSQL database and a Node.js Express server.
2. Prisma is configured and connected to the DB.
3. Users can register, login, and receive a JWT token.

**Phase 2: Data Modeling & REST API**
Goal: Define the relational schema and build endpoints for core features.
Requirements: REQ-AUTH-3, REQ-MATCH-1, REQ-MATCH-2, REQ-MATCH-3, REQ-JOURNAL-1, REQ-JOURNAL-2
Success criteria:
1. Prisma schema accurately models Users, Journals, Swipes, and Matches.
2. JWT middleware strictly guards API routes so users only access their own data.
3. Discover algorithm endpoint successfully returns non-matched user profiles using SQL joins/filters.

**Phase 3: WebSockets & Realtime Chat**
Goal: Enable private, real-time communication between matched users.
Requirements: REQ-CHAT-1, REQ-CHAT-2, REQ-CHAT-3
Success criteria:
1. Socket.io server is attached to the Express app and authenticates connections via JWT.
2. Users can join private room channels for their matches and exchange messages in real time.
3. Messages are persisted to PostgreSQL upon being sent.

**Phase 4: Razorpay Integration**
Goal: Monetize the platform via secure payment processing.
Requirements: REQ-PAY-1, REQ-PAY-2, REQ-PAY-3
Success criteria:
1. Razorpay Node SDK is integrated.
2. API endpoint creates Razorpay orders.
3. Secure webhook endpoint verifies Razorpay signatures and updates the user's subscription tier in PostgreSQL.

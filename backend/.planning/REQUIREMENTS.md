# Wehere Backend Requirements

## Version 1 Scope

### Authentication & Profiles (REQ-AUTH)
- **REQ-AUTH-1:** Custom JWT Authentication system (signup, login, token refresh).
- **REQ-AUTH-2:** Anonymous mode support (generate pseudonyms, tied to JWT session).
- **REQ-AUTH-3:** User profile management in PostgreSQL (name, avatar, bio, tags, mood, settings).

### Chat & Messaging (REQ-CHAT)
- **REQ-CHAT-1:** Real-time messaging using WebSockets (Socket.io).
- **REQ-CHAT-2:** 1-on-1 private threads and matching queues stored in PostgreSQL.
- **REQ-CHAT-3:** Push notifications/socket events for new messages.

### Match & Discover (REQ-MATCH)
- **REQ-MATCH-1:** Discover algorithm endpoint to fetch non-matched users based on preferences (using SQL queries).
- **REQ-MATCH-2:** Track swipes, likes, and match states in the relational database.
- **REQ-MATCH-3:** Free tier limits (5 swipes), resetting weekly or triggering upgrade prompts.

### Journaling (REQ-JOURNAL)
- **REQ-JOURNAL-1:** Private journal entries stored in PostgreSQL.
- **REQ-JOURNAL-2:** Store mood tracking, tags, and AI-prompt responses.

### Payments & Subscriptions (REQ-PAY)
- **REQ-PAY-1:** Razorpay Node.js SDK integration for "Wehere Plus" and institutional discounts.
- **REQ-PAY-2:** Express webhook endpoint to securely verify Razorpay payment signatures.
- **REQ-PAY-3:** Update user subscription state in PostgreSQL on successful webhook verification.

### Infrastructure & Deployment (REQ-INFRA)
- **REQ-INFRA-1:** Containerized via Docker.
- **REQ-INFRA-2:** `docker-compose.yml` to spin up Node.js API and PostgreSQL database together.

## Out of Scope (Future Versions)
- **REQ-OUT-1:** Community circles and group forums (removed per product owner).
- **REQ-OUT-2:** Live audio/video calling.

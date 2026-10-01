# Wehere Backend

## Overview
The backend system for the Wehere anonymous peer-support mobile application. It replaces the current mock data implementation in the Flutter frontend with a live, persistent architecture.

## Architecture & Stack
- **Paradigm:** Self-hosted API (REST + WebSockets for chat).
- **Compute/Framework:** Node.js with Express.js.
- **Authentication:** JWT (JSON Web Tokens) for session management (Anonymous & Account-linked).
- **Database:** PostgreSQL (using Prisma ORM for schema and migrations).
- **Real-time:** Socket.io or ws for real-time chat and push notifications.
- **Storage:** Local volume storage or self-hosted S3-compatible storage (MinIO) for avatars.
- **Deployment:** Docker & Docker Compose (can be run on any standard Linux VPS).
- **Payments:** Razorpay Node SDK for webhooks and subscription management.

## Core Directives
1. **Security First:** Strict JWT validation and row-level authorization in API controllers to ensure users only access their own data.
2. **Anonymity:** Ensure PII (Personally Identifiable Information) is heavily protected in the relational database.
3. **Self-Contained:** The entire backend stack (API, DB, Cache) must be orchestratable via a single `docker-compose.yml`.

## Repositories
- Frontend: `e:\Websites\Wehere`
- Backend: `e:\Websites\Wehere\backend`

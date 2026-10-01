# QA & Testing Guide

This repository contains the Flutter mobile app, Node/Express backend, and Next.js admin panel for the Wehere application.

## Quick Start (Local QA Environment)

You can spin up the entire application stack using Docker Compose for an isolated test environment.

1. **Start the environment:**
   ```bash
   docker-compose up -d
   ```
   This will start the PostgreSQL database, Backend API (port 4000), and Admin Panel (port 3000).

2. **Seed the database:**
   ```bash
   docker-compose exec backend node reset_data.js
   ```
   This clears existing data and populates it with a predefined `QA Tester` account, a `Helpful Peer` account, config options, and initial chat/match data.

3. **Configure the App:**
   Ensure the Flutter app points to your local network IP (e.g. `http://192.168.1.100:4000/api`) or the deployed test server instead of `localhost`. 
   Update `lib/core/network/api_client.dart` or use `--dart-define=API_URL=http://...` if configured to do so.

4. **Run the App:**
   ```bash
   flutter run
   ```

## Test Accounts

The `reset_data.js` script creates the following accounts:

- **Admin Account (Admin Panel):**
  - Email: `admin@wehere.com`
  - Password: `supersecureadmin`

- **QA Tester Account (Mobile App):**
  - Email: `tester@wehere.com`
  - Password: `password123`

- **Peer Account (Mobile App):**
  - Email: `peer@wehere.com`
  - Password: `password123`

## Testing OTP (Bypassing SMS/Email)

The backend has a built-in test bypass for OTP.
When `NODE_ENV` is NOT `production` and `TEST_OTP_ENABLED=true` in `backend/.env`, you can use the code **`123456`** for any OTP verification screen in the app. This allows testers to verify signup and login flows without an actual SMS gateway.

## Automated Checks

To ensure the codebase remains healthy during testing, run the smoke tests and analyzer:

```bash
flutter analyze
flutter test test/smoke_test.dart
```

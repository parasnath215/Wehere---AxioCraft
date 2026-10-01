# Phase 7: Full Stack Live Data Integration Plan

This document outlines the systematic plan to replace **all** remaining mock data in the Flutter app with fully functional, live database connections across every single screen.

## 1. Database Schema Expansion (Prisma)
To support the remaining features, we must expand `backend/prisma/schema.prisma` with the following models:
- **`CommunityPost`**: `id`, `authorId`, `topic`, `content`, `likesCount`, `createdAt`.
- **`Comment`**: `id`, `postId`, `authorId`, `content`, `createdAt`.
- **`WellnessGoal`**: `id`, `userId`, `title`, `subtitle`, `categoryColor`, `isCompleted`, `progress`, `createdAt`.
- **`EmergencyContact`**: `id`, `userId`, `name`, `phone`, `relationship`.

## 2. Backend API Roadmap

### A. Real-Time Chat Engine (`/api/chat` & Socket.io)
- **`GET /api/chat/conversations`**: Fetch all active matches/conversations for the inbox.
- **`GET /api/chat/messages/:id`**: Fetch historical messages for a specific conversation.
- **Socket.io `send_message`**: Finalize the event to save messages and broadcast to the recipient.

### B. Community Feed (`/api/community`)
- **`GET /api/community/posts`**: Fetch paginated community feed.
- **`POST /api/community/posts`**: Create a new peer support post.
- **`POST /api/community/posts/:id/like`**: Toggle like on a post.
- **`POST /api/community/posts/:id/comment`**: Reply to a post.

### C. Goals & Habits (`/api/goals`)
- **`GET /api/goals`**: Fetch user's wellness goals.
- **`POST /api/goals`**: Add a new goal.
- **`PUT /api/goals/:id/toggle`**: Mark goal as complete/incomplete.

### D. Emergency Contacts (`/api/sos`)
- **`GET /api/sos/contacts`**: Fetch user's trusted contacts.
- **`POST /api/sos/contacts`**: Add a new trusted contact.

---

## 3. Flutter App Integration Flow (Screen by Screen)

### Screen 1: Dashboard (Home)
- **Current State**: Uses mock `_goals`, mock `_weekDaysCheckIn`, and mock user stats.
- **Integration**: On `initState`, fetch `/api/progress` and `/api/goals`. Remove all dummy data from `AppState`.

### Screen 2: Discovery Deck (Swiping)
- **Current State**: Partially integrated.
- **Integration**: Ensure `fetchBackendData()` populates the deck properly. Remove hardcoded fallback profiles (Riya, Rohan, Meera). 

### Screen 3: Chat Inbox & Conversation Screen
- **Current State**: `sendMessage` creates a fake 1.4-second timer that auto-replies with dummy text.
- **Integration**: 
  1. Add `socket_io_client` to `pubspec.yaml`.
  2. Connect to `http://VPS_IP:4000` via sockets.
  3. Emit `send_message` events directly to the server.
  4. Listen for `receive_message` and `user_typing` to update the UI instantly.
  5. Fetch chat history via `/api/chat/messages/:id` instead of generating mock histories.

### Screen 4: Journal
- **Current State**: Fully integrated with the backend for fetching and creating. Just need to remove the hardcoded seed entry from `_initMockData()`.

### Screen 5: Community Feed
- **Current State**: 100% Mocked.
- **Integration**: Wire the Feed view to fetch `/api/community/posts`. Wire the "Like" button and "Add Comment" bottom sheet to POST requests.

---

## 4. Execution Strategy
1. **Wipe the Slate**: Delete `_initMockData()` from `lib/state/app_state.dart` entirely. The app will look completely empty (0 matches, 0 posts, 0 goals).
2. **Schema & Endpoints**: Build the new Prisma models and the 4 new Express routers (`chat.js`, `community.js`, `goals.js`, `sos.js`).
3. **Frontend Wiring**: Install Socket.io in Flutter and rebuild the state management to hydrate strictly from network responses.
4. **Final VPS Push**: Run the deployment script one last time to push the new database schema and APIs to the live server.

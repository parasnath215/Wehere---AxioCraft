# Wehere 💜 — Peer-to-Peer Mental Wellness & Emotional Connection App

**Wehere** is a cross-platform Flutter application built for Android and iOS, designed as a safe, supportive, Tinder-style peer connection platform for emotional well-being. It provides a non-clinical, empathetic space to connect, share experiences, track emotional growth, and access safety support resources anytime.

---

## 🌟 Key Features Implemented

### 1. Onboarding & Intake Experience
- **Splash & Walkthrough**: Welcoming purple gradient branding with 4 animated onboarding cards showcasing discovery, safe chats, mood tracking, and SOS help.
- **Auth Flow**: Clean tabbed Login & Signup with email OTP 6-digit PIN verification.
- **Guided Intake (5 Steps)**:
  1. What are you going through? (Anxiety, loneliness, grief, burnout, relationship stress, etc.)
  2. Support style preference (Empathetic listener, shared-experience buddy, accountability partner)
  3. Mood & communication pace (Gentle, deep talk, light distraction)
  4. Photo & profile bio setup
  5. **Anonymity Toggle**: Instant pseudonymous avatar generation with blurred photos for maximum comfort and privacy.

### 2. Tinder-Style Discovery & Matching Deck
- **Card Swipe Engine**: Smooth drag, tilt, and release gestures (Swipe Right to Connect, Swipe Left to Pass, Super Support Star).
- **Match Compatibility**: Match score % based on shared struggles, availability, and communication style.
- **"It's a Match!" Celebration Modal**: Dark-themed celebration popup with "Say Hello with an Icebreaker" and "Keep Browsing".

### 3. Safe Peer-to-Peer Interaction
- **Safe Space Guidelines Banner**: Prominently displayed in chat to set healthy boundaries.
- **Wellness Icebreakers**: Context-sensitive mental health prompts (e.g., *"What's one thing weighing on your mind today?"* or *"What gave you peace this week?"*).
- **Daily Wellness Tip Bar**: Calming micro-interventions inside conversation threads.
- **Trust Milestones**: Mutual trust progression unlocking voice/audio connection after verified positive interactions.

### 4. Wellness Layer & Reflection
- **Daily Mood Check-In**: 5 emotional states (Terrible, Anxious, Okay, Good, Thriving) with reflection tagging.
- **Interactive Journaling**: Prompts for gratitude, venting, and stream-of-consciousness writing.
- **Save Bottom Sheet & Summary**: "Before you go" grounding checklist and "All set!" completion modal.

### 5. Safety, Moderation & Crisis Escalation
- **Crisis Keyword Detection**: Auto-detects distress keywords in chat and immediately surfaces national helplines without silencing or shaming the user.
- **Dedicated SOS Help Hub**: High-visibility pulsing red emergency trigger, 24/7 volunteer listeners, and one-tap access to 988 Suicide & Crisis Lifeline, Crisis Text Line, and Trevor Project.
- **Disclaimers**: Explicit reminders throughout the app that peer support is not clinical therapy.
- **Report & Block Controls**: Immediate peer safety reporting with one-tap filtering.

### 6. Engagement & Habit Building
- **16-Day Streak Tracker (M–S)**: Supportive, non-punitive daily check-in habits.
- **Gamified Level Progression**: Level 12 "Growth Explorer" XP progress bar and claymorphic achievement badges (Helpful Listener, Consistency Master, Safe Space Creator).

---

## 📱 Project Structure

```
Wehere/
├── android/                   # Native Android configuration (Manifest, Gradle)
├── ios/                       # Native iOS configuration (Info.plist, Runner)
├── assets/
│   ├── mockups/               # 32 high-res design mockups from design team
│   ├── images/                # Illustration assets
│   └── icons/                 # UI icons
├── lib/                       # Flutter Application Source
│   ├── core/
│   │   ├── constants/         # AppConstants (disclaimers, helplines, support topics)
│   │   └── theme/             # AppColors (royal purple #5E4BEE), AppTheme, Typography
│   ├── models/                # UserProfile, MatchCard, ChatMessage, JournalEntry
│   ├── state/                 # AppState (centralized ChangeNotifier provider)
│   ├── widgets/
│   │   ├── common/            # Buttons, cards, mood chips, tag chips
│   │   ├── discovery/         # Swipeable deck, action buttons, match celebration
│   │   ├── chat/              # Chat bubbles, safe space banner, icebreaker sheet
│   │   └── sos/               # Pulsing emergency button
│   ├── screens/
│   │   ├── splash/            # Brand launch splash
│   │   ├── walkthrough/       # Onboarding carousel
│   │   ├── auth/              # Login, Signup, OTP verification
│   │   ├── onboarding/        # 5-step guided intake flow
│   │   ├── main_navigation_shell.dart # Bottom navigation bar with center action
│   │   ├── home/              # Dashboard, streak tracker, recommended peers
│   │   ├── discover/          # Tinder-style swipe discovery
│   │   ├── chat/              # Chat list & real-time messaging
│   │   ├── journal/           # Mood tracker & reflection journal
│   │   ├── progress/          # Insights, goal charts & streak calendar
│   │   ├── community/         # Theme circles & community feed
│   │   ├── sos/               # SOS emergency hub
│   │   └── profile/           # User profile, anonymity mode, XP bar, badges
│   └── main.dart              # Flutter App Entry point
├── pubspec.yaml               # Flutter package configuration & dependencies

## ⚙️ Backend & Admin Architecture
```
Wehere/
├── backend/                   # Node.js + Express Backend
│   ├── src/routes/            # API endpoints (Auth, Matches, Journal, Admin)
│   ├── prisma/                # Prisma ORM Schema for PostgreSQL
│   └── Dockerfile             # Production container definition
├── admin-panel/               # Next.js 14 Server-Side Rendered Dashboard
│   ├── src/app/               # App Router pages (Users, Matches, Dashboard)
│   └── Dockerfile             # Standalone production Next.js image
└── docker-compose.yml         # Unified orchestration (DB, Backend, Admin)
```

---

## 🚀 How to Run

### Option 2: Running via Flutter SDK (Android / iOS / Web / Desktop)
When you have the Flutter SDK installed on your machine:

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on an Android Emulator or Connected Device**:
   ```bash
   flutter run -d android
   ```

3. **Run on iOS Simulator (macOS)**:
   ```bash
   flutter run -d ios
   ```

### Option 3: Full-Stack Local Deployment (Docker Compose)
Wehere includes a complete microservice architecture orchestrated via Docker. This is the recommended way to test the backend and admin panel locally.

1. **Ensure Docker Desktop is running**.
2. **Start the cluster** (PostgreSQL, Backend API, Admin Next.js Panel):
   ```bash
   docker-compose up --build -d
   ```
3. **Run Database Migrations**:
   Wait for the containers to spin up, then push the schema to the database:
   ```bash
   docker-compose exec backend npx prisma db push
   ```
4. **Access the Services**:
   - **Backend API**: `http://localhost:4000/api`
   - **Admin Dashboard**: `http://localhost:3000` (Login with credentials from `docker-compose.yml`)
   - **Database**: Port `5432` on localhost

To connect the Flutter app to this local backend, set your API_URL when compiling:
```bash
flutter run --dart-define=API_URL=http://localhost:4000/api
```

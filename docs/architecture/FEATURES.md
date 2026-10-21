# Features Reference & Implementation Flows: Wehere

This document provides a comprehensive technical breakdown of every user-facing feature in the Wehere application. For each feature, the exact screens, widgets, state objects, backend endpoints, local storage keys, and step-by-step execution flows are cataloged.

---

## 1. Walkthrough & Value Introduction

- **Screens Involved**: [walkthrough_screen.dart](file:///e:/Websites/Wehere/lib/screens/walkthrough/walkthrough_screen.dart)
- **Widgets Used**: `PageView.builder`, `AnimatedContainer` (indicator dots), [WehereButton](file:///e:/Websites/Wehere/lib/widgets/common/wehere_button.dart).
- **State Objects**: `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)).
- **Services & APIs**: None (Offline onboarding introduction).
- **Local Storage Used**: `StorageHelper.write(key: 'has_seen_walkthrough', value: 'true')` ([storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L20)).
- **Step-by-Step Flow**:
  1. App opens on `SplashScreen`. If `hasSeenWalkthrough == false`, it navigates to `WalkthroughScreen`.
  2. User swipes through 4 slides ("You're not alone", "Meaningful Connections", "Safe & Private", "Grow Together").
  3. User taps "Get Started" or "Log In".
  4. `AuthNotifier.markWalkthroughSeen()` persists flag to secure storage.
  5. User is routed to `SignUpScreen` or `LoginScreen`.

---

## 2. User Registration & Photo Identification

- **Screens Involved**: [signup_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart)
- **Widgets Used**: `TextFormField`, [AvatarWidget](file:///e:/Websites/Wehere/lib/widgets/shared/avatar_widget.dart), `ImagePicker`, [UiUtils](file:///e:/Websites/Wehere/lib/core/utils/ui_utils.dart).
- **State Objects**: `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)).
- **Services & APIs**:
  - `POST /api/auth/signup` (`multipart/form-data`) with fields `email`, `password`, `pseudonym`, `phone` and files `images` (minimum 2 photos required).
- **Local Storage Used**: None during signup. The user record is not committed to local storage until OTP verification succeeds.
- **Step-by-Step Flow**:
  1. User fills in Display Name/Pseudonym, Email, Phone (optional), and Password (validated for 8+ chars, uppercase, and special char).
  2. User attaches at least 2 profile photos via `ImagePicker.pickImage()`.
  3. User checks "I agree to Terms & Conditions & Privacy Policy".
  4. User taps "Create Account".
  5. `AuthNotifier.register()` sends a multipart request to `/api/auth/signup`.
  6. Backend creates an ephemeral pending record, generates a 6-digit OTP, dispatches email via `email.js`, and returns `{ signupToken }`.
  7. Frontend receives `signupToken` and navigates to `OtpVerificationScreen(email)`.

---

## 3. Email OTP Verification & Cooldown Management

- **Screens Involved**: [otp_verification_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart)
- **Widgets Used**: 6 discrete `TextField` boxes with auto-advance `FocusNode`s, countdown timer, `WidgetsBindingObserver` for background lifecycle time synchronization.
- **State Objects**: `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)).
- **Services & APIs**:
  - `POST /api/auth/otp/verify` with body `{ otp, signupToken }`.
  - `POST /api/auth/otp/request` (for resend requests).
- **Local Storage Used**:
  - `StorageHelper.write(key: 'jwt_token', value: token)`
  - `StorageHelper.write(key: 'user_id', value: user.id)`
  - `StorageHelper.write(key: 'user_email', value: user.email)`
- **Step-by-Step Flow**:
  1. User enters 6-digit PIN. Once the 6th digit is typed, verification is triggered automatically.
  2. `AuthNotifier.verifyOtp(pin)` sends payload to `/api/auth/otp/verify`.
  3. On success, backend commits the user in PostgreSQL, sets `emailVerified: true`, and returns JWT token.
  4. Client writes token and user ID to secure storage.
  5. `AuthStatus` updates to `authenticated`. Router automatically redirects to `OnboardingFlowScreen`.

---

## 4. Credential Login & Password Recovery

- **Screens Involved**: [login_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart), [reset_password_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart)
- **Widgets Used**: `TextFormField`, password obscure toggle, floating snackbar ([UiUtils](file:///e:/Websites/Wehere/lib/core/utils/ui_utils.dart)).
- **State Objects**: `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)).
- **Services & APIs**:
  - `POST /api/auth/login` (Rate limited to 10 requests / 15 mins).
  - `POST /api/auth/otp/request` (`purpose: 'reset_password'`).
  - `POST /api/auth/reset-password` (`{ email, otp, newPassword }`).
- **Local Storage Used**:
  - `StorageHelper.write(key: 'jwt_token', value: token)`
  - `StorageHelper.write(key: 'user_id', value: user.id)`
  - `StorageHelper.write(key: 'user_email', value: user.email)`
- **Step-by-Step Flow**:
  1. User inputs email and password and taps "Log In".
  2. If credentials match and email is verified: JWT token is saved, `initializeSession()` loads profile, and user is routed to `MainNavigationShell`.
  3. If backend returns error `EMAIL_NOT_VERIFIED` (403): User is redirected to `OtpVerificationScreen`.
  4. If user taps "Forgot Password?": Enters email, backend issues password reset OTP, user enters new password on `ResetPasswordScreen`.

---

## 5. 5-Step Guided Onboarding Wizard

- **Screens Involved**: [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart)
- **Widgets Used**: `DropdownMenu` (State/City cascader from `IndianLocations.stateCityMap`), `DatePicker`, chip multi-selectors, Safe Space agreement toggle.
- **State Objects**: `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)), `AppState` ([app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart)).
- **Services & APIs**:
  - `PUT /api/auth/onboarding`
- **Local Storage Used**:
  - `StorageHelper.write(key: 'onboarding_completed', value: 'true')`
  - `StorageHelper.write(key: 'user_age', value: effectiveAge.toString())`
  - `SharedPreferences.setInt('user_age', effectiveAge)`
- **Step-by-Step Flow**:
  - **Step 1 (Identity & Demographics)**: User inputs real first name, display alias (screened against `_blockedWords` regex), Date of Birth (must be 18+), State & City from [IndianLocations](file:///e:/Websites/Wehere/lib/core/constants/indian_locations.dart), and Profession.
  - **Step 2 (Interests)**: Multi-select tags (Mental Health, Personal Growth, Reading, Mindfulness, etc.).
  - **Step 3 (Struggles & Feelings)**: Multi-select feelings (Lonely, Burnout, Financial Stress, Grief, etc.).
  - **Step 4 (Support Desired)**: Someone to Talk To, New Friends, Emotional Support, Accountability Partner.
  - **Step 5 (Safe Space Pledge & Notifications)**: Checkbox agreeing to respect and non-harassment; push/email notification toggles.
  - User taps "Finish Setup". Payload is sent via `PUT /api/auth/onboarding`.
  - Flags are written to storage; user enters `MainNavigationShell`.

---

## 6. Peer Discovery Card Swiping & Matching

- **Screens Involved**: [discover_swipe_screen.dart](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart)
- **Widgets Used**: [SwipeableCard](file:///e:/Websites/Wehere/lib/widgets/discovery/swipeable_card.dart) (pan gesture detector, transform translation and rotation), [CardActionButtons](file:///e:/Websites/Wehere/lib/widgets/discovery/card_action_buttons.dart), [MatchCelebrationDialog](file:///e:/Websites/Wehere/lib/widgets/discovery/match_dialog.dart), [ProfileDetailSheet](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart).
- **State Objects**: `AppState` (`cards`, `_swipedHistory`, `lastMatch`, `swipeCount`).
- **Services & APIs**:
  - `GET /api/match/discover` (Loads filtered peer cards matching interests and excluding blocked users).
  - `POST /api/match/swipe` with `{ targetUserId, isRight }`.
- **Local Storage Used**: None.
- **Step-by-Step Flow**:
  1. `DiscoverSwipeScreen` loads cards from `AppState.filteredCards`.
  2. User drags card or taps Connect (Heart) or Pass (X):
     - **Swipe Left (Pass)**: Card slides left, added to `_swipedHistory`. Calls `POST /api/match/swipe` with `isRight: false`.
     - **Swipe Right (Connect)**: Checks free-tier swipe limit (max 5 swipes unless Wehere Plus is subscribed). If permitted, calls `POST /api/match/swipe` with `isRight: true`.
  3. If the other user had also swiped right, backend creates a `Match` record (`status: 'connected'`) and returns `{ isMatch: true, match, conversationId }`.
  4. `AppState` sets `_lastMatch` and launches fullscreen `MatchCelebrationDialog`.
  5. Tapping "Start Chatting" pushes `ChatConversationScreen`.

---

## 7. Real-Time 1-on-1 Peer Chat & Sockets

- **Screens Involved**: [chat_conversation_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart), [chat_list_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_list_screen.dart)
- **Widgets Used**: [ChatBubble](file:///e:/Websites/Wehere/lib/widgets/chat/chat_bubble.dart), [SafeSpaceBanner](file:///e:/Websites/Wehere/lib/widgets/chat/safe_space_banner.dart), [IcebreakerSheet](file:///e:/Websites/Wehere/lib/widgets/chat/icebreaker_sheet.dart), [AvatarWidget](file:///e:/Websites/Wehere/lib/widgets/shared/avatar_widget.dart).
- **State Objects**: `AppState` (`messages`, `_typingStatus`, `_conversationIds`).
- **Services & APIs**:
  - `GET /api/conversations` (Fetches active conversations with last message).
  - `GET /api/conversations/:id/messages` (Historical message list).
  - WebSocket (`socket.io`):
    - Emits: `join_conversation`, `send_message`, `typing`.
    - Listens: `receive_message`, `user_typing`, `identity_revealed`, `name_reveal_requested`.
- **Step-by-Step Flow**:
  1. On screen mount, `AppState.joinConversation(conversationId)` joins the socket room.
  2. User types text. As user types, socket emits `typing`.
  3. User taps send. `AppState.sendMessage()` adds optimistic message to local state and emits `send_message` over WebSocket.
  4. Backend persists message to PostgreSQL `Message` table, increments sender XP by +10, and broadcasts `receive_message` to the room.
  5. Peer receives message instantly; unread badges update across tabs.

---

## 8. Progressive Mutual Name Disclosure Handshake

- **Screens Involved**: [chat_conversation_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart#L194)
- **Widgets Used**: `_buildProgressiveIdentityCard`, reveal dialog prompts.
- **State Objects**: `UserProfile` (`isMutuallyRevealed`, `myRevealed`, `peerRevealed`, `nameDisplayPreference`).
- **Services & APIs**:
  - `GET /api/conversations/:id/disclosure`
  - `POST /api/conversations/:id/reveal-name` (`{ realFirstName }`)
  - `POST /api/conversations/:id/decline-reveal`
  - WebSocket events: `request_reveal_identity`, `name_reveal_requested`, `identity_revealed`.
- **Step-by-Step Flow**:
  1. Users initially chat using pseudonyms (`@displayAlias`).
  2. User A taps "Reveal My Name" inside the conversation banner.
  3. Client emits `request_reveal_identity` and calls `POST /api/conversations/:id/reveal-name`.
  4. Backend marks `userARevealed = true`. User B receives an in-chat system notification: `"Peer requested to exchange names"`.
  5. User B taps "Accept & Reveal". Backend marks `userBRevealed = true`.
  6. Backend emits `identity_revealed` to both users. Real first names unlock in the conversation header with a green verified shield icon (`Icons.verified_user_rounded`).

---

## 9. Daily Mood Check-In & Streak Engine

- **Screens Involved**: [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart#L37)
- **Widgets Used**: 5 mood selection chips (Great, Good, Okay, Low, Struggling) with distinct hex themes from [AppColors](file:///e:/Websites/Wehere/lib/core/theme/app_colors.dart).
- **State Objects**: `AppState` (`todayMood`, `dayStreak`, `weeklyProgress`).
- **Services & APIs**:
  - `POST /api/progress/mood` (`{ mood }`).
  - `GET /api/progress/mood/today`.
  - `GET /api/progress`.
- **Local Storage Used**: None (synced with PostgreSQL `DailyMood` table).
- **Step-by-Step Flow**:
  1. `HomeScreen` displays the daily prompt: "How are you feeling today?".
  2. User selects a mood (e.g. "Great").
  3. `AppState.checkInMood(mood)` executes `POST /api/progress/mood`.
  4. Backend verifies streak continuity via `services/streak.js`: if consecutive day, increments `currentStreak` by 1; awards +15 XP.
  5. Weekly check-in indicator fills Monday–Sunday dots accordingly.

---

## 10. Interactive Box Breathing Visualizer

- **Screens Involved**: [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart#L446)
- **Widgets Used**: Custom animated breathing container with scaling transforms, phase indicator ("Inhale", "Hold", "Exhale", "Rest"), haptic vibrations (`HapticFeedback.lightImpact()`), sound prompt guidance.
- **State Objects**: Screen local state (`_breathingTimer`, `_breathingPhase`, `_cycleCount`).
- **Services & APIs**: None (Client-side mindfulness tool).
- **Step-by-Step Flow**:
  1. User taps "Box Breathing • 4 min exercise" card on `HomeScreen`.
  2. Modal opens with a dark deep-navy breathing surface ([AppColors.deepNavyCard](file:///e:/Websites/Wehere/lib/core/theme/app_colors.dart#L24)).
  3. Visual circle expands smoothly over 4 seconds ("Inhale").
  4. Stays expanded for 4 seconds ("Hold").
  5. Gently contracts over 4 seconds ("Exhale").
  6. Stays contracted for 4 seconds ("Rest").
  7. Cycles repeat until user closes or timer expires.

---

## 11. Private Wellness Journaling & Reflections

- **Screens Involved**: [journal_home_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart), [new_journal_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart), [journal_success_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_success_screen.dart)
- **Widgets Used**: Mood rating selector, `TextFormField` (reflection and gratitude), category pill selector (General, Gratitude, Reflection, Dreams), `ImagePicker` for journal attachments.
- **State Objects**: `AppState` (`journalEntries`, `selectedJournalFilter`, `selectedJournalDate`).
- **Services & APIs**:
  - `GET /api/journal`
  - `POST /api/journal/create` (`{ content, moodScore, category, isPrivate }`)
  - `PUT /api/journal/:id`
  - `DELETE /api/journal/:id`
- **Step-by-Step Flow**:
  1. User taps "New Entry" on `JournalHomeScreen`.
  2. Selects mood (Amazing, Good, Okay, Tired, Stressed) and types thoughts and gratitudes.
  3. Optionally attaches an image (validated <5MB).
  4. Taps "Save Entry". `AppState.addJournalEntry()` calls `POST /api/journal/create`.
  5. Backend persists to PostgreSQL `JournalEntry` table and grants +20 XP.
  6. App navigates to `JournalSuccessScreen` displaying a celebratory 3D notebook graphic and confirmation.

---

## 12. Community Wall Feed & Social Support

- **Screens Involved**: [community_screen.dart](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart)
- **Widgets Used**: `ListView.separated`, [AvatarWidget](file:///e:/Websites/Wehere/lib/widgets/shared/avatar_widget.dart), like/comment action buttons, empty state illustration.
- **State Objects**: `AppState` (`communityPosts`, `_postComments`).
- **Services & APIs**:
  - `GET /api/community`
  - `POST /api/community` (`{ topic, content }`)
  - `POST /api/community/:id/like`
  - `GET /api/community/:id/comments`
  - `POST /api/community/:id/comments` (`{ commentText }`)
- **Step-by-Step Flow**:
  1. User navigates to Community from `HomeScreen` quick links or drawer.
  2. App displays public peer posts tagged by topics (e.g. "Mindfulness", "Anxiety").
  3. User taps like (Heart): `AppState.togglePostLike()` sends `POST /api/community/:id/like`, optimistic counter increments.
  4. User taps comment: opens comments modal, sends text to `/api/community/:id/comments`.

---

## 13. Gamification XP, Levels & Milestone Badges

- **Screens Involved**: [progress_dashboard_screen.dart](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart)
- **Widgets Used**: XP progress bar (`LinearProgressIndicator`), interactive goals checklist, milestone grid displaying locked/unlocked badges.
- **State Objects**: `AppState` (`currentXp`, `targetXp`, `userLevel`, `goals`, `milestones`).
- **Services & APIs**:
  - `GET /api/progress`
  - `GET /api/goals`
  - `POST /api/goals`
  - `PUT /api/goals/:id/toggle`
- **Local Storage Used**: `StorageHelper.read/write` for unlocked milestone IDs (`persisted_milestone_keys`).
- **Step-by-Step Flow**:
  1. Any positive action (journaling, checking mood, chatting, completing goals) rewards XP.
  2. When `currentXp >= targetXp`, user levels up (`_userLevel++`, new target XP calculated).
  3. `AppState.checkMilestones()` runs verification rules (e.g. 1st journal entry unlocks "First Step 🌱", 7-day streak unlocks "Consistency Champion 🏆").
  4. Badges unlock with sound and are persisted across app sessions.

---

## 14. Crisis SOS & Emergency Resources Hub

- **Screens Involved**: [sos_help_screen.dart](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart)
- **Widgets Used**: [SosPulsingButton](file:///e:/Websites/Wehere/lib/widgets/sos/sos_pulsing_button.dart) (repeating animated radar waves), direct phone launch buttons, emergency contact list manager dialog.
- **State Objects**: `AppState` (`emergencyContacts`, `crisisDetected`).
- **Services & APIs**:
  - `GET /api/sos/resources`
  - `GET /api/sos/contacts`
  - `POST /api/sos/contacts` (`{ name, phone, relationship }`)
  - `DELETE /api/sos/contacts/:id`
- **Native Platform Services**:
  - `url_launcher` via `launchUrl(Uri.parse('tel:$cleanNumber'))`.
- **Step-by-Step Flow**:
  1. Tapping SOS on home or in emergencies opens `SosHelpScreen`.
  2. User can immediately tap any 24/7 hotline (Tele-MANAS `14416`, KIRAN `1800-599-0019`, Vandrevala `+91 9999 666 555`, National Emergency `112`) to launch system phone dialer.
  3. Tapping the big pulsing SOS button initiates an emergency countdown (5 seconds to cancel).
  4. If countdown expires, client triggers direct emergency contact dispatch.

---

## 15. Profile Management & Anonymity Settings

- **Screens Involved**: [profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart), [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart)
- **Widgets Used**: [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) (reorderable slots, image cropper integration), `RadioListTile` (name display preference selector), state/city dropdown menus.
- **State Objects**: `AppState` (`currentUser`).
- **Services & APIs**:
  - `GET /api/users/me`
  - `PUT /api/users/me`
  - `POST /api/users/me/photos` (`upload.single('photo')`)
  - `DELETE /api/users/me/photos`
  - `PUT /api/users/me/photos/order`
  - `POST /api/auth/change-password`
  - `DELETE /api/users/me` (Schedules account deletion)
- **Step-by-Step Flow**:
  1. User edits bio, age, state, city, profession, and name display preference (`DISPLAY_NAME_ONLY` vs `FIRST_NAME_PUBLIC`).
  2. Tapping save sends `PUT /api/users/me`.
  3. User can crop and upload new photos via [PhotoGrid](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart).
  4. User can request account deletion: backend schedules hard purge in 7 days (`scheduledDeletionDate`).

---

## 16. Wehere Plus Premium Subscription & Free Tier Gating

- **Screens Involved**: [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart)
- **Widgets Used**: Plan selector tabs (Standard vs. Student), student ID upload modal, payment method bottom sheet (UPI / Card).
- **State Objects**: `AppState` (`isSubscribed`, `_swipeCount`, `canRewind`).
- **Services & APIs**: None currently (Mocked client-side).
- **Step-by-Step Flow**:
  1. Free users are restricted to 5 swipes per session and blocked from rewinding passed cards.
  2. Once limit is hit, `PricingScreen` is displayed automatically.
  3. Student plan requires uploading College ID (must show college name & age).
  4. Selecting UPI/Card triggers `_finalizeSubscription()`, sets `isSubscribed = true` in `AppState`.
  5. Banner ads disappear and swipe deck limits unlock.

---

## 17. Campus & Institutional Partnerships Hub

- **Screens Involved**: [campus_corporate_screen.dart](file:///e:/Websites/Wehere/lib/screens/institutional/campus_corporate_screen.dart)
- **Widgets Used**: `TextFormField` for institutional access code and corporate partnership inquiry form.
- **State Objects**: Local screen state (`_codeController`, `_submittingInquiry`).
- **Services & APIs**: None (Client-side mock with 900ms simulated network delay).
- **Step-by-Step Flow**:
  1. College student enters college access code (e.g. `CAMPUS2026`).
  2. App displays verified wellness hub access message.
  3. Corporate wellness managers submit company inquiry form; displays 24h follow-up confirmation dialog.

---

## 18. Peer Safety: Reporting & Blocking

- **Screens Involved**: [profile_detail_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart), [chat_conversation_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart)
- **Widgets Used**: Alert dialog with category radios (Harassment, Inappropriate Photo, Impersonation, Spam, Harmful Content).
- **State Objects**: `AppState` (`reportAndBlockPeer`).
- **Services & APIs**:
  - `POST /api/users/:id/block`
  - `POST /api/users/:id/report`
- **Step-by-Step Flow**:
  1. User selects "Report & Block" on peer profile or chat menu.
  2. Selects violation reason and optional description.
  3. `AppState.reportAndBlockPeer(peerId, reason)` fires both `/block` and `/report` endpoints in parallel.
  4. Peer is immediately purged from user's match deck and conversation list.

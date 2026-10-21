# Functions & Class Reference: Wehere Codebase

An exhaustive technical reference cataloging every class, widget, controller, model, utility, and method across all Dart source files in `lib/`.

---

## 1. Core Application Entry & Navigation

### `lib/main.dart`
- **Function `main()`**
  - **File**: [main.dart](file:///e:/Websites/Wehere/lib/main.dart#L10)
  - **Purpose**: App startup entry point. Ensures Flutter bindings are initialized and configures transparent dark system status bars.
  - **Inputs**: None.
  - **Outputs**: `void`.
  - **Calls**: `WidgetsFlutterBinding.ensureInitialized()`, `SystemChrome.setSystemUIOverlayStyle()`, `runApp()`.
  - **Called By**: Flutter engine bootstrapper.
- **Class `WehereApp`**
  - **File**: [main.dart](file:///e:/Websites/Wehere/lib/main.dart#L21)
  - **Purpose**: Root `StatelessWidget` wrapping the application inside a `MultiProvider` for `AuthNotifier` and `AppState`.
  - **Inputs**: `Key? key`.
  - **Outputs**: `Widget` (`MultiProvider` -> `MaterialApp`).
  - **Calls**: `AuthNotifier.initializeSession()`, `AppTheme.lightTheme`, `AppRouter.onGenerateRoute`.
  - **Called By**: `runApp()` in `main()`.

---

### `lib/core/routing/app_routes.dart`
- **Class `AppRoutes`**
  - **File**: [app_routes.dart](file:///e:/Websites/Wehere/lib/core/routing/app_routes.dart#L1)
  - **Purpose**: Static dictionary containing all 17 named URL-style route identifiers.
  - **Constants**: `splash`, `walkthrough`, `login`, `signup`, `otp`, `resetPassword`, `onboarding`, `main`, `home`, `discover`, `reflect`, `community`, `chats`, `chatConversation`, `newJournal`, `journalSuccess`, `progress`, `profile`, `sos`, `institutional`.
  - **Calls**: None.
  - **Called By**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart), all UI navigation actions.

---

### `lib/core/routing/app_router.dart`
- **Class `AppRouter`**
  - **File**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L28)
  - **Purpose**: Route switch and generator factory.
- **Method `AppRouter.onGenerateRoute(RouteSettings settings)`**
  - **File**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L29)
  - **Purpose**: Inspects `settings.name` and constructs the appropriate animated page route.
  - **Inputs**: `RouteSettings settings`.
  - **Outputs**: `Route<dynamic>`.
  - **Calls**: `_buildPageRoute()`, `_buildProtectedRoute()`, `_errorRoute()`.
  - **Called By**: `MaterialApp.onGenerateRoute` in `main.dart`.
- **Method `AppRouter._buildProtectedRoute({required Widget Function() builder, required RouteSettings settings})`**
  - **File**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L146)
  - **Purpose**: Enforces reactive session state rules (`AuthStatus.unauthenticated` -> `LoginScreen`, `AuthStatus.unverified` -> `OtpVerificationScreen`, incomplete onboarding -> `OnboardingFlowScreen`).
  - **Inputs**: `builder` callback, `settings`.
  - **Outputs**: `Route<dynamic>` (`MaterialPageRoute`).
  - **Calls**: `context.watch<AuthNotifier>()`.
  - **Called By**: `AppRouter.onGenerateRoute` for `/main` and `/onboarding/wizard`.
- **Method `AppRouter._buildPageRoute(Widget page, RouteSettings settings, {PageTransitionType transitionType})`**
  - **File**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L173)
  - **Purpose**: Constructs a `PageRouteBuilder` with `Curves.easeOutCubic` slide/fade transitions.
  - **Inputs**: `Widget page`, `RouteSettings settings`, `PageTransitionType transitionType`.
  - **Outputs**: `Route<dynamic>`.
  - **Called By**: `AppRouter.onGenerateRoute`.
- **Method `AppRouter._errorRoute(String message)`**
  - **File**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L203)
  - **Purpose**: Renders fallback error page when route is not found or arguments are missing.
  - **Inputs**: `String message`.
  - **Outputs**: `Route<dynamic>`.

---

## 2. Core Network, Theme & Utilities

### `lib/core/network/api_client.dart`
- **Class `ApiClient`**
  - **File**: [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L7)
  - **Purpose**: Configures `Dio` instance, base URLs, timeouts, authorization header injection, and auth event streams.
- **Field `Dio dio`**: Configured HTTP client instance.
- **Stream `authEventStream`**: Broadcast stream emitting `AuthEvent.loggedOut` or `AuthEvent.emailNotVerified`.
- **Constructor `ApiClient()`**
  - **File**: [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L13)
  - **Purpose**: Attaches `InterceptorsWrapper` to inject `Bearer $token` from `StorageHelper` and intercept HTTP 401/403.
  - **Calls**: `StorageHelper.read(key: 'jwt_token')`, `StorageHelper.delete(key: 'jwt_token')`.
- **Globals `apiClientInstance` & `apiClient`**
  - **File**: [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L50-L51)
  - **Purpose**: Exported singletons used throughout `AppState` and `AuthNotifier`.

---

### `lib/core/utils/storage_helper.dart`
- **Class `StorageHelper`**
  - **File**: [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L5)
  - **Purpose**: Hardware-backed secure storage wrapper with SharedPreferences fallback.
- **Method `StorageHelper.read({required String key})`**
  - **File**: [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L8)
  - **Inputs**: `key` (`String`).
  - **Outputs**: `Future<String?>`.
  - **Calls**: `FlutterSecureStorage.read()`, falls back to `SharedPreferences.getString()` on `PlatformException`.
- **Method `StorageHelper.write({required String key, required String value})`**
  - **File**: [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L20)
  - **Inputs**: `key` (`String`), `value` (`String`).
  - **Outputs**: `Future<void>`.
  - **Calls**: `FlutterSecureStorage.write()`, falls back to `SharedPreferences.setString()`.
- **Method `StorageHelper.delete({required String key})`**
  - **File**: [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L29)
  - **Inputs**: `key` (`String`).
  - **Outputs**: `Future<void>`.
  - **Calls**: `FlutterSecureStorage.delete()`, falls back to `SharedPreferences.remove()`.

---

### `lib/core/utils/ui_utils.dart`
- **Class `UiUtils`**
  - **File**: [ui_utils.dart](file:///e:/Websites/Wehere/lib/core/utils/ui_utils.dart#L4)
  - **Purpose**: UI notification helper for rendering non-intrusive floating top snackbars over modal sheets.
- **Method `UiUtils.showTopSnackBar(BuildContext context, String message, {bool isError = true})`**
  - **File**: [ui_utils.dart](file:///e:/Websites/Wehere/lib/core/utils/ui_utils.dart#L5)
  - **Inputs**: `BuildContext context`, `String message`, optional `bool isError`.
  - **Outputs**: `void`.
  - **Calls**: `Overlay.of(context).insert()`, auto-dismisses after 3 seconds.
  - **Called By**: `login_screen.dart`, `signup_screen.dart`, `reset_password_screen.dart`.

---

### `lib/core/constants/app_constants.dart`
- **Class `AppConstants`**
  - **File**: [app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart#L1)
  - **Purpose**: Static constant store for backend URLs, disclaimers, interest tags, onboarding prompts, and verified crisis helplines.
  - **Key Static Constants**:
    - `apiBaseUrl`: Defaults to `'http://200.97.165.22:4000/api'`.
    - `appName`: `'Wehere'`.
    - `safeSpaceNotice`: Mandatory community pledge text.
    - `therapyDisclaimer`: Legal distinction between peer support and clinical crisis services.
    - `interests`: 15 default wellness tags.
    - `feelingOptions`: 12 struggle/feeling options.
    - `supportTypes`: 5 support relationship archetypes.
    - `crisisHelplines`: 7 Indian and international 24/7 helplines.

---

### `lib/core/constants/indian_locations.dart`
- **Class `IndianLocations`**
  - **File**: [indian_locations.dart](file:///e:/Websites/Wehere/lib/core/constants/indian_locations.dart#L1)
  - **Purpose**: Comprehensive map of all 28 Indian States and 8 Union Territories mapped to their respective major cities.
  - **Constant `stateCityMap`**: `Map<String, List<String>>` containing ~400 Indian municipal cities.
  - **Called By**: [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart), [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart).

---

### `lib/core/theme/`
- **Class `AppColors`** ([app_colors.dart](file:///e:/Websites/Wehere/lib/core/theme/app_colors.dart)): 50+ color constants including primary indigo (`0xFF4F46E5`), surface neutrals, mood tracking colors (Great, Good, Okay, Low, Struggling), gradients (`primaryGradient`, `heroCardGradient`, `sosGlowGradient`).
- **Class `AppTextStyles`** ([app_text_styles.dart](file:///e:/Websites/Wehere/lib/core/theme/app_text_styles.dart)): Font definitions using `GoogleFonts.newsreader()` (serif) and `GoogleFonts.plusJakartaSans()` (sans-serif).
- **Class `AppTheme`** ([app_theme.dart](file:///e:/Websites/Wehere/lib/core/theme/app_theme.dart)): Material 3 `ThemeData` configuring buttons, input fields, app bars, and card borders.

---

## 3. Data Models (`lib/models/`)

### `lib/models/user_profile.dart`
- **Class `UserProfile`**
  - **File**: [user_profile.dart](file:///e:/Websites/Wehere/lib/models/user_profile.dart#L1)
  - **Purpose**: Model representing a user profile with progressive identity disclosure fields.
  - **Fields**: `id`, `name`, `displayName`, `realFirstName`, `legalFullName`, `handle`, `nameDisplayPreference`, `isMutuallyRevealed`, `myRevealed`, `peerRevealed`, `age`, `location`, `profession`, `bio`, `avatarUrl`, `images`, `isVerified`, `isOnline`, `moodStatus`, `matchPercentage`, `interests`, `feelings`, `supportTypes`, `values`, `isAnonymous`, `trustLevel`.
  - **Getter `cardName`**: Evaluates `nameDisplayPreference` to return either `realFirstName` or `displayName`/`name`.
  - **Getter `displayAlias`**: Returns `displayName` or falls back to `name`.
  - **Method `copyWith(...)`**: Returns cloned instance with updated parameters.

### `lib/models/match_card.dart`
- **Class `MatchCard`**
  - **File**: [match_card.dart](file:///e:/Websites/Wehere/lib/models/match_card.dart#L3)
  - **Purpose**: Pairs a `UserProfile` with card-specific discovery attributes (`isNewHere`, `commonInterests`, `compatibilityReason`).

### `lib/models/chat_message.dart`
- **Class `ChatMessage`**
  - **File**: [chat_message.dart](file:///e:/Websites/Wehere/lib/models/chat_message.dart#L1)
  - **Purpose**: Message entity storing `id`, `senderId`, `text`, `timestamp`, `isMine`, `isDelivered`, `isRead`, `isIcebreaker`, `isVoiceNote`, `voiceDurationSeconds`, `isCrisisIntervention`.

### `lib/models/journal_entry.dart`
- **Class `JournalEntry`**
  - **File**: [journal_entry.dart](file:///e:/Websites/Wehere/lib/models/journal_entry.dart#L1)
  - **Purpose**: Reflection entity storing `id`, `date`, `mood`, `thought`, `gratitude`, `category`, `photoUrl`, `isPrivate`.

### `lib/models/community_post.dart`
- **Class `CommunityPost`**: Public community post entity with like/comment counters and author badge.
- **Class `CommunityComment`**: Comment entity attached to a post.
- **Class `WellnessGoal`**: Self-care goal with completion toggle and progress float (`0.0` to `1.0`).

### `lib/models/emergency_contact.dart`
- **Class `EmergencyContact`**: Personal SOS contact model storing `id`, `name`, `phone`, `relationship`.

### `lib/models/milestone.dart`
- **Class `Milestone`**: Gamification badge model. Includes strict unlock condition check: `isUnlocked => _isUnlockedFlag && (targetProgress == 0 || currentProgress >= targetProgress)`.

### `lib/models/notification.dart`
- **Class `UserNotification`**: In-app push notification item (`id`, `title`, `content`, `type`, `isRead`, `createdAt`).

### `lib/models/config_options.dart`
- **Class `ConfigOption`**: Server-driven configuration item (`id`, `label`).
- **Class `ConfigLimits`**: Server-driven limit boundaries (`minPhotos`, `maxPhotos`, `bioMaxLength`, `maxInterests`, `maxFeelings`, `maxSupportTypes`, `locationMaxLength`, `pseudonymMaxLength`).

---

## 4. State Holders (`lib/state/`)

### `lib/state/auth_notifier.dart`
- **Class `AuthNotifier`** (extends `ChangeNotifier`)
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L11)
  - **Purpose**: Session state machine, auth API communications, token persistence.
- **Enum `AuthStatus`**: `{ initializing, unauthenticated, unverified, authenticated }`.
- **Method `initializeSession()`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L50)
  - **Purpose**: Reads stored JWT token and user ID; queries `GET /api/users/me` to verify session and onboarding state.
- **Method `login(String email, String password)`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L89)
  - **Purpose**: Calls `POST /api/auth/login`. Handles `EMAIL_NOT_VERIFIED` 403 response code by switching status to `unverified`.
- **Method `register(String name, String email, String password, ...)`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L170)
  - **Purpose**: Sends multipart form data with images to `POST /api/auth/signup`. Sets `_pendingSignupToken`.
- **Method `signup(...)`**: Alias to `register(...)`.
- **Method `verifyOtp(String pin)`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L229)
  - **Purpose**: Submits OTP to `POST /api/auth/otp/verify`. Saves confirmed JWT and user ID.
- **Method `completeOnboarding(...)`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L298)
  - **Purpose**: Submits preferences to `PUT /api/auth/onboarding` and marks `onboarding_completed` in storage.
- **Method `logout()`**
  - **File**: [auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart#L338)
  - **Purpose**: Purges `jwt_token`, `user_id`, `user_email`, `user_age`, and resets state to `unauthenticated`.

---

### `lib/state/app_state.dart`
- **Class `AppState`** (extends `ChangeNotifier`)
  - **File**: [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L18)
  - **Purpose**: Main application state controller managing deck, chats, journals, streaks, XP, goals, and websockets.
- **Methods Reference**:
  - `fetchCurrentUser()`: Queries `GET /api/users/me` and parses user profile.
  - `fetchConfigOptions()`: Queries `GET /api/config/options` for admin-configured chips.
  - `fetchBackendData()`: Master orchestrator loading conversations, journals, goals, progress streaks, and notifications in parallel.
  - `initSocket(String token)`: Initializes `socket.io-client`, attaches JWT, registers listeners for `receive_message`, `user_typing`, `identity_revealed`.
  - `joinConversation(String conversationId)`: Emits socket event `join_conversation`.
  - `sendMessage(String receiverId, String text, String conversationId, ...)`: Emits socket event `send_message` and adds optimistic message to state.
  - `sendVoiceNote(String receiverId, int durationSeconds)`: Emits voice note message.
  - `swipeLeft()`: Records pass, sends `POST /api/match/swipe` with `isRight: false`.
  - `swipeRight()`: Gated by `canSwipe()`. Sends `POST /api/match/swipe` with `isRight: true`. If match, sets `_lastMatch`.
  - `rewindLastSwipe()`: Gated by `isSubscribed`. Restores previous card from `_swipedHistory`.
  - `checkInMood(String mood)`: Calls `POST /api/progress/mood`. Updates streak and grants +15 XP.
  - `addJournalEntry(...)`: Calls `POST /api/journal/create`. Updates entries list and grants +20 XP.
  - `updateJournalEntry(...)`: Calls `PUT /api/journal/:id`.
  - `deleteJournalEntry(String id)`: Calls `DELETE /api/journal/:id`.
  - `toggleGoal(String goalId)`: Calls `PUT /api/goals/:id/toggle`. Updates progress and grants +10 XP.
  - `addGoal(...)`: Calls `POST /api/goals`.
  - `togglePostLike(String postId)`: Calls `POST /api/community/:id/like`.
  - `addComment(...)`: Calls `POST /api/community/:id/comments`.
  - `addEmergencyContact(...)`: Calls `POST /api/sos/contacts`.
  - `removeEmergencyContact(String id)`: Calls `DELETE /api/sos/contacts/:id`.
  - `reportAndBlockPeer(String peerId, String reason)`: Calls `/block` and `/report` concurrently.
  - `fetchConversationDisclosure(String peerId)`: Calls `GET /api/conversations/:id/disclosure`.
  - `revealName(...)`: Calls `POST /api/conversations/:id/reveal-name`.
  - `declineReveal(...)`: Calls `POST /api/conversations/:id/decline-reveal`.
  - `updateNameDisplayPreference(String preference)`: Calls `PUT /api/users/me` with preference.
  - `setAnonymity(bool val)`: Calls `PUT /api/users/me` with `{ isAnonymous: val }`.
  - `changePassword(...)`: Calls `POST /api/auth/change-password`.
  - `deleteAccount()`: Calls `DELETE /api/users/me` (schedules account deletion).
  - `markNotificationsRead()`: Calls `PUT /api/notifications/read-all`.
  - `checkMilestones()`: Evaluates user activity counts and unlocks badge achievements.

---

## 5. Screen Widgets (`lib/screens/`)

| Widget Name | File Path | Type | Purpose & Main Methods |
| :--- | :--- | :--- | :--- |
| `SplashScreen` | [splash_screen.dart](file:///e:/Websites/Wehere/lib/screens/splash/splash_screen.dart) | `StatefulWidget` | Shows emblem, runs `_checkAuthAndNavigate()` after 2-second delay. |
| `WalkthroughScreen` | [walkthrough_screen.dart](file:///e:/Websites/Wehere/lib/screens/walkthrough/walkthrough_screen.dart) | `StatefulWidget` | 4-slide carousel with indicator pills; marks walkthrough seen. |
| `LoginScreen` | [login_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart) | `StatefulWidget` | Credential form, `_handleForgotPassword()`, `_sendPasswordResetOtp()`. |
| `SignUpScreen` | [signup_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart) | `StatefulWidget` | Registration form, 2-photo picker, password validator, terms checkbox. |
| `OtpVerificationScreen` | [otp_verification_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) | `StatefulWidget` | 6 discrete PIN boxes, lifecycle time-synced 60s cooldown timer. |
| `ResetPasswordScreen` | [reset_password_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart) | `StatefulWidget` | Form taking 6-digit recovery code and new password. |
| `OnboardingFlowScreen` | [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart) | `StatefulWidget` | 5-step wizard with State/City cascading dropdowns, 18+ age validator. |
| `MainNavigationShell` | [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart) | `StatefulWidget` | `IndexedStack` wrapper with double-back exit pop interceptor. |
| `HomeScreen` | [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart) | `StatelessWidget` | Dashboard: mood check-in, Box Breathing modal, streak tracker, quick links. |
| `DiscoverSwipeScreen` | [discover_swipe_screen.dart](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) | `StatefulWidget` | Swiping deck; triggers match celebration dialog. |
| `JournalHomeScreen` | [journal_home_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) | `StatelessWidget` | Reflection feed, calendar date picker, category filter. |
| `NewJournalScreen` | [new_journal_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) | `StatefulWidget` | Creation form with mood chips, thought text, gratitude, image picker. |
| `JournalSuccessScreen` | [journal_success_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_success_screen.dart) | `StatelessWidget` | Affirmation screen with 3D notebook artwork and review options. |
| `ChatListScreen` | [chat_list_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_list_screen.dart) | `StatefulWidget` | Searchable match list, online indicators, unread message badges. |
| `ChatConversationScreen`| [chat_conversation_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) | `StatefulWidget` | Active chat: messages, voice notes, mutual name reveal handshake. |
| `CommunityScreen` | [community_screen.dart](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) | `StatelessWidget` | Public community wall, likes, comments, empty state illustration. |
| `ProgressDashboardScreen`| [progress_dashboard_screen.dart](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) | `StatefulWidget` | XP level progression, goals checklist, unlocked milestone badges. |
| `ProfileScreen` | [profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) | `StatelessWidget` | User stats, chips summary, settings options (logout, delete account). |
| `EditProfileScreen` | [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart) | `StatefulWidget` | Photo grid, state/city dropdowns, name display preference radio. |
| `SosHelpScreen` | [sos_help_screen.dart](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) | `StatelessWidget` | Crisis helplines, pulsing SOS button, 5-second countdown alert. |
| `CampusCorporateScreen` | [campus_corporate_screen.dart](file:///e:/Websites/Wehere/lib/screens/institutional/campus_corporate_screen.dart) | `StatefulWidget` | Institutional campus access code verifier and corporate inquiry form. |
| `PricingScreen` | [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart) | `StatefulWidget` | Wehere Plus plans, student ID verification modal, mock UPI payment. |

---

## 6. Shared & Reusable Widgets (`lib/widgets/`)

| Widget Name | File Path | Purpose |
| :--- | :--- | :--- |
| `MockBannerAd` | [mock_banner_ad.dart](file:///e:/Websites/Wehere/lib/widgets/mock_banner_ad.dart) | Displays placeholder reward/banner ad; hidden if `isSubscribed == true`. |
| `ChatBubble` | [chat_bubble.dart](file:///e:/Websites/Wehere/lib/widgets/chat/chat_bubble.dart) | Renders incoming/outgoing chat messages, delivery checks, and voice bars. |
| `IcebreakerSheet` | [icebreaker_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/chat/icebreaker_sheet.dart) | Bottom sheet offering 5 curated mental wellness conversation starters. |
| `SafeSpaceBanner` | [safe_space_banner.dart](file:///e:/Websites/Wehere/lib/widgets/chat/safe_space_banner.dart) | In-chat warning banner reminding users of kindness and community rules. |
| `WellnessTipBar` | [wellness_tip_bar.dart](file:///e:/Websites/Wehere/lib/widgets/chat/wellness_tip_bar.dart) | Horizontal tip pill displayed atop chat screen. |
| `AnimatedPressable` | [animated_pressable.dart](file:///e:/Websites/Wehere/lib/widgets/common/animated_pressable.dart) | Scales down to `0.96` on tap down and springs back on release. |
| `AnimatedPulse` | [animated_pulse.dart](file:///e:/Websites/Wehere/lib/widgets/common/animated_pulse.dart) | Looping scale pulse animation for logos and badges. |
| `MoodChip` | [mood_chip.dart](file:///e:/Websites/Wehere/lib/widgets/common/mood_chip.dart) | Selectable pill chip for mood check-ins. |
| `TagChip` | [tag_chip.dart](file:///e:/Websites/Wehere/lib/widgets/common/tag_chip.dart) | Read-only or removable category/interest pill chip. |
| `WehereButton` | [wehere_button.dart](file:///e:/Websites/Wehere/lib/widgets/common/wehere_button.dart) | Full-width rounded primary elevated button with loading indicator. |
| `WehereCard` | [wehere_card.dart](file:///e:/Websites/Wehere/lib/widgets/common/wehere_card.dart) | Standard white surface card with rounded corners and border. |
| `CardActionButtons` | [card_action_buttons.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/card_action_buttons.dart) | Pass (X), Connect (Heart), and Super-Support (Star) floating action row. |
| `MatchCelebrationDialog`| [match_dialog.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/match_dialog.dart) | Fullscreen match celebration dialog with glowing side-by-side avatars. |
| `ProfileDetailSheet` | [profile_detail_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart) | Detailed peer profile sheet with photos, values, and block/report actions. |
| `SwipeableCard` | [swipeable_card.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/swipeable_card.dart) | Draggable card with rotation physics and CONNECT/PASS stamp overlays. |
| `PhotoGrid` | [photo_grid.dart](file:///e:/Websites/Wehere/lib/widgets/profile/photo_grid.dart) | Reorderable 6-slot photo upload grid with image cropping integration. |
| `AvatarWidget` | [avatar_widget.dart](file:///e:/Websites/Wehere/lib/widgets/shared/avatar_widget.dart) | Circle avatar with network fallback, asset fallback, and initials badge. |
| `SosPulsingButton` | [sos_pulsing_button.dart](file:///e:/Websites/Wehere/lib/widgets/sos/sos_pulsing_button.dart) | Animated glowing red circular button with pulsing ripple rings. |

---

## 7. Audit of Unused Code, Deprecations & Duplications

1. **Unused State Variable in `AppState`**:
   - `int _unreadNotifications = 0` in [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L218) is declared as a private field, but the getter `unreadNotifications` calculates it dynamically from `_notifications.where((n) => !n.isRead).length`. The field `_unreadNotifications` is never written to or read directly.
2. **Deprecated No-Op Method in `AppState`**:
   - `void toggleWeekCheckIn(int idx)` on [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L213-L215) is completely empty with comment: `// Deprecated: UI now reads weeklyProgress from backend`. It should be removed.
3. **Hardcoded Machine Path**:
   - `PricingScreen` in [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L222) references a local machine path (`C:/Users/paras/...`). It will fail on all real devices and fallback to `errorBuilder`.
4. **Duplicate Profession Lists**:
   - The list `professionOptions` is duplicated verbatim between [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart#L49-L59) and [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart#L33-L43). It should be centralized in `AppConstants`.
5. **Duplicate Blocked Words Regex**:
   - The regex `_blockedWords` is declared locally in [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart#L39) and not shared with `edit_profile_screen.dart`.

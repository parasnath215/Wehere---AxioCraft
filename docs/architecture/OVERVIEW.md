# Architecture Overview: Wehere Mobile & Ecosystem

## 1. What the App Does (In Plain Language)
**Wehere** is a peer-to-peer mental wellness connection and emotional support mobile application designed for young adults, college students, and professionals in India (and internationally). Inspired by card-swiping discovery interfaces (Tinder/Bumble), Wehere removes superficial romantic dating dynamics and replaces them with empathy-first, safe-space peer support.

Key pillars of the platform:
- **Card-Swiping Discovery**: Users view peer profiles displaying real-time moods, struggles, support goals, and shared values (rather than vanity metrics). Swiping right requests a mutual peer connection; swiping left passes gently.
- **Mutual Safe Connections**: When two users like each other, a match is created. Both users can break the ice using guided mental wellness prompts or direct messaging.
- **Progressive Identity Disclosure**: To prevent harassment, catfishing, and privacy anxiety, users start completely anonymous or under a chosen alias/pseudonym. Real names and verified first names are only disclosed if both users mutually agree via a two-way disclosure handshake.
- **Self-Care & Daily Reflections**: In-app private journaling, mood check-ins (1–5 scale), interactive 4-4-4-4 Box Breathing visualizer, and wellness habit goals.
- **Community Wall**: A supportive public feed where users share vulnerability, reflections, and encouragement.
- **Emergency Crisis Hub (SOS)**: One-tap access to 24/7 verified Indian helplines (Tele-MANAS, KIRAN, Vandrevala Foundation, AASRA, NIMHANS, 112) and personal emergency contact dispatch with an automated countdown trigger.
- **Wehere Plus Subscription**: Tiered student and standard plans offering ad-free experiences, unlimited deck rewinds, and expanded preference customizations.
- **Institutional Partnerships**: Dedicated access for colleges and corporate wellness programs to onboard campuses with institutional codes.

---

## 2. Flutter & Dart Versions, and Pubspec Dependencies

### SDK Versions (`pubspec.yaml`)
- **Dart SDK**: `>=3.0.0 <4.0.0` ([pubspec.yaml](file:///e:/Websites/Wehere/pubspec.yaml#L7))
- **Flutter Framework**: Material 3 enabled (`uses-material-design: true` on [pubspec.yaml](file:///e:/Websites/Wehere/pubspec.yaml#L30))

### Every Dependency in `pubspec.yaml` and Its Technical Purpose
| Package Name | Version Constraint | Exact Purpose in Codebase | Citing File / Key Usages |
| :--- | :--- | :--- | :--- |
| `flutter` | `sdk: flutter` | Core Flutter SDK framework for rendering, layout, animation, and platform interaction. | [main.dart](file:///e:/Websites/Wehere/lib/main.dart#L1) |
| `cupertino_icons` | `^1.0.8` | Provides iOS-style Cupertino icon set assets. | [pubspec.yaml](file:///e:/Websites/Wehere/pubspec.yaml#L12) |
| `google_fonts` | `^6.2.1` | Loads modern typography at runtime (`Newsreader` serif for headings and `Plus Jakarta Sans` for UI copy/chips). | [app_text_styles.dart](file:///e:/Websites/Wehere/lib/core/theme/app_text_styles.dart#L2) |
| `provider` | `^6.1.2` | Reactive dependency injection and state management for `AuthNotifier` and `AppState`. | [main.dart](file:///e:/Websites/Wehere/lib/main.dart#L3), [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L18) |
| `intl` | `^0.19.0` | Date formatting and timestamp stringification (`DateFormat`). | [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart#L4), [journal_home_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart#L3) |
| `dio` | `^5.11.1` | Robust HTTP networking client with custom interceptors for JWT token injection and 401/403 event handling. | [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L2) |
| `flutter_secure_storage` | `^11.2.0` | Hardware-backed encrypted keychain/keystore storage for sensitive JWT session tokens and user credentials. | [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L2) |
| `shared_preferences` | `^2.5.5` | Key-value disk persistence fallback for user age, walkthrough status, and draft form states. | [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart#L3) |
| `image_picker` | `^1.2.3` | Camera and gallery photo selection for signup identification, profile pictures, and journal memories. | [signup_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart#L9), [new_journal_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart#L4) |
| `socket_io_client` | `^3.1.6` | Real-time WebSocket connection for 1-on-1 instant messaging, typing indicators, and mutual identity reveal handshakes. | [app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart#L10) |
| `image_cropper` | `^12.2.1` | Native Android/iOS image crop activity for squaring and optimizing profile avatar uploads. | [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L30) |
| `url_launcher` | `^6.3.3` | System intent launcher to dial crisis hotline telephone numbers (`tel:14416`), send SMS, and open web URLs. | [sos_help_screen.dart](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart#L1) |

### Development Dependencies
| Package Name | Version Constraint | Exact Purpose |
| :--- | :--- | :--- |
| `flutter_test` | `sdk: flutter` | Unit and widget testing framework. |
| `flutter_lints` | `^3.0.0` | Recommended static analysis rules for Dart and Flutter. |

---

## 3. Architecture Pattern in Use & Consistency Evaluation

### Architecture Style: Feature-Driven Screen Layer with Centralized Multi-Domain `ChangeNotifier`
The codebase does **not** follow a strict Clean Architecture (domain/usecase/data/presentation) or pure BLoC pattern. Instead, it implements a **Hybrid Layered & Feature-Oriented Provider Pattern**:

1. **Presentation Layer (`lib/screens/`, `lib/widgets/`)**:
   - Organized primarily by business features: `auth/`, `chat/`, `community/`, `discover/`, `home/`, `institutional/`, `journal/`, `onboarding/`, `profile/`, `progress/`, `sos/`, `splash/`, `walkthrough/`.
   - Reusable atoms and molecules reside in `lib/widgets/` (split into `common/`, `chat/`, `discovery/`, `profile/`, `sos/`, `subscription/`, `shared/`).
2. **State & Orchestration Layer (`lib/state/`)**:
   - `AuthNotifier` ([auth_notifier.dart](file:///e:/Websites/Wehere/lib/state/auth_notifier.dart)): Dedicated state machine handling session lifecycle (`initializing`, `unauthenticated`, `unverified`, `authenticated`), JWT storage, registration multipart uploads, OTP verification, and onboarding completion.
   - `AppState` ([app_state.dart](file:///e:/Websites/Wehere/lib/state/app_state.dart)): A monolithic state holder (~1,800 lines) that aggregates cards, chat sockets, journals, goals, community feeds, emergency contacts, user XP gamification, and subscription status.
3. **Core Infrastructure Layer (`lib/core/`)**:
   - `core/network/api_client.dart`: Dio singleton with auth token interceptor and broadcast event stream.
   - `core/routing/app_router.dart`: Centralized `onGenerateRoute` with protected route authentication guards and custom page transition animations.
   - `core/theme/`: Comprehensive design token system (`AppColors`, `AppTextStyles`, `AppTheme`).
   - `core/utils/`: Hardware storage helper (`StorageHelper`) and floating overlay notifications (`UiUtils`).
   - `core/constants/`: Central static texts, helpline directories (`AppConstants`), and comprehensive Indian administrative geography (`IndianLocations`).
4. **Data Model Layer (`lib/models/`)**:
   - Plain Dart data transfer objects (`UserProfile`, `MatchCard`, `ChatMessage`, `JournalEntry`, `CommunityPost`, `WellnessGoal`, `EmergencyContact`, `Milestone`, `UserNotification`, `ConfigOption`).

### Architectural Consistency & Debt Audit
- **Consistency Score**: **7.5 / 10**
- **Strong Patterns**:
  - The separation of routing into [app_routes.dart](file:///e:/Websites/Wehere/lib/core/routing/app_routes.dart) and [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart) is cleanly maintained.
  - Theme tokens are universally consumed; raw colors or ad-hoc typography are rarely hardcoded.
  - Authentication status is strictly guarded at both router level (`_buildProtectedRoute`) and Dio interceptor level (`AuthEvent.loggedOut`).
- **Architectural Debt**:
  - **God Object Anti-Pattern**: `AppState` has too many responsibilities (discovery swiping, socket lifecycle, journal CRUD, community likes, emergency contacts, milestone unlocks, and subscription gating). It should be separated into dedicated domain stores (`ChatProvider`, `DiscoveryProvider`, `JournalProvider`, `GamificationProvider`).
  - **Direct HTTP Calls in Screens**: While most operations go through `AppState`, several screens make ad-hoc `apiClient.post` or `apiClient.put` calls directly (e.g. [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart#L365), [login_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart#L40), [reset_password_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart#L51)) rather than delegating to repository services.
  - **Hardcoded Local Machine File Reference**: `PricingScreen` in [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L222) attempts to read an image from a developer's local Windows directory (`C:/Users/paras/...`).

---

## 4. Complete Directory Structure Under `lib/`

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # Central app strings, default tags, crisis helpline registry, and API base URL
│   │   └── indian_locations.dart       # Exhaustive lookup map of 36 Indian states/UTs and their respective cities
│   ├── network/
│   │   └── api_client.dart             # Dio HTTP client, JWT bearer interceptor, and AuthEvent broadcast stream
│   ├── routing/
│   │   ├── app_router.dart             # Route generator, protected auth guard, and page transition curves
│   │   └── app_routes.dart             # Central string route constants
│   ├── theme/
│   │   ├── app_colors.dart             # Hex color palette, semantic mood colors, and linear gradients
│   │   ├── app_text_styles.dart        # Typography definitions (Newsreader serif + Plus Jakarta Sans)
│   │   └── app_theme.dart              # Global MaterialApp Material 3 ThemeData definition
│   └── utils/
│       ├── storage_helper.dart         # FlutterSecureStorage with SharedPreferences fallback wrapper
│       └── ui_utils.dart               # Overlay-based top floating snackbar/toast utility
├── models/
│   ├── chat_message.dart               # Message entity (text, voice note duration, crisis flags, delivery status)
│   ├── community_post.dart             # Public community post, comment, and wellness goal entities
│   ├── config_options.dart             # Dynamic admin configuration options (interests, feelings, upload limits)
│   ├── emergency_contact.dart          # Personal emergency SOS contact model
│   ├── journal_entry.dart              # Private journal entity (mood score, category, reflections, gratitude)
│   ├── match_card.dart                 # Discovery swipe card pairing a UserProfile with compatibility tags
│   ├── milestone.dart                  # Gamification badge achievement model with progress tracking
│   ├── notification.dart               # User in-app notification item
│   └── user_profile.dart               # Core user entity with progressive disclosure fields and alias logic
├── screens/
│   ├── main_navigation_shell.dart      # Root bottom navigation shell (IndexedStack for 5 tabs + double-back exit)
│   ├── auth/
│   │   ├── login_screen.dart           # Credential login, forgot password OTP trigger
│   │   ├── otp_verification_screen.dart# 6-box OTP entry with 60s cooldown timer and auto-paste
│   │   ├── reset_password_screen.dart  # OTP-backed password reset screen
│   │   └── signup_screen.dart          # Registration form (mandatory 2 photos, password rules, terms checkbox)
│   ├── chat/
│   │   ├── chat_conversation_screen.dart # 1-on-1 real-time socket chat, voice notes, mutual name disclosure
│   │   └── chat_list_screen.dart       # List of active matches, search filter, and recent message snippets
│   ├── community/
│   │   └── community_screen.dart       # Community feed with likes, comments, and empty state
│   ├── discover/
│   │   └── discover_swipe_screen.dart  # Interactive Tinder-style swipe deck with match celebration modal
│   ├── home/
│   │   └── home_screen.dart            # Main dashboard: mood check-in, Box Breathing modal, daily streak, quick links
│   ├── institutional/
│   │   └── campus_corporate_screen.dart# College campus & workplace partnership inquiry hub
│   ├── journal/
│   │   ├── journal_home_screen.dart    # Calendar filter and list of private user journal reflections
│   │   ├── journal_success_screen.dart # Post-journal affirmation screen with 3D book graphic
│   │   └── new_journal_screen.dart     # Journal creation & editing form with mood chips and image attachment
│   ├── onboarding/
│   │   └── onboarding_flow_screen.dart # 5-step onboarding wizard: age/location validation, interests, safe pledge
│   ├── profile/
│   │   ├── edit_profile_screen.dart    # Edit photos, pseudonym, name preference, state/city, profession, bio
│   │   └── profile_screen.dart         # User profile view with stats (streak, journals, peers) and settings menu
│   ├── progress/
│   │   └── progress_dashboard_screen.dart # XP level progress, interactive wellness goals checklist, milestone grid
│   ├── sos/
│   │   └── sos_help_screen.dart        # Crisis SOS hub with pulsing trigger, emergency contacts, helpline dialers
│   ├── splash/
│   │   └── splash_screen.dart          # Animated startup screen with session check and route dispatch
│   └── walkthrough/
│       └── walkthrough_screen.dart     # 4-page introduction carousel with smooth PageView indicators
├── state/
│   ├── app_state.dart                  # Global application domain state, socket event listener, deck management
│   └── auth_notifier.dart              # Global authentication state machine, token storage, OTP verification
├── widgets/
│   ├── mock_banner_ad.dart             # Conditional banner ad widget (hidden for Wehere Plus subscribers)
│   ├── chat/
│   │   ├── chat_bubble.dart            # Message bubble with delivery status, crisis highlights, voice note bar
│   │   ├── icebreaker_sheet.dart       # Bottom sheet with guided wellness icebreaker prompts
│   │   ├── safe_space_banner.dart      # Persistent in-chat reminder on community safety and respect
│   │   └── wellness_tip_bar.dart       # Mental wellness suggestion pill
│   ├── common/
│   │   ├── animated_pressable.dart     # Scale-down tap feedback container
│   │   ├── animated_pulse.dart         # Repeating scale animation utility
│   │   ├── mood_chip.dart              # Selectable mood rating chip
│   │   ├── tag_chip.dart               # Category/interest pill chip
│   │   ├── wehere_button.dart          # Primary rounded elevated button
│   │   └── wehere_card.dart            # Reusable styled white surface card with border
│   ├── discovery/
│   │   ├── card_action_buttons.dart    # Pass (X), Connect (Heart), and Super-Support (Star) floating triggers
│   │   ├── match_dialog.dart           # Fullscreen celebration popup when a mutual match occurs
│   │   ├── profile_detail_sheet.dart   # Bottom sheet showing extended bio, photos, values, and report/block actions
│   │   └── swipeable_card.dart         # Draggable transform card with angle tilt and CONNECT/PASS overlays
│   ├── profile/
│   │   └── photo_grid.dart             # Reorderable 6-slot photo upload grid with image cropper integration
│   ├── shared/
│   │   └── avatar_widget.dart          # Robust circle avatar supporting network URLs, asset paths, and fallback initials
│   ├── sos/
│   │   └── sos_pulsing_button.dart     # Glowing red circular SOS trigger button with animated waves
│   └── subscription/
│       └── subscription_sheet.dart     # Wehere Plus pricing view, student verification dialog, mock UPI gateway
└── main.dart                           # App root initialization, MultiProvider registration, and system UI overlay
```

---

## 5. Environments, Flavors, and How to Run, Build, and Release

### Environments & Configuration
The application supports environment switching via Dart compile-time environment definitions (`--dart-define`):
- **Default Production Base URL**: `http://200.97.165.22:4000/api` (Configured in [app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart#L2) and [api_client.dart](file:///e:/Websites/Wehere/lib/core/network/api_client.dart#L15))
- **Environment Flag**: `API_URL`

### How to Run Locally

#### Running against Development / Local Backend:
```bash
# Pointing to a local Node.js backend running on port 4000
flutter run --dart-define=API_URL=http://10.0.2.2:4000/api  # Android Emulator
flutter run --dart-define=API_URL=http://localhost:4000/api  # iOS Simulator / macOS
```

#### Running against Production VPS:
```bash
flutter run
```

### How to Build

#### 1. Android Build
```bash
# Debug APK
flutter build apk --debug

# Production Split APKs (optimizes size per architecture)
flutter build apk --release --split-per-abi

# Production Android App Bundle (.aab) for Google Play Store
flutter build appbundle --release
```
- **Android Configuration Notes**:
  - Application ID: `com.wehere.app` ([android/app/build.gradle.kts](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L19))
  - Minimum SDK: Managed by Flutter SDK default (minSdk 21+)
  - Java/Kotlin: Java 17, Kotlin 2.4.0 JVM Target 17 ([android/app/build.gradle.kts](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L43))
  - Permissions: `android.permission.INTERNET` declared in [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L2)
  - Cleartext HTTP allowed: `android:usesCleartextTraffic="true"` ([AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L6))

#### 2. iOS Build
```bash
# iOS Archive for App Store Connect
flutter build ipa --release
```
- **iOS Configuration Notes**:
  - Bundle Identifier: Default Runner identifier (`com.wehere.app`)
  - Transport Security: `NSAllowsArbitraryLoads: true` enabled in [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L44)
  - **Critical Build Warning**: [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) currently lacks `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`. Building for physical iOS devices or uploading to TestFlight will be rejected until these permissions keys are added.

### Release Checklist
1. Increment `version: 1.0.0+1` in [pubspec.yaml](file:///e:/Websites/Wehere/pubspec.yaml#L4).
2. Configure Android release keystore in `android/key.properties` and update `signingConfigs` in [android/app/build.gradle.kts](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L36).
3. Add missing Apple privacy keys to [ios/Runner/Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist).
4. Run `flutter analyze` and `flutter test` to ensure code health before generating release bundles.

# Screens and Navigation Architecture: Wehere

## 1. Navigation Setup Overview

The Wehere application uses Flutter's native declarative and imperative **`Navigator 1.0`** pattern governed by a centralized router:
- **Routing Manifest**: [app_routes.dart](file:///e:/Websites/Wehere/lib/core/routing/app_routes.dart) defines static route path string constants.
- **Route Generator**: [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart) provides the static `onGenerateRoute(RouteSettings settings)` method with custom transitions and reactive authentication guards.
- **Root Shell**: [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart) uses an `IndexedStack` to persist scroll and view state across five core tabs while managing custom Android hardware back-button intercept behavior.

### Navigation Transition Curves
The custom helper `_buildPageRoute` in [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L173-L201) applies physics-based transition curves (`Curves.easeOutCubic`, 260ms duration):
- `PageTransitionType.fade`: Used for default screen changes and journal affirmations.
- `PageTransitionType.slideRight`: Used for horizontal navigation (auth progression, conversations, dashboards).
- `PageTransitionType.slideUp`: Used for bottom-sheet modal screen presentations (new journal editor, SOS emergency hub).

---

## 2. Route Guards & Protection Strategy

In [app_router.dart](file:///e:/Websites/Wehere/lib/core/routing/app_router.dart#L146-L170), protected destinations (`/main`, `/onboarding/wizard`) are wrapped with `_buildProtectedRoute`.
The guard dynamically inspects the global `AuthNotifier` state:

```text
[ Incoming Route Request ]
            |
            v
   Is User Unauthenticated?  ------(YES)-----> Redirect to LoginScreen
            |
           (NO)
            v
   Is User Email Unverified? ------(YES)-----> Redirect to OtpVerificationScreen
            |
           (NO)
            v
Has Completed Onboarding?    ------(NO)------> Redirect to OnboardingFlowScreen
            |
          (YES)
            v
 Render Requested Screen (e.g., MainNavigationShell)
```

- **Unauthenticated**: Renders [LoginScreen](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart).
- **Unverified**: Renders [OtpVerificationScreen](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) passing `auth.registeredEmail`.
- **Incomplete Onboarding**: Renders [OnboardingFlowScreen](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart).
- **Compliant**: Renders the target builder.

---

## 3. Exhaustive Screen & Page Catalog

| Screen Class | File Path | Route Path Constant | Required Arguments | Presentation Mode | Navigation Guards |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `SplashScreen` | [splash_screen.dart](file:///e:/Websites/Wehere/lib/screens/splash/splash_screen.dart) | `AppRoutes.splash` (`'/'`) | None | Fullscreen Root | None (Public) |
| `WalkthroughScreen` | [walkthrough_screen.dart](file:///e:/Websites/Wehere/lib/screens/walkthrough/walkthrough_screen.dart) | `AppRoutes.walkthrough` (`'/walkthrough'`) | None | Fullscreen Slide | None (Public) |
| `LoginScreen` | [login_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart) | `AppRoutes.login` (`'/auth/login'`) | None | Fullscreen Fade | None (Public) |
| `SignUpScreen` | [signup_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/signup_screen.dart) | `AppRoutes.signup` (`'/auth/signup'`) | None | Fullscreen Fade | None (Public) |
| `OtpVerificationScreen` | [otp_verification_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/otp_verification_screen.dart) | `AppRoutes.otp` (`'/auth/otp'`) | `email` (`String`) | Slide from Right | None (Public / Auth Flow) |
| `ResetPasswordScreen` | [reset_password_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/reset_password_screen.dart) | `AppRoutes.resetPassword` (`'/auth/reset'`) | `email` (`String`) | Slide from Right | None (Public / Auth Flow) |
| `OnboardingFlowScreen` | [onboarding_flow_screen.dart](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart) | `AppRoutes.onboarding` (`'/onboarding/wizard'`) | None | Fullscreen Flow | Protected (`AuthNotifier`) |
| `MainNavigationShell` | [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart) | `AppRoutes.main` (`'/main'`) | None | Persistent IndexedStack | Protected (`AuthNotifier`) |
| `HomeScreen` | [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart) | Embedded Tab 0 | None | Tab Surface | Inherits from Shell |
| `DiscoverSwipeScreen`| [discover_swipe_screen.dart](file:///e:/Websites/Wehere/lib/screens/discover/discover_swipe_screen.dart) | Embedded Tab 1 | None | Tab Surface | Inherits from Shell |
| `JournalHomeScreen` | [journal_home_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_home_screen.dart) | Embedded Tab 2 | None | Tab Surface | Inherits from Shell |
| `ChatListScreen` | [chat_list_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_list_screen.dart) | Embedded Tab 3 | None | Tab Surface | Inherits from Shell |
| `ProfileScreen` | [profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/profile_screen.dart) | Embedded Tab 4 / `AppRoutes.profile` | None | Tab Surface / Slide Right | Inherits / Public |
| `ChatConversationScreen`| [chat_conversation_screen.dart](file:///e:/Websites/Wehere/lib/screens/chat/chat_conversation_screen.dart) | `AppRoutes.chatConversation` (`'/chats/conversation'`) | `peer` (`UserProfile`) | Slide from Right | Runtime check (`peer != null`) |
| `NewJournalScreen` | [new_journal_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/new_journal_screen.dart) | `AppRoutes.newJournal` (`'/journal/new'`) | `editEntry` (`JournalEntry?`) | Modal Slide Up | None |
| `JournalSuccessScreen`| [journal_success_screen.dart](file:///e:/Websites/Wehere/lib/screens/journal/journal_success_screen.dart) | `AppRoutes.journalSuccess` (`'/journal/success'`) | `entry` (`JournalEntry`) | Fade | Runtime check (`entry != null`) |
| `CommunityScreen` | [community_screen.dart](file:///e:/Websites/Wehere/lib/screens/community/community_screen.dart) | `AppRoutes.community` (`'/community'`) | None | Slide from Right | None |
| `ProgressDashboardScreen`| [progress_dashboard_screen.dart](file:///e:/Websites/Wehere/lib/screens/progress/progress_dashboard_screen.dart) | `AppRoutes.progress` (`'/progress'`) | None | Slide from Right | None |
| `EditProfileScreen` | [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart) | Direct `Navigator.push` from Profile | None | Standard Material Page | Inherits from Profile |
| `SosHelpScreen` | [sos_help_screen.dart](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) | `AppRoutes.sos` (`'/sos'`) | None | High-Priority Slide Up | None (Emergency Route) |
| `CampusCorporateScreen`| [campus_corporate_screen.dart](file:///e:/Websites/Wehere/lib/screens/institutional/campus_corporate_screen.dart) | `AppRoutes.institutional` (`'/institutional'`) | None | Slide from Right | None |
| `PricingScreen` | [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart) | Direct `showWeherePlusSubscriptionSheet` | None | Fullscreen Dialog | Gated by Free Tier Limits |

---

## 4. Modal Overlays & Bottom Sheets

Beyond named page routes, several interactive features are presented as transient sheets:
1. **MatchCelebrationDialog** ([match_dialog.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/match_dialog.dart)):
   - Triggered when `swipeRight()` resolves to a mutual match (`isMatch == true`).
   - Fullscreen dark mode celebration overlay showing side-by-side avatars, common interests, and actions: "Start Chatting", "Send an Icebreaker", or "Keep Swiping".
2. **ProfileDetailSheet** ([profile_detail_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/discovery/profile_detail_sheet.dart)):
   - Triggered by tapping the top-right information button on a swipeable card.
   - Shows photos, bio, mutual interests, values, and security actions (Report & Block).
3. **IcebreakerSheet** ([icebreaker_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/chat/icebreaker_sheet.dart)):
   - Triggered in 1-on-1 chat to select gentle conversation starters.
4. **Box Breathing Modal** ([home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart#L446)):
   - Fullscreen interactive modal guiding users through 4s Inhale, 4s Hold, 4s Exhale, 4s Rest cycles.
5. **Student ID Upload & Payment Sheet** ([subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L61-L172)):
   - College verification alert and bottom sheet mocking UPI / Card payments.

---

## 5. Mermaid Navigation Flow Diagram

```mermaid
flowchart TD
    %% Entry and Splash
    Start([App Launch]) --> Splash[SplashScreen]
    
    Splash -- Initializing --> Splash
    Splash -- Session Valid & Onboarded --> Main[MainNavigationShell]
    Splash -- Session Valid & Not Onboarded --> Onboarding[OnboardingFlowScreen]
    Splash -- First Time User --> Walkthrough[WalkthroughScreen]
    Splash -- Logged Out / Returning --> Login[LoginScreen]

    %% Walkthrough & Auth
    Walkthrough -- Get Started --> SignUp[SignUpScreen]
    Walkthrough -- Log In --> Login

    Login -- Don't have account --> SignUp
    Login -- Forgot Password --> ForgotDialog[Forgot Password Modal]
    ForgotDialog -- Request OTP --> ResetPass[ResetPasswordScreen]
    ResetPass -- Password Updated --> Login

    SignUp -- Multipart Form Submit --> OTP[OtpVerificationScreen]
    OTP -- Verify Success --> Onboarding

    Onboarding -- Step 5 Complete --> Main

    %% Main Navigation Shell Tabs
    subgraph MainNavigationShell [Main Navigation Shell (IndexedStack)]
        Tab0[Tab 0: HomeScreen]
        Tab1[Tab 1: DiscoverSwipeScreen]
        Tab2[Tab 2: JournalHomeScreen]
        Tab3[Tab 3: ChatListScreen]
        Tab4[Tab 4: ProfileScreen]
    end

    Main --> Tab0
    Main --> Tab1
    Main --> Tab2
    Main --> Tab3
    Main --> Tab4

    %% Interactions from HomeScreen
    Tab0 -- Tap Avatar / Mood --> Tab4
    Tab0 -- Tap Box Breathing --> BreathingModal[Box Breathing Visualizer]
    Tab0 -- Tap Find your people --> Tab1
    Tab0 -- Tap Write reflection --> NewJournal[NewJournalScreen]
    Tab0 -- Tap Community --> Community[CommunityScreen]
    Tab0 -- Tap Emergency SOS --> SOS[SosHelpScreen]
    Tab0 -- Tap Streaks / Growth --> Progress[ProgressDashboardScreen]

    %% Interactions from DiscoverSwipeScreen
    Tab1 -- Tap Card More Details --> ProfileSheet[ProfileDetailSheet]
    Tab1 -- Swipe Right & Mutual Match --> MatchModal[MatchCelebrationDialog]
    Tab1 -- Free Swipes Exhausted --> Pricing[PricingScreen / Wehere Plus]
    MatchModal -- Start Chatting --> ChatConv[ChatConversationScreen]

    %% Interactions from Journal
    Tab2 -- Tap New Entry --> NewJournal
    NewJournal -- Save Journal --> JournalSuccess[JournalSuccessScreen]
    JournalSuccess -- Done --> Tab2

    %% Interactions from Chat
    Tab3 -- Tap Conversation Item --> ChatConv
    ChatConv -- Safety Menu --> ReportBlockModal[Report & Block Dialog]
    ChatConv -- Tap Icebreaker --> IcebreakerSheet[Icebreaker Sheet]
    ChatConv -- Request Name Reveal --> RevealPrompt[Mutual Name Disclosure Handshake]

    %% Interactions from Profile
    Tab4 -- Edit Profile --> EditProfile[EditProfileScreen]
    Tab4 -- Campus & Corporate Hub --> Institutional[CampusCorporateScreen]
    Tab4 -- Wehere Plus Upgrade --> Pricing
    Tab4 -- Logout --> Login
```

---

## 6. Deep Links & Route Shortcomings
- **Deep Linking Status**: Currently, deep linking schemes (`https://wehere.app/invite/...` or custom scheme `wehere://`) are **not wired** in [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml) or [ios/Runner/Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist).
- **Back Button Double Tap**: [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart#L45-L68) enforces an Android back-button interception: pressing back on any tab returns to Tab 0 (`HomeScreen`). Pressing back on Tab 0 twice within 2 seconds exits the app via `SystemNavigator.pop()`.

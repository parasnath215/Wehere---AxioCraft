# Technical Audit: Issues, Gaps & Prioritized Action Plan

This document serves as the comprehensive senior architectural audit of all flaws, security vulnerabilities, fake/mocked features, performance bottlenecks, and dead code identified across the Wehere codebase.

---

## 1. Fake, Mocked, or Hardcoded Data & Unwired Features

| Issue Description | Exact File Path & Lines | Current Behavior | Required Production Behavior |
| :--- | :--- | :--- | :--- |
| **Local Machine Image Path in Pricing Screen** | [subscription_sheet.dart:L222](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L222) | Attempts to load image from `C:/Users/paras/...`. Always fails on real devices and falls back to error builder. | Bundle image asset into `assets/images/` and load via `Image.asset()`. |
| **Wehere Plus Payment Gateway is a Mock** | [subscription_sheet.dart:L144-L191](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L144-L191) | Buttons for UPI and Credit/Debit Card trigger `_finalizeSubscription()`, directly setting `appState.setSubscribed(true)` in local memory. | Integrate real payment gateway (Razorpay / Stripe / Google Play Billing / StoreKit In-App Purchases) with backend webhook verification. |
| **Student ID Verification is Unwired** | [subscription_sheet.dart:L52-L123](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart#L52-L123) | "Upload ID & Continue" immediately advances to payment without uploading the document to the backend or validating student eligibility. | Upload document to backend `/api/users/me/student-verification` and hold subscription in pending status until manual or OCR verification. |
| **Institutional & Campus Corporate Screen is a Pure Simulation** | [campus_corporate_screen.dart:L27-L85](file:///e:/Websites/Wehere/lib/screens/institutional/campus_corporate_screen.dart#L27-L85) | Accepts any alphanumeric code (e.g. `ABC`) and shows green checkmark. Partnership inquiries use `Future.delayed(900ms)` without making any API call. | Wire to backend `/api/institutional/verify-code` and `POST /api/institutional/inquiry`. |
| **Mock Fallback Profiles in `AppState`** | [app_state.dart:L20-L40](file:///e:/Websites/Wehere/lib/state/app_state.dart#L20-L40), [L347-L420](file:///e:/Websites/Wehere/lib/state/app_state.dart#L347-L420) | Hardcodes `user_paras_01`, `peer_test_01`, `peer_ananya_02`, `peer_rohan_03` if backend returns an error or empty list. | Replace hardcoded mocks with proper empty state UI and retry buttons. |

---

## 2. Bugs, Crashes & Security Vulnerabilities

| Severity | Issue Description | Exact File Path & Lines | Impact | Status / Fix |
| :--- | :--- | :--- | :--- | :--- |
| **CRITICAL** | **Backend Prisma Error in Admin Analytics Endpoint** | [backend/src/routes/admin.js](file:///e:/Websites/Wehere/backend/src/routes/admin.js) | Query calls `prisma.journal.count({ where: { authorId: id } })`. Crashes with HTTP 500. | **RESOLVED (Phase 1)**: Corrected to `prisma.journalEntry.count({ where: { userId: id } })`. |
| **CRITICAL** | **iOS App Store Rejection / Crash (Missing Privacy Keys)** | [ios/Runner/Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) | Lacks camera & photo library strings. | **PARTIALLY RESOLVED (Phase 1/6)**: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` added. |
| **HIGH** | **Cleartext HTTP Traffic over Public Internet** | [app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart), [AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml), [Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist) | Hardcoded unencrypted IP `http://200.97.165.22:4000/api` was used. | **RESOLVED (Phase 1)**: Base URL centralized via `--dart-define=API_URL`, release mode startup guard requires HTTPS, cleartext removed from main manifest. |
| **HIGH** | **Unencrypted JWT Storage Fallback** | [storage_helper.dart](file:///e:/Websites/Wehere/lib/core/utils/storage_helper.dart) | Plaintext fallback to `SharedPreferences` on keychain exceptions. | **RESOLVED (Phase 1)**: Plaintext fallback restricted strictly to `kDebugMode`. Release builds fail securely. |
| **MEDIUM** | **Direct HTTP Calls Bypassing State Layer** | [edit_profile_screen.dart](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart), [login_screen.dart](file:///e:/Websites/Wehere/lib/screens/auth/login_screen.dart) | Screens call `apiClient.put()` directly without updating `AppState.currentUser`. | Pending Phase 8 refactor. |

---

## 3. Dead Code, Unused Variables & Deprecations

1. **Unused Field `_unreadNotifications`**:
   - Location: [app_state.dart:L218](file:///e:/Websites/Wehere/lib/state/app_state.dart#L218)
   - Reason: Field is declared as private `_unreadNotifications = 0`, but getter `unreadNotifications` computes dynamically from `_notifications.where((n) => !n.isRead).length`. Field is never updated.
2. **Deprecated Empty Method `toggleWeekCheckIn`**:
   - Location: [app_state.dart:L213-L215](file:///e:/Websites/Wehere/lib/state/app_state.dart#L213-L215)
   - Code: `void toggleWeekCheckIn(int idx) { /* Deprecated: UI now reads weeklyProgress from backend */ }`.
3. **Android Gradle Template TODOs**:
   - Location: [android/app/build.gradle.kts:L18](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L18) (`// TODO: Specify your own unique Application ID`) and [L34](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L34) (`// TODO: Add your own signing config for the release build`).
4. **Duplicate Profession Lists**:
   - Locations: [onboarding_flow_screen.dart:L49-L59](file:///e:/Websites/Wehere/lib/screens/onboarding/onboarding_flow_screen.dart#L49-L59) and [edit_profile_screen.dart:L33-L43](file:///e:/Websites/Wehere/lib/screens/profile/edit_profile_screen.dart#L33-L43).
   - Reason: Identical 9-element string list duplicated across both files. Should be moved to `AppConstants`.

---

## 4. Performance & Memory Leak Audit

1. **Over-Broad `context.watch<AppState>()` in Navigation Shell**:
   - In [main_navigation_shell.dart:L41](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart#L41), the root shell watches the entire `AppState`.
   - **Impact**: Any state update (e.g., an incoming socket chat message in the background, a milestone check, or a mood check-in) causes the entire 5-tab `IndexedStack` to re-execute its build tree.
   - **Fix**: Use targeted selectors:
     ```dart
     final activeIndex = context.select<AppState, int>((s) => s.currentTabIndex);
     final unreadCount = context.select<AppState, int>((s) => s.unreadMessages);
     ```
2. **Missing `const` Constructors on Static Layout Nodes**:
   - Multiple cards, headers, and decoration containers across [home_screen.dart](file:///e:/Websites/Wehere/lib/screens/home/home_screen.dart) and [sos_help_screen.dart](file:///e:/Websites/Wehere/lib/screens/sos/sos_help_screen.dart) lack `const` modifiers, causing unnecessary GC memory churn during scroll events.
3. **Socket Message Duplicate Array Allocation**:
   - In [app_state.dart:L1030](file:///e:/Websites/Wehere/lib/state/app_state.dart#L1030), each incoming message reconstructs and replaces the entire list for a conversation:
     ```dart
     _messages[peerId] = [...existing, newMsg];
     ```
   - On active conversations, this creates unnecessary memory reallocations. Should use in-place list modification with unmodifiable getters.

---

## 5. Prioritized Remediation Roadmap

### Priority 0: Critical Blockers
1. **[RESOLVED]** Fix runtime crash bug in `backend/src/routes/admin.js` (`prisma.journal` -> `prisma.journalEntry`).
2. Add missing camera and photo library usage descriptions to `ios/Runner/Info.plist` (Completed in Phase 1; remaining native configuration in Phase 6).
3. Remove the local Windows path (`C:/Users/paras/...`) in `subscription_sheet.dart` and bundle the asset (Phase 6).
4. **[RESOLVED]** Replace cleartext HTTP base URL (`http://200.97.165.22:4000/api`) with HTTPS/TLS via `--dart-define=API_URL`.

### Priority 1: Security & Compliance
1. **[RESOLVED]** Restrict plaintext `SharedPreferences` token fallback in `storage_helper.dart` to debug builds only.
2. Implement refresh token rotation (`/api/auth/refresh`) to prevent indefinite 30-day token replay windows (Phase 2).
3. Configure release keystore signing in `android/app/build.gradle.kts` (Phase 6).

### Priority 2: Real Backend Integrations (Unwiring Fakes)
1. Replace mock payment flow in [subscription_sheet.dart](file:///e:/Websites/Wehere/lib/widgets/subscription/subscription_sheet.dart) with real Google Play Billing / Apple StoreKit integration.
2. Wire [campus_corporate_screen.dart](file:///e:/Websites/Wehere/lib/screens/institutional/campus_corporate_screen.dart) to real backend verification and inquiry endpoints.
3. Integrate Firebase Cloud Messaging (FCM) or Apple Push Notification Service (APNs) for native background alerts.

### Priority 3: Architecture & Performance Polish
1. Refactor monolithic `AppState` (~1,800 lines) into domain notifiers (`DiscoveryNotifier`, `ChatNotifier`, `JournalNotifier`, `WellnessNotifier`).
2. Replace broad `context.watch<AppState>()` in [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart) with granular `context.select()`.
3. Eliminate duplicate `professionOptions` and regex rules into [app_constants.dart](file:///e:/Websites/Wehere/lib/core/constants/app_constants.dart).

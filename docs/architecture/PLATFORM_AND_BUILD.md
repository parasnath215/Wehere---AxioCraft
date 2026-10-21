# Platform & Build Configuration: Wehere

## 1. Android Platform Configuration

### Gradle Build Configuration
- **Build File**: [android/app/build.gradle.kts](file:///e:/Websites/Wehere/android/app/build.gradle.kts)
- **Plugin Application**:
  - `id("com.android.application")`
  - `id("dev.flutter.flutter-gradle-plugin")`
- **Namespace & Application ID**:
  - `namespace = "com.wehere.app"` ([build.gradle.kts:L8](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L8))
  - `applicationId = "com.wehere.app"` ([build.gradle.kts:L19](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L19))
- **Compilation Targets & Java Version**:
  - `compileOptions`: `sourceCompatibility = JavaVersion.VERSION_17`, `targetCompatibility = JavaVersion.VERSION_17` ([build.gradle.kts:L13-L14](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L13-L14)).
  - `kotlin.compilerOptions`: `jvmTarget = JvmTarget.JVM_17` ([build.gradle.kts:L43](file:///e:/Websites/Wehere/android/app/build.gradle.kts#L43)).
  - `compileSdk = flutter.compileSdkVersion`.
  - `minSdk = flutter.minSdkVersion` (Defaulting to 21).
  - `targetSdk = flutter.targetSdkVersion` (Targeting Android 14 / API 34).
- **Signing Configurations**:
  - Release build currently points to debug signing:
    ```kotlin
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    ```
  - **Action Required for Production**: Create a dedicated Java Keystore (`upload-keystore.jks`), create `android/key.properties`, and link release signing before publishing to Google Play Console.

### Android Manifest & Native Activities
- **Manifest File**: [android/app/src/main/AndroidManifest.xml](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml)
- **Permissions Declared**:
  - `<uses-permission android:name="android.permission.INTERNET"/>` ([AndroidManifest.xml:L2](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L2))
- **Application Attributes**:
  - `android:label="Wehere"`
  - `android:usesCleartextTraffic="true"` (Allows unencrypted HTTP communication with `http://200.97.165.22:4000`)
- **Native Activities Registered**:
  1. `.MainActivity`:
     - Standard Flutter embedding v2 activity.
     - `android:launchMode="singleTop"`
     - `android:windowSoftInputMode="adjustResize"`
     - Filters: `android.intent.action.MAIN` and `android.intent.category.LAUNCHER`.
  2. `com.yalantis.ucrop.UCropActivity` ([AndroidManifest.xml:L30](file:///e:/Websites/Wehere/android/app/src/main/AndroidManifest.xml#L30)):
     - Native cropping activity used by `image_cropper` for profile avatar squaring.
     - `android:screenOrientation="portrait"`
     - `android:theme="@style/Theme.AppCompat.Light.NoActionBar"`

---

## 2. iOS Platform Configuration

### Info.plist Configuration
- **Manifest File**: [ios/Runner/Info.plist](file:///e:/Websites/Wehere/ios/Runner/Info.plist)
- **Bundle Identifiers**:
  - `CFBundleDisplayName`: `Wehere` ([Info.plist:L8](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L8))
  - `CFBundleName`: `wehere` ([Info.plist:L16](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L16))
  - `CFBundleIdentifier`: `$(PRODUCT_BUNDLE_IDENTIFIER)` (defaults to `com.wehere.app`)
  - `CFBundlePackageType`: `APPL`
- **Supported Orientations**:
  - Restricted strictly to portrait: `<string>UIInterfaceOrientationPortrait</string>` ([Info.plist:L33](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L33)).
- **App Transport Security (ATS)**:
  - `NSAppTransportSecurity` -> `NSAllowsArbitraryLoads: true` ([Info.plist:L44](file:///e:/Websites/Wehere/ios/Runner/Info.plist#L44)). Allows non-HTTPS HTTP traffic.

### Critical iOS Missing Keys Audit
The following required Cocoa privacy keys are **currently missing** in `ios/Runner/Info.plist`:
1. `NSCameraUsageDescription`: Required for `image_picker` when users take a live photo during signup.
2. `NSPhotoLibraryUsageDescription`: Required for selecting photos from the iOS Photo Library for profile photos and journal entries.
3. `NSMicrophoneUsageDescription`: Required if voice notes are recorded natively via the device microphone.

> [!WARNING]
> Attempting to run `flutter build ipa` or upload to TestFlight will result in rejection or runtime crashes when camera/photo features are tapped on iOS 17+.

---

## 3. Native Platform Channels & Custom Code

### Custom Platform Channels
- The repository contains **zero custom MethodChannels or EventChannels** written in Swift, Objective-C, Kotlin, or Java.
- All native bridge operations are handled entirely by verified third-party plugins:
  - `flutter_secure_storage`: Accesses iOS Keychain Services and Android Keystore.
  - `shared_preferences`: Accesses iOS `NSUserDefaults` and Android `SharedPreferences`.
  - `image_picker`: Dispatches system photo picker intents.
  - `image_cropper`: Opens `UCropActivity` on Android and CocoaPods UCrop on iOS.
  - `url_launcher`: Invokes system intent handlers (`tel:`, `https:`).

---

## 4. Push Notifications, Deep Links & Background Services

| Feature | Current Implementation Status | Technical Details |
| :--- | :--- | :--- |
| **Push Notifications (FCM / APNs)** | **Not Implemented** | No Firebase plugins (`firebase_core`, `firebase_messaging`) are installed. Notifications are simulated in the UI and refreshed via in-app polling (`GET /api/notifications`). |
| **Deep Linking (Universal / App Links)** | **Not Configured** | Neither `assetlinks.json` (Android) nor `apple-app-site-association` (iOS) are registered in the native manifests. Routes cannot be opened externally via URLs. |
| **Background Processing** | **Not Present on Mobile** | Mobile app does not run background tasks when suspended. All timers (e.g. OTP countdown) record timestamps and synchronize on `AppLifecycleState.resumed`. Background tasks (account cleanup, auto-deletions) run on the Node.js server. |
| **System Back-Button Trapping** | **Implemented** | [main_navigation_shell.dart](file:///e:/Websites/Wehere/lib/screens/main_navigation_shell.dart#L45) uses Flutter's `PopScope` to intercept Android physical back navigation, redirecting to Tab 0 or exiting if tapped twice within 2 seconds. |

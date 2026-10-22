import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/storage_helper.dart';
import '../core/network/api_client.dart';
import '../core/routing/app_routes.dart';
import '../core/routing/app_router.dart';
import '../services/social_auth_service.dart';
import 'app_state.dart';

enum AuthStatus { initializing, unauthenticated, unverified, authenticated }

class SocialRegistrationData {
  final String provider; // 'google' | 'apple'
  final String idToken;
  final String? nonce;
  final String email;
  final String name;
  final String? givenName;
  final String? familyName;
  final String? pictureUrl;
  final String? locale;
  final String? suggestedPhone;

  SocialRegistrationData({
    required this.provider,
    required this.idToken,
    this.nonce,
    required this.email,
    required this.name,
    this.givenName,
    this.familyName,
    this.pictureUrl,
    this.locale,
    this.suggestedPhone,
  });
}

class SocialOutcome {
  final bool isLoggedIn;
  final bool isNeedsRegistration;
  final bool isUnderage;
  final bool isAccountBanned;
  final bool isError;
  final SocialRegistrationData? registrationData;
  final String? errorMessage;

  const SocialOutcome._({
    this.isLoggedIn = false,
    this.isNeedsRegistration = false,
    this.isUnderage = false,
    this.isAccountBanned = false,
    this.isError = false,
    this.registrationData,
    this.errorMessage,
  });

  factory SocialOutcome.loggedIn() => const SocialOutcome._(isLoggedIn: true);
  factory SocialOutcome.needsRegistration(SocialRegistrationData data) =>
      SocialOutcome._(isNeedsRegistration: true, registrationData: data);
  factory SocialOutcome.underage() => const SocialOutcome._(isUnderage: true);
  factory SocialOutcome.accountBanned(String msg) =>
      SocialOutcome._(isAccountBanned: true, errorMessage: msg);
  factory SocialOutcome.error(String msg) =>
      SocialOutcome._(isError: true, errorMessage: msg);
}

/// Pure routing decision function for testability
String resolveNextRoute({
  required bool isAuthenticated,
  required bool emailVerified,
  required bool needsDob,
  required bool onboardingCompleted,
}) {
  if (!isAuthenticated) return AppRoutes.login;
  if (!emailVerified) return AppRoutes.otp;
  if (needsDob) return AppRoutes.dobGate;
  if (!onboardingCompleted) return AppRoutes.onboarding;
  return AppRoutes.main;
}

class AuthNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initializing;
  String? _userId;
  String _registeredName = 'User';
  String _registeredEmail = '';
  bool _hasSeenWalkthrough = false;
  bool _hasCompletedOnboarding = false;
  bool _needsDob = false;
  String? _authError;
  bool _isLoading = false;

  DateTime? _suggestedDob;
  DateTime? get suggestedDob => _suggestedDob;

  String? _suggestedPhone;
  String? get suggestedPhone => _suggestedPhone;

  late final StreamSubscription _authSubscription;

  AuthNotifier() {
    _authSubscription = apiClientInstance.authEventStream.listen((event) {
      if (event == AuthEvent.loggedOut) {
        logout();
      } else if (event == AuthEvent.emailNotVerified) {
        _status = AuthStatus.unverified;
        notifyListeners();
      } else if (event == AuthEvent.ageRequired) {
        _needsDob = true;
        notifyListeners();
      } else if (event == AuthEvent.underage) {
        handleUnderage();
      }
    });
  }

  bool get needsDob => _needsDob;
  void setNeedsDob(bool val) {
    _needsDob = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated || _status == AuthStatus.unverified;
  bool get hasSeenWalkthrough => _hasSeenWalkthrough;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get authError => _authError;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String get registeredName => _registeredName;
  String get registeredEmail => _registeredEmail;

  String nextRoute() {
    return resolveNextRoute(
      isAuthenticated: isAuthenticated,
      emailVerified: _status == AuthStatus.authenticated,
      needsDob: _needsDob,
      onboardingCompleted: _hasCompletedOnboarding,
    );
  }

  void navigateAfterAuth(BuildContext context) {
    final target = nextRoute();
    if (target == AppRoutes.main) {
      try {
        Provider.of<AppState>(context, listen: false).setTabIndex(0);
      } catch (_) {}
    }
    Navigator.pushNamedAndRemoveUntil(context, target, (r) => false);
  }

  Future<void> initializeSession() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    try {
      final token = await StorageHelper.read(key: 'jwt_token');
      final savedId = await StorageHelper.read(key: 'user_id');
      final savedEmail = await StorageHelper.read(key: 'user_email');
      final seenWalkthroughStr = await StorageHelper.read(key: 'has_seen_walkthrough');
      
      _hasSeenWalkthrough = seenWalkthroughStr == 'true';

      if (token != null && savedId != null) {
        _userId = savedId;
        _registeredEmail = savedEmail ?? '';
        
        // Fetch current user from server
        try {
          final res = await apiClient.get('/users/me');
          final data = res.data;
          final isVerified = data['emailVerified'] == true;
          _needsDob = data['needsDob'] == true;
          _hasCompletedOnboarding = data['onboardingCompleted'] == true;
          _status = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
          if (data['pseudonym'] != null) _registeredName = data['pseudonym'];
          if (data['email'] != null) _registeredEmail = data['email'];

          // Cache onboarding completed flag
          if (_hasCompletedOnboarding) {
            await StorageHelper.write(key: 'onboarding_completed', value: 'true');
          }
        } catch (e) {
          _status = AuthStatus.authenticated;
          _needsDob = false;
          _hasCompletedOnboarding = true;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> refreshSession([BuildContext? context]) async {
    try {
      final res = await apiClient.get('/users/me');
      if (res.statusCode == 200) {
        final data = res.data;
        final isVerified = data['emailVerified'] == true;
        _needsDob = data['needsDob'] == true;
        _hasCompletedOnboarding = data['onboardingCompleted'] == true;
        _status = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
        if (data['pseudonym'] != null) _registeredName = data['pseudonym'];
        if (data['email'] != null) _registeredEmail = data['email'];

        if (_hasCompletedOnboarding) {
          await StorageHelper.write(key: 'onboarding_completed', value: 'true');
        }

        notifyListeners();

        if (context != null && context.mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.fetchCurrentUser();
          await appState.fetchBackendData();
          final token = await StorageHelper.read(key: 'jwt_token');
          if (token != null) {
            appState.initSocket(token);
          }
        }
      }
    } catch (e) {
      debugPrint('refreshSession error: $e');
    }
  }

  Future<void> handleUnderage([BuildContext? context]) async {
    await StorageHelper.delete(key: 'jwt_token');
    await StorageHelper.delete(key: 'user_id');
    await StorageHelper.delete(key: 'user_email');
    await StorageHelper.delete(key: 'user_age');
    await StorageHelper.delete(key: 'user_dob');
    await StorageHelper.delete(key: 'onboarding_completed');

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    _status = AuthStatus.unauthenticated;
    _userId = null;
    _registeredEmail = '';
    _needsDob = false;
    _hasCompletedOnboarding = false;
    notifyListeners();

    if (context != null && context.mounted) {
      try {
        Provider.of<AppState>(context, listen: false).resetAllData();
      } catch (_) {}
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.underage, (r) => false);
    } else {
      final nav = AppRouter.navigatorKey.currentState;
      nav?.pushNamedAndRemoveUntil(AppRoutes.underage, (r) => false);
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final user = response.data['user'];

      await StorageHelper.write(key: 'jwt_token', value: token);
      await StorageHelper.write(key: 'user_id', value: user['id']);
      await StorageHelper.write(key: 'user_email', value: user['email']);

      _userId = user['id'];
      _registeredEmail = user['email'];
      
      final isVerified = user['emailVerified'] == true || user['role'] == 'ADMIN';
      _status = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
      _needsDob = response.data['needsDob'] == true;
      _hasCompletedOnboarding = response.data['onboardingCompleted'] == true;

      if (_hasCompletedOnboarding) {
        await StorageHelper.write(key: 'onboarding_completed', value: 'true');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.data?['error'] == 'EMAIL_NOT_VERIFIED') {
        final data = e.response?.data;
        if (data != null && data['token'] != null) {
          await StorageHelper.write(key: 'jwt_token', value: data['token']);
          if (data['user'] != null && data['user']['id'] != null) {
            await StorageHelper.write(key: 'user_id', value: data['user']['id']);
            _userId = data['user']['id'];
          }
          await StorageHelper.write(key: 'user_email', value: data['email'] ?? email);
        }
        _registeredEmail = data?['email'] ?? email;
        _status = AuthStatus.unverified;
        _authError = e.response?.data?['message'] ?? 'Please verify your email before logging in.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (e.response?.data?['error'] == 'UNDERAGE') {
        await handleUnderage();
        return false;
      }
      final resData = e.response?.data;
      _authError = (resData is Map)
          ? (resData['message'] ?? resData['error'] ?? 'Login failed. Please check credentials.')
          : 'Login failed. Please check credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<SocialOutcome> continueWithProvider(String provider) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      SocialCredential? cred;
      if (provider == 'google') {
        cred = await SocialAuthService.signInWithGoogle();
      } else if (provider == 'apple') {
        cred = await SocialAuthService.signInWithApple();
      } else {
        _isLoading = false;
        notifyListeners();
        return SocialOutcome.error('Unsupported provider: $provider');
      }

      if (cred == null) {
        _isLoading = false;
        notifyListeners();
        return SocialOutcome.error('Sign-in cancelled');
      }

      if (cred.suggestedDob != null) {
        _suggestedDob = cred.suggestedDob;
      }
      if (cred.suggestedPhone != null) {
        _suggestedPhone = cred.suggestedPhone;
      }

      final checkRes = await socialCheck(
        provider: cred.provider,
        idToken: cred.idToken,
        nonce: cred.nonce,
        givenName: cred.givenName,
        familyName: cred.familyName,
      );

      if (checkRes['exists'] == true) {
        final loginSuccess = await socialLogin(
          provider: cred.provider,
          idToken: cred.idToken,
          nonce: cred.nonce,
        );
        _isLoading = false;
        notifyListeners();
        if (loginSuccess) {
          return SocialOutcome.loggedIn();
        } else {
          return SocialOutcome.error(_authError ?? 'Failed to log in with $provider');
        }
      } else {
        _isLoading = false;
        notifyListeners();
        final profile = checkRes['profile'] as Map<String, dynamic>? ?? {};
        final regData = SocialRegistrationData(
          provider: cred.provider,
          idToken: cred.idToken,
          nonce: cred.nonce,
          email: profile['email'] ?? cred.email ?? '',
          name: profile['name'] ?? cred.displayName ?? '',
          givenName: profile['givenName'] ?? cred.givenName,
          familyName: profile['familyName'] ?? cred.familyName,
          pictureUrl: profile['pictureUrl'] ?? cred.photoUrl,
          locale: profile['locale'],
          suggestedPhone: cred.suggestedPhone,
        );
        return SocialOutcome.needsRegistration(regData);
      }
    } on DioException catch (e) {
      _isLoading = false;
      final errCode = e.response?.data?['error'];
      final message = e.response?.data?['message'] ?? 'Social sign-in failed.';
      if (errCode == 'UNDERAGE') {
        await handleUnderage();
        return SocialOutcome.underage();
      } else if (errCode == 'ACCOUNT_BANNED') {
        _authError = message;
        notifyListeners();
        return SocialOutcome.accountBanned(message);
      }
      _authError = message;
      notifyListeners();
      return SocialOutcome.error(message);
    } catch (e) {
      _isLoading = false;
      _authError = e.toString();
      notifyListeners();
      return SocialOutcome.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> socialCheck({
    required String provider,
    required String idToken,
    String? nonce,
    String? givenName,
    String? familyName,
  }) async {
    final res = await apiClient.post('/auth/social/check', data: {
      'provider': provider,
      'idToken': idToken,
      if (nonce != null && nonce.isNotEmpty) 'nonce': nonce,
      if (givenName != null && givenName.isNotEmpty) 'givenName': givenName,
      if (familyName != null && familyName.isNotEmpty) 'familyName': familyName,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<bool> socialLogin({
    required String provider,
    required String idToken,
    String? nonce,
  }) async {
    try {
      final response = await apiClient.post('/auth/social/login', data: {
        'provider': provider,
        'idToken': idToken,
        if (nonce != null && nonce.isNotEmpty) 'nonce': nonce,
      });

      final token = response.data['token'];
      final user = response.data['user'];

      await StorageHelper.write(key: 'jwt_token', value: token);
      await StorageHelper.write(key: 'user_id', value: user['id']);
      await StorageHelper.write(key: 'user_email', value: user['email'] ?? '');

      _userId = user['id'];
      _registeredEmail = user['email'] ?? '';
      _registeredName = user['displayName'] ?? user['pseudonym'] ?? 'Explorer';
      _needsDob = response.data['needsDob'] == true;
      _hasCompletedOnboarding = response.data['onboardingCompleted'] == true;
      _status = AuthStatus.authenticated;
      _authError = null;

      if (_hasCompletedOnboarding) {
        await StorageHelper.write(key: 'onboarding_completed', value: 'true');
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      final errCode = e.response?.data?['error'];
      final message = e.response?.data?['message'] ?? 'Social login failed.';
      if (errCode == 'UNDERAGE') {
        await handleUnderage();
      }
      _authError = message;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> socialRegister({
    required String provider,
    required String idToken,
    String? nonce,
    required String pseudonym,
    String? password,
    String? phone,
    String? givenName,
    String? familyName,
    required List<String> imagePaths,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final formData = FormData();
      formData.fields.add(MapEntry('provider', provider));
      formData.fields.add(MapEntry('idToken', idToken));
      if (nonce != null && nonce.isNotEmpty) {
        formData.fields.add(MapEntry('nonce', nonce));
      }
      formData.fields.add(MapEntry('pseudonym', pseudonym));
      if (password != null && password.isNotEmpty) {
        formData.fields.add(MapEntry('password', password));
      }
      if (phone != null && phone.isNotEmpty) {
        formData.fields.add(MapEntry('phone', phone));
      }
      if (givenName != null && givenName.isNotEmpty) {
        formData.fields.add(MapEntry('givenName', givenName));
      }
      if (familyName != null && familyName.isNotEmpty) {
        formData.fields.add(MapEntry('familyName', familyName));
      }

      for (final path in imagePaths) {
        final filename = path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(path, filename: filename),
        ));
      }

      final response = await apiClient.post('/auth/social/register', data: formData);
      final token = response.data['token'];
      final user = response.data['user'];

      await StorageHelper.write(key: 'jwt_token', value: token);
      await StorageHelper.write(key: 'user_id', value: user['id']);
      await StorageHelper.write(key: 'user_email', value: user['email'] ?? '');

      _userId = user['id'];
      _registeredEmail = user['email'] ?? '';
      _registeredName = user['displayName'] ?? user['pseudonym'] ?? 'Explorer';
      _needsDob = response.data['needsDob'] == true;
      _hasCompletedOnboarding = response.data['onboardingCompleted'] == true;
      _status = AuthStatus.authenticated;

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      final resData = e.response?.data;
      _authError = (resData is Map)
          ? (resData['message'] ?? resData['error'] ?? 'Social registration failed.')
          : 'Social registration failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _authError = 'Social registration error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  String _userHandle = '';
  String get userHandle => _userHandle;

  String? _pendingSignupToken;
  String? get pendingSignupToken => _pendingSignupToken;

  void updatePendingSignupToken(String token) {
    _pendingSignupToken = token;
    notifyListeners();
  }

  void cancelPendingSignup() {
    _pendingSignupToken = null;
    _registeredEmail = '';
    _registeredName = '';
    _userHandle = '';
    _status = AuthStatus.unauthenticated;
    _authError = null;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password, {String? customHandle, String? phone, List<String>? imagePaths}) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
        'pseudonym': customHandle ?? name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var path in imagePaths) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          final fileName = path.split(Platform.pathSeparator).last;
          formData.files.add(MapEntry(
            'images',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ));
        }
      }

      final response = await apiClient.post(
        '/auth/signup',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      _pendingSignupToken = response.data['signupToken'];
      _registeredEmail = email;
      _registeredName = name;
      _userHandle = customHandle ?? name;
      _status = AuthStatus.unverified;

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _authError = e.response?.data?['error'] ?? e.response?.data?['message'] ?? 'Registration failed: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, {String? customHandle, String? phone, List<String>? imagePaths}) =>
      register(name, email, password, customHandle: customHandle, phone: phone, imagePaths: imagePaths);

  Future<bool> verifyOtp(String pin) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        '/auth/otp/verify',
        data: {
          'otp': pin,
          if (_pendingSignupToken != null) 'signupToken': _pendingSignupToken,
        },
        options: _pendingSignupToken != null
            ? Options(headers: {'Authorization': 'Bearer $_pendingSignupToken'})
            : null,
      );

      if (res.data['success'] == true) {
        final token = res.data['token'];
        final user = res.data['user'];

        if (token != null) {
          await StorageHelper.write(key: 'jwt_token', value: token);
        }
        if (user != null) {
          if (user['id'] != null) {
            await StorageHelper.write(key: 'user_id', value: user['id']);
            _userId = user['id'];
          }
          if (user['email'] != null) {
            await StorageHelper.write(key: 'user_email', value: user['email']);
            _registeredEmail = user['email'];
          }
          if (user['pseudonym'] != null) {
            _userHandle = user['pseudonym'];
          }
        }

        _pendingSignupToken = null;
        _status = AuthStatus.authenticated;
        _needsDob = res.data['needsDob'] == true;
        _hasCompletedOnboarding = res.data['onboardingCompleted'] == true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = res.data['error'] ?? res.data['message'] ?? 'Invalid verification code.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _authError = e.response?.data?['error'] ?? e.response?.data?['message'] ?? 'Failed to verify OTP.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Failed to verify OTP. Check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markWalkthroughSeen() async {
    _hasSeenWalkthrough = true;
    await StorageHelper.write(key: 'has_seen_walkthrough', value: 'true');
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    String? displayName,
    String? realFirstName,
    String? handle,
    String? nameDisplayPreference,
    required String location,
    String? profession,
    required List<String> interests,
    required List<String> feelings,
    required List<String> supportTypes,
    required bool isAnonymous,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.put('/auth/onboarding', data: {
        'name': name,
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        if (realFirstName != null && realFirstName.isNotEmpty) 'realFirstName': realFirstName,
        if (handle != null && handle.isNotEmpty) 'handle': handle,
        if (nameDisplayPreference != null) 'nameDisplayPreference': nameDisplayPreference,
        'location': location,
        if (profession != null && profession.isNotEmpty) 'profession': profession,
        'interests': interests,
        'feelings': feelings,
        'supportTypes': supportTypes,
        'isAnonymous': isAnonymous,
      });
      await StorageHelper.write(key: 'onboarding_completed', value: 'true');
      _hasCompletedOnboarding = true;
      _needsDob = false;
    } catch (e) {
      _authError = 'Failed to save onboarding preferences';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageHelper.delete(key: 'jwt_token');
    await StorageHelper.delete(key: 'user_id');
    await StorageHelper.delete(key: 'user_email');
    await StorageHelper.delete(key: 'user_age');
    await StorageHelper.delete(key: 'user_dob');
    await StorageHelper.delete(key: 'onboarding_completed');

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    _userId = null;
    _registeredEmail = '';
    _needsDob = false;
    _hasCompletedOnboarding = false;
    _status = AuthStatus.unauthenticated;
    _authError = null;
    notifyListeners();
  }
}

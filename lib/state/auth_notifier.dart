import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/storage_helper.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initializing, unauthenticated, unverified, authenticated }

class AuthNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initializing;
  String? _userId;
  String _registeredName = 'User';
  String _registeredEmail = '';
  bool _hasSeenWalkthrough = false;
  bool _hasCompletedOnboarding = false;
  String? _authError;
  bool _isLoading = false;

  final 
  late StreamSubscription _authSubscription;

  AuthNotifier() {
    _authSubscription = apiClientInstance.authEventStream.listen((event) {
      if (event == AuthEvent.loggedOut) {
        logout();
      } else if (event == AuthEvent.emailNotVerified) {
        _status = AuthStatus.unverified;
        notifyListeners();
      }
    });
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
        
        // Check if verified by hitting /me
        try {
          final res = await apiClient.get('/users/me');
          final isVerified = res.data['emailVerified'] == true || res.data['isAnonymous'] == true;
          _status = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
          
          final savedOnboarding = await StorageHelper.read(key: 'onboarding_completed');
          _hasCompletedOnboarding = savedOnboarding == 'true' || res.data['interests']?.isNotEmpty == true;
        } catch (e) {
           _status = AuthStatus.authenticated; // optimistic, interceptor will downgrade if 403
           final savedOnboarding = await StorageHelper.read(key: 'onboarding_completed');
           _hasCompletedOnboarding = savedOnboarding == 'true';
        }

      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
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
      
      final savedOnboarding = await StorageHelper.read(key: 'onboarding_completed');
      _hasCompletedOnboarding = savedOnboarding == 'true' || (user['interests'] != null && user['interests'].isNotEmpty);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _authError = e.response?.data?['error'] ?? 'Login failed';
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

  String _userHandle = '';
  String get userHandle => _userHandle;

  Future<bool> register(String name, String email, String password, {String? customHandle, List<String>? imagePaths}) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
        'pseudonym': customHandle ?? name,
      });

      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var path in imagePaths) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(path),
          ));
        }
      }

      final response = await apiClient.post(
        '/auth/signup',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final token = response.data['token'];
      final user = response.data['user'];

      await StorageHelper.write(key: 'jwt_token', value: token);
      await StorageHelper.write(key: 'user_id', value: user['id']);
      await StorageHelper.write(key: 'user_email', value: user['email']);

      _userId = user['id'];
      _registeredEmail = user['email'];
      _registeredName = name;
      _userHandle = customHandle ?? '@user_${user['id'].substring(0,5)}';
      
      final isVerified = user['emailVerified'] == true;
      _status = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _authError = e.response?.data?['error'] ?? 'Registration failed: ${e.message}';
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

  Future<bool> signup(String name, String email, String password, {String? customHandle, List<String>? imagePaths}) =>
      register(name, email, password, customHandle: customHandle, imagePaths: imagePaths);

  Future<bool> verifyOtp(String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await apiClient.post('/auth/otp/verify', data: {
        'otp': pin,
      });

      if (res.data['success'] == true) {
        _status = AuthStatus.authenticated;
        _hasCompletedOnboarding = false; // Need to do onboarding after verify
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'Invalid verification code.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _authError = e.response?.data?['error'] ?? 'Failed to verify OTP.';
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
    required String location,
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
        'location': location,
        'interests': interests,
        'feelings': feelings,
        'supportTypes': supportTypes,
        'isAnonymous': isAnonymous,
      });
      await StorageHelper.write(key: 'onboarding_completed', value: 'true');
      _hasCompletedOnboarding = true;
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
    _userId = null;
    _status = AuthStatus.unauthenticated;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }
}

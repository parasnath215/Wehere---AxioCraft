import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/storage_helper.dart';

enum AuthEvent { loggedOut, emailNotVerified, ageRequired }

bool shouldForceLogout(int? status, String path, String? code) {
  return (status == 401 && (code == 'TOKEN_INVALID' || code == 'TOKEN_EXPIRED')) ||
      (status == 403 && code == 'ACCOUNT_BANNED');
}

class ApiClient {
  late final Dio dio;
  
  final StreamController<AuthEvent> _authEventController = StreamController.broadcast();
  Stream<AuthEvent> get authEventStream => _authEventController.stream;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageHelper.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final status = e.response?.statusCode;
        final path = e.requestOptions.path;
        final dynamic data = e.response?.data;
        final String? code = data is Map ? data['error']?.toString() : null;

        if (status == 403 && code == 'EMAIL_NOT_VERIFIED') {
          _authEventController.add(AuthEvent.emailNotVerified);
        } else if (status == 403 && code == 'AGE_REQUIRED') {
          _authEventController.add(AuthEvent.ageRequired);
        } else if (shouldForceLogout(status, path, code)) {
          await StorageHelper.delete(key: 'jwt_token');
          _authEventController.add(AuthEvent.loggedOut);
        }
        return handler.next(e);
      },
    ));
  }
}

final apiClientInstance = ApiClient();
final apiClient = apiClientInstance.dio;

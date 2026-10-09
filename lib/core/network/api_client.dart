import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/storage_helper.dart';

enum AuthEvent { loggedOut, emailNotVerified }

class ApiClient {
  late final Dio dio;
  
  final StreamController<AuthEvent> _authEventController = StreamController.broadcast();
  Stream<AuthEvent> get authEventStream => _authEventController.stream;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'http://200.97.165.22:4000/api'),
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
        if (e.response?.statusCode == 401) {
          await StorageHelper.delete(key: 'jwt_token');
          _authEventController.add(AuthEvent.loggedOut);
        } else if (e.response?.statusCode == 403) {
          final errorMsg = e.response?.data?['error'];
          if (errorMsg == 'EMAIL_NOT_VERIFIED') {
            _authEventController.add(AuthEvent.emailNotVerified);
          } else {
            await StorageHelper.delete(key: 'jwt_token');
            _authEventController.add(AuthEvent.loggedOut);
          }
        }
        return handler.next(e);
      },
    ));
  }
}

final apiClientInstance = ApiClient();
final apiClient = apiClientInstance.dio;

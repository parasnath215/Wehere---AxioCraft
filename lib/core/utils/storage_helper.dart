import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const _secureStorage = FlutterSecureStorage();

  static bool _isSensitiveTokenKey(String key) {
    return key == 'jwt_token' || key == 'refresh_token';
  }

  static Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (_) {
      // In release mode, never fallback to unencrypted SharedPreferences for sensitive auth tokens
      if (_isSensitiveTokenKey(key) && !kDebugMode) {
        return null;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (_) {
      if (_isSensitiveTokenKey(key) && !kDebugMode) {
        return;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (_) {}
    } catch (_) {}
  }

  static Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (_) {
      if (_isSensitiveTokenKey(key) && !kDebugMode) {
        return;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (_) {}
    } catch (_) {}
  }
}

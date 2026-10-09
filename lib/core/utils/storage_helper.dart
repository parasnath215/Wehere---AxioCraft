import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const _secureStorage = FlutterSecureStorage();
  
  static Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (_) {
      // Fallback for iOS Simulator keychain issue
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}

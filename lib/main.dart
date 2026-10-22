import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'state/app_state.dart';
import 'state/auth_notifier.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode && !AppConstants.apiBaseUrl.startsWith('https://')) {
    throw StateError('Release builds require an https API_URL (--dart-define=API_URL=https://...)');
  }

  // F12: Delete legacy keys user_age and user_dob from secure storage and SharedPreferences
  try {
    await StorageHelper.delete(key: 'user_age');
    await StorageHelper.delete(key: 'user_dob');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_age');
    await prefs.remove('user_dob');
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WehereApp());
}

class WehereApp extends StatelessWidget {
  const WehereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()..initializeSession()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Wehere',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

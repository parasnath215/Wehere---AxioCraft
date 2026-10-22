import 'package:flutter_test/flutter_test.dart';
import 'package:wehere/core/network/api_client.dart';
import 'package:wehere/core/routing/app_routes.dart';
import 'package:wehere/state/auth_notifier.dart';

void main() {
  group('shouldForceLogout unit tests', () {
    test('401 with TOKEN_INVALID forces logout', () {
      expect(shouldForceLogout(401, '/api/users/me', 'TOKEN_INVALID'), isTrue);
    });

    test('401 with TOKEN_EXPIRED forces logout', () {
      expect(shouldForceLogout(401, '/api/users/me', 'TOKEN_EXPIRED'), isTrue);
    });

    test('401 with INVALID_CREDENTIALS does not force logout', () {
      expect(shouldForceLogout(401, '/api/auth/login', 'INVALID_CREDENTIALS'), isFalse);
    });

    test('401 with null code does not force logout', () {
      expect(shouldForceLogout(401, '/api/auth/login', null), isFalse);
    });

    test('403 with ACCOUNT_BANNED forces logout', () {
      expect(shouldForceLogout(403, '/api/users/me', 'ACCOUNT_BANNED'), isTrue);
    });

    test('403 with UNDERAGE does not force logout via shouldForceLogout (handled separately)', () {
      expect(shouldForceLogout(403, '/api/users/me', 'UNDERAGE'), isFalse);
    });

    test('403 with EMAIL_NOT_VERIFIED does not force logout', () {
      expect(shouldForceLogout(403, '/api/users/me', 'EMAIL_NOT_VERIFIED'), isFalse);
    });

    test('403 with AGE_REQUIRED does not force logout', () {
      expect(shouldForceLogout(403, '/api/users/me', 'AGE_REQUIRED'), isFalse);
    });

    test('200 OK does not force logout', () {
      expect(shouldForceLogout(200, '/api/users/me', null), isFalse);
    });
  });

  group('resolveNextRoute Pure Routing Decision Matrix', () {
    test('Unauthenticated user routes to login', () {
      final route = resolveNextRoute(
        isAuthenticated: false,
        emailVerified: false,
        needsDob: false,
        onboardingCompleted: false,
      );
      expect(route, AppRoutes.login);
    });

    test('Authenticated but email not verified routes to OTP verification', () {
      final route = resolveNextRoute(
        isAuthenticated: true,
        emailVerified: false,
        needsDob: false,
        onboardingCompleted: false,
      );
      expect(route, AppRoutes.otp);
    });

    test('Authenticated, email verified, needs DOB routes to DobGateScreen', () {
      final route = resolveNextRoute(
        isAuthenticated: true,
        emailVerified: true,
        needsDob: true,
        onboardingCompleted: false,
      );
      expect(route, AppRoutes.dobGate);
    });

    test('Authenticated, email verified, has DOB, onboarding pending routes to Onboarding', () {
      final route = resolveNextRoute(
        isAuthenticated: true,
        emailVerified: true,
        needsDob: false,
        onboardingCompleted: false,
      );
      expect(route, AppRoutes.onboarding);
    });

    test('Authenticated, email verified, has DOB, onboarding complete routes to MainNavigationShell', () {
      final route = resolveNextRoute(
        isAuthenticated: true,
        emailVerified: true,
        needsDob: false,
        onboardingCompleted: true,
      );
      expect(route, AppRoutes.main);
    });
  });
}

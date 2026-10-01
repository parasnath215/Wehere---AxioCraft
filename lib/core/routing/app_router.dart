import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_notifier.dart';
import 'app_routes.dart';

// Screens
import '../../screens/splash/splash_screen.dart';
import '../../screens/walkthrough/walkthrough_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/onboarding/onboarding_flow_screen.dart';
import '../../screens/main_navigation_shell.dart';
import '../../screens/chat/chat_conversation_screen.dart';
import '../../screens/journal/new_journal_screen.dart';
import '../../screens/journal/journal_success_screen.dart';
import '../../screens/progress/progress_dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/sos/sos_help_screen.dart';
import '../../screens/institutional/campus_corporate_screen.dart';
import '../../models/user_profile.dart';
import '../../models/journal_entry.dart';

enum PageTransitionType { fade, slideRight, slideUp }

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildPageRoute(const SplashScreen(), settings);

      case AppRoutes.walkthrough:
        return _buildPageRoute(const WalkthroughScreen(), settings);

      case AppRoutes.login:
        return _buildPageRoute(const LoginScreen(), settings);

      case AppRoutes.signup:
        return _buildPageRoute(const SignUpScreen(), settings);

      case AppRoutes.otp:
        final email = settings.arguments as String? ?? 'your email';
        return _buildPageRoute(
          OtpVerificationScreen(email: email),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      case AppRoutes.resetPassword:
        final email = settings.arguments as String? ?? '';
        return _buildPageRoute(
          ResetPasswordScreen(email: email),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      // Protected Route: Onboarding Flow
      case AppRoutes.onboarding:
        return _buildProtectedRoute(
          builder: () => const OnboardingFlowScreen(),
          settings: settings,
        );

      // Protected Route: Main Navigation Shell
      case AppRoutes.main:
        return _buildProtectedRoute(
          builder: () => const MainNavigationShell(),
          settings: settings,
        );

      // Protected Route: Chat 1-on-1 Conversation
      case AppRoutes.chatConversation:
        final peer = settings.arguments as UserProfile?;
        if (peer == null) return _errorRoute('Peer profile required');
        return _buildPageRoute(
          ChatConversationScreen(peer: peer),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      // Modal Stack: New Journal Reflection
      case AppRoutes.newJournal:
        return _buildPageRoute(
          const NewJournalScreen(),
          settings,
          transitionType: PageTransitionType.slideUp,
        );

      // Modal Stack: Journal Saved Success
      case AppRoutes.journalSuccess:
        final entry = settings.arguments as JournalEntry?;
        if (entry == null) return _errorRoute('Journal entry required');
        return _buildPageRoute(
          JournalSuccessScreen(entry: entry),
          settings,
          transitionType: PageTransitionType.fade,
        );

      // Modal / Screen: Progress & Streaks
      case AppRoutes.progress:
        return _buildPageRoute(
          const ProgressDashboardScreen(),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      // Modal / Screen: Profile & Growth
      case AppRoutes.profile:
        return _buildPageRoute(
          const ProfileScreen(),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      // Global Emergency Priority Route: SOS Help Hub
      case AppRoutes.sos:
        return _buildPageRoute(
          const SosHelpScreen(),
          settings,
          transitionType: PageTransitionType.slideUp,
        );

      // Campus & Corporate Institutional Hub
      case AppRoutes.institutional:
        return _buildPageRoute(
          const CampusCorporateScreen(),
          settings,
          transitionType: PageTransitionType.slideRight,
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Protected Route Guard wrapper
  static Route<dynamic> _buildProtectedRoute({
    required Widget Function() builder,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final auth = context.watch<AuthNotifier>();

        if (auth.status == AuthStatus.unauthenticated) {
          return const LoginScreen();
        }

        if (auth.status == AuthStatus.authenticated && !auth.hasCompletedOnboarding) {
          return const OnboardingFlowScreen();
        }

        return builder();
      },
    );
  }

  /// Custom Transition Route Builder
  static Route<dynamic> _buildPageRoute(
    Widget page,
    RouteSettings settings, {
    PageTransitionType transitionType = PageTransitionType.fade,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case PageTransitionType.slideRight:
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);

          case PageTransitionType.slideUp:
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);

          case PageTransitionType.fade:
            return FadeTransition(opacity: animation, child: child);
        }
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.red)),
        ),
      ),
    );
  }
}

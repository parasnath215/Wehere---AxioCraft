import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final auth = context.read<AuthNotifier>();
    
    // We delay slightly for branding/splash to show
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      if (auth.status == AuthStatus.initializing) {
        // Wait longer if still initializing
        Future.delayed(const Duration(milliseconds: 500), _checkAuthAndNavigate);
        return;
      }

      if (auth.isAuthenticated) {
        if (!auth.hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
        }
      } else if (!auth.hasSeenWalkthrough) {
        Navigator.pushReplacementNamed(context, AppRoutes.walkthrough);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7A62F8),
              Color(0xFF5E4BEE),
              Color(0xFF4C3ADB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),

                // Center Brand Identity
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Heart Sprout Emblem
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.favorite_rounded, size: 68, color: AppColors.primary),
                          Positioned(
                            top: 24,
                            right: 24,
                            child: Icon(Icons.eco_rounded, size: 28, color: Color(0xFF22C55E)),
                          ),
                          Icon(Icons.accessibility_new_rounded, size: 36, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    const Text(
                      'We Here',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Heart Divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 36, height: 1.5, color: Colors.white38),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.favorite, size: 14, color: Colors.white70),
                        ),
                        Container(width: 36, height: 1.5, color: Colors.white38),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'A safe place to talk,\nconnect and heal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'You’re not alone. ♡',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    const SizedBox(height: 16),
                    // Dot Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(isActive: true),
                        _buildDot(isActive: false),
                        _buildDot(isActive: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white38,
        shape: BoxShape.circle,
      ),
    );
  }
}

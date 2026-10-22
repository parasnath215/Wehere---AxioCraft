import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_routes.dart';
import '../../widgets/common/animated_pulse.dart';
import '../../state/auth_notifier.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    final auth = context.read<AuthNotifier>();
    
    // We delay slightly for branding/splash to show
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      if (auth.status == AuthStatus.initializing) {
        // Wait longer if still initializing
        _navTimer = Timer(const Duration(milliseconds: 500), _checkAuthAndNavigate);
        return;
      }

      if (auth.isAuthenticated) {
        auth.navigateAfterAuth(context);
      } else if (!auth.hasSeenWalkthrough) {
        Navigator.pushReplacementNamed(context, AppRoutes.walkthrough);
      } else {
        auth.navigateAfterAuth(context);
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
                    AnimatedPulse(
                      duration: const Duration(milliseconds: 1500),
                      minScale: 0.95,
                      maxScale: 1.05,
                      child: Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/Wehere_Logo_Assets/2_icon_mark_alone_transparent.png',
                            fit: BoxFit.contain,
                          ),
                        ),
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

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

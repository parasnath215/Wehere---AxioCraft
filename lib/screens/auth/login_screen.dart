import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isResetting = false;

  Future<void> _handleForgotPassword() async {
    String input = _loginController.text.trim();
    if (input.isEmpty) {
      final result = await _showForgotPasswordDialog();
      if (result == null || result.trim().isEmpty) return;
      input = result.trim();
    }

    await _sendPasswordResetOtp(input);
  }

  Future<void> _sendPasswordResetOtp(String identifier) async {
    setState(() => _isResetting = true);
    try {
      await apiClient.post('/auth/otp/request', data: {
        'email': identifier,
        'purpose': 'reset_password',
      });
      if (mounted) {
        final targetEmail = identifier;
        UiUtils.showTopSnackBar(context, 'Recovery code sent! Please check your email.', isError: false);
        Navigator.pushNamed(context, AppRoutes.resetPassword, arguments: targetEmail);
      }
    } on DioException catch (e) {
      if (mounted) {
        final err = e.response?.data?['error'] ?? 'Failed to request password reset';
        UiUtils.showTopSnackBar(context, err);
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  Future<String?> _showForgotPasswordDialog() async {
    final dialogController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password 🔑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email to receive a recovery code.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dialogController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                hintText: 'Email',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = dialogController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Illustration & Welcome Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Welcome\nBack!', style: AppTextStyles.h1),
                            const SizedBox(width: 8),
                            const Text('💜', style: TextStyle(fontSize: 26)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to continue your journey towards better connections.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySoft,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset('assets/Wehere_Logo_Assets/2_icon_mark_alone_transparent.png'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Segmented Tab Switch (Log In / Sign Up)
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.signup,
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 6),
                              Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Email input
              TextField(
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 14),

              // Password input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Remember me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _rememberMe = val ?? true;
                          });
                        },
                      ),
                      Text('Remember me', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  TextButton(
                    onPressed: _isResetting ? null : _handleForgotPassword,
                    child: _isResetting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Text(
                            'Forgot Password?',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final email = _loginController.text.trim();
                          final password = _passwordController.text.trim();
                          if (email.isEmpty || password.isEmpty) {
                            UiUtils.showTopSnackBar(context, 'Please enter email and password');
                            return;
                          }
                          // Email Validation
                          final emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
                          if (!emailRegExp.hasMatch(email)) {
                            UiUtils.showTopSnackBar(context, 'Please enter a valid email address.');
                            return;
                          }

                          final success = await context.read<AuthNotifier>().login(email, password);
                          if (context.mounted) {
                            final authNotifier = context.read<AuthNotifier>();
                            if (success && authNotifier.status == AuthStatus.authenticated) {
                              context.read<AppState>().setTabIndex(0);
                              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
                            } else if (authNotifier.status == AuthStatus.unverified) {
                              UiUtils.showTopSnackBar(context, 'Please verify your email address to continue.');
                              Navigator.pushNamed(context, AppRoutes.otp);
                            } else if (authNotifier.authError != null) {
                              UiUtils.showTopSnackBar(context, authNotifier.authError!);
                            }
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // OR divider
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
                ],
              ),

              const SizedBox(height: 18),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          try {
                            final GoogleSignIn googleSignIn = GoogleSignIn(
                              serverClientId: '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com',
                            );
                            final account = await googleSignIn.signIn();
                            if (account == null) return;

                            final googleAuth = await account.authentication;
                            final idToken = googleAuth.idToken;
                            if (idToken == null || idToken.isEmpty) {
                              if (context.mounted) UiUtils.showTopSnackBar(context, 'Failed to retrieve Google identity token.');
                              return;
                            }

                            if (!context.mounted) return;
                            final authNotifier = context.read<AuthNotifier>();
                            final check = await authNotifier.checkGoogleUser(idToken);

                            if (check != null && check['exists'] == true) {
                              // Existing user -> login directly using retrieved token!
                              final success = await authNotifier.loginWithGoogle(idToken);
                              if (!context.mounted) return;
                              if (success && authNotifier.status == AuthStatus.authenticated) {
                                if (authNotifier.needsDob) {
                                  Navigator.pushReplacementNamed(context, AppRoutes.dobGate);
                                } else if (!authNotifier.hasCompletedOnboarding) {
                                  Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
                                } else {
                                  context.read<AppState>().setTabIndex(0);
                                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
                                }
                              } else if (authNotifier.authError != null) {
                                UiUtils.showTopSnackBar(context, authNotifier.authError!);
                              }
                            } else {
                              // Brand new user from login screen -> forward to SignUpScreen with prefilled Google details!
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                AppRoutes.signup,
                                arguments: GoogleUserData(
                                  name: account.displayName ?? '',
                                  email: account.email,
                                  photoUrl: account.photoUrl,
                                  idToken: idToken,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) UiUtils.showTopSnackBar(context, 'Google sign-in error: $e');
                          }
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}

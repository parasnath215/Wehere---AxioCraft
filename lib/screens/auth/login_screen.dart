import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../core/network/api_client.dart';

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
    final email = _loginController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first.')),
      );
      return;
    }

    setState(() => _isResetting = true);
    try {
      await apiClient.post('/auth/otp/request', data: {
        'email': email,
        'purpose': 'reset_password',
      });
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.resetPassword, arguments: email);
      }
    } on DioException catch (e) {
      if (mounted) {
        final err = e.response?.data?['error'] ?? 'Failed to request password reset';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
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
                    child: const Icon(Icons.favorite, size: 54, color: AppColors.primary),
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

              // Email or Phone input
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  hintText: 'Email or Phone Number',
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
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                    onPressed: _handleForgotPassword,
                    child: Text(
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
                          if (_loginController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter email and password'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          final success = await context.read<AuthNotifier>().login(_loginController.text.trim(), _passwordController.text.trim());
                          if (success && context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
                          } else if (context.mounted && context.read<AuthNotifier>().authError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.read<AuthNotifier>().authError!), backgroundColor: Colors.redAccent),
                            );
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

            ],
          ),
        ),
      ),
    );
  }
}

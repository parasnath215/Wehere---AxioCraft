import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/ui_utils.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    if (otp.length != 6 || password.isEmpty) {
      UiUtils.showTopSnackBar(context, 'Please enter a valid 6-digit code and password.');
      return;
    }
    final passRegExp = RegExp(r'^(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!passRegExp.hasMatch(password)) {
      UiUtils.showTopSnackBar(context, 'Password must be at least 8 chars long, include a number and a special character.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await apiClient.post('/auth/reset-password', data: {
        'email': widget.email,
        'otp': otp,
        'newPassword': password,
      });

      if (mounted) {
        UiUtils.showTopSnackBar(context, 'Password updated successfully! ✨', isError: false);
        Navigator.pop(context); // Go back to login screen
      }
    } on DioException catch (e) {
      if (mounted) {
        final err = e.response?.data?['error'] ?? 'Failed to reset password';
        UiUtils.showTopSnackBar(context, err);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password 🔑', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit recovery code sent to ${widget.email} and create a new password.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.security_rounded, color: AppColors.primary),
                  hintText: '6-digit code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  hintText: 'New Password',
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

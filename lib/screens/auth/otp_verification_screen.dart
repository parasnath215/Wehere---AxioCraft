import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/network/api_client.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with WidgetsBindingObserver {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 60;
  DateTime? _targetTime;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer(60); // Default 60s cooldown from signup
  }

  void _startTimer(int seconds) {
    _targetTime = DateTime.now().add(Duration(seconds: seconds));
    _secondsRemaining = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetTime == null) return timer.cancel();
      final diff = _targetTime!.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        setState(() => _secondsRemaining = diff);
      } else {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _targetTime != null) {
      final diff = _targetTime!.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        setState(() => _secondsRemaining = diff);
      } else {
        setState(() => _secondsRemaining = 0);
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      final res = await apiClient.post('/auth/otp/request', data: {
        'email': widget.email,
        'purpose': 'verify_email',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.'), backgroundColor: AppColors.onlineGreen),
        );
        _startTimer(res.data['cooldown'] ?? 60);
      }
    } on DioException catch (e) {
      if (context.mounted) {
        final errorMsg = e.response?.data?['error'] ?? 'Failed to resend code';
        final cooldown = e.response?.data?['cooldown'];
        if (cooldown != null && cooldown is int) {
          _startTimer(cooldown);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 48, color: AppColors.primary),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.onlineGreen,
                        child: Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Verify Your Email', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'We’ve sent a 6-digit code to',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                widget.email.isNotEmpty ? widget.email : 'yourname@email.com',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),



              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 46,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _controllers[index].text.isNotEmpty ? AppColors.primary : AppColors.cardBorder,
                        width: _controllers[index].text.isNotEmpty ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto submit if all 6 filled
                        if (index == 5 && val.isNotEmpty) {
                          _verifySubmit(context, auth);
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 14),
              Text('Enter the 6-digit code below', style: AppTextStyles.bodySmall),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Didn’t receive the code?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Check your spam folder or request a new code.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _handleResend,
                child: Text(
                  _secondsRemaining > 0
                      ? 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                      : (_isResending ? 'Sending...' : 'Resend code now'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _secondsRemaining > 0 ? AppColors.textSecondary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _verifySubmit(context, auth),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  auth.logout();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                },
                child: Text(
                  'Change Email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifySubmit(BuildContext context, AuthNotifier auth) async {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length < 6) {
      UiUtils.showTopSnackBar(context, 'Please enter all 6 digits.');
      return;
    }
    
    // Clear keyboard
    FocusScope.of(context).unfocus();

    final appState = context.read<AppState>();
    final success = await auth.verifyOtp(pin);
    if (success && context.mounted) {
      appState.initializeUserFromAuth(
        id: auth.userId ?? 'user_1',
        name: auth.registeredName,
        email: auth.registeredEmail,
      );
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (context.mounted && auth.authError != null) {
      UiUtils.showTopSnackBar(context, auth.authError!);
    }
  }
}

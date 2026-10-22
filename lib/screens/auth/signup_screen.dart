import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/ui_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _password = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  bool _isGoogleVerified = false;
  String? _googleIdToken;
  bool _didInitGoogleData = false;

  // Password criteria getters
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasCaps => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_password);
  bool get _hasSpecial => RegExp(r'''[!@#$%^&*()_+={}\[\]|\\:;"'<>,.?/~`]''').hasMatch(_password);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _clearLegacyDrafts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitGoogleData) {
      _didInitGoogleData = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GoogleUserData) {
        _applyGoogleData(args);
      }
    }
  }

  void _applyGoogleData(GoogleUserData data) {
    setState(() {
      _isGoogleVerified = true;
      _googleIdToken = data.idToken;
      if (_nameController.text.isEmpty) {
        _nameController.text = data.name;
      }
      _emailController.text = data.email;
    });

    if (data.photoUrl != null && data.photoUrl!.isNotEmpty && _imagePaths.isEmpty) {
      _downloadGooglePhoto(data.photoUrl!);
    }
  }

  Future<void> _downloadGooglePhoto(String url) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/google_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await dio.download(url, filePath);
      if (File(filePath).existsSync() && mounted) {
        setState(() {
          if (!_imagePaths.contains(filePath)) {
            _imagePaths.insert(0, filePath);
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading Google photo: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '477223765836-9t4oml9khj3jelnlqc33r093uupa08cr.apps.googleusercontent.com',
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) UiUtils.showTopSnackBar(context, 'Failed to retrieve Google identity token.');
        return;
      }

      if (!mounted) return;
      final authNotifier = context.read<AuthNotifier>();
      final check = await authNotifier.checkGoogleUser(idToken);

      if (check != null && check['exists'] == true) {
        // Existing user -> login directly using retrieved token!
        final success = await authNotifier.loginWithGoogle(idToken);
        if (!mounted) return;
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
        // Brand new Google user: auto-fill the form and skip OTP!
        _applyGoogleData(GoogleUserData(
          name: account.displayName ?? '',
          email: account.email,
          photoUrl: account.photoUrl,
          idToken: idToken,
        ));
        if (mounted) {
          UiUtils.showTopSnackBar(
            context,
            'Google account connected. Profile details auto-filled! (OTP will be skipped)',
            isError: false,
          );
        }
      }
    } catch (e) {
      if (mounted) UiUtils.showTopSnackBar(context, 'Google sign-in error: $e');
    }
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {
        _password = _passwordController.text;
      });
    }
  }

  Future<void> _clearLegacyDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('signup_draft_handle');
      await prefs.remove('signup_draft_name');
      await prefs.remove('signup_draft_email');
      await prefs.remove('signup_draft_phone');
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 5) {
      UiUtils.showTopSnackBar(context, 'Maximum 5 images allowed');
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (_imagePaths.length < 5) {
            _imagePaths.add(img.path);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
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
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Create Your Account', style: AppTextStyles.h1),
                  const SizedBox(width: 8),
                  const Text('🌱', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Let’s get you started on your journey.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 12),

              // Image Picker Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Profile Photos (Minimum 2 required)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imagePaths.asMap().entries.map((e) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: FileImage(File(e.value)), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(e.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        )
                      ],
                    )),
                    if (_imagePaths.length < 5)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Full Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  hintText: 'Full Name',
                ),
              ),
              const SizedBox(height: 14),

              // Email
              if (_isGoogleVerified)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verified via Google — Email OTP verification skipped',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _emailController,
                readOnly: _isGoogleVerified,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    _isGoogleVerified ? Icons.check_circle_rounded : Icons.email_outlined,
                    color: _isGoogleVerified ? const Color(0xFF10B981) : AppColors.primary,
                  ),
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 14),

              // Phone Number
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                  hintText: 'Phone Number (Optional)',
                ),
              ),
              const SizedBox(height: 14),

              // Password
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
              const SizedBox(height: 8),
              _buildPasswordRequirementsCard(),
              const SizedBox(height: 14),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  hintText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Agree to terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        _agreedToTerms = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: AppTextStyles.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final url = Uri.parse('https://weherenetworks.com/terms-of-service.html');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.inAppWebView);
                                }
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final url = Uri.parse('https://weherenetworks.com/privacy-policy.html');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.inAppWebView);
                                }
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!_agreedToTerms) {
                            UiUtils.showTopSnackBar(context, 'Please agree to the Terms of Service & Privacy Policy.');
                            return;
                          }
                          if (_imagePaths.length < 2) {
                            UiUtils.showTopSnackBar(context, 'Please select at least 2 profile images.');
                            return;
                          }
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          final phone = _phoneController.text.trim();
                          final pass = _passwordController.text.trim();
                          final confirmPass = _confirmPasswordController.text.trim();

                          if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                            UiUtils.showTopSnackBar(context, 'Please fill all the required fields.');
                            return;
                          }

                          // Email Validation
                          final emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegExp.hasMatch(email)) {
                            UiUtils.showTopSnackBar(context, 'Please enter a valid email address.');
                            return;
                          }

                          // Phone Validation (if entered)
                          if (phone.isNotEmpty) {
                            final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
                            final phoneRegExp = RegExp(r"^\+?[0-9]{7,15}$");
                            if (!phoneRegExp.hasMatch(cleanPhone)) {
                              UiUtils.showTopSnackBar(context, 'Please enter a valid phone number (7-15 digits).');
                              return;
                            }
                          }

                          // Password Criteria Validation: 8 chars, 1 caps, 1 lower, 1 special
                          if (!_hasMinLength || !_hasCaps || !_hasLower || !_hasSpecial) {
                            UiUtils.showTopSnackBar(
                              context,
                              'Password must be at least 8 characters, contain 1 uppercase, 1 lowercase, and 1 special character.',
                            );
                            return;
                          }

                          if (pass != confirmPass) {
                            UiUtils.showTopSnackBar(context, 'Passwords do not match.');
                            return;
                          }

                          final appState = context.read<AppState>();
                          if (_isGoogleVerified && _googleIdToken != null) {
                            final success = await auth.registerWithGoogle(
                              idToken: _googleIdToken!,
                              pseudonym: name,
                              password: pass.isNotEmpty ? pass : null,
                              phone: phone.isNotEmpty ? phone : null,
                              imagePaths: _imagePaths,
                            );

                            if (success) {
                              appState.onboardingName = name;
                              appState.initializeUserFromAuth(
                                id: auth.userId?.isNotEmpty == true ? auth.userId! : 'usr_${DateTime.now().millisecondsSinceEpoch}',
                                name: auth.registeredName,
                                email: auth.registeredEmail,
                              );
                              if (context.mounted) {
                                if (auth.needsDob) {
                                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dobGate, (route) => false);
                                } else if (!auth.hasCompletedOnboarding) {
                                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (route) => false);
                                } else {
                                  context.read<AppState>().setTabIndex(0);
                                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
                                }
                              }
                            } else if (context.mounted && auth.authError != null) {
                              UiUtils.showTopSnackBar(context, auth.authError!);
                            }
                            return;
                          }

                          final success = await auth.register(
                            name,
                            email,
                            pass,
                            phone: phone.isNotEmpty ? phone : null,
                            imagePaths: _imagePaths,
                          );

                          if (success) {
                            appState.onboardingName = name;
                            if (context.mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.otp,
                                arguments: email,
                              );
                            }
                          } else if (context.mounted && auth.authError != null) {
                            UiUtils.showTopSnackBar(context, auth.authError!);
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
                            Text('Create ID & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

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

              const SizedBox(height: 16),

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
                  onPressed: auth.isLoading ? null : () => _handleGoogleSignIn(),
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

              const SizedBox(height: 20),

              // Already have an account? Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: Text(
                      'Log In',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementRow('8 characters minimum', _hasMinLength),
          const SizedBox(height: 6),
          _buildRequirementRow('1 uppercase letter (minimum)', _hasCaps),
          const SizedBox(height: 6),
          _buildRequirementRow('1 special character (minimum)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: isMet ? AppColors.onlineGreen : AppColors.sosRed,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              color: isMet ? AppColors.onlineGreen : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

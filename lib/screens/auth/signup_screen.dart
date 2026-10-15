import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/ui_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _password = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  // Password criteria getters
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasCaps => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _hasSpecial => RegExp(r'[^a-zA-Z0-9]').hasMatch(_password);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _handleController.addListener(_saveDraft);
    _nameController.addListener(_saveDraft);
    _emailController.addListener(_saveDraft);
    _loadDraft();
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {
        _password = _passwordController.text;
      });
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftHandle = prefs.getString('signup_draft_handle');
      final draftName = prefs.getString('signup_draft_name');
      final draftEmail = prefs.getString('signup_draft_email');
      if (mounted) {
        setState(() {
          if (draftHandle != null && draftHandle.isNotEmpty && _handleController.text.isEmpty) {
            _handleController.text = draftHandle;
          }
          if (draftName != null && draftName.isNotEmpty && _nameController.text.isEmpty) {
            _nameController.text = draftName;
          }
          if (draftEmail != null && draftEmail.isNotEmpty && _emailController.text.isEmpty) {
            _emailController.text = draftEmail;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signup_draft_handle', _handleController.text.trim());
      await prefs.setString('signup_draft_name', _nameController.text.trim());
      await prefs.setString('signup_draft_email', _emailController.text.trim());
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _handleController.removeListener(_saveDraft);
    _nameController.removeListener(_saveDraft);
    _emailController.removeListener(_saveDraft);
    _handleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
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

  void _randomizeHandle() {
    final adjectives = [
      'gentle', 'calm', 'serene', 'mindful', 'hopeful', 'radiant', 'peaceful',
      'bright', 'golden', 'kind', 'warm', 'brave', 'cozy', 'zen', 'vibrant',
      'stellar', 'luminous', 'tender', 'tranquil', 'graceful', 'blissful', 'sunny'
    ];
    final nouns = [
      'river', 'nebula', 'lotus', 'ember', 'compass', 'spirit', 'meadow',
      'breeze', 'aurora', 'haven', 'echo', 'solace', 'horizon', 'spark',
      'willow', 'ocean', 'cedar', 'starlight', 'voyager', 'oasis', 'bloom'
    ];
    final rng = math.Random();
    final adj = adjectives[rng.nextInt(adjectives.length)];
    final noun = nouns[rng.nextInt(nouns.length)];
    // Random 4-digit number ensuring guaranteed unique handles across users
    final numSuffix = 1000 + rng.nextInt(9000);
    final uniqueId = '${adj}_${noun}_$numSuffix';
    setState(() {
      _handleController.text = uniqueId;
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

              const SizedBox(height: 20),

              // Unique ID Handle Input
              TextField(
                controller: _handleController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
                  hintText: 'Unique Handle (e.g. johndoe94)',
                  suffixIcon: TextButton.icon(
                    onPressed: _randomizeHandle,
                    icon: const Icon(Icons.shuffle_rounded, size: 14),
                    label: const Text('Random ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  hintText: 'Email',
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
                          final pass = _passwordController.text.trim();
                          final confirmPass = _confirmPasswordController.text.trim();
                          final handle = _handleController.text.trim();

                          if (name.isEmpty || email.isEmpty || pass.isEmpty || handle.isEmpty) {
                            UiUtils.showTopSnackBar(context, 'Please fill all the required fields.');
                            return;
                          }

                          // Email Validation
                          final emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegExp.hasMatch(email)) {
                            UiUtils.showTopSnackBar(context, 'Please enter a valid email address.');
                            return;
                          }

                          // Password Criteria Validation: 8 chars, 1 caps, 1 special (minimum)
                          if (!_hasMinLength || !_hasCaps || !_hasSpecial) {
                            UiUtils.showTopSnackBar(
                              context,
                              'Password must be at least 8 characters long, contain at least 1 uppercase letter and 1 special character.',
                            );
                            return;
                          }

                          if (pass != confirmPass) {
                            UiUtils.showTopSnackBar(context, 'Passwords do not match.');
                            return;
                          }

                          final appState = context.read<AppState>();
                          final success = await auth.register(
                            name,
                            email,
                            pass,
                            customHandle: handle,
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
              const SizedBox(height: 16),

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

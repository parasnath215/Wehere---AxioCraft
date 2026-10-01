import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _handleController = TextEditingController(text: 'alex_7294');
  final TextEditingController _nameController = TextEditingController(text: 'Alex');
  final TextEditingController _emailController = TextEditingController(text: 'alex@example.com');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _randomizeHandle() {
    final handles = [
      'gentle_river_42',
      'calm_nebula_88',
      'quiet_compass_19',
      'mindful_lotus_77',
      'serene_ember_33',
      'alex_growth_94',
      'brave_spirit_11'
    ];
    final rand = handles[DateTime.now().millisecondsSinceEpoch % handles.length];
    setState(() {
      _handleController.text = rand;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
        ),
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
                  hintText: 'Unique Handle (e.g. alex_7294)',
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

              // Phone Number (Optional)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
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
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                        children: const [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign Up Button
              ElevatedButton(
                onPressed: () async {
                  if (_imagePaths.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least 2 profile images.'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  
                  final auth = context.read<AuthNotifier>();
                  final appState = context.read<AppState>();
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final pass = _passwordController.text.trim();
                  final handle = _handleController.text.trim();

                  final success = await auth.register(
                    name.isNotEmpty ? name : 'Alex',
                    email.isNotEmpty ? email : 'alex@wehere.com',
                    pass.isNotEmpty ? pass : 'secret123',
                    customHandle: handle.isNotEmpty ? handle : null,
                    imagePaths: _imagePaths,
                  );

                  if (success) {
                    appState.onboardingName = name.isNotEmpty ? name : 'Alex';
                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.otp,
                        arguments: email,
                      );
                    }
                  } else if (context.mounted && auth.authError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.authError!), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Create ID & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
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

              // Divider "or sign up with"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or sign up with', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),
              const SizedBox(height: 20),

              // Social OAuth Buttons (Google & Apple Only)
              Row(
                children: [
                  _buildOAuthButton(
                    label: 'Google',
                    icon: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      child: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF4285F4))),
                    ),
                    onTap: () async {
                      final auth = context.read<AuthNotifier>();
                      final appState = context.read<AppState>();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signing up with Google Account... 🌱'), duration: Duration(seconds: 1)),
                      );
                      final success = await auth.register(
                        _nameController.text.isNotEmpty ? _nameController.text : 'Alex',
                        'alex@gmail.com',
                        'demo1234',
                        customHandle: _handleController.text.isNotEmpty ? _handleController.text : null,
                      );
                      if (success) {
                        appState.onboardingName = _nameController.text.isNotEmpty ? _nameController.text : 'Alex';
                        if (context.mounted) {
                          Navigator.pushNamed(context, AppRoutes.onboarding);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 14),
                  _buildOAuthButton(
                    label: 'Apple',
                    icon: const Icon(Icons.apple_rounded, size: 20, color: Colors.black),
                    onTap: () async {
                      final auth = context.read<AuthNotifier>();
                      final appState = context.read<AppState>();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signing up with Apple ID... '), duration: Duration(seconds: 1)),
                      );
                      final success = await auth.register(
                        _nameController.text.isNotEmpty ? _nameController.text : 'Alex',
                        'alex@apple.com',
                        'demo1234',
                        customHandle: _handleController.text.isNotEmpty ? _handleController.text : null,
                      );
                      if (success) {
                        appState.onboardingName = _nameController.text.isNotEmpty ? _nameController.text : 'Alex';
                        if (context.mounted) {
                          Navigator.pushNamed(context, AppRoutes.onboarding);
                        }
                      }
                    },
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

  Widget _buildOAuthButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                'Sign up with $label',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

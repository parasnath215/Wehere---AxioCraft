import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _currentStep = 1;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Step 2 Interests
  final Set<String> _selectedInterests = {};

  // Step 3 Feelings Lately
  final Set<String> _selectedFeelings = {};

  // Step 4 Looking For
  final Set<String> _selectedLookingFor = {};

  // Step 5 Anonymity / Photos
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.onboardingName.isNotEmpty) {
        setState(() {
          _nameController.text = appState.onboardingName;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Step $_currentStep of 5',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator Bar (5 Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: List.generate(5, (index) {
                  final stepNum = index + 1;
                  final isDone = stepNum < _currentStep;
                  final isCurrent = stepNum == _currentStep;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDone || isCurrent) ? AppColors.primary : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Continue CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ElevatedButton(
                onPressed: _handleNext,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 6 ? 'Start Your Journey' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    if (_currentStep == 2 && _selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one interest.')));
      return;
    }
    if (_currentStep == 3 && _selectedFeelings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select how you are feeling.')));
      return;
    }
    if (_currentStep == 4 && _selectedLookingFor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select what you are looking for.')));
      return;
    }

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Complete Onboarding with real user details on backend
      await context.read<AuthNotifier>().completeOnboarding(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        interests: _selectedInterests.toList(),
        feelings: _selectedFeelings.toList(),
        supportTypes: _selectedLookingFor.toList(),
        isAnonymous: _isAnonymous,
      );

      // Also update local state so UI is reactive
      appState.completeOnboarding(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        interests: _selectedInterests.toList(),
        feelings: _selectedFeelings.toList(),
        supportTypes: _selectedLookingFor.toList(),
        isAnonymous: _isAnonymous,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1ProfileInfo();
      case 2:
        return _buildStep2Interests();
      case 3:
        return _buildStep3Feelings();
      case 4:
        return _buildStep4LookingFor();
      case 5:
        return _buildStep6Summary(); // Privacy is now step 5
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Tell Us About Yourself (Mockup 1.17.22 AM (1))
  Widget _buildStep1ProfileInfo() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.assignment_ind_outlined, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('Tell us about yourself ✨', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('This helps us personalize your experience for a better you.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),

        // Auto-fetch banner
        Consumer<AppState>(
          builder: (context, appState, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Details auto-fetched from created ID ${appState.currentUser.id}. All responses customize your peer matches.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
            labelText: 'Full Name (Or Pseudonym)',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
            labelText: 'Location (Optional)',
          ),
        ),
        const SizedBox(height: 24),
        _buildPrivacyBadge('Your information is safe with us. We respect your privacy and never share your data.'),
      ],
    );
  }

  // STEP 2: Interests (Mockup 1.17.22 AM (2))
  Widget _buildStep2Interests() {
    final interestsList = [
      {'name': 'Mental Health', 'icon': Icons.favorite_outline},
      {'name': 'Personal Growth', 'icon': Icons.eco_outlined},
      {'name': 'Relationships', 'icon': Icons.people_outline},
      {'name': 'Education', 'icon': Icons.menu_book_outlined},
      {'name': 'Career', 'icon': Icons.work_outline},
      {'name': 'Mindfulness', 'icon': Icons.spa_outlined},
      {'name': 'Health & Fitness', 'icon': Icons.fitness_center_outlined},
      {'name': 'Hobbies', 'icon': Icons.palette_outlined},
      {'name': 'Other', 'icon': Icons.more_horiz_rounded},
    ];

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.favorite_rounded, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('What are you\ninterested in? ✨', textAlign: TextAlign.center, style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Choose a few topics that matter to you.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: interestsList.length,
          itemBuilder: (context, index) {
            final item = interestsList[index];
            final name = item['name'] as String;
            final icon = item['icon'] as IconData;
            final isSelected = _selectedInterests.contains(name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(name);
                  } else {
                    _selectedInterests.add(name);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1EFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 26, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildPrivacyBadge('Don’t worry, you can always update your interests later.'),
      ],
    );
  }

  // STEP 3: Feelings Lately (Mockup 1.17.26 AM)
  Widget _buildStep3Feelings() {
    final feelings = [
      {'name': 'Lonely', 'emoji': '😔'},
      {'name': 'Anxious', 'emoji': '😟'},
      {'name': 'Stressed', 'emoji': '😫'},
      {'name': 'Heartbroken', 'emoji': '💔'},
      {'name': 'Career Pressure', 'emoji': '🎓'},
      {'name': 'Family Issues', 'emoji': '👥'},
      {'name': 'Overwhelmed', 'emoji': '🌧️'},
      {'name': 'Burnout', 'emoji': '🪫'},
      {'name': 'Self Growth', 'emoji': '🌱'},
    ];

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.cloud_outlined, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('How are you feeling\nlately?', textAlign: TextAlign.center, style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Select all that you relate to.\nThis helps us recommend better connections for you.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: feelings.length,
          itemBuilder: (context, index) {
            final item = feelings[index];
            final name = item['name'] as String;
            final emoji = item['emoji'] as String;
            final isSelected = _selectedFeelings.contains(name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFeelings.remove(name);
                  } else {
                    _selectedFeelings.add(name);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1EFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildPrivacyBadge('Your feelings are safe with us 💜 We never judge. Your privacy and comfort are our top priority.'),
      ],
    );
  }

  // STEP 4: What are you looking for? (Mockup 1.17.25 AM (2))
  Widget _buildStep4LookingFor() {
    final supportOptions = [
      {'title': 'Someone to Talk To', 'desc': 'I want someone to listen and talk to me.', 'icon': Icons.chat_bubble_outline},
      {'title': 'New Friends', 'desc': 'I want to make new friends and build meaningful bonds.', 'icon': Icons.people_outline},
      {'title': 'Emotional Support', 'desc': 'I need support and guidance through tough times.', 'icon': Icons.favorite_border},
      {'title': 'Accountability Partner', 'desc': 'I want someone to stay motivated and achieve goals together.', 'icon': Icons.track_changes_outlined},
      {'title': 'Motivation & Positivity', 'desc': 'I want positive vibes and daily motivation.', 'icon': Icons.wb_sunny_outlined},
    ];

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.radar_rounded, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('What are you\nlooking for?', textAlign: TextAlign.center, style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Choose what best describes you. You can select multiple options.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        ...supportOptions.map((opt) {
          final title = opt['title'] as String;
          final desc = opt['desc'] as String;
          final icon = opt['icon'] as IconData;
          final isSelected = _selectedLookingFor.contains(title);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedLookingFor.remove(title);
                  } else {
                    _selectedLookingFor.add(title);
                  }
                });
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF3F0FF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.h3.copyWith(fontSize: 14, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(desc, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildPrivacyBadge('You’re in control. You can change this anytime from your settings.'),
      ],
    );
  }



  // STEP 6: You're All Set Summary
  Widget _buildStep6Summary() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text('You’re All Set! ✨', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Thanks for completing your profile.\nWe’re excited to support you on your journey.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Here’s a summary of your preferences', style: AppTextStyles.h3.copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              _buildSummaryRow(
                Icons.favorite_rounded,
                'Interests',
                _selectedInterests.take(3).join(', '),
              ),
              const Divider(height: 24),
              _buildSummaryRow(
                Icons.track_changes_rounded,
                'Goals',
                _selectedLookingFor.take(2).join(', '),
              ),
              const Divider(height: 24),
              _buildSummaryRow(
                Icons.person_rounded,
                'About You',
                _isAnonymous ? 'Anonymous Mode (Safe Pseudonym)' : '${_nameController.text}, ${_locationController.text}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPrivacyBadge('Great things take time. You’ve taken the first step today. We’re here for you, every step of the way. 💜'),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      ],
    );
  }

  Widget _buildPrivacyBadge(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';
import '../../core/constants/indian_locations.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _currentStep = 1;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController(); // App Display Name / Alias
  final TextEditingController _firstNameController = TextEditingController(); // Mandatory Real Name
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _stateMenuController = TextEditingController();
  final TextEditingController _cityMenuController = TextEditingController();
  final TextEditingController _professionMenuController = TextEditingController();
  
  String? _locationError;
  String? _professionError;
  String? _nameError;
  String? _realNameError;

  static final RegExp _blockedWords = RegExp(
    r'\b(suicide|kill\s*myself|self\s*harm|slit|die|cutter|worthless|hang\s*myself|murder|fuck|shit|bitch|asshole|bastard|dick|slut|whore|nigger|faggot)\b',
    caseSensitive: false,
  );

  // Using IndianLocations.stateCityMap
  String? _selectedState;
  String? _selectedCity;
  String? _selectedProfession;

  static const List<String> professionOptions = [
    'Working Professional',
    'College / University Student',
    'Freelancer / Creator',
    'Business Owner / Entrepreneur',
    'Looking for Work',
    'Taking a Break',
    'Homemaker / Caregiver',
    'Preparing for Exams / Further Studies',
    'Others',
  ];

  void _updateLocationController() {
    if (_selectedState != null && _selectedCity != null) {
      _locationController.text = '$_selectedCity, $_selectedState';
    } else if (_selectedState != null) {
      _locationController.text = _selectedState!;
    } else {
      _locationController.text = '';
    }
  }

  // Step 2 Interests
  final Set<String> _selectedInterests = {};

  // Step 3 Feelings Lately
  final Set<String> _selectedFeelings = {};

  // Step 4 Looking For
  final Set<String> _selectedLookingFor = {};

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_saveDraft);
    _firstNameController.addListener(_saveDraft);
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Delete draft keys onboarding_draft_dob and onboarding_draft_age once at startup of the screen
      await prefs.remove('onboarding_draft_dob');
      await prefs.remove('onboarding_draft_age');

      final savedName = prefs.getString('onboarding_draft_name');
      final savedFirstName = prefs.getString('onboarding_draft_first_name');
      final savedState = prefs.getString('onboarding_draft_state');
      final savedCity = prefs.getString('onboarding_draft_city');
      final savedProfession = prefs.getString('onboarding_draft_profession');
      final savedInterests = prefs.getStringList('onboarding_draft_interests');
      final savedFeelings = prefs.getStringList('onboarding_draft_feelings');
      final savedLookingFor = prefs.getStringList('onboarding_draft_looking_for');
      final savedStep = prefs.getInt('onboarding_draft_step');
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);

      setState(() {
          // Display Name prefilled from server displayName if present
          if (savedName != null && savedName.isNotEmpty) {
            _nameController.text = savedName;
          } else if (appState.currentUser.displayName != null && appState.currentUser.displayName!.isNotEmpty) {
            _nameController.text = appState.currentUser.displayName!;
          } else {
            _nameController.text = '';
          }

          // Real Name prefilled from server realFirstName
          if (savedFirstName != null && savedFirstName.isNotEmpty) {
            _firstNameController.text = savedFirstName;
          } else if (appState.currentUser.realFirstName != null && appState.currentUser.realFirstName!.isNotEmpty) {
            _firstNameController.text = appState.currentUser.realFirstName!;
          } else if (appState.onboardingName.isNotEmpty) {
            _firstNameController.text = appState.onboardingName;
          } else if (appState.currentUser.name.isNotEmpty) {
            _firstNameController.text = appState.currentUser.name;
          }

          if (savedState != null && savedState.isNotEmpty) {
            String resolvedState = savedState;
            if (!IndianLocations.stateCityMap.containsKey(resolvedState) && (resolvedState == 'Delhi (National Capital Territory)' || resolvedState == 'Delhi (NCT)')) {
              resolvedState = 'Delhi';
            }
            _selectedState = resolvedState;
            _stateMenuController.text = resolvedState;
          }
          if (savedCity != null && savedCity.isNotEmpty) {
            _selectedCity = savedCity;
            _cityMenuController.text = savedCity;
          }
          _updateLocationController();

          if (savedProfession != null && savedProfession.isNotEmpty) {
            _selectedProfession = savedProfession;
            _professionMenuController.text = savedProfession;
          }

          if (savedInterests != null && savedInterests.isNotEmpty) {
            _selectedInterests.clear();
            _selectedInterests.addAll(savedInterests);
          }
          if (savedFeelings != null && savedFeelings.isNotEmpty) {
            _selectedFeelings.clear();
            _selectedFeelings.addAll(savedFeelings);
          }
          if (savedLookingFor != null && savedLookingFor.isNotEmpty) {
            _selectedLookingFor.clear();
            _selectedLookingFor.addAll(savedLookingFor);
          }

          if (savedStep != null && savedStep >= 1 && savedStep <= 5) {
            _currentStep = savedStep;
          }
        });
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_draft_name', _nameController.text.trim());
      await prefs.setString('onboarding_draft_first_name', _firstNameController.text.trim());
      if (_selectedState != null) {
        await prefs.setString('onboarding_draft_state', _selectedState!);
      } else {
        await prefs.remove('onboarding_draft_state');
      }
      if (_selectedCity != null) {
        await prefs.setString('onboarding_draft_city', _selectedCity!);
      } else {
        await prefs.remove('onboarding_draft_city');
      }
      if (_selectedProfession != null) {
        await prefs.setString('onboarding_draft_profession', _selectedProfession!);
      } else {
        await prefs.remove('onboarding_draft_profession');
      }
      await prefs.setStringList('onboarding_draft_interests', _selectedInterests.toList());
      await prefs.setStringList('onboarding_draft_feelings', _selectedFeelings.toList());
      await prefs.setStringList('onboarding_draft_looking_for', _selectedLookingFor.toList());
      await prefs.setInt('onboarding_draft_step', _currentStep);
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_draft_name');
      await prefs.remove('onboarding_draft_first_name');
      await prefs.remove('onboarding_draft_dob');
      await prefs.remove('onboarding_draft_age');
      await prefs.remove('onboarding_draft_state');
      await prefs.remove('onboarding_draft_city');
      await prefs.remove('onboarding_draft_profession');
      await prefs.remove('onboarding_draft_interests');
      await prefs.remove('onboarding_draft_feelings');
      await prefs.remove('onboarding_draft_looking_for');
      await prefs.remove('onboarding_draft_step');
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.removeListener(_saveDraft);
    _firstNameController.removeListener(_saveDraft);
    _nameController.dispose();
    _firstNameController.dispose();
    _locationController.dispose();
    _stateMenuController.dispose();
    _cityMenuController.dispose();
    _professionMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 1) {
          setState(() {
            _currentStep--;
          });
          _saveDraft();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _currentStep > 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                    _saveDraft();
                  },
                )
              : null,
          title: Text(
            'Step $_currentStep of 5',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      ),
    );
  }

  void _handleNext() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_currentStep == 1) {
      final realName = _firstNameController.text.trim();
      if (realName.isEmpty) {
        setState(() {
          _realNameError = 'Please enter your real name.';
        });
        return;
      }
      if (realName.length < 2) {
        setState(() {
          _realNameError = 'Real name must be at least 2 characters.';
        });
        return;
      }
      final displayName = _nameController.text.trim();
      if (displayName.isEmpty) {
        setState(() {
          _nameError = 'Please choose an App Display Name / Alias.';
        });
        return;
      }
      if (displayName.length < 2) {
        setState(() {
          _nameError = 'Display name must be at least 2 characters.';
        });
        return;
      }
      if (_blockedWords.hasMatch(displayName)) {
        setState(() {
          _nameError = 'Please choose a gentle, safe display name without triggering or offensive words.';
        });
        return;
      }

      if (_selectedState == null || _selectedCity == null) {
        setState(() {
          if (_selectedState == null && _selectedCity == null) {
            _locationError = 'Please select state and city';
          } else if (_selectedState == null) {
            _locationError = 'Please select state first';
          } else {
            _locationError = 'Please select city';
          }
        });
        return;
      }
      if (_selectedProfession == null) {
        setState(() {
          _professionError = 'Please select your profession';
        });
        return;
      }
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
      _saveDraft();
    } else {
      final auth = context.read<AuthNotifier>();
      final displayName = _nameController.text.trim();
      final realFirstName = _firstNameController.text.trim();

      await auth.completeOnboarding(
        name: displayName,
        displayName: displayName,
        realFirstName: realFirstName.isNotEmpty ? realFirstName : null,
        nameDisplayPreference: 'DISPLAY_NAME_ONLY',
        location: _locationController.text.trim(),
        profession: _selectedProfession,
        interests: _selectedInterests.toList(),
        feelings: _selectedFeelings.toList(),
        supportTypes: _selectedLookingFor.toList(),
        isAnonymous: false,
      );

      if (!mounted) return;

      if (!auth.hasCompletedOnboarding) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.authError ?? 'Failed to complete onboarding')),
        );
        return;
      }

      // Also update local state so UI is reactive
      appState.completeOnboarding(
        name: displayName,
        displayName: displayName,
        realFirstName: realFirstName.isNotEmpty ? realFirstName : null,
        nameDisplayPreference: 'DISPLAY_NAME_ONLY',
        location: _locationController.text.trim(),
        profession: _selectedProfession,
        interests: _selectedInterests.toList(),
        feelings: _selectedFeelings.toList(),
        supportTypes: _selectedLookingFor.toList(),
        isAnonymous: false,
      );

      await _clearDraft();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (route) => false,
        );
      }
    }
  }

  IconData _getInterestIcon(String name) {
    switch(name) {
      case 'Mental Health': return Icons.favorite_outline;
      case 'Personal Growth': return Icons.eco_outlined;
      case 'Relationships': return Icons.people_outline;
      case 'Education': return Icons.menu_book_outlined;
      case 'Career': return Icons.work_outline;
      case 'Mindfulness': return Icons.spa_outlined;
      case 'Health & Fitness': return Icons.fitness_center_outlined;
      case 'Hobbies': return Icons.palette_outlined;
      case 'Others':
      case 'Other': return Icons.more_horiz_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  String _getFeelingEmoji(String name) {
    switch(name) {
      case 'Just Need Someone to Talk To': return '💬';
      case 'Relationship Issues': return '💔';
      case 'Friendship Issues': return '🤝';
      case 'Study Pressure': return '📚';
      case 'Financial Stress': return '💸';
      case 'Feeling Down': return '😔';
      case 'Low Confidence': return '🥺';
      case 'Major Life Changes': return '🎒';
      case 'Grief / Loss': return '🕊️';
      case 'Frustrated / Angry': return '😤';
      case 'Feeling Lost': return '🧭';
      case 'Looking for Motivation': return '🔥';
      // Fallbacks
      case 'Lonely': return '😔';
      case 'Anxious': return '😟';
      case 'Stressed': return '😫';
      case 'Heartbroken': return '💔';
      case 'Career Pressure': return '🎓';
      case 'Family Issues': return '👥';
      case 'Overwhelmed': return '🌧️';
      case 'Burnout': return '🪫';
      case 'Self Growth': return '🌱';
      default: return '🙂';
    }
  }

  Map<String, dynamic> _getSupportDetails(String title) {
    switch(title) {
      case 'Someone to Talk To': return {'desc': 'I want someone to listen and talk to me.', 'icon': Icons.chat_bubble_outline};
      case 'New Friends': return {'desc': 'I want to make new friends and build meaningful bonds.', 'icon': Icons.people_outline};
      case 'Emotional Support': return {'desc': 'I need support and guidance through tough times.', 'icon': Icons.favorite_border};
      case 'Accountability Partner': return {'desc': 'I want someone to stay motivated and achieve goals together.', 'icon': Icons.track_changes_outlined};
      case 'Motivation & Positivity': return {'desc': 'I want positive vibes and daily motivation.', 'icon': Icons.wb_sunny_outlined};
      default: return {'desc': 'Support from the community.', 'icon': Icons.handshake_outlined};
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

        // 1. Mandatory Real Name (auto-filled from signup)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _firstNameController,
              onChanged: (_) {
                if (_realNameError != null) setState(() => _realNameError = null);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                labelText: 'Real Name *',
                hintText: 'e.g. Rahul Sharma',
                errorText: _realNameError,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Your real name is kept private and only shared in chat when you both mutually agree.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
               ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. App Display Name / Alias (empty by default)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                labelText: 'App Display Name / Alias *',
                hintText: 'e.g. QuietRiver, MindfulSam',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'This is the alias potential matches see on your card. Pick an alias or preferred nickname that keeps you comfortable.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownMenu<String>(
          controller: _stateMenuController,
          menuHeight: 220,
          menuStyle: const MenuStyle(
            maximumSize: WidgetStatePropertyAll<Size>(Size(280, 220)),
          ),
          initialSelection: _selectedState,
          enableFilter: true,
          enableSearch: true,
          expandedInsets: EdgeInsets.zero,
          leadingIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
          label: const Text('State *'),
          onSelected: (val) {
            setState(() {
              _selectedState = val;
              _selectedCity = null;
              _cityMenuController.clear();
              _locationError = null;
              _updateLocationController();
            });
            _saveDraft();
          },
          dropdownMenuEntries: IndianLocations.stateCityMap.keys.map((String state) {
            return DropdownMenuEntry<String>(value: state, label: state);
          }).toList(),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _selectedState == null
              ? () {
                  setState(() {
                    _locationError = 'Please select state first';
                  });
                }
              : null,
          child: IgnorePointer(
            ignoring: _selectedState == null,
            child: DropdownMenu<String>(
              controller: _cityMenuController,
              menuHeight: 220,
              menuStyle: const MenuStyle(
                maximumSize: WidgetStatePropertyAll<Size>(Size(280, 220)),
              ),
              initialSelection: _selectedCity,
              enableFilter: true,
              enableSearch: true,
              expandedInsets: EdgeInsets.zero,
              leadingIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
              label: const Text('City *'),
              onSelected: (val) {
                setState(() {
                  _selectedCity = val;
                  _locationError = null;
                  _updateLocationController();
                });
                _saveDraft();
              },
              dropdownMenuEntries: (_selectedState == null ? <String>[] : IndianLocations.stateCityMap[_selectedState] ?? <String>[]).map((String city) {
                return DropdownMenuEntry<String>(value: city, label: city);
              }).toList(),
            ),
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sosRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.sosRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: const TextStyle(
                      color: AppColors.sosRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        DropdownMenu<String>(
          controller: _professionMenuController,
          menuHeight: 240,
          menuStyle: const MenuStyle(
            maximumSize: WidgetStatePropertyAll<Size>(Size(320, 240)),
          ),
          initialSelection: _selectedProfession,
          enableFilter: true,
          enableSearch: true,
          expandedInsets: EdgeInsets.zero,
          leadingIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primary),
          label: const Text('Profession *'),
          onSelected: (val) {
            setState(() {
              _selectedProfession = val;
              _professionError = null;
            });
            _saveDraft();
          },
          dropdownMenuEntries: professionOptions.map((String prof) {
            return DropdownMenuEntry<String>(value: prof, label: prof);
          }).toList(),
        ),
        if (_professionError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sosRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.sosRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _professionError!,
                    style: const TextStyle(
                      color: AppColors.sosRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildPrivacyBadge('Your information is safe with us. We respect your privacy and never share your data.'),
      ],
    );
  }

  // STEP 2: Interests (Mockup 1.17.22 AM (2))
  Widget _buildStep2Interests() {
    final appState = Provider.of<AppState>(context);
    final interestsList = appState.availableInterests.isNotEmpty ? appState.availableInterests.map((e) => e.label).toList() : [
      'Mental Health', 'Personal Growth', 'Relationships', 'Education', 'Career', 'Mindfulness', 'Health & Fitness', 'Hobbies', 'Others'
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
            final name = interestsList[index];
            final icon = _getInterestIcon(name);
            final isSelected = _selectedInterests.contains(name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(name);
                  } else {
                    if (_selectedInterests.length < 5) {
                      _selectedInterests.add(name);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can select up to 5 interests.')));
                    }
                  }
                });
                _saveDraft();
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
    final appState = Provider.of<AppState>(context);
    final feelings = appState.availableFeelings.isNotEmpty ? appState.availableFeelings.map((e) => e.label).toList() : [
      'Just Need Someone to Talk To',
      'Relationship Issues',
      'Friendship Issues',
      'Study Pressure',
      'Financial Stress',
      'Feeling Down',
      'Low Confidence',
      'Major Life Changes',
      'Grief / Loss',
      'Frustrated / Angry',
      'Feeling Lost',
      'Looking for Motivation',
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
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemCount: feelings.length,
          itemBuilder: (context, index) {
            final name = feelings[index];
            final emoji = _getFeelingEmoji(name);
            final isSelected = _selectedFeelings.contains(name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFeelings.remove(name);
                  } else {
                    if (_selectedFeelings.length < 5) {
                      _selectedFeelings.add(name);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can select up to 5 feelings.')));
                    }
                  }
                });
                _saveDraft();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1EFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
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
    final appState = Provider.of<AppState>(context);
    final supportOptions = appState.availableSupportTypes.isNotEmpty ? appState.availableSupportTypes.map((e) => e.label).toList() : [
      'Someone to Talk To', 'New Friends', 'Emotional Support', 'Accountability Partner', 'Motivation & Positivity'
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
        Text('You can select upto two options.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        ...supportOptions.map((title) {
          final details = _getSupportDetails(title);
          final desc = details['desc'] as String;
          final icon = details['icon'] as IconData;
          final isSelected = _selectedLookingFor.contains(title);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedLookingFor.remove(title);
                  } else {
                    if (_selectedLookingFor.length < 2) {
                      _selectedLookingFor.add(title);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can select up to 2 options.')));
                    }
                  }
                });
                _saveDraft();
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
              const SizedBox(height: 6),
              Text('Tap any section to review or make changes.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _buildSummaryRow(
                Icons.favorite_rounded,
                'Interests',
                _selectedInterests.take(3).join(', '),
                onTap: () {
                  setState(() => _currentStep = 2);
                  _saveDraft();
                },
              ),
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.track_changes_rounded,
                'Goals',
                _selectedLookingFor.take(2).join(', '),
                onTap: () {
                  setState(() => _currentStep = 4);
                  _saveDraft();
                },
              ),
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.person_rounded,
                'About You',
                '${_firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : _nameController.text}${_locationController.text.isNotEmpty ? ', ${_locationController.text}' : ''}${_selectedProfession != null ? ' • $_selectedProfession' : ''}',
                onTap: () {
                  setState(() => _currentStep = 1);
                  _saveDraft();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPrivacyBadge('Great things take time. You’ve taken the first step today. We’re here for you, every step of the way. 💜'),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
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
                  Row(
                    children: [
                      Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(value.isEmpty ? 'Tap to choose' : value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
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

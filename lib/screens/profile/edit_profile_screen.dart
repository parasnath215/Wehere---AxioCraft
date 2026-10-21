import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state.dart';
import '../../widgets/profile/photo_grid.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/indian_locations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _pseudonymController;
  late TextEditingController _realFirstNameController;
  late String _nameDisplayPreference;

  String? _selectedState;
  String? _selectedCity;
  String? _selectedProfession;
  String? _professionError;

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
  
  List<String> _selectedInterests = [];
  List<String> _selectedFeelings = [];
  List<String> _selectedSupportTypes = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _bioController = TextEditingController(text: user.bio);
    _locationController = TextEditingController(text: user.location);
    _selectedProfession = user.profession;
    if (user.location.isNotEmpty) {
      final parts = user.location.split(', ');
      if (parts.length == 2 && IndianLocations.stateCityMap.containsKey(parts[1])) {
        _selectedState = parts[1];
        if (IndianLocations.stateCityMap[_selectedState]!.contains(parts[0])) {
          _selectedCity = parts[0];
        }
      } else if (parts.length == 2 && (parts[1] == 'Delhi (National Capital Territory)' || parts[1] == 'Delhi (NCT)')) {
        _selectedState = 'Delhi';
        if (IndianLocations.stateCityMap[_selectedState]!.contains(parts[0])) {
          _selectedCity = parts[0];
        }
      } else if (IndianLocations.stateCityMap.containsKey(user.location)) {
        _selectedState = user.location;
      }
    }
    _pseudonymController = TextEditingController(text: user.displayName ?? user.name);
    _realFirstNameController = TextEditingController(text: user.realFirstName ?? '');
    _nameDisplayPreference = user.nameDisplayPreference;
    _selectedInterests = List.from(user.interests);
    _selectedFeelings = List.from(user.feelings);
    _selectedSupportTypes = List.from(user.supportTypes);
    
    // Fetch config options if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<AppState>().isConfigLoaded) {
        context.read<AppState>().fetchConfigOptions();
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _pseudonymController.dispose();
    _realFirstNameController.dispose();
    super.dispose();
  }

  void _promptSwitchToPublicFirstName() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Privacy Warning'),
          ],
        ),
        content: const Text(
          'Showing your first name increases the chance of acquaintances recognizing your profile while swiping.\n\nAre you sure you want to display your real first name on discovery cards?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _nameDisplayPreference = 'FIRST_NAME_PUBLIC';
              });
            },
            child: const Text('Confirm & Switch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProfession == null || _selectedProfession!.trim().isEmpty) {
      setState(() => _professionError = 'Please select your profession');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your profession')),
      );
      return;
    }

    final state = context.read<AppState>();
    if (state.currentUser.images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 2 photos')),
      );
      return;
    }

    final finalAge = state.currentUser.age;

    setState(() => _isSaving = true);
    try {
      final response = await apiClient.put('/users/me', data: {
        'displayName': _pseudonymController.text.trim(),
        'pseudonym': _pseudonymController.text.trim(),
        'realFirstName': _realFirstNameController.text.trim().isNotEmpty ? _realFirstNameController.text.trim() : null,
        'nameDisplayPreference': _nameDisplayPreference,
        'bio': _bioController.text.trim(),
        'location': _locationController.text,
        'profession': _selectedProfession,
        'interests': _selectedInterests,
        'feelings': _selectedFeelings,
        'supportTypes': _selectedSupportTypes,
      });

      if (response.statusCode == 200) {
        final user = state.currentUser.copyWith(
          name: _pseudonymController.text.trim(),
          displayName: _pseudonymController.text.trim(),
          realFirstName: _realFirstNameController.text.trim().isNotEmpty ? _realFirstNameController.text.trim() : null,
          nameDisplayPreference: _nameDisplayPreference,
          age: finalAge,
          bio: _bioController.text.trim(),
          location: _locationController.text,
          profession: _selectedProfession,
          interests: _selectedInterests,
          feelings: _selectedFeelings,
          supportTypes: _selectedSupportTypes,
        );
        state.updateUserProfile(user);
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.h3),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (!_isSaving)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: appState.configLoadError 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load profile options'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: appState.fetchConfigOptions, child: const Text('Retry'))
                ],
              ),
            )
          : !appState.isConfigLoaded
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(appState),
    );
  }

  Widget _buildForm(AppState appState) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoGrid(),
          const SizedBox(height: 24),
          _buildTextField(
            'App Display Name / Alias',
            _pseudonymController,
            max: 50,
            helperText: 'Public pseudonym shown to other peers on cards and chats.',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Real First Name (Private by default)',
            _realFirstNameController,
            max: 50,
            validator: (v) => null,
            helperText: 'Shared during chat only with mutual consent (unless public discovery is enabled).',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Age',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.currentUser.age > 0 ? '${appState.currentUser.age} years old' : 'Not set',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Date of birth is verified and cannot be changed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Privacy & Identity Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Privacy & Identity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Control how your name is shown on peer discovery cards.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                // Option 1: DISPLAY_NAME_ONLY
                InkWell(
                  onTap: () {
                    setState(() {
                      _nameDisplayPreference = 'DISPLAY_NAME_ONLY';
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _nameDisplayPreference == 'DISPLAY_NAME_ONLY'
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _nameDisplayPreference == 'DISPLAY_NAME_ONLY'
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'DISPLAY_NAME_ONLY',
                          groupValue: _nameDisplayPreference,
                          onChanged: (val) {
                            setState(() {
                              _nameDisplayPreference = val!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Show Display Name (Recommended for mental health privacy)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Matches see your chosen pseudonym on discovery cards',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _nameDisplayPreference == 'DISPLAY_NAME_ONLY'
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Option 2: FIRST_NAME_PUBLIC
                InkWell(
                  onTap: () {
                    if (_nameDisplayPreference != 'FIRST_NAME_PUBLIC') {
                      _promptSwitchToPublicFirstName();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _nameDisplayPreference == 'FIRST_NAME_PUBLIC'
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _nameDisplayPreference == 'FIRST_NAME_PUBLIC'
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'FIRST_NAME_PUBLIC',
                          groupValue: _nameDisplayPreference,
                          onChanged: (val) {
                            if (val == 'FIRST_NAME_PUBLIC') {
                              _promptSwitchToPublicFirstName();
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Show First Name on Discovery Card',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Displays real first name while swiping',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          DropdownMenu<String>(
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
                _updateLocationController();
              });
            },
            dropdownMenuEntries: IndianLocations.stateCityMap.keys.map((String state) {
              return DropdownMenuEntry<String>(value: state, label: state);
            }).toList(),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            initialSelection: _selectedCity,
            enableFilter: true,
            enableSearch: true,
            expandedInsets: EdgeInsets.zero,
            leadingIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
            label: const Text('City *'),
            onSelected: (val) {
              setState(() {
                _selectedCity = val;
                _updateLocationController();
              });
            },
            dropdownMenuEntries: (_selectedState == null ? <String>[] : IndianLocations.stateCityMap[_selectedState]!).map((String city) {
              return DropdownMenuEntry<String>(value: city, label: city);
            }).toList(),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
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
            },
            dropdownMenuEntries: professionOptions.map((String prof) {
              return DropdownMenuEntry<String>(value: prof, label: prof);
            }).toList(),
          ),
          if (_professionError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _professionError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            'Bio', 
            _bioController, 
            maxLines: 4, 
            max: appState.configLimits?.bioMaxLength ?? 500,
            helperText: 'A short description about yourself (optional).',
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final limit = appState.configLimits?.bioMaxLength ?? 500;
              if (value.length > limit) return 'Bio cannot exceed $limit characters';
              return null;
            }
          ),
          const SizedBox(height: 24),
          _buildMultiSelect('Interests', appState.availableInterests, _selectedInterests, appState.configLimits?.maxInterests ?? 5),
          const SizedBox(height: 24),
          _buildMultiSelect('Feelings Lately', appState.availableFeelings, _selectedFeelings, appState.configLimits?.maxFeelings ?? 5),
          const SizedBox(height: 24),
          _buildMultiSelect('Looking For', appState.availableSupportTypes, _selectedSupportTypes, appState.configLimits?.maxSupportTypes ?? 2),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, {
    int maxLines = 1, 
    required int max, 
    String? Function(String?)? validator,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
        if (helperText != null) ...[
          const SizedBox(height: 3),
          Text(helperText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: max,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: validator ?? ((value) => value == null || value.isEmpty ? 'Required' : null),
        ),
      ],
    );
  }

  Widget _buildMultiSelect(String title, List options, List<String> selected, int maxCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
            Text('${selected.length}/$maxCount', style: TextStyle(fontSize: 12, color: selected.length >= maxCount ? Colors.red : AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map<Widget>((option) {
            final isSelected = selected.contains(option.label);
            return FilterChip(
              label: Text(option.label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    if (selected.length < maxCount) {
                      selected.add(option.label);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can select up to $maxCount options.')));
                    }
                  } else {
                    selected.remove(option.label);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

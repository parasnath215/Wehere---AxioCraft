import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state.dart';
import '../../widgets/profile/photo_grid.dart';
import '../../core/network/api_client.dart';

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
    _pseudonymController = TextEditingController(text: user.name);
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
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final state = context.read<AppState>();
    if (state.currentUser.images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 2 photos')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await apiClient.put('/users/me', data: {
        'pseudonym': _pseudonymController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
        'interests': _selectedInterests,
        'feelings': _selectedFeelings,
        'supportTypes': _selectedSupportTypes,
      });

      if (response.statusCode == 200) {
        // AppState will usually update if we integrate properly, but let's do it manually just in case
        // The API returns the updated user, but without full details sometimes.
        final user = state.currentUser.copyWith(
          name: _pseudonymController.text,
          bio: _bioController.text,
          location: _locationController.text,
          interests: _selectedInterests,
          feelings: _selectedFeelings,
          supportTypes: _selectedSupportTypes,
        );
        state.updateUserProfile(user);
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
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
          _buildTextField('Pseudonym / Name', _pseudonymController, max: 50),
          const SizedBox(height: 16),
          _buildTextField('Location', _locationController, max: 100),
          const SizedBox(height: 16),
          _buildTextField('Bio', _bioController, maxLines: 4, max: appState.configLimits?.bioMaxLength ?? 500),
          const SizedBox(height: 24),
          _buildMultiSelect('Interests', appState.availableInterests, _selectedInterests, appState.configLimits?.maxInterests ?? 10),
          const SizedBox(height: 24),
          _buildMultiSelect('Feelings Lately', appState.availableFeelings, _selectedFeelings, appState.configLimits?.maxFeelings ?? 10),
          const SizedBox(height: 24),
          _buildMultiSelect('Looking For', appState.availableSupportTypes, _selectedSupportTypes, appState.configLimits?.maxSupportTypes ?? 5),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, required int max}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: max,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
          children: options.map((option) {
            final isSelected = selected.contains(option.label);
            return FilterChip(
              label: Text(option.label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    if (selected.length < maxCount) selected.add(option.label);
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

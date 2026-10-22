import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/auth_notifier.dart';
import '../../state/app_state.dart';
import '../../widgets/common/wehere_button.dart';

class DobGateScreen extends StatefulWidget {
  const DobGateScreen({super.key});

  @override
  State<DobGateScreen> createState() => _DobGateScreenState();
}

class _DobGateScreenState extends State<DobGateScreen> {
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Please select your date of birth');
      return;
    }

    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }

    if (age < 18) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be 18 or older to use Wehere.')),
      );
      await context.read<AuthNotifier>().logout();
      return;
    }

    setState(() => _isSubmitting = true);
    final formatted =
        "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final res = await apiClient.put('/users/me/dob', data: {'dateOfBirth': formatted});
      if (res.statusCode == 200) {
        if (!mounted) return;
        final auth = context.read<AuthNotifier>();
        auth.setNeedsDob(false);
        if (!mounted) return;
        final appState = context.read<AppState>();
        await appState.fetchCurrentUser();
        await appState.fetchBackendData();
      }
    } on DioException catch (e) {
      final errCode = e.response?.data?['error'];
      final msg = e.response?.data?['message'] ?? 'Failed to update date of birth';
      if (errCode == 'UNDERAGE') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be 18 or older to use Wehere.')),
        );
        await context.read<AuthNotifier>().logout();
        return;
      }
      setState(() => _errorMessage = msg.toString());
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate == null
        ? 'Select Date of Birth'
        : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cake_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Self-Declared Age',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We need your self-declared date of birth to confirm you are 18 or older.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _errorMessage != null ? Colors.redAccent : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              WehereButton(
                text: _isSubmitting ? 'Confirming...' : 'Confirm',
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<AuthNotifier>().logout(),
                child: const Text('Log out', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

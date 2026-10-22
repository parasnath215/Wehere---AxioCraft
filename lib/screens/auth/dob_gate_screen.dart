import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/auth_notifier.dart';
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

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDisplayDate(DateTime d) {
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    // If AuthNotifier.suggestedDob is set (A8) pre-select it
    final auth = context.read<AuthNotifier>();
    if (auth.suggestedDob != null) {
      _selectedDate = auth.suggestedDob;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.input,
      initialDatePickerMode: DatePickerMode.year,
      fieldHintText: 'dd/mm/yyyy',
      helpText: 'Enter your date of birth',
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
      setState(() => _errorMessage = 'Please enter your exact date of birth');
      return;
    }

    final formattedDisplay = _formatDisplayDate(_selectedDate!);

    // Confirmation dialog: "You entered 14 Mar 2001. You can't change this later. Is it correct?" with "Edit" and "Yes, confirm"
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Date of Birth'),
        content: Text(
          "You entered $formattedDisplay. You can't change this later. Is it correct?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final formattedApi =
        "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final res = await apiClient.put('/users/me/dob', data: {'dateOfBirth': formattedApi});
      if (res.statusCode == 200) {
        if (!mounted) return;
        final auth = context.read<AuthNotifier>();
        auth.setNeedsDob(false);
        await auth.refreshSession(context);
        if (!mounted) return;
        auth.navigateAfterAuth(context);
        return;
      }
    } on DioException catch (e) {
      final errCode = e.response?.data?['error'];
      final msg = e.response?.data?['message'] ?? 'Failed to update date of birth';
      if (errCode == 'UNDERAGE') {
        if (!mounted) return;
        await context.read<AuthNotifier>().handleUnderage(context);
        return;
      }
      if (e.response?.statusCode == 409) {
        if (!mounted) return;
        final auth = context.read<AuthNotifier>();
        auth.setNeedsDob(false);
        await auth.refreshSession(context);
        if (!mounted) return;
        auth.navigateAfterAuth(context);
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
        : _formatDisplayDate(_selectedDate!);

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
                'Your date of birth',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Wehere is only for people aged 18 or older. Enter your exact date of birth. You will not be able to change it later.',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';

class JournalHomeScreen extends StatelessWidget {
  const JournalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => appState.setTabIndex(0),
        ),
        title: Text('My Journal 📖', style: AppTextStyles.h2.copyWith(fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            onPressed: () => _pickDateFilter(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New Entry Action Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Reflection',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Take 3 minutes to unwind and write down how your day went.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(130, 38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.newJournal);
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('Write Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Filter by Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Past Entries', style: AppTextStyles.h3),
                  Wrap(
                    spacing: 6,
                    children: ['All', 'Gratitude', 'Reflection', 'Venting'].map((cat) {
                      final isSel = appState.selectedJournalFilter == cat;
                      return GestureDetector(
                        onTap: () => appState.setJournalFilter(cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (appState.selectedJournalDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InputChip(
                    label: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(appState.selectedJournalDate!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    deleteIconColor: Colors.white,
                    onDeleted: () => appState.setJournalDate(null),
                  ),
                ),

              if (appState.filteredJournalEntries.isNotEmpty)
                ...appState.filteredJournalEntries.map((entry) {
                  final dateFormatted = DateFormat('MMM dd, yyyy • hh:mm a').format(entry.date);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                entry.mood,
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(entry.category, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ),
                            const Spacer(),
                            Text(dateFormatted, style: AppTextStyles.caption.copyWith(fontSize: 10)),

                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.thought,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                        if (entry.gratitude.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, size: 12, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Grateful for: ${entry.gratitude}',
                                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                })
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No journal entries in this category', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('Tap Write Entry above to create a new reflection.', style: AppTextStyles.bodySmall),
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

  void _pickDateFilter(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // If a date is already selected, picking again might mean clearing it or picking a new one
    // Let's just let them pick a new date, and provide a clear mechanism in the UI instead.
    final picked = await showDatePicker(
      context: context,
      initialDate: appState.selectedJournalDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      appState.setJournalDate(picked);
      final formatted = DateFormat('MMM dd, yyyy').format(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing reflection entries for $formatted ✨'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () => appState.setJournalDate(null),
          ),
        ),
      );
    }
  }
}

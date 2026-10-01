import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/journal_entry.dart';
import 'new_journal_screen.dart';

class JournalSuccessScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalSuccessScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(entry.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Notebook Illustration
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.book_rounded, size: 68, color: AppColors.primary),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('All set!', style: AppTextStyles.h1),
                  const SizedBox(width: 8),
                  const Text('✨', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your entry has been saved successfully.\nGreat job reflecting today! 💜',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 24),

              // "Your Entry" Summary Card (Mockup 1.17.18 AM (3))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark_added_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Your Entry', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                        const Spacer(),
                        Text(dateStr, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quote block
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F4FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
                          Text(
                            entry.thought,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tags row
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTagBadge(Icons.menu_book_rounded, entry.category),
                        _buildTagBadge(Icons.favorite_border_rounded, 'Gratitude'),
                        _buildTagBadge(Icons.sentiment_satisfied_alt_rounded, entry.mood),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // "What's next?" Grid (3 cards)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('What’s next?', style: AppTextStyles.h3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNextCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Write Another',
                      subtitle: 'Capture more thoughts',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const NewJournalScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNextCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Daily Log',
                      subtitle: 'See entries & progress',
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNextCard(
                      icon: Icons.insights_rounded,
                      title: 'Insights',
                      subtitle: 'Growth journey',
                      color: AppColors.onlineGreen,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Motivational Reminder Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3EFFF), Color(0xFFECE7FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keep going, Alex!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Small reflections create big changes.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, size: 20, color: AppColors.primaryLight),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Done Button
              ElevatedButton(
                onPressed: () {
                  // Unwind modal stack to root navigation shell cleanly
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildNextCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_rounded, size: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

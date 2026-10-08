import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  int _activeTimeFilter = 0;
  final List<String> _timeFilters = ['Week', 'Month', '3 Months', 'Year'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final goals = appState.goals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Progress ✨', style: AppTextStyles.h2.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () => _showProgressNotifications(context, appState),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Illustration & Subtext (Mockup 1.17.20 AM (2))
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.trending_up_rounded, size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Track your growth and celebrate wins.', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Filter Tabs (Week, Month, 3 Months, Year)
              Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: List.generate(_timeFilters.length, (index) {
                    final isSel = _activeTimeFilter == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTimeFilter = index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _timeFilters[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),



              // Goals Overview with Progress Bars
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Goals Overview', style: AppTextStyles.h3),
                        GestureDetector(
                          onTap: () => _showAddGoalDialog(context, appState),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Add Goal', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...goals.map((g) {
                      final pctInt = (g.progress * 100).toInt();
                      return GestureDetector(
                        onTap: () => appState.toggleGoal(g.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    g.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: g.isCompleted ? AppColors.onlineGreen : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      g.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        decoration: g.isCompleted ? TextDecoration.lineThrough : null,
                                        color: g.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    g.isCompleted ? 'Done! ✨' : '$pctInt%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: g.isCompleted ? AppColors.onlineGreen : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: g.progress,
                                  minHeight: 7,
                                  backgroundColor: AppColors.surfaceSubtle,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    g.isCompleted ? AppColors.onlineGreen : Color(int.parse(g.categoryColor)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Your Streak Card (16 Days / M-T-W-T-F-S-S)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Streak (Tap to Check In)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                Text(
                                  '${appState.dayStreak} days',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Text('Keep your streak alive!', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // M T W T F S S Circles (Interactive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final day = entry.value;
                        final isDone = idx < appState.weekDaysCheckIn.length && appState.weekDaysCheckIn[idx];

                        return GestureDetector(
                          onTap: () => appState.toggleWeekCheckIn(idx),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDone ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDone ? AppColors.primary : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDone ? AppColors.primary : AppColors.cardBorder, width: 1.5),
                                ),
                                child: isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (appState.goals.isNotEmpty && appState.goals.every((g) => g.isCompleted)) ...[
                // Milestone Unlocked Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Milestone Unlocked! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('You completed ${appState.goals.length} goals this week. Amazing work!', style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(90, 34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _showMilestonesSheet(context),
                        child: const Text('Milestones', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, AppState appState) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Wellness Goal 🌱', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'Goal title (e.g. 10-Min Evening Meditation)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleCtrl,
                decoration: const InputDecoration(hintText: 'Description or target (e.g. Daily before bed)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    appState.addGoal(
                      titleCtrl.text.trim(),
                      subtitleCtrl.text.trim().isNotEmpty ? subtitleCtrl.text.trim() : 'Daily wellness practice',
                      '0xFF5E4BEE',
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New goal added! +40 XP')),
                    );
                  }
                },
                child: const Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMilestonesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Earned Milestones 🏆', style: AppTextStyles.h2.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFFEEEAFE), child: Text('🎧')),
              title: Text('Helpful Listener', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Exchanged 10+ supportive messages with peers'),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
            ),
            const ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Text('🔥')),
              title: Text('Consistency Master', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Maintained an active 16-day reflection streak'),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
            ),
            const ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFFE8F8F0), child: Text('🛡️')),
              title: Text('Safe Space Creator', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('100% positive kindness and empathy ratings'),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressNotifications(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress & Streak Alerts 🔔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Mark Read', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 20),
              ),
              title: const Text('Streak Milestone Reached! 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('You are on a ${appState.dayStreak}-day streak. Keep your mindfulness momentum going!', style: const TextStyle(fontSize: 11)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF2563EB), size: 20),
              ),
              title: const Text('Goals Overview: 72% Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('You completed 3 out of 4 wellness goals this week. Great work! ✨', style: TextStyle(fontSize: 11)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.military_tech_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text('Level ${appState.userLevel} Growth Explorer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${appState.currentXp} / ${appState.targetXp} XP accumulated toward Level ${appState.userLevel + 1}.', style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

}

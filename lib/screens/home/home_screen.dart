import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';

import '../../widgets/common/mood_chip.dart';
import '../../widgets/shared/avatar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AppState>().fetchBackendData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, appState, user),
                const SizedBox(height: 16),
                _buildDailyCheckIn(context, appState),
                const SizedBox(height: 24),
                _buildProgressBanner(context, appState),
                const SizedBox(height: 24),
                _buildCoreNavigationGrid(context, appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // --- Helper Methods for Redesign ---

  Widget _buildHeader(BuildContext context, AppState appState, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_getGreeting()}, ${user.isAnonymous ? 'Friend' : user.name}',
                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s take a moment for you.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          // Action Icons
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🚨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('SOS', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showNotifications(context, appState),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 26),
                    if (appState.unreadNotifications > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            appState.unreadNotifications > 9 ? '9+' : '${appState.unreadNotifications}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  appState.setTabIndex(4);
                },
                child: AvatarWidget(
                  imageUrl: user.avatarUrl,
                  radius: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCheckIn(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?', style: AppTextStyles.h3),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MoodChip(
                  label: 'Great',
                  emoji: '😄',
                  tintColor: const Color(0xFF22C55E),
                  isSelected: appState.todayMood == 'Great',
                  onTap: () => appState.checkInMood('Great'),
                ),
              ),
              Expanded(
                child: MoodChip(
                  label: 'Good',
                  emoji: '🙂',
                  tintColor: const Color(0xFF3B82F6),
                  isSelected: appState.todayMood == 'Good',
                  onTap: () => appState.checkInMood('Good'),
                ),
              ),
              Expanded(
                child: MoodChip(
                  label: 'Okay',
                  emoji: '😐',
                  tintColor: const Color(0xFFF59E0B),
                  isSelected: appState.todayMood == 'Okay',
                  onTap: () => appState.checkInMood('Okay'),
                ),
              ),
              Expanded(
                child: MoodChip(
                  label: 'Not Good',
                  emoji: '🙁',
                  tintColor: const Color(0xFFF97316),
                  isSelected: appState.todayMood == 'Not Good',
                  onTap: () {
                    appState.checkInMood('Not Good');
                    _showGentleSheet(context, appState);
                  },
                ),
              ),
              Expanded(
                child: MoodChip(
                  label: 'Struggling',
                  emoji: '😣',
                  tintColor: const Color(0xFFEF4444),
                  isSelected: appState.todayMood == 'Struggling',
                  onTap: () {
                    appState.checkInMood('Struggling');
                    _showGentleSheet(context, appState);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(BuildContext context, AppState appState) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${appState.dayStreak}-Day Streak!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                      Text('${appState.weeklyProgress}/7 days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: appState.weeklyProgress / 7.0,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Every moment counts toward building your wellness journey.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJournalDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} | $hour:$minute $amPm';
  }

  Widget _buildCoreNavigationGrid(BuildContext context, AppState appState) {
    final journalCount = appState.journalEntries.length;
    final lastJournalDate = journalCount > 0 
        ? _formatJournalDate(appState.journalEntries.first.date)
        : 'Reflect on your day';

    final peersCount = appState.cards.length;
    final communityCount = appState.communityPosts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explore Wehere', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildNavCard(
                  title: 'Find Peers',
                  subtitle: peersCount > 0 ? '$peersCount peers nearby' : 'Connect with community',
                  icon: Icons.groups_rounded,
                  color: AppColors.onlineGreen,
                  onTap: () => appState.setTabIndex(1),
                  gradient: const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNavCard(
                  title: 'My Journal',
                  subtitle: lastJournalDate,
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => appState.setTabIndex(3),
                  gradient: const LinearGradient(colors: [Color(0xFFFFEDD5), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNavCard(
            title: 'Community Board',
            subtitle: communityCount > 0 ? '$communityCount active discussions' : 'Share posts and discuss topics',
            icon: Icons.forum_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => appState.setTabIndex(2),
            gradient: const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, required Gradient gradient}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  Icon(icon, color: color, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }


  void _showNotifications(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Supportive Alerts 🔔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  GestureDetector(
                    onTap: () async {
                      await appState.markNotificationsRead();
                    },
                    child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (appState.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("You're all caught up!", style: TextStyle(color: Colors.grey))),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: appState.notifications.length,
                    itemBuilder: (ctx, i) {
                      final n = appState.notifications[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: n.isRead ? Colors.grey.shade100 : AppColors.primarySoft, shape: BoxShape.circle),
                          child: Icon(
                            n.type == 'match' ? Icons.favorite : 
                            n.type == 'community' ? Icons.people : 
                            n.type == 'progress' ? Icons.local_fire_department : Icons.notifications, 
                            color: n.isRead ? Colors.grey : AppColors.primary, size: 20
                          ),
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                        subtitle: Text(n.content, style: TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  void _showEditMoodDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.currentUser.moodStatus);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'How are you feeling?'),
          maxLength: 30,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              appState.updateUserMoodStatus(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGentleSheet(BuildContext context, AppState appState) {
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
            const Text('We are here for you 💜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            const Text('It takes courage to admit you\'re struggling. What would help you right now?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
              title: const Text('Find a peer to talk to'),
              onTap: () {
                Navigator.pop(ctx);
                appState.setTabIndex(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: Color(0xFFD97706)),
              title: const Text('Journal my thoughts'),
              onTap: () {
                Navigator.pop(ctx);
                appState.setTabIndex(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.sosRed),
              title: const Text('I need urgent help (SOS)'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.sos);
              },
            ),
          ],
        ),
      ),
    );
  }
}

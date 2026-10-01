import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';

import '../../widgets/common/mood_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, appState, user),
              const SizedBox(height: 16),
              _buildDailyCheckIn(context, appState),
              const SizedBox(height: 20),
              _buildProgressBanner(context, appState),
              const SizedBox(height: 24),
              _buildCoreNavigationGrid(context, appState),
              const SizedBox(height: 28),
              _buildRecommendedPeers(context, appState),
            ],
          ),
        ),
      ),
    );
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
                    'Hi, ${user.isAnonymous ? 'Friend' : user.name}',
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
                onTap: () => _showNotifications(context),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 26),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showAppMenu(context, appState),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(user.avatarUrl),
                  backgroundColor: AppColors.primarySoft,
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
              MoodChip(
                label: 'Great',
                emoji: '😄',
                tintColor: const Color(0xFF22C55E),
                isSelected: appState.todayMood == 'Great',
                onTap: () => appState.checkInMood('Great'),
              ),
              MoodChip(
                label: 'Good',
                emoji: '🙂',
                tintColor: const Color(0xFF3B82F6),
                isSelected: appState.todayMood == 'Good',
                onTap: () => appState.checkInMood('Good'),
              ),
              MoodChip(
                label: 'Okay',
                emoji: '😐',
                tintColor: const Color(0xFFF59E0B),
                isSelected: appState.todayMood == 'Okay',
                onTap: () => appState.checkInMood('Okay'),
              ),
              MoodChip(
                label: 'Not Good',
                emoji: '🙁',
                tintColor: const Color(0xFFF97316),
                isSelected: appState.todayMood == 'Not Good',
                onTap: () => appState.checkInMood('Not Good'),
              ),
              MoodChip(
                label: 'Struggling',
                emoji: '😣',
                tintColor: const Color(0xFFEF4444),
                isSelected: appState.todayMood == 'Struggling',
                onTap: () => appState.checkInMood('Struggling'),
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
                      const Text('7/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildCoreNavigationGrid(BuildContext context, AppState appState) {
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
                child: Column(
                  children: [
                    _buildNavCard(
                      title: 'Find Peers',
                      subtitle: 'Connect with a supportive community',
                      icon: Icons.groups_rounded,
                      color: AppColors.onlineGreen,
                      onTap: () => appState.setTabIndex(1),
                      gradient: const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      title: 'Group Chats',
                      subtitle: 'Topics: some fundling topics, Anxiety Support, evermore, e.g...',
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => appState.setTabIndex(2), // Assume Chat is tab 2
                      gradient: const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNavCard(
                  title: 'My Journal',
                  subtitle: 'Mar 11, 2023 | 1:10 PM\nReflect on your day',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => appState.setTabIndex(3), // Assume Journal is tab 3
                  gradient: const LinearGradient(colors: [Color(0xFFFFEDD5), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
            ],
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

  Widget _buildRecommendedPeers(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recommended For You', style: AppTextStyles.h3),
              GestureDetector(
                onTap: () => appState.setTabIndex(1),
                child: const Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 215,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildPeerCard(context: context, name: 'Aanya', age: 23, purpose: 'Looking for someone to talk to', badge: 'Good Listener', avatarUrl: 'assets/mockups/discover_swipe.jpeg'),
              _buildPeerCard(context: context, name: 'Rohan', age: 26, purpose: 'Interested in personal growth', badge: 'Motivational', avatarUrl: 'assets/mockups/home_dashboard_priya.jpeg'),
              _buildPeerCard(context: context, name: 'Meera', age: 24, purpose: 'Looking for emotional support', badge: 'Empathetic', avatarUrl: 'assets/mockups/profile_detail.jpeg'),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildPeerCard({
    required BuildContext context,
    required String name,
    required int age,
    required String purpose,
    required String badge,
    required String avatarUrl,
  }) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage(avatarUrl),
                onBackgroundImageError: (_, __) {},
                backgroundColor: AppColors.primarySoft,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$name, $age',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            purpose,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.2),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.setTabIndex(1);
              },
              child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }



  void _showAppMenu(BuildContext context, AppState appState) {
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(appState.currentUser.avatarUrl),
                  backgroundColor: AppColors.primarySoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showEditMoodDialog(context, appState);
                        },
                        child: Row(
                          children: [
                            Flexible(child: Text(appState.currentUser.moodStatus, style: const TextStyle(fontSize: 12, color: AppColors.primary), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                appState.setTabIndex(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: AppColors.primary),
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings available in next update.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Color(0xFF10B981)),
              title: const Text('Progress & Milestones', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.progress);
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.sosRed),
              title: const Text('24/7 Crisis Help & Helplines', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.sosRed)),
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

  void _showNotifications(BuildContext context) {
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
                Text('Supportive Alerts 🔔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Clear All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.favorite, color: AppColors.primary, size: 20),
              ),
              title: const Text('Riya replied to your message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('“Small wins matter a lot 💜 Celebrate them always!” • 5m ago', style: TextStyle(fontSize: 11)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 20),
              ),
              title: const Text('16-Day Streak Active! 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('You’re building steady consistency. Keep it going!', style: TextStyle(fontSize: 11)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.spa, color: Color(0xFF0284C7), size: 20),
              ),
              title: const Text('Daily Mindfulness Prompt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Remember to pause and take 3 deep breaths today.', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
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
}

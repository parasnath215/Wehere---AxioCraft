import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';
import '../progress/progress_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Growth 🌟', style: AppTextStyles.h2.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.sosRed),
            onPressed: () {
              context.read<AuthNotifier>().logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () => _showSettingsSheet(context, appState),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Header (Mockup 1.17.19 AM (2))
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context, appState),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: AssetImage(user.avatarUrl),
                          onBackgroundImageError: (_, __) {},
                          backgroundColor: AppColors.primarySoft,
                          child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Hi, ${user.name}!', style: AppTextStyles.h2),
                                const SizedBox(width: 4),
                                const Text('✨', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySoft,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                minimumSize: const Size(80, 28),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 12),
                              label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _showEditProfileSheet(context, appState),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.bio.isNotEmpty ? user.bio : 'Learning to be kind to myself one day at a time. 🌱',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Registered Unique ID Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REGISTERED UNIQUE ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(user.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ID ${user.id} to clipboard!'), duration: const Duration(seconds: 2)),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Copy ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Anonymity Mode Toggle Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: user.isAnonymous ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: user.isAnonymous ? AppColors.primary : AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: user.isAnonymous ? AppColors.primary : AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.masks_rounded, size: 20, color: user.isAnonymous ? Colors.white : AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Anonymity Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            user.isAnonymous
                                ? 'Active: Peers only see your safe avatar & pseudonym'
                                : 'Disabled: Real name & photo visible to matches',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: user.isAnonymous,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        appState.setAnonymity(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4 Stat Badges (Streak, Goals, Hours Focused, Score)
              Row(
                children: [
                  _buildStatCard(
                    iconEmoji: '🔥',
                    value: '${appState.dayStreak}',
                    title: 'Day Streak',
                    subtitle: 'Active now',
                    tintColor: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    iconEmoji: '🎯',
                    value: '${appState.goals.where((g) => g.isCompleted).length}',
                    title: 'Goals Done',
                    subtitle: 'This Month',
                    tintColor: AppColors.onlineGreen,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    iconEmoji: '⏱️',
                    value: '89',
                    title: 'Hours Mindful',
                    subtitle: '+18% growth',
                    tintColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    iconEmoji: '⭐',
                    value: '4.8',
                    title: 'Well-being',
                    subtitle: 'Great!',
                    tintColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Level 12 "Growth Explorer" XP Card (Mockup 1.17.19 AM (2))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('LEVEL', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                          Text('${appState.userLevel}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Growth Explorer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${appState.currentXp} / ${appState.targetXp} XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: (appState.currentXp / appState.targetXp).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceSubtle,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${(appState.targetXp - appState.currentXp).clamp(0, appState.targetXp)} XP to next level', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // My Goals Overview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Goals', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
                      );
                    },
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...appState.goals.map((goal) {
                final pct = (goal.progress * 100).toInt();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(int.parse(goal.categoryColor))),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Recent Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Badges', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () => _showRewardsBadgesSheet(context, appState),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBadgeCard('🔥', '7-Day Streak', onTap: () => _showRewardsBadgesSheet(context, appState)),
                    _buildBadgeCard('🎯', 'Goal Crusher', onTap: () => _showRewardsBadgesSheet(context, appState)),
                    _buildBadgeCard('🏹', 'On Track', onTap: () => _showRewardsBadgesSheet(context, appState)),
                    _buildBadgeCard('⭐', 'First Milestone', onTap: () => _showRewardsBadgesSheet(context, appState)),
                    _buildBadgeCard('🧘', 'Mindful Master', onTap: () => _showRewardsBadgesSheet(context, appState)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String iconEmoji,
    required String value,
    required String title,
    required String subtitle,
    required Color tintColor,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(iconEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 8, color: tintColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(String emoji, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AppState appState) {
    final avatars = [
      'assets/mockups/user_dashboard_alex.jpeg',
      'assets/mockups/home_dashboard_priya.jpeg',
      'assets/mockups/discover_swipe.jpeg',
      'assets/mockups/profile_detail.jpeg',
      'assets/mockups/match_celebration.jpeg',
      'assets/mockups/intake_name.jpeg',
    ];

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
            const Text('Choose Your Avatar 🎨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Pick a look that matches your gentle vibe.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: avatars.map((url) {
                final isSelected = appState.currentUser.avatarUrl == url;
                return GestureDetector(
                  onTap: () async {
                    // Update user avatar
                    await appState.updateProfile(
                      name: appState.currentUser.name,
                      bio: appState.currentUser.bio,
                      location: appState.currentUser.location,
                      lookingFor: appState.currentUser.lookingFor,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar updated! Looking great ✨')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: AssetImage(url),
                      backgroundColor: AppColors.primarySoft,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppState appState) {
    final user = appState.currentUser;
    final nameCtrl = TextEditingController(text: user.name);
    final bioCtrl = TextEditingController(text: user.bio);
    final locCtrl = TextEditingController(text: user.location);
    final lookCtrl = TextEditingController(text: user.lookingFor);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile ✍️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'About You / Bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lookCtrl,
                decoration: const InputDecoration(labelText: 'What Kind of Support You Want'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  await appState.updateProfile(
                    name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : user.name,
                    bio: bioCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    lookingFor: lookCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved successfully! ✨')),
                  );
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, AppState appState) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Settings & Safety ⚙️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Gentle reminders and peer chat pings'),
              activeThumbColor: AppColors.primary,
              value: appState.pushNotifications,
              onChanged: (val) {
                appState.pushNotifications = val;
                (ctx as Element).markNeedsBuild();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Safe Content Moderation', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Auto-filter harmful or distressing content'),
              activeThumbColor: AppColors.primary,
              value: true,
              onChanged: (_) {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Wehere Terms & Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    title: const Text('Privacy & Protection'),
                    content: const Text(
                      'Wehere is built with privacy-first architecture.\n\n'
                      '• Your messages are encrypted and private.\n'
                      '• Anonymity mode ensures you can connect pseudoymously.\n'
                      '• We never sell user data or run targeted behavioral ads.',
                    ),
                    actions: [
                      ElevatedButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Understood')),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh_rounded, color: Colors.orange),
              title: const Text('Reset Deck & Matches', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                appState.refreshDeck();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cards and peer deck replenished!')),
                );
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<AuthNotifier>().logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardsBadgesSheet(BuildContext context, AppState appState) {
    final badges = [
      {'emoji': '🔥', 'title': '16-Day Streak', 'desc': 'Showed up for mental wellness 16 days in a row!', 'earned': true},
      {'emoji': '🎯', 'title': 'Goal Crusher', 'desc': 'Completed 5 self-care goals this month.', 'earned': true},
      {'emoji': '🏹', 'title': 'On Track', 'desc': 'Consistent habit tracking for 2 weeks.', 'earned': true},
      {'emoji': '⭐', 'title': 'First Milestone', 'desc': 'Passed 2,000 XP in the Wehere journey.', 'earned': true},
      {'emoji': '🧘', 'title': 'Mindful Master', 'desc': 'Completed 10 daily reflection journal entries.', 'earned': true},
      {'emoji': '👑', 'title': 'Empathy Champion', 'desc': 'Sent 50 encouraging peer messages.', 'earned': false},
      {'emoji': '🌟', 'title': 'Support Star', 'desc': 'Received a Super Support star from a peer.', 'earned': false},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Milestones & Rewards 🏆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Level ${appState.userLevel} Growth Explorer • ${appState.currentXp} Total XP', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: badges.length,
                itemBuilder: (context, i) {
                  final b = badges[i];
                  final earned = b['earned'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: earned ? const Color(0xFFF5F3FF) : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: earned ? AppColors.primaryBorder : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Text(b['emoji'] as String, style: TextStyle(fontSize: 28, color: earned ? null : Colors.grey)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: earned ? AppColors.textPrimary : AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text(b['desc'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: earned ? AppColors.primary : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            earned ? 'Unlocked' : 'Locked',
                            style: TextStyle(fontSize: 10, color: earned ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

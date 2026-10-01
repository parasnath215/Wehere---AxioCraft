import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/shared/avatar_widget.dart';
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
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () => _showSettingsSheet(context, appState),
          ),
          const SizedBox(width: 8),
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
                  AvatarWidget(
                    imageUrl: user.avatarUrl,
                    radius: 36,
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

              // ID Card removed per requirements

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
                      onChanged: (val) async {
                        final success = await appState.setAnonymity(val);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update anonymity. Please try again.')),
                          );
                        } else if (success && val && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Anonymity Active'),
                              content: const Text('Other users will now see you as "Anonymous" with a default avatar. Your real name and photo remain visible to you.'),
                              actions: [ElevatedButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Got it'))],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
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
                          const SizedBox(height: 4),
                          Text('${(appState.targetXp - appState.currentXp).clamp(0, appState.targetXp)} XP to next level', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          const Text('Earn XP by: Community Posts, Matches, Daily Journals', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
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
              ...appState.goals.take(3).map((goal) {
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


            ],
          ),
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
                  if (!context.mounted) return;
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _showChangePasswordDialog(context, appState);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: AppColors.sosRed),
              title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.sosRed)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sosRed),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAccountDialog(context, appState);
              },
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
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
                        onPressed: () {
                          Navigator.pop(dCtx);
                          context.read<AuthNotifier>().logout();
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                        },
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppState appState) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters')));
                return;
              }
              final success = await appState.changePassword(currentCtrl.text, newCtrl.text);
              if (context.mounted) {
                Navigator.pop(dCtx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password. Please check your current password.')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.sosRed)),
        content: const Text(
          'Are you absolutely sure you want to delete your account? '
          'This action is irreversible and all your data, chats, and progress will be permanently lost.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
            onPressed: () async {
              final success = await appState.deleteAccount();
              if (context.mounted) {
                Navigator.pop(dCtx);
                if (success) {
                  context.read<AuthNotifier>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete account. Please contact support.')));
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/shared/avatar_widget.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.h2.copyWith(fontSize: 20)),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress / avatar (Tinder style)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _calculateCompletionScore(user),
                      strokeWidth: 6,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  AvatarWidget(
                    imageUrl: user.images.isNotEmpty ? AppConstants.apiBaseUrl.replaceAll('/api', '') + user.images.first : user.avatarUrl,
                    radius: 60,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${user.name}, ${user.age}', style: AppTextStyles.h2),
                  if (user.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: AppColors.primary, size: 20),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${( _calculateCompletionScore(user) * 100).toInt()}% COMPLETED',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (user.bio.isNotEmpty)
                Text(
                  user.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
                ),
              const SizedBox(height: 24),
              _buildTagsList(user.supportTypes, appState.availableSupportTypes, 'Looking For', Icons.search),
              _buildTagsList(user.interests, appState.availableInterests, 'Interests', Icons.star_border),
              _buildTagsList(user.feelings, appState.availableFeelings, 'Feeling', Icons.mood),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.cardBorder),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              ),
              const SizedBox(height: 24),

              // Anonymity Mode Toggle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: user.isAnonymous ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: user.isAnonymous ? AppColors.primary : AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: user.isAnonymous ? AppColors.primary.withOpacity(0.1) : AppColors.surface, shape: BoxShape.circle),
                      child: Icon(Icons.visibility_off_outlined, color: user.isAnonymous ? AppColors.primary : AppColors.textSecondary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Incognito Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Hide exact location and photos', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: user.isAnonymous,
                      activeColor: AppColors.primary,
                      onChanged: (val) async {
                        try {
                          await apiClient.put('/users/me', data: {'isAnonymous': val});
                          appState.updateUserProfile(user.copyWith(isAnonymous: val));
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update mode')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateCompletionScore(dynamic user) {
    int score = 0;
    if (user.images.length >= 2) score += 20;
    if (user.bio.isNotEmpty) score += 20;
    if (user.interests.isNotEmpty) score += 20;
    if (user.feelings.isNotEmpty) score += 20;
    if (user.supportTypes.isNotEmpty) score += 20;
    return score / 100.0;
  }

  Widget _buildTagsList(List<String> selectedIds, List options, String title, IconData icon) {
    if (selectedIds.isEmpty) return const SizedBox();
    
    final List<String> labels = selectedIds.map((id) {
      try {
        final opt = options.firstWhere((o) => o.id == id || o.label == id);
        return (opt.label as String);
      } catch (_) {
        return id; 
      }
    }).toList().cast<String>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels.map<Widget>((label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            )).toList(),
          ),
        ],
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
                const Text('Settings & Safety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Privacy & Protection', style: TextStyle(fontWeight: FontWeight.w600)),
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
}

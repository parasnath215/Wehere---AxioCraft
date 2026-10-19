import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/shared/avatar_widget.dart';
import '../../widgets/common/animated_pressable.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    final streakCount = appState.dayStreak;
    final entriesCount = appState.journalEntries.length;
    final peersCount = appState.matchedUsers.length;

    // Default chips matching mockup if empty
    final lookingFor = user.supportTypes.isNotEmpty
        ? user.supportTypes
        : ['Emotional support', 'Accountability partner'];
    final interests = user.interests.isNotEmpty
        ? user.interests
        : ['Career', 'Mindfulness', 'Relationships'];
    final workingThrough = user.feelings.isNotEmpty
        ? user.feelings
        : ['Family issues', 'Career pressure'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Center Avatar
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AvatarWidget(
                    imageUrl: user.avatarUrl.isNotEmpty
                        ? user.avatarUrl
                        : 'assets/images/paras_avatar.jpg',
                    radius: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Name, Age & Verified badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: GoogleFonts.newsreader(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Bio
              Text(
                user.bio.isNotEmpty ? user.bio : 'Here to grow, one day at a time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Stats Card (Day streak | Entries | Peers)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3FA),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    _buildStatCol('$streakCount', 'Day streak'),
                    _buildStatDivider(),
                    _buildStatCol('$entriesCount', 'Entries'),
                    _buildStatDivider(),
                    _buildStatCol('$peersCount', 'Peers'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Edit Profile Button
              AnimatedPressable(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                pressedScale: 0.98,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Edit profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 5. Profile Attributes Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Looking for
                    _buildTagGroup(
                      icon: Icons.search_rounded,
                      title: 'Looking for',
                      tags: lookingFor,
                    ),
                    const SizedBox(height: 18),

                    // Interests
                    _buildTagGroup(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Interests',
                      tags: interests,
                    ),
                    const SizedBox(height: 18),

                    // Working through
                    _buildTagGroup(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Working through',
                      tags: workingThrough,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Settings & Quick Access Group
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & visibility',
                      onTap: () => _showPrivacyDialog(context),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildSettingTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Reminders',
                      onTap: () => _showRemindersDialog(context),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildSettingTile(
                      icon: Icons.support_rounded,
                      title: 'Crisis resources',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildSettingTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      titleColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () => _showSignOutDialog(context),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildSettingTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete account',
                      titleColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () => _showDeleteAccountDialog(context),
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

  Widget _buildStatCol(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildTagGroup({
    required IconData icon,
    required String title,
    required List<String> tags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEFD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                t,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3730A3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 22),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final appState = context.watch<AppState>();
            final currentPref = appState.currentUser.nameDisplayPreference;

            void handleSwitchToPublic() {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text('Privacy Warning'),
                    ],
                  ),
                  content: const Text(
                    'Showing your first name increases the chance of acquaintances recognizing your profile while swiping.\n\nAre you sure you want to display your real first name on discovery cards?',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await appState.updateNameDisplayPreference('FIRST_NAME_PUBLIC');
                        setModalState(() {});
                      },
                      child: const Text('Confirm & Switch', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text('Privacy & Visibility', style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your progressive identity and discovery card display preference.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  // Preference Option 1: Display Name Only
                  InkWell(
                    onTap: () async {
                      if (currentPref != 'DISPLAY_NAME_ONLY') {
                        await appState.updateNameDisplayPreference('DISPLAY_NAME_ONLY');
                        setModalState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: currentPref == 'DISPLAY_NAME_ONLY' ? AppColors.primarySoft : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentPref == 'DISPLAY_NAME_ONLY' ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'DISPLAY_NAME_ONLY',
                            groupValue: currentPref,
                            onChanged: (val) async {
                              if (val != null) {
                                await appState.updateNameDisplayPreference(val);
                                setModalState(() {});
                              }
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Show Display Name (Recommended)',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Matches see your alias (${appState.currentUser.displayAlias}) on discovery cards for mental health privacy.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Preference Option 2: First Name Public
                  InkWell(
                    onTap: () {
                      if (currentPref != 'FIRST_NAME_PUBLIC') {
                        handleSwitchToPublic();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: currentPref == 'FIRST_NAME_PUBLIC' ? AppColors.primarySoft : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentPref == 'FIRST_NAME_PUBLIC' ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'FIRST_NAME_PUBLIC',
                            groupValue: currentPref,
                            onChanged: (val) {
                              if (val == 'FIRST_NAME_PUBLIC') {
                                handleSwitchToPublic();
                              }
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Show First Name on Discovery Card',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Displays your real first name (${appState.currentUser.realFirstName?.isNotEmpty == true ? appState.currentUser.realFirstName : "Not set"}) while swiping.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRemindersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Daily Reminders', style: GoogleFonts.newsreader(fontWeight: FontWeight.w600)),
        content: Text(
          'Gentle notifications are scheduled daily at 9:00 AM and 8:30 PM to support your mindful check-in and reflection.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign Out', style: GoogleFonts.newsreader(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to sign out from your account?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().resetUserSession();
              context.read<AuthNotifier>().logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final deletionDate = DateTime.now().add(const Duration(days: 30));
    final formattedDate = DateFormat('MMMM d, yyyy').format(deletionDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.sosRed, size: 24),
            const SizedBox(width: 8),
            Text('Delete Account', style: GoogleFonts.newsreader(fontWeight: FontWeight.w600, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account will be scheduled for permanent deletion. Your data will be deleted in 30 days ($formattedDate).',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To continue from where you left, just log in before $formattedDate.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiClient.delete('/users/me');
              } catch (_) {}
              if (!context.mounted) return;
              context.read<AppState>().resetUserSession();
              await context.read<AuthNotifier>().logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account scheduled for deletion. Log in before $formattedDate to restore.'),
                  duration: const Duration(seconds: 5),
                ),
              );
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
            child: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../common/tag_chip.dart';

class ProfileDetailSheet extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSendHello;

  const ProfileDetailSheet({
    super.key,
    required this.profile,
    required this.onPass,
    required this.onLike,
    required this.onSendHello,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Top navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(
                  children: [
                    Text('User Profile ✨', style: AppTextStyles.h3),
                    Text('Get to know each other better 💜', style: AppTextStyles.caption),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => _showProfileOptions(context),
                ),
              ],
            ),
          ),

          // Scrollable Profile Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Banner with Match & Online Badges
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            profile.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: AppColors.onlineGreen),
                              SizedBox(width: 4),
                              Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B163B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, size: 12, color: AppColors.primaryLight),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.matchPercentage}% Match',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Name, verified, location, active, and save/share actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${profile.name}, ${profile.age}', style: AppTextStyles.h2),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(profile.location, style: AppTextStyles.bodySmall),
                              const SizedBox(width: 8),
                              const Icon(Icons.circle, size: 6, color: AppColors.onlineGreen),
                              const SizedBox(width: 4),
                              Text('Active now', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onlineGreen)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildActionCircle(Icons.bookmark_border_rounded, 'Save'),
                          const SizedBox(width: 12),
                          _buildActionCircle(Icons.share_outlined, 'Share'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // About Me Card
                  _buildSectionCard(
                    title: 'About Me',
                    icon: Icons.person_outline_rounded,
                    child: Text(profile.bio, style: AppTextStyles.bodyMedium),
                  ),

                  const SizedBox(height: 14),

                  // Two cards: "I'm Here For" & "Feeling Right Now"
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSectionCard(
                          title: "I'm Here For",
                          icon: Icons.favorite_outline_rounded,
                          child: Text(
                            profile.lookingFor,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSectionCard(
                          title: 'Feeling Right Now',
                          icon: Icons.sentiment_satisfied_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  profile.moodStatus,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Taking it one day at a time 🌱', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // My Interests
                  _buildSectionCard(
                    title: 'My Interests',
                    icon: Icons.star_border_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests.map((topic) => TagChip(label: topic)).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // What Matters to Me
                  _buildSectionCard(
                    title: 'What Matters to Me',
                    icon: Icons.diamond_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.values.map((v) => TagChip(label: v, icon: Icons.check_circle_outline)).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // About My Space
                  _buildSectionCard(
                    title: 'About My Space',
                    icon: Icons.lock_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This is a safe space for me. I’m looking for kind, respectful and non-judgmental connections.',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Safe Space Pledged',
                                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90), // Spacing for sticky bottom buttons
                ],
              ),
            ),
          ),

          // Sticky Bottom Buttons (Pass, Like, Send Hello)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.cardBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pass button
                _buildBottomCircleAction(
                  icon: Icons.close_rounded,
                  label: 'Pass',
                  color: const Color(0xFFEF4444),
                  onTap: onPass,
                ),
                const SizedBox(width: 12),
                // Like button
                _buildBottomCircleAction(
                  icon: Icons.favorite_rounded,
                  label: 'Like',
                  color: AppColors.primary,
                  onTap: onLike,
                ),
                const SizedBox(width: 12),
                // Send Hello button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Send Hello', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: onSendHello,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title, style: AppTextStyles.h3.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceSubtle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildBottomCircleAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
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
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.primary),
              title: const Text('Share Profile Link', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile link for ${profile.name} copied to clipboard! 💜')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Safe Space Community Pledge', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Safe Space Guidelines 💜'),
                    content: const Text(
                      '• Respect boundaries and vulnerability.\n'
                      '• Never harass, judge, or demean peers.\n'
                      '• Keep conversations strictly supportive and confidential.',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Understood'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.orange),
              title: const Text('Block & Pass Candidate', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                onPass();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${profile.name} was passed and hidden from your deck.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: AppColors.sosRed),
              title: const Text('Report Profile for Inappropriate Content', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.sosRed)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Our moderation team will review this within 1 hour.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

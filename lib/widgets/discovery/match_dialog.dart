import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';

class MatchCelebrationDialog extends StatelessWidget {
  final UserProfile currentUser;
  final UserProfile matchedUser;
  final VoidCallback onStartChat;
  final VoidCallback onSendIcebreaker;
  final VoidCallback onKeepSwiping;

  const MatchCelebrationDialog({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.onStartChat,
    required this.onSendIcebreaker,
    required this.onKeepSwiping,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onKeepSwiping,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Close',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "It's a Match!",
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.favorite_border_rounded, color: AppColors.primaryLight, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${matchedUser.name} liked each other.\nLet’s start a meaningful conversation! 💜',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Side-by-side Avatars with neon glow
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileAvatarCard('You', currentUser.avatarUrl, isCurrentUser: true),
                  Transform.translate(
                    offset: const Offset(0, 0),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: -10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonPurpleGlow.withValues(alpha: 0.8),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  _buildProfileAvatarCard('${matchedUser.name}, ${matchedUser.age}', matchedUser.avatarUrl),
                ],
              ),

              const SizedBox(height: 28),

              // "You both connect on" Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161234),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, size: 16, color: AppColors.primaryLight),
                        SizedBox(width: 6),
                        Text(
                          'You both connect on',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildConnectionTag('Healing & Growing', Icons.spa_outlined, const Color(0xFF6366F1)),
                        _buildConnectionTag('Reading', Icons.menu_book_rounded, const Color(0xFF8B5CF6)),
                        _buildConnectionTag('Nature', Icons.eco_outlined, const Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You both believe in kindness, personal growth\nand being a better version of yourself. 🌱',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              GestureDetector(
                onTap: onStartChat,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Start Chatting',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: onSendIcebreaker,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B163B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primaryLight),
                      SizedBox(width: 8),
                      Text(
                        'Send a Icebreaker',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '• Break the ice with a gentle start',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white54),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Keep swiping
              GestureDetector(
                onTap: onKeepSwiping,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Keep Swiping',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.sync_rounded, size: 18, color: AppColors.primaryLight),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Safe Space banner at bottom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF171333),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 22, color: AppColors.primaryLight),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You’re in a Safe Space\nBe kind, respectful and supportive. Let’s build a positive community together. 💜',
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                      ),
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

  Widget _buildProfileAvatarCard(String label, String avatarUrl, {bool isCurrentUser = false}) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 155,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2B215E),
                child: const Icon(Icons.person, size: 60, color: Colors.white30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionTag(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

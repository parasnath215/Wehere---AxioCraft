import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';

class MatchCelebrationDialog extends StatefulWidget {
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
  State<MatchCelebrationDialog> createState() => _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<MatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedName = widget.matchedUser.cardName.isNotEmpty
        ? widget.matchedUser.cardName
        : widget.matchedUser.name;
    final matchedAge = widget.matchedUser.age > 0 ? widget.matchedUser.age : 24;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.25,
            colors: [
              Color(0xFF1D144A),
              Color(0xFF0F0B26),
              Color(0xFF070514),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Row with Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onKeepSwiping();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title with glowing heart
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "It's a Match!",
                          style: GoogleFonts.newsreader(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFC084FC),
                          size: 30,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'You and $matchedName liked each other.\nLet’s start a meaningful conversation! 💜',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.42,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Side-by-side Avatars with pulsating glowing heart
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileCard(
                          label: 'You',
                          avatarUrl: widget.currentUser.avatarUrl,
                          images: widget.currentUser.images,
                          fallbackName: widget.currentUser.cardName,
                          isCurrentUser: true,
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: -10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.8),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                        _buildProfileCard(
                          label: '$matchedName, $matchedAge',
                          avatarUrl: widget.matchedUser.avatarUrl,
                          images: widget.matchedUser.images,
                          fallbackName: matchedName,
                          isCurrentUser: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // "You both connect on" Dynamic Card
                  _buildConnectionCard(),

                  const SizedBox(height: 24),

                  // Primary CTA: Start Chatting
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onStartChat();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_rounded, size: 19, color: Colors.white),
                          SizedBox(width: 9),
                          Text(
                            'Start Chatting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary CTA: Send an Icebreaker
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSendIcebreaker();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1438),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFC084FC)),
                          SizedBox(width: 8),
                          Text(
                            'Send an Icebreaker',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '• Break the ice with a gentle start',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white60),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tertiary Action: Keep Swiping
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onKeepSwiping();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Keep Swiping',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFC084FC),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.sync_rounded, size: 18, color: Color(0xFFC084FC)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Safe Space banner at bottom
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161234),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 22, color: Color(0xFFC084FC)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You’re in a Safe Space\nBe kind, respectful and supportive. Let’s build a positive community together. 💜',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String label,
    required String avatarUrl,
    required List<String> images,
    required String fallbackName,
    required bool isCurrentUser,
  }) {
    return Column(
      children: [
        Container(
          width: 132,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.85),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _buildAvatarImage(avatarUrl, images, fallbackName),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String? avatarUrl, List<String>? images, String fallbackName) {
    String? validUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      validUrl = avatarUrl.trim();
    } else if (images != null && images.isNotEmpty) {
      validUrl = images.first.trim();
    }

    if (validUrl != null && !validUrl.startsWith('http') && !validUrl.startsWith('assets/')) {
      final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
      validUrl = baseUrl + (validUrl.startsWith('/') ? validUrl : '/$validUrl');
    }

    if (validUrl != null && validUrl.startsWith('http')) {
      return Image.network(
        validUrl,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF1E173E),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC084FC)),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(fallbackName),
      );
    } else if (validUrl != null && validUrl.startsWith('assets/')) {
      return Image.asset(
        validUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(fallbackName),
      );
    }

    return _buildFallbackAvatar(fallbackName);
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1663), Color(0xFF6B21A8), Color(0xFF4F46E5)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    // Dynamically calculate shared tags
    final myInterests = widget.currentUser.interests;
    final peerInterests = widget.matchedUser.interests;
    final sharedInterests = myInterests.where((i) {
      return peerInterests.any((p) => p.toLowerCase().trim() == i.toLowerCase().trim());
    }).toList();

    final mySupport = widget.currentUser.supportTypes;
    final peerSupport = widget.matchedUser.supportTypes;
    final sharedSupport = mySupport.where((s) {
      return peerSupport.any((p) => p.toLowerCase().trim() == s.toLowerCase().trim());
    }).toList();

    List<Widget> connectionTags = [];

    // Add shared interests
    for (final tag in sharedInterests.take(3)) {
      connectionTags.add(_buildDynamicTag(tag, _getTagIcon(tag), _getTagColor(tag)));
    }

    // Add shared support if space allows
    if (connectionTags.length < 3) {
      for (final tag in sharedSupport.take(3 - connectionTags.length)) {
        connectionTags.add(_buildDynamicTag(tag, _getTagIcon(tag), const Color(0xFF10B981)));
      }
    }

    // If still empty, display peer interests or default uplifting pillars
    if (connectionTags.isEmpty) {
      final fallbackTags = peerInterests.isNotEmpty
          ? peerInterests.take(2).toList()
          : ['Kindness', 'Safe Space', 'Listening'];
      for (final tag in fallbackTags) {
        connectionTags.add(_buildDynamicTag(tag, _getTagIcon(tag), _getTagColor(tag)));
      }
    }

    final reasonText = sharedInterests.isNotEmpty
        ? 'You both connect on ${sharedInterests.take(2).join(' & ')}.\nA gentle start for a supportive connection. 🌱'
        : 'You both believe in kindness, personal growth\nand being a better version of yourself. 🌱';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161234),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFC084FC)),
              SizedBox(width: 7),
              Text(
                'You both connect on',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
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
            children: connectionTags,
          ),
          const SizedBox(height: 12),
          Text(
            reasonText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12.2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTag(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTagIcon(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('heal') || lower.contains('grow')) return Icons.spa_outlined;
    if (lower.contains('read') || lower.contains('book')) return Icons.menu_book_rounded;
    if (lower.contains('nature') || lower.contains('plant') || lower.contains('eco')) return Icons.eco_outlined;
    if (lower.contains('mindful') || lower.contains('meditat')) return Icons.self_improvement_rounded;
    if (lower.contains('mental') || lower.contains('health')) return Icons.psychology_outlined;
    if (lower.contains('relation') || lower.contains('love')) return Icons.favorite_border_rounded;
    if (lower.contains('career') || lower.contains('work')) return Icons.work_outline_rounded;
    if (lower.contains('music')) return Icons.music_note_rounded;
    if (lower.contains('travel')) return Icons.flight_takeoff_rounded;
    if (lower.contains('talk') || lower.contains('friend')) return Icons.chat_bubble_outline_rounded;
    if (lower.contains('support')) return Icons.volunteer_activism_outlined;
    return Icons.auto_awesome_rounded;
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('heal') || lower.contains('grow')) return const Color(0xFF6366F1);
    if (lower.contains('read') || lower.contains('book')) return const Color(0xFF8B5CF6);
    if (lower.contains('nature') || lower.contains('eco')) return const Color(0xFF10B981);
    if (lower.contains('mental')) return const Color(0xFFEC4899);
    if (lower.contains('career')) return const Color(0xFF3B82F6);
    if (lower.contains('music')) return const Color(0xFFF59E0B);
    return const Color(0xFFA855F7);
  }
}

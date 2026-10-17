import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../widgets/shared/avatar_widget.dart';
import '../../widgets/common/animated_pressable.dart';

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
          color: AppColors.primary,
          onRefresh: () async {
            await context.read<AppState>().fetchBackendData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, appState, user),
                const SizedBox(height: 22),
                _buildMoodTrackerCard(context, appState),
                const SizedBox(height: 18),
                _buildBreathingCard(context),
                const SizedBox(height: 18),
                _buildStreakCard(context, appState),
                const SizedBox(height: 26),
                _buildForYouSection(context, appState),
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

  Widget _buildHeader(BuildContext context, AppState appState, dynamic user) {
    final dateString = DateFormat('EEEE, MMM d').format(DateTime.now());
    final displayName = user.name.isNotEmpty && user.name != 'Loading...'
        ? user.name
        : 'Paras';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateString,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_getGreeting()}, $displayName',
                style: GoogleFonts.newsreader(
                  fontSize: 29,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            appState.setTabIndex(4); // Switch to Profile tab
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AvatarWidget(
              imageUrl: user.avatarUrl.isNotEmpty
                  ? user.avatarUrl
                  : 'assets/images/paras_avatar.jpg',
              radius: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTrackerCard(BuildContext context, AppState appState) {
    final moods = [
      {
        'label': 'Great',
        'icon': Icons.sentiment_very_satisfied_rounded,
        'bg': AppColors.moodGreatBg,
        'color': AppColors.moodGreat,
      },
      {
        'label': 'Good',
        'icon': Icons.sentiment_satisfied_rounded,
        'bg': AppColors.moodGoodBg,
        'color': AppColors.moodGood,
      },
      {
        'label': 'Okay',
        'icon': Icons.sentiment_neutral_rounded,
        'bg': AppColors.moodOkayBg,
        'color': AppColors.moodOkay,
      },
      {
        'label': 'Low',
        'icon': Icons.sentiment_dissatisfied_rounded,
        'bg': AppColors.moodLowBg,
        'color': AppColors.moodLow,
      },
      {
        'label': 'Struggling',
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'bg': AppColors.moodStrugglingBg,
        'color': AppColors.moodStruggling,
      },
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
          Text(
            'How are you feeling right now?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((mood) {
              final label = mood['label'] as String;
              final icon = mood['icon'] as IconData;
              final bg = mood['bg'] as Color;
              final color = mood['color'] as Color;
              final isSelected = appState.todayMood == label;

              return GestureDetector(
                onTap: () {
                  appState.checkInMood(label);
                  if (label == 'Low' || label == 'Struggling' || label == 'Not Good') {
                    _showGentleSheet(context, appState);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: color, width: 2.2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.deepNavyCard,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavyCard.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Concentric Breathing Graphic
          const _BreathingRippleIndicator(),
          const SizedBox(width: 16),
          // Text & Action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take a 1-minute breath',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '4-7-8 breathing to settle your mind.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedPressable(
                  onTap: () => _showBreathingModal(context),
                  pressedScale: 0.94,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Start',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavyCard,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, AppState appState) {
    final streak = appState.dayStreak > 0 ? appState.dayStreak : 4;
    final progress = appState.weeklyProgress > 0 ? appState.weeklyProgress : 4;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
          children: [
            // Top Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.actionPurpleBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: AppColors.actionPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak-day check-in streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Small steps, every day.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$progress/7',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 7 Days Pill Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isFilled = index < progress;
                return Column(
                  children: [
                    Container(
                      height: 7,
                      width: 38,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AppColors.streakFilled
                            : AppColors.streakEmpty,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouSection(BuildContext context, AppState appState) {
    final journalEntries = appState.journalEntries;
    final lastJournalText = journalEntries.isNotEmpty
        ? 'Last entry · ${DateFormat('MMM d, h:mm a').format(journalEntries.first.date)}'
        : 'Last entry · Oct 13, 9:44 AM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For you today',
          style: GoogleFonts.newsreader(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Continue your journal
        _buildActionRowItem(
          icon: Icons.menu_book_rounded,
          iconBg: AppColors.actionPinkBg,
          iconColor: AppColors.actionPink,
          title: 'Continue your journal',
          subtitle: lastJournalText,
          onTap: () => appState.setTabIndex(2), // Switch to Journal Tab
        ),
        const SizedBox(height: 12),

        // 2. Find a peer
        _buildActionRowItem(
          icon: Icons.people_outline_rounded,
          iconBg: AppColors.actionPurpleBg,
          iconColor: AppColors.actionPurple,
          title: 'Find a peer',
          subtitle: '3 people share your interests',
          onTap: () => appState.setTabIndex(1), // Switch to Explore Tab
        ),
        const SizedBox(height: 12),

        // 3. Get help now
        _buildActionRowItem(
          icon: Icons.support_outlined,
          iconBg: AppColors.actionBlueBg,
          iconColor: AppColors.actionBlue,
          title: 'Get help now',
          subtitle: 'Crisis lines and grounding tools',
          onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
        ),
      ],
    );
  }

  Widget _buildActionRowItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showBreathingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BreathingModalSheet(),
    );
  }

  void _showGentleSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'We are here for you 💜',
                style: GoogleFonts.newsreader(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'It takes courage to admit you\'re having a hard time. How can we support you today?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              _buildSupportOption(
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF4F46E5),
                title: 'Find an empathetic peer to talk to',
                onTap: () {
                  Navigator.pop(ctx);
                  appState.setTabIndex(1);
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                icon: Icons.air_rounded,
                color: const Color(0xFF0284C7),
                title: 'Try a calming breathing exercise',
                onTap: () {
                  Navigator.pop(ctx);
                  _showBreathingModal(context);
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                icon: Icons.health_and_safety_rounded,
                color: AppColors.sosRed,
                title: 'Access crisis helplines & grounding (SOS)',
                isPrimary: true,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.sos);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary ? color.withValues(alpha: 0.25) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isPrimary ? color : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
          ],
        ),
      ),
    );
  }
}

/// Breathing ripple circle graphic with pulse effect
class _BreathingRippleIndicator extends StatefulWidget {
  const _BreathingRippleIndicator();

  @override
  State<_BreathingRippleIndicator> createState() => _BreathingRippleIndicatorState();
}

class _BreathingRippleIndicatorState extends State<_BreathingRippleIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: 74,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF283375).withValues(alpha: 0.35 + 0.2 * val),
          ),
          child: Container(
            width: 58 + 4 * val,
            height: 58 + 4 * val,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B4896).withValues(alpha: 0.65),
            ),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5667CA),
              ),
              child: const Icon(
                Icons.air_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Interactive 4-7-8 Breathing Exercise Modal Sheet
class _BreathingModalSheet extends StatefulWidget {
  const _BreathingModalSheet();

  @override
  State<_BreathingModalSheet> createState() => _BreathingModalSheetState();
}

class _BreathingModalSheetState extends State<_BreathingModalSheet> {
  int _secondsLeft = 4;
  String _phase = 'Inhale';
  String _instruction = 'Tap Start to begin 4-7-8 breathing...';
  Timer? _timer;
  bool _isActive = false;

  void _startCycle() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          if (_phase == 'Inhale') {
            _phase = 'Hold';
            _secondsLeft = 7;
            _instruction = 'Hold gently...';
          } else if (_phase == 'Hold') {
            _phase = 'Exhale';
            _secondsLeft = 8;
            _instruction = 'Exhale slowly through your mouth...';
          } else {
            _phase = 'Inhale';
            _secondsLeft = 4;
            _instruction = 'Breathe in calmly through your nose...';
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _phase == 'Inhale' ? 1.25 : (_phase == 'Hold' ? 1.25 : 0.88);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1-Minute Breath',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _instruction,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Breathing Circle
          GestureDetector(
            onTap: () {
              setState(() {
                _isActive = !_isActive;
                if (_isActive) {
                  _startCycle();
                } else {
                  _timer?.cancel();
                }
              });
            },
            child: AnimatedScale(
              scale: _isActive ? scale : 1.0,
              duration: Duration(seconds: _secondsLeft > 0 ? _secondsLeft : 1),
              curve: Curves.easeInOut,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isActive ? _phase : 'Start',
                      style: GoogleFonts.newsreader(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$_secondsLeft',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Inhale 4s • Hold 7s • Exhale 8s',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

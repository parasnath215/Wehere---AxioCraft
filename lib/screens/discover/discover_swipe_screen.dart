import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import '../../widgets/discovery/swipeable_card.dart';
import '../../widgets/discovery/card_action_buttons.dart';
import '../../widgets/discovery/match_dialog.dart';
import '../../widgets/discovery/profile_detail_sheet.dart';
import '../../widgets/common/animated_pulse.dart';
import '../chat/chat_conversation_screen.dart';

class DiscoverSwipeScreen extends StatefulWidget {
  const DiscoverSwipeScreen({super.key});

  @override
  State<DiscoverSwipeScreen> createState() => _DiscoverSwipeScreenState();
}

class _DiscoverSwipeScreenState extends State<DiscoverSwipeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cards = appState.filteredCards;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Find your people)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your people',
                    style: GoogleFonts.newsreader(
                      fontSize: 29,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect with peers who understand what you’re going through.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 2. Swipeable Card Stack or Empty State
            Expanded(
              child: cards.isNotEmpty
                  ? Stack(
                      children: [
                        // Background card for 3D depth
                        if (cards.length > 1)
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                            ),
                          ),

                        // Active Top Swipeable Card
                        Positioned.fill(
                          child: SwipeableCard(
                            card: cards.first,
                            onSwipeLeft: () {
                              appState.swipeLeft();
                            },
                            onSwipeRight: () async {
                              final isMatch = await appState.swipeRight();
                              if (mounted && isMatch && appState.lastMatch != null) {
                                _showMatchCelebration(context, appState);
                              }
                            },
                            onTapDetail: () {
                              _openProfileDetail(context, cards.first.profile, appState);
                            },
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AnimatedPulse(
                              duration: Duration(milliseconds: 1800),
                              minScale: 0.92,
                              maxScale: 1.08,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'You’ve seen everyone for now! 💜',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back soon for more kind, empathetic peers or refresh your deck.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => appState.refreshDeck(),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text(
                                'Refresh Deck',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            if (cards.isNotEmpty) ...[
              // 3. Action Buttons Row (X, Heart, Star)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: CardActionButtons(
                  onPass: () => appState.swipeLeft(),
                  onConnect: () async {
                    final isMatch = await appState.swipeRight();
                    if (mounted && isMatch && appState.lastMatch != null) {
                      _showMatchCelebration(context, appState);
                    }
                  },
                  onSuperLike: () {
                    appState.superSupport();
                    if (appState.lastMatch != null) {
                      _showMatchCelebration(context, appState);
                    }
                  },
                ),
              ),

              // 4. Verified peer trust subtext
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Every peer is verified. You can report or block anytime.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMatchCelebration(BuildContext context, AppState appState) {
    final matchedCard = appState.lastMatch!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MatchCelebrationDialog(
        currentUser: appState.currentUser,
        matchedUser: matchedCard.profile,
        onStartChat: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(peer: matchedCard.profile),
            ),
          );
        },
        onSendIcebreaker: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(peer: matchedCard.profile),
            ),
          );
        },
        onKeepSwiping: () {
          Navigator.pop(ctx);
          appState.clearLastMatch();
        },
      ),
    );
  }

  void _openProfileDetail(BuildContext context, dynamic userProfile, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ProfileDetailSheet(
          profile: userProfile,
          onPass: () {
            Navigator.pop(ctx);
            appState.swipeLeft();
          },
          onLike: () async {
            Navigator.pop(ctx);
            final isMatch = await appState.swipeRight();
            if (mounted && isMatch && appState.lastMatch != null) {
              _showMatchCelebration(context, appState);
            }
          },
          onSendHello: () {
            Navigator.pop(ctx);
            appState.swipeRight();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatConversationScreen(peer: userProfile),
              ),
            );
          },
        ),
      ),
    );
  }
}

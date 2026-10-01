import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state.dart';
import '../../widgets/discovery/swipeable_card.dart';
import '../../widgets/discovery/card_action_buttons.dart';
import '../../widgets/discovery/match_dialog.dart';
import '../../widgets/discovery/profile_detail_sheet.dart';
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
          children: [
            // 1. Header (Mockup 1.17.18 AM (2))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.diversity_1_rounded, color: AppColors.primary, size: 22),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Text('Find Your People', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                          const SizedBox(width: 4),
                          const Text('✨', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text('Swipe to connect with people who get you.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          SizedBox(width: 4),
                          Text('💜', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _attemptPreferenceChange(appState, () => _showDeckFilters(context, appState));
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Swipeable Card Stack or Empty State
            Expanded(
              child: cards.isNotEmpty
                  ? Stack(
                      children: [
                        // Background card for 3D stacked appearance
                        if (cards.length > 1)
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                              if (isMatch && appState.lastMatch != null) {
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                              child: const Icon(Icons.favorite_outline_rounded, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 20),
                            Text('You’ve seen everyone for now! 💜', textAlign: TextAlign.center, style: AppTextStyles.h2),
                            const SizedBox(height: 8),
                            Text(
                              'Check back soon for more kind, empathetic peers or refresh your deck.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => appState.refreshDeck(),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text('Refresh Deck', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Guidance text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text.rich(
                TextSpan(
                  text: 'Swipe ',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  children: const [
                    TextSpan(text: 'right ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    TextSpan(text: 'to connect  •  Swipe '),
                    TextSpan(text: 'left ', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    TextSpan(text: 'to pass'),
                  ],
                ),
              ),
            ),

            // 4. Action Buttons (Pass, Connect, Superlike, Rewind)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: CardActionButtons(
                onPass: () => appState.swipeLeft(),
                onConnect: () async {
                  final isMatch = await appState.swipeRight();
                  if (isMatch && appState.lastMatch != null) {
                    _showMatchCelebration(context, appState);
                  }
                },
                onSuperLike: () {
                  appState.superSupport();
                  if (appState.lastMatch != null) {
                    _showMatchCelebration(context, appState);
                  }
                },
                onRewind: appState.canRewind ? () => appState.rewindLastSwipe() : null,
              ),
            ),
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
              builder: (_) => ChatConversationScreen(
                peer: matchedCard.profile,
                autoSendIcebreaker: true,
              ),
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

  void _openProfileDetail(BuildContext context, userProfile, AppState appState) {
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
            if (isMatch && appState.lastMatch != null) {
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

  void _showDeckFilters(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (fCtx, setFilterState) {
          return Container(
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Discovery Deck ✨', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Category Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tabs.map((tab) {
                    final isSel = appState.activeDiscoveryFilter == tab.replaceAll(' 🟢', '');
                    return GestureDetector(
                      onTap: () {
                        final clean = tab.replaceAll(' 🟢', '');
                        appState.setDiscoveryFilter(clean);
                        setFilterState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primarySoft : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Mutual Connection Priorities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text('Burnout Relief 💜', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.surfaceSubtle),
                    Chip(label: Text('Quiet Listening 🌿', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.surfaceSubtle),
                    Chip(label: Text('Personal Growth 🌱', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.surfaceSubtle),
                    Chip(label: Text('Mindfulness 🧘', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.surfaceSubtle),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          appState.refreshDeck();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deck filters reset to default "For You".')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Reset Deck'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Showing peers for "${appState.activeDiscoveryFilter}" ✨')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}

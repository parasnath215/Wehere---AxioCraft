import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../../state/app_state.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/safe_space_banner.dart';
import '../../widgets/chat/wellness_tip_bar.dart';
import '../../widgets/chat/icebreaker_sheet.dart';
import '../../widgets/subscription/subscription_sheet.dart';
import '../sos/sos_help_screen.dart';

class ChatConversationScreen extends StatefulWidget {
  final UserProfile peer;
  final bool autoSendIcebreaker;

  const ChatConversationScreen({
    super.key,
    required this.peer,
    this.autoSendIcebreaker = false,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _crisisDetected = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSendIcebreaker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendPrompt("What's one good thing that happened today? ✨");
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt(String text) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.sendMessage(widget.peer.id, text, isIcebreaker: true);
    _scrollToBottom();
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Crisis detection (Safety & Moderation layer)
    final lower = text.toLowerCase();
    if (lower.contains('suicide') ||
        lower.contains('kill myself') ||
        lower.contains('end my life') ||
        lower.contains('hurt myself') ||
        lower.contains('cant go on') ||
        lower.contains("can't go on")) {
      setState(() {
        _crisisDetected = true;
      });
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.sendMessage(widget.peer.id, text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final messages = appState.messages[widget.peer.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(widget.peer.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  backgroundColor: AppColors.primarySoft,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                if (widget.peer.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.peer.name, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                      const SizedBox(width: 4),
                      if (widget.peer.isVerified)
                        const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.onlineGreen),
                      const SizedBox(width: 4),
                      Text('Online • ', style: AppTextStyles.caption.copyWith(color: AppColors.onlineGreen, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          widget.peer.moodStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 20),
            ),
            onPressed: () {
              showWeherePlusSubscriptionSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onPressed: () => _showSafetyOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Safe Space Banner
            SafeSpaceBanner(
              onLearnMore: () {
                _showSafeSpaceDialog(context);
              },
            ),

            // Crisis Helpline Alert (Appears automatically if distress keywords detected)
            if (_crisisDetected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEECEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sosRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: AppColors.sosRed, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You matter. We’re here for you.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sosRed)),
                          SizedBox(height: 2),
                          Text('Free, 24/7 confidential listeners are standing by.', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sosRed,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SosHelpScreen()));
                      },
                      child: const Text('Get Help', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Date separator
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Today', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),

            // Messages Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ChatBubble(
                    message: msg,
                    peerAvatar: widget.peer.avatarUrl,
                  );
                },
              ),
            ),

            // Peer typing indicator
            if (appState.isPeerTyping(widget.peer.id))
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: AssetImage(widget.peer.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: AppColors.primarySoft,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.peer.name} is typing...',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Daily Wellness Tip
            const WellnessTipBar(),

            // Chat Input Bar (Mockup 1.17.17 AM (1))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // (+) Add action: opens icebreaker / breathing exercises
                  GestureDetector(
                    onTap: () {
                      _showAttachmentOrActivitySheet(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Voice Note or Send Button
                  if (_textController.text.trim().isEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        final appState = Provider.of<AppState>(context, listen: false);
                        appState.sendVoiceNote(widget.peer.id, 4);
                        _scrollToBottom();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recorded and sent 4s voice note 🎙️'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _handleSendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOrActivitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Shared Wellness Activities ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.auto_awesome, color: AppColors.primary)),
              title: const Text('Send Mental Wellness Icebreaker'),
              subtitle: const Text('Choose from supportive conversation prompts'),
              onTap: () {
                Navigator.pop(ctx);
                _openIcebreakerPicker();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F8F0), child: Icon(Icons.air_rounded, color: AppColors.onlineGreen)),
              title: const Text('Guided 2-Minute Breathing Together'),
              subtitle: const Text('Sync calm 4-7-8 breathing in real time'),
              onTap: () {
                Navigator.pop(ctx);
                _sendPrompt('Hey, let’s do a quick 2-minute calming breath together 🌿');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openIcebreakerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IcebreakerSheet(
        onSelectPrompt: (prompt) {
          _sendPrompt(prompt);
        },
      ),
    );
  }

  void _showSafetyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Safe Space Guidelines'),
              onTap: () {
                Navigator.pop(ctx);
                _showSafeSpaceDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.orange),
              title: const Text('Block & Remove Connection'),
              subtitle: const Text('You will no longer see or receive messages from this peer'),
              onTap: () {
                Navigator.pop(ctx);
                final appState = Provider.of<AppState>(context, listen: false);
                appState.reportAndBlockPeer(widget.peer.id, 'User blocked connection');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connection blocked and removed from your matches.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: AppColors.sosRed),
              title: const Text('Report Inappropriate Behavior', style: TextStyle(color: AppColors.sosRed)),
              subtitle: const Text('Immediate confidential review by human moderator'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Our safety team is reviewing it.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeSpaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Safe Space Pledge'),
          ],
        ),
        content: const Text(
          '1. Treat each other with kindness, patience, and non-judgment.\n\n'
          '2. Keep personal details confidential.\n\n'
          '3. Wehere is a peer support space. If in immediate danger, please reach out through our SOS Help button.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }
}

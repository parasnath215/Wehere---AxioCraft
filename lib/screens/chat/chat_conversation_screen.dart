import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../../state/app_state.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/safe_space_banner.dart';
import '../../widgets/shared/avatar_widget.dart';

class ChatConversationScreen extends StatefulWidget {
  final UserProfile peer;
  final String? initialMessage;
  final bool autoSendInitialMessage;

  const ChatConversationScreen({
    super.key,
    required this.peer,
    this.initialMessage,
    this.autoSendInitialMessage = false,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppState>(context, listen: false);
      var conversationId = appState.getConversationId(widget.peer.id);
      if (conversationId == null) {
        await appState.fetchConversations();
        conversationId = appState.getConversationId(widget.peer.id);
      }
      if (conversationId != null) {
        appState.joinConversation(conversationId);
      }
      appState.fetchConversationDisclosure(widget.peer.id);

      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        if (widget.autoSendInitialMessage && conversationId != null) {
          appState.sendMessage(widget.peer.id, widget.initialMessage!, conversationId, isIcebreaker: true);
          _scrollToBottom();
        } else {
          _textController.text = widget.initialMessage!;
        }
      }
    });
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

  void _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    var conversationId = appState.getConversationId(widget.peer.id);
    if (conversationId == null) {
      await appState.fetchConversations();
      conversationId = appState.getConversationId(widget.peer.id);
    }
    if (conversationId != null) {
      appState.sendMessage(widget.peer.id, text, conversationId);
      _textController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final peer = appState.matchedUsers.firstWhere(
      (u) => u.id == widget.peer.id,
      orElse: () => widget.peer,
    );
    final messages = appState.messages[peer.id] ?? [];

    final String headerTitle = (peer.isMutuallyRevealed && peer.realFirstName != null && peer.realFirstName!.trim().isNotEmpty)
        ? '${peer.realFirstName} (@${peer.displayAlias})'
        : peer.displayAlias;

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
                AvatarWidget(
                  imageUrl: peer.avatarUrl,
                  radius: 20,
                ),
                if (peer.isOnline)
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
                      Flexible(
                        child: Text(
                          headerTitle,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (peer.isMutuallyRevealed)
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: Color(0xFF16A34A),
                        )
                      else if (peer.isVerified)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 7, color: AppColors.onlineGreen),
                      const SizedBox(width: 5),
                      Text(
                        'Online • ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.onlineGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          peer.moodStatus.isNotEmpty
                              ? peer.moodStatus
                              : 'Happy to listen or sit in quiet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
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

            // Progressive Identity Disclosure Banner / Card
            _buildProgressiveIdentityCard(context, appState, peer),



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

            // Messages Stream or Warm Welcome Empty State
            Expanded(
              child: messages.isNotEmpty
                  ? ListView.builder(
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
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarWidget(
                              imageUrl: widget.peer.avatarUrl.isNotEmpty
                                  ? widget.peer.avatarUrl
                                  : 'assets/images/peer_test.jpg',
                              radius: 36,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'You and ${widget.peer.name} connected!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.newsreader(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Say hello and start your conversation.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Peer typing indicator
            if (appState.isPeerTyping(widget.peer.id))
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Row(
                  children: [
                    AvatarWidget(
                      imageUrl: widget.peer.avatarUrl,
                      radius: 12,
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

            // Chat Input Bar
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
              ),
            ),
          ],
        ),
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
          '3. Wehere is a peer support space. For any complaints or support, reach out to grievance@wehere.co.in.',
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

  Widget _buildProgressiveIdentityCard(BuildContext context, AppState appState, UserProfile peer) {
    // 1. Mutually revealed
    if (peer.isMutuallyRevealed) {
      final myName = (appState.currentUser.realFirstName?.isNotEmpty == true)
          ? appState.currentUser.realFirstName!
          : appState.currentUser.displayAlias;
      final peerName = peer.realFirstName ?? peer.displayAlias;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Identity revealed! You are now chatting as $myName and $peerName.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. My user revealed, pending peer's acceptance
    if (peer.myRevealed && !peer.peerRevealed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You've offered to share your first name. Waiting for ${peer.displayAlias} to accept.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Your name is safely hidden until both peers mutually opt in.",
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Peer requested reveal, waiting for my consent
    if (!peer.myRevealed && peer.peerRevealed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_chat_unread_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${peer.displayAlias} would like to exchange real first names.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Would you like to share yours? If you accept, you will both see each other\'s real first names.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleShareFirstName(context, appState, peer),
                    child: const Text('Share First Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    final conversationId = appState.getConversationId(peer.id);
                    if (conversationId != null) {
                      appState.declineReveal(peer.id, conversationId);
                    }
                  },
                  child: const Text('Keep Anonymous', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 4. Neither revealed yet: Subtle "Exchange First Names" action card
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exchange First Names',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Chatting as ${peer.displayAlias}. Opt in mutually.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _handleShareFirstName(context, appState, peer),
            child: const Text(
              'Reveal Name',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleShareFirstName(BuildContext context, AppState appState, UserProfile peer) {
    final convId = appState.getConversationId(peer.id);
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation is initializing... Please try again in a moment.')),
      );
      return;
    }

    final myFirstName = appState.currentUser.realFirstName;
    if (myFirstName == null || myFirstName.trim().isEmpty) {
      final firstNameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Share Your First Name', style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your first name to share with ${peer.displayAlias}. It will remain strictly protected and only revealed once both of you consent.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: firstNameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Real First Name',
                  hintText: 'e.g. Sam, Alex, Priya',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final name = firstNameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogCtx);
                final success = await appState.revealName(peer.id, convId, realFirstName: name);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Offered to share name with ${peer.displayAlias}')),
                  );
                }
              },
              child: const Text('Confirm & Share', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Exchange First Names', style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(
            'Share your real first name ($myFirstName) with ${peer.displayAlias}? Your name will only be revealed if both of you opt in.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await appState.revealName(peer.id, convId, realFirstName: myFirstName);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Offered to share name with ${peer.displayAlias}')),
                  );
                }
              },
              child: const Text('Share First Name', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}

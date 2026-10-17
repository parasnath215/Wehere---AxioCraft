import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_message.dart';
import '../shared/avatar_widget.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final String peerAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.peerAvatar,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    if (message.isMine) {
      // Outgoing bubble (vibrant purple)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 60, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: message.isVoiceNote
                  ? _buildVoicePlayer(isMine: true)
                  : Text(
                      message.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF4F46E5)),
              ],
            ),
          ],
        ),
      );
    } else {
      // Incoming bubble (crisp white with peer avatar)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 16, right: 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              imageUrl: widget.peerAvatar.isNotEmpty
                  ? widget.peerAvatar
                  : 'assets/images/peer_test.jpg',
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: message.isVoiceNote
                        ? _buildVoicePlayer(isMine: false)
                        : Text(
                            message.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVoicePlayer({required bool isMine}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Simulated audio waveform
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(12, (i) {
            final heights = [8.0, 16.0, 22.0, 12.0, 18.0, 24.0, 10.0, 20.0, 14.0, 18.0, 12.0, 6.0];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: heights[i % heights.length],
              decoration: BoxDecoration(
                color: _isPlaying ? AppColors.primary : AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '0:0${widget.message.voiceDurationSeconds > 0 ? widget.message.voiceDurationSeconds : 4}',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

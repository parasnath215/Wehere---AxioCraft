import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CardActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onConnect;
  final VoidCallback onSuperLike;
  final VoidCallback? onRewind;

  const CardActionButtons({
    super.key,
    required this.onPass,
    required this.onConnect,
    required this.onSuperLike,
    this.onRewind,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind Button
        if (onRewind != null) ...[
          _buildCircleButton(
            size: 46,
            icon: Icons.replay_rounded,
            iconColor: const Color(0xFFF59E0B),
            bgColor: Colors.white,
            onTap: onRewind!,
            boxShadowColor: Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(width: 14),
        ],

        // Pass Button (X)
        _buildCircleButton(
          size: 58,
          icon: Icons.close_rounded,
          iconColor: const Color(0xFF8E8EA9),
          bgColor: Colors.white,
          onTap: onPass,
          boxShadowColor: Colors.black.withValues(alpha: 0.06),
        ),
        const SizedBox(width: 18),

        // Connect / Like Button (Large Glowing Heart)
        _buildCircleButton(
          size: 72,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          bgColor: AppColors.primary,
          onTap: onConnect,
          boxShadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 18),

        // Super Like / Star Button
        _buildCircleButton(
          size: 58,
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFF5277),
          bgColor: Colors.white,
          onTap: onSuperLike,
          boxShadowColor: Colors.black.withValues(alpha: 0.06),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required double size,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required Color boxShadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: boxShadowColor,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.48, color: iconColor),
      ),
    );
  }
}

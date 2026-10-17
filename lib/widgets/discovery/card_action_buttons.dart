import 'package:flutter/material.dart';

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
        // Pass Button (X)
        _buildCircleButton(
          size: 56,
          icon: Icons.close_rounded,
          iconColor: const Color(0xFF64748B),
          bgColor: Colors.white,
          onTap: onPass,
          boxShadowColor: Colors.black.withValues(alpha: 0.05),
          hasBorder: true,
        ),
        const SizedBox(width: 22),

        // Connect / Like Button (Large Glowing Heart)
        _buildCircleButton(
          size: 70,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          bgColor: const Color(0xFF4F46E5),
          onTap: onConnect,
          boxShadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.38),
          hasBorder: false,
        ),
        const SizedBox(width: 22),

        // Super Like / Star Button (Star Outline)
        _buildCircleButton(
          size: 56,
          icon: Icons.star_outline_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: Colors.white,
          onTap: onSuperLike,
          boxShadowColor: Colors.black.withValues(alpha: 0.05),
          hasBorder: true,
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
    required bool hasBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: const Color(0xFFEFF1F7), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: boxShadowColor,
              blurRadius: hasBorder ? 12 : 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.46, color: iconColor),
      ),
    );
  }
}

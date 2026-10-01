import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SosPulsingButton extends StatefulWidget {
  final VoidCallback onTap;

  const SosPulsingButton({super.key, required this.onTap});

  @override
  State<SosPulsingButton> createState() => _SosPulsingButtonState();
}

class _SosPulsingButtonState extends State<SosPulsingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 12.0, end: 28.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.sosGlowGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosRed.withValues(alpha: 0.4),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF859B).withValues(alpha: 0.3),
                        blurRadius: _glowAnimation.value * 1.5,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        size: 42,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'I Need Help\nNow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Tap the button above if you need\nimmediate support.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              '100% Confidential',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

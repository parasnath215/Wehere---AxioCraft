import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? textColor;

  const TagChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.primary;
    final effectiveBgColor = isSelected
        ? effectiveActiveColor.withValues(alpha: 0.12)
        : (backgroundColor ?? AppColors.surfaceSubtle);

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? effectiveActiveColor : AppColors.cardBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? effectiveActiveColor : (textColor ?? AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.chipText.copyWith(
              color: isSelected ? effectiveActiveColor : (textColor ?? AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_circle_rounded, size: 16, color: effectiveActiveColor),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }
    return chip;
  }
}

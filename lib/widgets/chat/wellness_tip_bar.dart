import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class WellnessTipBar extends StatefulWidget {
  final String tip;

  const WellnessTipBar({
    super.key,
    this.tip = 'Tip: Take breaks, breathe, and be gentle with yourself. 🌿',
  });

  @override
  State<WellnessTipBar> createState() => _WellnessTipBarState();
}

class _WellnessTipBarState extends State<WellnessTipBar> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7EED8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, size: 18, color: AppColors.onlineGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.tip,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF1E6E45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isVisible = false;
              });
            },
            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF1E6E45)),
          ),
        ],
      ),
    );
  }
}

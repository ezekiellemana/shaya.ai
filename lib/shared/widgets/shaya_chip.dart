import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

class ShayaChip extends StatelessWidget {
  const ShayaChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isMood = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isMood;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: isMood ? 26 : 24,
        padding: EdgeInsets.symmetric(horizontal: isMood ? 14 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMood ? 13 : 6),
          border: Border.all(
            color: selected
                ? const Color(0xFF9B4DCA)
                : Colors.white.withValues(alpha: 0.08),
          ),
          color: selected ? const Color(0x339B4DCA) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: ShayaTextStyles.tag.copyWith(
              color: selected ? kPurpleLight : kTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}

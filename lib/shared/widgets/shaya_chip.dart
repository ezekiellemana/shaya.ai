import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';

class ShayaChip extends StatelessWidget {
  const ShayaChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.isMood = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool isMood;

  @override
  Widget build(BuildContext context) {
    final radius = isMood ? 999.0 : 16.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                ShayaHaptics.trigger(ShayaHapticType.selection);
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: isMood ? 36 : 34,
          padding: EdgeInsets.symmetric(horizontal: isMood ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected
                  ? kPurpleLight.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      kPrimaryPurple.withValues(alpha: 0.30),
                      kViolet.withValues(alpha: 0.18),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.03),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kPrimaryPurple.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: ShayaTextStyles.tag.copyWith(
                color: selected ? Colors.white : kBodyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

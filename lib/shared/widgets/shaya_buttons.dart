import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
    this.hapticType = ShayaHapticType.light,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final ShayaHapticType? hapticType;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled ? kGradPrimary : null,
          color: isEnabled ? null : kSurfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: kPrimaryPurple.withValues(alpha: 0.26),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    if (hapticType != null) {
                      ShayaHaptics.trigger(hapticType!);
                    }
                    onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(label, style: ShayaTextStyles.button),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryOutlineButton extends StatelessWidget {
  const SecondaryOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.hapticType = ShayaHapticType.light,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ShayaHapticType? hapticType;

  @override
  Widget build(BuildContext context) {
    final wrappedPress = onPressed == null
        ? null
        : () {
            if (hapticType != null) {
              ShayaHaptics.trigger(hapticType!);
            }
            onPressed?.call();
          };
    final button = icon == null
        ? OutlinedButton(onPressed: wrappedPress, child: Text(label))
        : OutlinedButton.icon(
            onPressed: wrappedPress,
            icon: Icon(icon, size: 18, color: Colors.white),
            label: Text(label),
          );
    return SizedBox(height: 50, child: button);
  }
}

class DangerOutlineButton extends StatelessWidget {
  const DangerOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kDanger),
          foregroundColor: kDanger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: ShayaTextStyles.body.copyWith(color: kDanger),
        ),
      ),
    );
  }
}

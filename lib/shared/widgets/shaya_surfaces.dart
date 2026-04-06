import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

enum ShayaStateTone { neutral, success, warning, error }

class ShayaSurfaceCard extends StatelessWidget {
  const ShayaSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
    this.radius = 24,
    this.showGlow = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double radius;
  final bool showGlow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient:
          gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kSurfaceDark.withValues(alpha: 0.94),
              kSurface.withValues(alpha: 0.84),
            ],
          ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: kShadowDark.withValues(alpha: 0.42),
          blurRadius: 32,
          offset: const Offset(0, 18),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: decoration,
          child: Stack(
            children: [
              if (showGlow)
                Positioned(
                  top: -22,
                  right: -12,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kPurpleLight.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const SizedBox(width: 120, height: 120),
                    ),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShayaSectionHeader extends StatelessWidget {
  const ShayaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: ShayaTextStyles.metadata),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class ShayaStateCard extends StatelessWidget {
  const ShayaStateCard({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.tone = ShayaStateTone.neutral,
  });

  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final ShayaStateTone tone;

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (tone) {
      ShayaStateTone.success => kSuccess,
      ShayaStateTone.warning => kWarning,
      ShayaStateTone.error => kDanger,
      ShayaStateTone.neutral => kPurpleLight,
    };

    final stateIcon =
        icon ??
        switch (tone) {
          ShayaStateTone.success => Icons.check_circle_outline_rounded,
          ShayaStateTone.warning => Icons.hourglass_bottom_rounded,
          ShayaStateTone.error => Icons.priority_high_rounded,
          ShayaStateTone.neutral => Icons.auto_awesome_rounded,
        };

    return ShayaSurfaceCard(
      borderColor: accentColor.withValues(alpha: 0.22),
      showGlow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.16),
              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
            ),
            child: Icon(stateIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'Nothing here yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ShayaTextStyles.body,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

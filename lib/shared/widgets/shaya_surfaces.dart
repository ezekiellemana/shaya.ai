import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';

enum ShayaStateTone { neutral, success, warning, error }

enum ShayaArtworkVariant {
  generic,
  home,
  library,
  playlist,
  search,
  player,
  profile,
  subscription,
  payment,
}

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
    this.hapticType,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double radius;
  final bool showGlow;
  final Color? borderColor;
  final ShayaHapticType? hapticType;

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
                  onTap: onTap == null
                      ? null
                      : () {
                          if (hapticType != null) {
                            ShayaHaptics.trigger(hapticType!);
                          }
                          onTap?.call();
                        },
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
    this.artworkVariant = ShayaArtworkVariant.generic,
  });

  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final ShayaStateTone tone;
  final ShayaArtworkVariant artworkVariant;

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
          _StateArtwork(
            accentColor: accentColor,
            icon: stateIcon,
            variant: artworkVariant,
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

class _StateArtwork extends StatelessWidget {
  const _StateArtwork({
    required this.accentColor,
    required this.icon,
    required this.variant,
  });

  final Color accentColor;
  final IconData icon;
  final ShayaArtworkVariant variant;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = switch (variant) {
      ShayaArtworkVariant.payment || ShayaArtworkVariant.subscription => kCyan,
      ShayaArtworkVariant.profile => kPink,
      _ => kPurpleLight,
    };
    final assetPath = _assetPathForVariant();

    return SizedBox(
      width: 180,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.22),
                  secondaryColor.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.20)),
            ),
          ),
          if (assetPath != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Opacity(
                  opacity: 0.80,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ...switch (variant) {
            ShayaArtworkVariant.home => [
              _artOrb(26, 14, 54, accentColor, 0.16),
              _artOrb(128, 20, 34, secondaryColor, 0.16),
              _artWave(20, 74, 132),
            ],
            ShayaArtworkVariant.library => [
              _artStack(22, 20, 62, 44, 0.10),
              _artStack(46, 30, 70, 52, 0.15),
              _artStack(78, 40, 78, 58, 0.20),
            ],
            ShayaArtworkVariant.playlist => [
              _artStack(18, 28, 60, 60, 0.08),
              _artStack(54, 18, 60, 60, 0.14),
              _artStack(92, 28, 60, 60, 0.20),
            ],
            ShayaArtworkVariant.search => [
              _artRing(54, 28, 42, accentColor),
              _artHandle(90, 66, secondaryColor),
              _artOrb(26, 18, 20, secondaryColor, 0.18),
            ],
            ShayaArtworkVariant.player => [
              _artWave(26, 72, 128),
              _artOrb(126, 16, 28, accentColor, 0.16),
            ],
            ShayaArtworkVariant.profile => [
              _artOrb(40, 18, 24, accentColor, 0.16),
              _artSilhouette(52, 24, secondaryColor),
            ],
            ShayaArtworkVariant.subscription => [
              _artCard(24, 26, 126, 54, accentColor),
              _artOrb(134, 18, 24, secondaryColor, 0.18),
            ],
            ShayaArtworkVariant.payment => [
              _artCard(26, 30, 124, 48, secondaryColor),
              _artChip(42, 44),
              _artOrb(128, 18, 26, accentColor, 0.16),
            ],
            ShayaArtworkVariant.generic => [
              _artOrb(26, 18, 44, accentColor, 0.16),
              _artOrb(124, 18, 28, secondaryColor, 0.16),
              _artWave(28, 74, 120),
            ],
          },
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.18),
              border: Border.all(color: accentColor.withValues(alpha: 0.26)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  String? _assetPathForVariant() => switch (variant) {
    ShayaArtworkVariant.home => 'assets/branding/empty_home.png',
    ShayaArtworkVariant.library => 'assets/branding/empty_library.png',
    ShayaArtworkVariant.playlist => 'assets/branding/empty_playlist.png',
    ShayaArtworkVariant.search => 'assets/branding/empty_search.png',
    ShayaArtworkVariant.player => 'assets/branding/empty_player.png',
    ShayaArtworkVariant.profile => 'assets/branding/empty_profile.png',
    ShayaArtworkVariant.subscription =>
      'assets/branding/empty_subscription.png',
    ShayaArtworkVariant.payment => 'assets/branding/empty_payment.png',
    ShayaArtworkVariant.generic => null,
  };

  Widget _artOrb(
    double left,
    double top,
    double size,
    Color color,
    double alpha,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }

  Widget _artWave(double left, double top, double width) {
    return Positioned(
      left: left,
      top: top,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(10, (index) {
          final heights = [
            10.0,
            18.0,
            24.0,
            16.0,
            26.0,
            22.0,
            14.0,
            24.0,
            18.0,
            12.0,
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: (width / 16).clamp(4, 8),
              height: heights[index],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _artStack(
    double left,
    double top,
    double width,
    double height,
    double alpha,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }

  Widget _artRing(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.30), width: 4),
        ),
      ),
    );
  }

  Widget _artHandle(double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: 0.8,
        child: Container(
          width: 28,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withValues(alpha: 0.24),
          ),
        ),
      ),
    );
  }

  Widget _artSilhouette(double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.20),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 54,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artCard(
    double left,
    double top,
    double width,
    double height,
    Color color,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artChip(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 24,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

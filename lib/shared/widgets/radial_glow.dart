import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

class RadialGlow extends StatelessWidget {
  const RadialGlow({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              kPrimaryPurple.withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
          backgroundBlendMode: BlendMode.screen,
        ),
      ),
    );
  }
}

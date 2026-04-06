import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

enum WaveformVariant { brand, studio, cinematic, lyrical }

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    this.playedRatio = 0,
    this.barCount = 24,
    this.height = 36,
    this.variant = WaveformVariant.studio,
  });

  final double playedRatio;
  final int barCount;
  final double height;
  final WaveformVariant variant;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<double> _bars;

  @override
  void initState() {
    super.initState();
    _bars = _generateBars();
    _controller = AnimationController(
      vsync: this,
      duration: _style.animationDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barCount != widget.barCount ||
        oldWidget.variant != widget.variant) {
      _bars = _generateBars();
      _controller.duration = _style.animationDuration;
      if (_controller.isAnimating) {
        _controller
          ..reset()
          ..repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(widget.barCount, (index) {
              final motionMultiplier =
                  style.baseMotion +
                  (_controller.value * style.motionAmplitude);
              final animatedHeight = _bars[index] * motionMultiplier;
              final isPlayed =
                  index / widget.barCount <= widget.playedRatio.clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: style.spacing),
                child: Container(
                  width: style.barWidth,
                  height: animatedHeight.clamp(
                    style.minHeight,
                    style.maxHeight,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(style.barWidth + 2),
                    gradient: isPlayed ? style.playedGradient : null,
                    color: isPlayed ? null : style.unplayedColor,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  _WaveformStyle get _style => switch (widget.variant) {
    WaveformVariant.brand => const _WaveformStyle(
      animationDuration: Duration(milliseconds: 1150),
      barWidth: 3.4,
      spacing: 2.2,
      minHeight: 10,
      maxHeight: 30,
      baseHeight: 12,
      heightVariance: 18,
      baseMotion: 0.82,
      motionAmplitude: 0.28,
      playedGradient: kGradAccent,
      unplayedColor: Color(0x26FFFFFF),
    ),
    WaveformVariant.cinematic => const _WaveformStyle(
      animationDuration: Duration(milliseconds: 1320),
      barWidth: 3.8,
      spacing: 2.4,
      minHeight: 11,
      maxHeight: 34,
      baseHeight: 14,
      heightVariance: 20,
      baseMotion: 0.78,
      motionAmplitude: 0.30,
      playedGradient: LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF7B2FBE), Color(0xFFE040FB)],
      ),
      unplayedColor: Color(0x20E8F6FF),
    ),
    WaveformVariant.lyrical => const _WaveformStyle(
      animationDuration: Duration(milliseconds: 980),
      barWidth: 2.6,
      spacing: 2.0,
      minHeight: 8,
      maxHeight: 24,
      baseHeight: 10,
      heightVariance: 12,
      baseMotion: 0.86,
      motionAmplitude: 0.18,
      playedGradient: LinearGradient(
        colors: [Color(0xFFE040FB), Color(0xFFB77AE8), Color(0xFF22D3EE)],
      ),
      unplayedColor: Color(0x22FFFFFF),
    ),
    WaveformVariant.studio => const _WaveformStyle(
      animationDuration: Duration(milliseconds: 1080),
      barWidth: 3.0,
      spacing: 2.0,
      minHeight: 8,
      maxHeight: 28,
      baseHeight: 10,
      heightVariance: 16,
      baseMotion: 0.80,
      motionAmplitude: 0.24,
      playedGradient: kGradCyan,
      unplayedColor: Color(0x1AFFFFFF),
    ),
  };

  List<double> _generateBars() {
    final style = _style;
    final random = Random((widget.variant.index * 37) + widget.barCount + 5);
    return List<double>.generate(widget.barCount, (index) {
      final t = widget.barCount == 1 ? 0.0 : index / (widget.barCount - 1);
      return switch (widget.variant) {
        WaveformVariant.brand =>
          style.baseHeight +
              ((sin(t * pi * 2.2) + 1) * 0.5 * style.heightVariance) +
              random.nextDouble() * 5,
        WaveformVariant.cinematic =>
          style.baseHeight +
              ((sin(t * pi * 3.3) + 1) * 0.5 * style.heightVariance) +
              ((index % 3 == 0) ? 6 : 0) +
              random.nextDouble() * 4,
        WaveformVariant.lyrical =>
          style.baseHeight +
              ((sin(t * pi * 5.5).abs()) * style.heightVariance) +
              random.nextDouble() * 3,
        WaveformVariant.studio =>
          style.baseHeight + random.nextDouble() * style.heightVariance,
      };
    });
  }
}

class _WaveformStyle {
  const _WaveformStyle({
    required this.animationDuration,
    required this.barWidth,
    required this.spacing,
    required this.minHeight,
    required this.maxHeight,
    required this.baseHeight,
    required this.heightVariance,
    required this.baseMotion,
    required this.motionAmplitude,
    required this.playedGradient,
    required this.unplayedColor,
  });

  final Duration animationDuration;
  final double barWidth;
  final double spacing;
  final double minHeight;
  final double maxHeight;
  final double baseHeight;
  final double heightVariance;
  final double baseMotion;
  final double motionAmplitude;
  final Gradient playedGradient;
  final Color unplayedColor;
}

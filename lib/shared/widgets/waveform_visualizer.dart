import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    this.playedRatio = 0,
    this.barCount = 24,
    this.height = 36,
  });

  final double playedRatio;
  final int barCount;
  final double height;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _bars;

  @override
  void initState() {
    super.initState();
    final random = Random(5);
    _bars = List<double>.generate(
      widget.barCount,
      (_) => 8 + random.nextInt(18).toDouble(),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(widget.barCount, (index) {
              final animatedHeight =
                  _bars[index] * (0.75 + (_controller.value * 0.25));
              final isPlayed =
                  index / widget.barCount <= widget.playedRatio.clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  width: 2.5,
                  height: animatedHeight.clamp(8, 26),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isPlayed ? kGradCyan : null,
                    color: isPlayed
                        ? null
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

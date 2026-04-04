import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/radial_glow.dart';
import 'package:shaya_ai/shared/widgets/waveform_visualizer.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned(top: 72, right: 24, child: RadialGlow(size: 180)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final size in [140.0, 108.0, 76.0])
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kPurpleLight.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      const Text(
                        'S',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Shaya AI',
                    style: ShayaTextStyles.display.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create music, lyrics, and video from a single prompt.',
                    style: ShayaTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 140,
                    child: WaveformVisualizer(barCount: 28, height: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

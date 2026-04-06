import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/radial_glow.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
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
            const Positioned(top: -28, left: -8, child: RadialGlow(size: 150)),
            const Positioned(top: 72, right: 24, child: RadialGlow(size: 180)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ShayaSurfaceCard(
                  showGlow: true,
                  padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final size in [152.0, 118.0, 84.0])
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
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: kGradAccent,
                            ),
                            child: const Center(
                              child: Text(
                                'S',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Shaya AI',
                        style: ShayaTextStyles.display.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create music, lyrics, and video from a single prompt.',
                        style: ShayaTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Afrofuturist creative studio',
                          style: ShayaTextStyles.tag.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 160,
                        child: WaveformVisualizer(barCount: 28, height: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

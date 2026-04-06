import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';
import 'package:shaya_ai/shared/widgets/shaya_motion.dart';
import 'package:shaya_ai/shared/widgets/song_artwork.dart';
import 'package:shaya_ai/shared/widgets/waveform_visualizer.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(playerControllerProvider);
    final song = controller.currentSong;
    if (song == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.push('/player'),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kSurfaceDark.withValues(alpha: 0.96),
                      kSurface.withValues(alpha: 0.84),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryPurple.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ShayaSongArtwork(
                        song: song,
                        size: 48,
                        radius: 14,
                        heroTag: ShayaHeroTags.songArtwork(song.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, style: ShayaTextStyles.songName),
                          const SizedBox(height: 4),
                          Text(
                            song.genreSummary,
                            style: ShayaTextStyles.metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          WaveformVisualizer(
                            playedRatio: controller.progressRatio,
                            barCount: 18,
                            height: 18,
                            variant: _variantForSong(song),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ShayaHaptics.trigger(ShayaHapticType.light);
                          controller.togglePlayback();
                        },
                        icon: Icon(
                          controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  WaveformVariant _variantForSong(Song song) {
    if (song.hasVideo) {
      return WaveformVariant.cinematic;
    }
    if (song.contentKind == SongContentKind.lyrics || song.hasLyrics) {
      return WaveformVariant.lyrical;
    }
    return WaveformVariant.studio;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/waveform_visualizer.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerControllerProvider);
    final song = player.currentSong;
    if (song == null) {
      return const ShayaScreenScaffold(
        title: 'Now Playing',
        child: AsyncStateView(
          message: 'Play a song from Home, Generate, or Library first.',
        ),
      );
    }

    return ShayaScreenScaffold(
      title: 'Now Playing',
      subtitle: song.genreSummary,
      showGlow: true,
      child: Column(
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: kGradCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kPurpleLight.withValues(alpha: 0.25)),
            ),
            child: const Center(
              child: Icon(Icons.album_rounded, size: 72, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            song.title,
            style: ShayaTextStyles.display.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 8),
          Text(
            song.prompt,
            style: ShayaTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          WaveformVisualizer(
            playedRatio: player.progressRatio,
            barCount: 48,
            height: 34,
          ),
          Slider(
            value: player.position.inMilliseconds.toDouble().clamp(
              0,
              (player.duration?.inMilliseconds ?? 1).toDouble(),
            ),
            max: (player.duration?.inMilliseconds ?? 1).toDouble(),
            onChanged: (value) =>
                player.seek(Duration(milliseconds: value.toInt())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: player.toggleShuffle,
                icon: const Icon(Icons.shuffle_rounded, size: 24),
              ),
              IconButton(
                onPressed: player.skipPrevious,
                icon: const Icon(Icons.skip_previous_rounded, size: 32),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kGradPrimary,
                ),
                child: IconButton(
                  onPressed: player.togglePlayback,
                  icon: Icon(
                    player.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: player.skipNext,
                icon: const Icon(Icons.skip_next_rounded, size: 32),
              ),
              IconButton(
                onPressed: player.cycleRepeatMode,
                icon: const Icon(Icons.repeat_rounded, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
            child: Text(_showLyrics ? 'Hide lyrics' : 'Show lyrics overlay'),
          ),
          if (_showLyrics && song.hasLyrics) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: song.lyricsSections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: ShayaTextStyles.title.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(section.content, style: ShayaTextStyles.body),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

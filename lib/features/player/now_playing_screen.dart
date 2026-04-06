import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';
import 'package:shaya_ai/shared/widgets/shaya_motion.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/song_artwork.dart';
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
          title: 'Nothing playing yet',
          message: 'Play a song from Home, Generate, or Library first.',
          artworkVariant: ShayaArtworkVariant.player,
        ),
      );
    }

    return ShayaScreenScaffold(
      title: 'Now Playing',
      subtitle: song.genreSummary,
      showGlow: true,
      child: Column(
        children: [
          ShayaSurfaceCard(
            showGlow: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: kPurpleLight.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryPurple.withValues(alpha: 0.22),
                        blurRadius: 36,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ShayaSongArtwork(
                    song: song,
                    size: 280,
                    radius: 30,
                    heroTag: ShayaHeroTags.songArtwork(song.id),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  song.title,
                  style: ShayaTextStyles.display.copyWith(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  song.prompt,
                  style: ShayaTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ShayaSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(player.position),
                      style: ShayaTextStyles.metadata,
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(player.duration),
                      style: ShayaTextStyles.metadata,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WaveformVisualizer(
                  playedRatio: player.progressRatio,
                  barCount: 48,
                  height: 34,
                  variant: _waveformVariant(song),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: player.position.inMilliseconds.toDouble().clamp(
                    0,
                    (player.duration?.inMilliseconds ?? 1).toDouble(),
                  ),
                  max: (player.duration?.inMilliseconds ?? 1).toDouble(),
                  onChanged: (value) =>
                      player.seek(Duration(milliseconds: value.toInt())),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.shuffle_rounded,
                      onPressed: player.toggleShuffle,
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      onPressed: player.skipPrevious,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: kGradPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryPurple.withValues(alpha: 0.30),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          ShayaHaptics.trigger(ShayaHapticType.light);
                          player.togglePlayback();
                        },
                        icon: Icon(
                          player.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: player.skipNext,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.repeat_rounded,
                      onPressed: player.cycleRepeatMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ShayaSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShayaSectionHeader(
                  title: 'Lyrics overlay',
                  subtitle: song.hasLyrics
                      ? 'Reveal and follow along with the saved lyric structure.'
                      : 'No lyric sections are attached to this song yet.',
                  action: TextButton(
                    onPressed: () => setState(() => _showLyrics = !_showLyrics),
                    child: Text(_showLyrics ? 'Hide' : 'Show'),
                  ),
                ),
                if (_showLyrics && song.hasLyrics) ...[
                  const SizedBox(height: 14),
                  Column(
                    children: song.lyricsSections.map((section) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShayaSurfaceCard(
                          radius: 18,
                          padding: const EdgeInsets.all(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.heading,
                                style: ShayaTextStyles.title.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                section.content,
                                style: ShayaTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    final safe = duration ?? Duration.zero;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  WaveformVariant _waveformVariant(Song song) {
    if (song.hasVideo) {
      return WaveformVariant.cinematic;
    }
    if (song.contentKind == SongContentKind.lyrics || song.hasLyrics) {
      return WaveformVariant.lyrical;
    }
    return WaveformVariant.studio;
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: IconButton(
        onPressed: () {
          ShayaHaptics.trigger(ShayaHapticType.light);
          onPressed();
        },
        icon: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}

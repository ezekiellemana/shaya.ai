import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/song_artwork.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.trailing,
    this.heroTag,
    this.hapticType = ShayaHapticType.light,
  });

  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? heroTag;
  final ShayaHapticType? hapticType;

  @override
  Widget build(BuildContext context) {
    final contentType = song.hasVideo
        ? 'Audio + video'
        : song.contentKind == SongContentKind.lyrics
        ? 'Lyrics draft'
        : 'Audio track';

    return ShayaSurfaceCard(
      onTap: onTap,
      hapticType: onTap == null ? null : hapticType,
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ShayaSongArtwork(song: song, size: 68, radius: 18, heroTag: heroTag),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: ShayaTextStyles.songName),
                const SizedBox(height: 6),
                Text(
                  song.genreSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShayaTextStyles.metadata,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(contentType, style: ShayaTextStyles.tag),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
        ],
      ),
    );
  }
}

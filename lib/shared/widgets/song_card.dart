import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

class SongCard extends StatelessWidget {
  const SongCard({super.key, required this.song, this.onTap, this.trailing});

  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final contentType = song.hasVideo
        ? 'Audio + video'
        : song.contentKind == SongContentKind.lyrics
        ? 'Lyrics draft'
        : 'Audio track';

    return ShayaSurfaceCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 68,
              height: 68,
              child: song.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _fallbackArt(),
                    )
                  : _fallbackArt(),
            ),
          ),
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

  Widget _fallbackArt() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kGradCard),
      child: Stack(
        children: const [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.stars_rounded, color: Colors.white70, size: 16),
          ),
          Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

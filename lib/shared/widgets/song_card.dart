import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';

class SongCard extends StatelessWidget {
  const SongCard({super.key, required this.song, this.onTap, this.trailing});

  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 58,
                height: 58,
                child: song.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _fallbackArt(),
                      )
                    : _fallbackArt(),
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
                    song.genre.isEmpty
                        ? 'AI composition'
                        : song.genre.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShayaTextStyles.metadata,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.hasVideo
                        ? 'Audio + video'
                        : song.contentKind == SongContentKind.lyrics
                        ? 'Lyrics draft'
                        : 'Audio track',
                    style: ShayaTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kPurpleLight,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kGradAccent),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

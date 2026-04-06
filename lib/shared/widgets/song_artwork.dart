import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/shaya_shimmer.dart';

class ShayaSongArtwork extends StatelessWidget {
  const ShayaSongArtwork({
    super.key,
    required this.song,
    required this.size,
    required this.radius,
    this.heroTag,
  });

  final Song song;
  final double size;
  final double radius;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final artwork = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: song.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => ShayaSkeletonBlock(
                  width: size,
                  height: size,
                  radius: radius,
                ),
                errorWidget: (_, _, _) => _fallbackArt(),
              )
            : _fallbackArt(),
      ),
    );

    if (heroTag == null) {
      return artwork;
    }

    return Hero(tag: heroTag!, child: artwork);
  }

  Widget _fallbackArt() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kGradCard),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              song.hasVideo
                  ? Icons.movie_creation_outlined
                  : Icons.stars_rounded,
              color: Colors.white70,
              size: size * 0.22,
            ),
          ),
          Positioned(
            left: size * 0.14,
            top: size * 0.18,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Icon(
              song.hasVideo
                  ? Icons.graphic_eq_rounded
                  : Icons.music_note_rounded,
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

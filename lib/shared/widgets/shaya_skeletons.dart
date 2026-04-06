import 'package:flutter/material.dart';
import 'package:shaya_ai/shared/widgets/shaya_shimmer.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

class ShayaHomeFeedSkeleton extends StatelessWidget {
  const ShayaHomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonSectionCard(),
        SizedBox(height: 18),
        _SkeletonFeaturedCard(),
        SizedBox(height: 18),
        _SkeletonSongList(count: 3),
      ],
    );
  }
}

class ShayaLibrarySkeleton extends StatelessWidget {
  const ShayaLibrarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonPlaylistList(),
        SizedBox(height: 18),
        _SkeletonSongList(count: 4),
      ],
    );
  }
}

class ShayaSearchResultsSkeleton extends StatelessWidget {
  const ShayaSearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonSectionCard(),
        SizedBox(height: 14),
        _SkeletonPlaylistList(),
        SizedBox(height: 14),
        _SkeletonSongList(count: 3),
      ],
    );
  }
}

class ShayaProfileSkeleton extends StatelessWidget {
  const ShayaProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShayaSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShayaSkeletonBlock(
                width: 96,
                height: 96,
                shape: BoxShape.circle,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShayaSkeletonBlock(width: 160, height: 22, radius: 14),
                    SizedBox(height: 10),
                    ShayaSkeletonBlock(width: 100, height: 12, radius: 10),
                    SizedBox(height: 14),
                    ShayaSkeletonBlock(width: 120, height: 32, radius: 999),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ShayaSkeletonBlock(height: 42, radius: 16),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ShayaSkeletonBlock(height: 42, radius: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: _SkeletonStatTile()),
            SizedBox(width: 8),
            Expanded(child: _SkeletonStatTile()),
            SizedBox(width: 8),
            Expanded(child: _SkeletonStatTile()),
          ],
        ),
        const SizedBox(height: 18),
        const _SkeletonSectionCard(),
      ],
    );
  }
}

class ShayaSettingsSkeleton extends StatelessWidget {
  const ShayaSettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonSectionCard(),
        SizedBox(height: 18),
        _SkeletonSettingsPanel(),
      ],
    );
  }
}

class ShayaAuthBusySkeleton extends StatelessWidget {
  const ShayaAuthBusySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSkeletonBlock(width: 132, height: 14, radius: 10),
          SizedBox(height: 10),
          ShayaSkeletonBlock(height: 12, radius: 8),
          SizedBox(height: 8),
          ShayaSkeletonBlock(width: 190, height: 12, radius: 8),
        ],
      ),
    );
  }
}

class ShayaPaymentPlaceholderSkeleton extends StatelessWidget {
  const ShayaPaymentPlaceholderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      showGlow: true,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSkeletonBlock(width: 148, height: 18, radius: 12),
          SizedBox(height: 10),
          ShayaSkeletonBlock(height: 12, radius: 8),
          SizedBox(height: 8),
          ShayaSkeletonBlock(width: 210, height: 12, radius: 8),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: ShayaSkeletonBlock(height: 84, radius: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    ShayaSkeletonBlock(height: 40, radius: 18),
                    SizedBox(height: 12),
                    ShayaSkeletonBlock(height: 32, radius: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShayaPlaylistDetailSkeleton extends StatelessWidget {
  const ShayaPlaylistDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonSectionCard(),
        SizedBox(height: 18),
        _SkeletonSongList(count: 4),
      ],
    );
  }
}

class ShayaInlineAvatarSkeleton extends StatelessWidget {
  const ShayaInlineAvatarSkeleton({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShayaSkeletonBlock(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }
}

class _SkeletonFeaturedCard extends StatelessWidget {
  const _SkeletonFeaturedCard();

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              ShayaSkeletonBlock(width: 84, height: 84, radius: 26),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShayaSkeletonBlock(width: 160, height: 24, radius: 14),
                    SizedBox(height: 10),
                    ShayaSkeletonBlock(height: 14, radius: 10),
                    SizedBox(height: 8),
                    ShayaSkeletonBlock(width: 180, height: 14, radius: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              ShayaSkeletonBlock(width: 76, height: 28, radius: 999),
              SizedBox(width: 8),
              ShayaSkeletonBlock(width: 76, height: 28, radius: 999),
              SizedBox(width: 8),
              ShayaSkeletonBlock(width: 76, height: 28, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonSectionCard extends StatelessWidget {
  const _SkeletonSectionCard();

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShayaSkeletonBlock(width: 170, height: 20, radius: 12),
          SizedBox(height: 10),
          ShayaSkeletonBlock(height: 14, radius: 10),
          SizedBox(height: 8),
          ShayaSkeletonBlock(width: 220, height: 14, radius: 10),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShayaSkeletonBlock(height: 46, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: ShayaSkeletonBlock(height: 46, radius: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonSongList extends StatelessWidget {
  const _SkeletonSongList({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _SkeletonSongCard(),
        );
      }),
    );
  }
}

class _SkeletonSongCard extends StatelessWidget {
  const _SkeletonSongCard();

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          ShayaSkeletonBlock(width: 68, height: 68, radius: 18),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShayaSkeletonBlock(width: 180, height: 16, radius: 10),
                SizedBox(height: 8),
                ShayaSkeletonBlock(width: 140, height: 12, radius: 8),
                SizedBox(height: 12),
                ShayaSkeletonBlock(width: 88, height: 28, radius: 999),
              ],
            ),
          ),
          SizedBox(width: 10),
          ShayaSkeletonBlock(width: 36, height: 36, shape: BoxShape.circle),
        ],
      ),
    );
  }
}

class _SkeletonPlaylistList extends StatelessWidget {
  const _SkeletonPlaylistList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ShayaSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                ShayaSkeletonBlock(width: 56, height: 56, radius: 18),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShayaSkeletonBlock(width: 150, height: 16, radius: 10),
                      SizedBox(height: 8),
                      ShayaSkeletonBlock(width: 80, height: 12, radius: 8),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                ShayaSkeletonBlock(
                  width: 18,
                  height: 18,
                  shape: BoxShape.circle,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SkeletonStatTile extends StatelessWidget {
  const _SkeletonStatTile();

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSkeletonBlock(width: 20, height: 20, shape: BoxShape.circle),
          SizedBox(height: 14),
          ShayaSkeletonBlock(width: 42, height: 22, radius: 12),
          SizedBox(height: 6),
          ShayaSkeletonBlock(width: 52, height: 12, radius: 8),
        ],
      ),
    );
  }
}

class _SkeletonSettingsPanel extends StatelessWidget {
  const _SkeletonSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSkeletonBlock(width: 140, height: 20, radius: 12),
          SizedBox(height: 10),
          ShayaSkeletonBlock(height: 12, radius: 8),
          SizedBox(height: 8),
          ShayaSkeletonBlock(width: 200, height: 12, radius: 8),
          SizedBox(height: 18),
          ShayaSkeletonBlock(height: 44, radius: 16),
          SizedBox(height: 12),
          ShayaSkeletonBlock(height: 74, radius: 20),
          SizedBox(height: 12),
          ShayaSkeletonBlock(height: 44, radius: 16),
          SizedBox(height: 10),
          ShayaSkeletonBlock(height: 44, radius: 16),
        ],
      ),
    );
  }
}

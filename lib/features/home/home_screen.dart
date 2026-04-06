import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';
import 'package:shaya_ai/shared/widgets/shaya_motion.dart';
import 'package:shaya_ai/shared/widgets/shaya_shimmer.dart';
import 'package:shaya_ai/shared/widgets/shaya_skeletons.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/song_artwork.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedMood = AppConstants.moods.first;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final feedAsync = ref.watch(homeFeedProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Row(
                children: [
                  profileAsync.when(
                    data: (profile) => _HomeAvatar(photoUrl: profile?.photoUrl),
                    loading: () => const ShayaInlineAvatarSkeleton(),
                    error: (_, _) => const _HomeAvatar(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: profileAsync.when(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habari, ${profile?.displayName ?? 'Creator'}',
                            style: ShayaTextStyles.display.copyWith(
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Shape your next track or video.',
                            style: ShayaTextStyles.body,
                          ),
                        ],
                      ),
                      loading: () => const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShayaSkeletonBlock(
                            width: 180,
                            height: 22,
                            radius: 12,
                          ),
                          SizedBox(height: 8),
                          ShayaSkeletonBlock(
                            width: 140,
                            height: 14,
                            radius: 10,
                          ),
                        ],
                      ),
                      error: (_, _) => Text(
                        'Welcome to Shaya AI',
                        style: ShayaTextStyles.display.copyWith(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ShayaSurfaceCard(
                onTap: () => context.go('/search'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: kPurpleLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search by title, mood, or genre',
                        style: ShayaTextStyles.body,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const ShayaSectionHeader(
                title: "What's your mood?",
                subtitle:
                    'Tune your home feed to the energy you want right now.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.moods.map((mood) {
                  return ShayaChip(
                    label: mood,
                    selected: _selectedMood == mood,
                    isMood: true,
                    onTap: () => setState(() => _selectedMood = mood),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              feedAsync.when(
                data: (songs) => _FeaturedHomeSection(
                  songs: songs,
                  selectedMood: _selectedMood,
                  onPlaySong: _playSong,
                ),
                loading: () => const ShayaHomeFeedSkeleton(),
                error: (error, _) => AsyncStateView(
                  title: 'Unable to load the home feed',
                  message: error.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(homeFeedProvider),
                  tone: ShayaStateTone.error,
                  artworkVariant: ShayaArtworkVariant.home,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playSong(Song song, {required List<Song> queue}) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(playerControllerProvider).loadSong(song, queue: queue);
      if (!mounted) {
        return;
      }
      await router.push('/player');
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _FeaturedHomeSection extends StatelessWidget {
  const _FeaturedHomeSection({
    required this.songs,
    required this.selectedMood,
    required this.onPlaySong,
  });

  final List<Song> songs;
  final String selectedMood;
  final Future<void> Function(Song song, {required List<Song> queue})
  onPlaySong;

  @override
  Widget build(BuildContext context) {
    final moodMatches = songs
        .where(
          (song) =>
              (song.mood ?? '').isEmpty ||
              (song.mood ?? '').toLowerCase() == selectedMood.toLowerCase(),
        )
        .toList();
    final displaySongs = moodMatches.isNotEmpty ? moodMatches : songs;
    final featured = displaySongs.isNotEmpty ? displaySongs.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured != null) ...[
          const ShayaSectionHeader(
            title: 'Featured',
            subtitle: 'A highlighted public release from the Shaya catalog.',
          ),
          const SizedBox(height: 10),
          ShayaSurfaceCard(
            onTap: () => onPlaySong(featured, queue: displaySongs),
            hapticType: ShayaHapticType.light,
            showGlow: true,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF25104B), Color(0xFF102040)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShayaSongArtwork(
                      song: featured,
                      size: 84,
                      radius: 26,
                      heroTag: ShayaHeroTags.songArtwork(featured.id),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            featured.title,
                            style: ShayaTextStyles.display.copyWith(
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            featured.prompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ShayaTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: featured.genre
                      .map((tag) => ShayaChip(label: tag, selected: true))
                      .toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: kGradAccent,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Play now',
                        style: ShayaTextStyles.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      featured.hasVideo ? 'AUDIO + VIDEO' : 'AUDIO',
                      style: ShayaTextStyles.tag.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const ShayaSectionHeader(
          title: 'Trending songs',
          subtitle: 'Fresh public releases from the community catalog.',
        ),
        const SizedBox(height: 10),
        if (songs.isEmpty)
          const AsyncStateView(
            title: 'No public songs yet',
            message: 'No public playable songs are available yet.',
            artworkVariant: ShayaArtworkVariant.home,
          )
        else ...[
          if (moodMatches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No public songs match $selectedMood yet. Showing the latest public releases instead.',
                style: ShayaTextStyles.metadata,
              ),
            ),
          Column(
            children: displaySongs
                .map(
                  (song) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SongCard(
                      song: song,
                      heroTag: song.id == featured?.id
                          ? null
                          : ShayaHeroTags.songArtwork(song.id),
                      onTap: () => onPlaySong(song, queue: displaySongs),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: ShayaHeroTags.profileAvatarCurrentUser,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: photoUrl == null ? kGradAccent : null,
          border: Border.all(color: kPurpleLight.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: kPrimaryPurple.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: photoUrl == null
              ? const Icon(Icons.person_rounded, color: Colors.white)
              : CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.person_rounded, color: Colors.white),
                  placeholder: (_, _) => const ShayaSkeletonBlock(
                    width: 52,
                    height: 52,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Row(
                children: [
                  profileAsync.when(
                    data: (profile) => _HomeAvatar(photoUrl: profile?.photoUrl),
                    loading: () => const _HomeAvatar(),
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
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            'Shape your next track or video.',
                            style: ShayaTextStyles.body,
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => Text(
                        'Welcome to Shaya AI',
                        style: ShayaTextStyles.display.copyWith(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => context.go('/search'),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPrimaryPurple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: kPurpleLight,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search by title, mood, or genre',
                        style: ShayaTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text("What's your mood?", style: ShayaTextStyles.title),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AsyncStateView(
                  message: error.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(homeFeedProvider),
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
          Text('Featured', style: ShayaTextStyles.title),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onPlaySong(featured, queue: displaySongs),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: kGradCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPurpleLight.withValues(alpha: 0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featured.title,
                    style: ShayaTextStyles.display.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    featured.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ShayaTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: featured.genre
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(tag, style: ShayaTextStyles.tag),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Play now',
                        style: ShayaTextStyles.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('Trending songs', style: ShayaTextStyles.title),
        const SizedBox(height: 10),
        if (songs.isEmpty)
          const AsyncStateView(
            message: 'No public playable songs are available yet.',
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
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl == null ? kGradAccent : null,
        border: Border.all(color: kPurpleLight.withValues(alpha: 0.3)),
      ),
      child: ClipOval(
        child: photoUrl == null
            ? const Icon(Icons.person_rounded, color: Colors.white)
            : CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.person_rounded, color: Colors.white),
                placeholder: (_, _) => Container(
                  color: Colors.white.withValues(alpha: 0.06),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

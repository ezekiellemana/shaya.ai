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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kGradAccent,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
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
              Text('What’s your mood?', style: ShayaTextStyles.title),
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
}

class _FeaturedHomeSection extends StatelessWidget {
  const _FeaturedHomeSection({required this.songs, required this.selectedMood});

  final List<Song> songs;
  final String selectedMood;

  @override
  Widget build(BuildContext context) {
    final filtered = songs
        .where(
          (song) =>
              (song.mood ?? '').isEmpty ||
              (song.mood ?? '').toLowerCase() == selectedMood.toLowerCase(),
        )
        .toList();
    final featured = filtered.isNotEmpty ? filtered.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured != null) ...[
          Text('Featured', style: ShayaTextStyles.title),
          const SizedBox(height: 10),
          Container(
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
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('Trending songs', style: ShayaTextStyles.title),
        const SizedBox(height: 10),
        if (songs.isEmpty)
          const AsyncStateView(message: 'No public songs are available yet.')
        else
          Column(
            children: songs
                .map(
                  (song) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SongCard(song: song),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

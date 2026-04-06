import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/features/search/search_results.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_haptics.dart';
import 'package:shaya_ai/shared/widgets/shaya_motion.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_skeletons.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider(_activeQuery));
    final router = GoRouter.of(context);

    return ShayaScreenScaffold(
      title: 'Search',
      subtitle: 'Search songs, lyrics, moods, genres, and playlists.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSurfaceCard(
            showGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _activeQuery = value),
              style: ShayaTextStyles.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search your library and playlists',
                suffixIcon: _activeQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ShayaSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShayaSectionHeader(
                  title: 'Quick picks',
                  subtitle:
                      'Tap a genre or mood to jump straight into your catalog.',
                ),
                const SizedBox(height: 14),
                _QuickPickSection(
                  title: 'Genres',
                  items: AppConstants.genreTags,
                  activeQuery: _activeQuery,
                  onSelect: _selectQuery,
                ),
                const SizedBox(height: 16),
                _QuickPickSection(
                  title: 'Moods',
                  items: AppConstants.moods,
                  activeQuery: _activeQuery,
                  onSelect: _selectQuery,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          searchResultsAsync.when(
            data: (results) => _SearchResultsView(
              results: results,
              onOpenPlaylist: (playlist) =>
                  context.push('/playlist/${playlist.id}'),
              onPlaySong: (song, queue) =>
                  _playSong(song, queue: queue, router: router),
            ),
            loading: () => const ShayaSearchResultsSkeleton(),
            error: (error, _) => AsyncStateView(
              title: 'Search unavailable',
              message: error.toString(),
              tone: ShayaStateTone.error,
              artworkVariant: ShayaArtworkVariant.search,
            ),
          ),
        ],
      ),
    );
  }

  void _selectQuery(String value) {
    _searchController.text = value;
    setState(() => _activeQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _activeQuery = '');
  }

  Future<void> _playSong(
    Song song, {
    required List<Song> queue,
    required GoRouter router,
  }) async {
    await ref.read(playerControllerProvider).loadSong(song, queue: queue);
    if (!mounted) {
      return;
    }
    await router.push('/player');
  }
}

class _QuickPickSection extends StatelessWidget {
  const _QuickPickSection({
    required this.title,
    required this.items,
    required this.activeQuery,
    required this.onSelect,
  });

  final String title;
  final List<String> items;
  final String activeQuery;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final normalizedActive = activeQuery.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return ShayaChip(
              label: item,
              selected: normalizedActive == item.toLowerCase(),
              isMood: title == 'Moods',
              onTap: () => onSelect(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.results,
    required this.onOpenPlaylist,
    required this.onPlaySong,
  });

  final SearchResults results;
  final ValueChanged<Playlist> onOpenPlaylist;
  final Future<void> Function(Song song, List<Song> queue) onPlaySong;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return AsyncStateView(
        title: results.hasQuery ? 'No matches found' : 'Your catalog is empty',
        message: results.hasQuery
            ? 'No songs or playlists match "${results.query}".'
            : 'Nothing to search yet. Create songs, lyrics, or playlists and they will appear here.',
        artworkVariant: ShayaArtworkVariant.search,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShayaSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.travel_explore_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  results.hasQuery
                      ? 'Found ${results.playlists.length} playlists and ${results.songs.length} songs'
                      : 'Everything in your catalog',
                  style: ShayaTextStyles.body,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (results.playlists.isNotEmpty) ...[
          const ShayaSectionHeader(
            title: 'Playlists',
            subtitle: 'Open collections directly from search results.',
          ),
          const SizedBox(height: 10),
          Column(
            children: results.playlists.map((playlist) {
              final songs = results.songsForPlaylist(playlist);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlaylistResultCard(
                  playlist: playlist,
                  songs: songs,
                  onTap: () => onOpenPlaylist(playlist),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (results.songs.isNotEmpty) ...[
          const ShayaSectionHeader(
            title: 'Songs',
            subtitle: 'Play search matches instantly from this list.',
          ),
          const SizedBox(height: 10),
          Column(
            children: results.songs.map((song) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SongCard(
                  song: song,
                  heroTag: ShayaHeroTags.songArtwork(song.id),
                  onTap: () => onPlaySong(song, results.songs),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _PlaylistResultCard extends StatelessWidget {
  const _PlaylistResultCard({
    required this.playlist,
    required this.songs,
    required this.onTap,
  });

  final Playlist playlist;
  final List<Song> songs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = songs.take(2).map((song) => song.title).join(' / ');
    return ShayaSurfaceCard(
      onTap: onTap,
      hapticType: ShayaHapticType.light,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Hero(
            tag: ShayaHeroTags.playlistCover(playlist.id),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF220A3E), Color(0xFF0D1B3E)],
                ),
              ),
              child: const Icon(Icons.queue_music_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playlist.name, style: ShayaTextStyles.songName),
                const SizedBox(height: 4),
                Text(
                  '${playlist.songIds.length} tracks',
                  style: ShayaTextStyles.metadata,
                ),
                const SizedBox(height: 8),
                Text(
                  preview.isEmpty ? 'No tracks added yet.' : preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShayaTextStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: kPurpleLight,
            size: 22,
          ),
        ],
      ),
    );
  }
}

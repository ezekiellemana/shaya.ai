import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

enum _LibraryTab { songs, videos, lyrics }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _LibraryTab _tab = _LibraryTab.songs;

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(librarySongsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);

    return ShayaScreenScaffold(
      title: 'Library',
      subtitle: 'All of your songs, videos, lyrics, and playlists.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tabChip('Songs', _LibraryTab.songs),
              _tabChip('Videos', _LibraryTab.videos),
              _tabChip('Lyrics', _LibraryTab.lyrics),
            ],
          ),
          const SizedBox(height: 18),
          playlistsAsync.when(
            data: (playlists) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Playlists',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: _createPlaylist,
                      child: const Text('Create'),
                    ),
                  ],
                ),
                if (playlists.isEmpty)
                  const Text('No playlists yet.')
                else
                  Column(
                    children: playlists
                        .map(
                          (playlist) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(playlist.name),
                            subtitle: Text('${playlist.songIds.length} tracks'),
                            onTap: () =>
                                context.push('/playlist/${playlist.id}'),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 18),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          songsAsync.when(
            data: (songs) {
              final filtered = switch (_tab) {
                _LibraryTab.songs =>
                  songs.where((song) => song.hasAudio).toList(),
                _LibraryTab.videos =>
                  songs.where((song) => song.hasVideo).toList(),
                _LibraryTab.lyrics =>
                  songs.where((song) => song.hasLyrics).toList(),
              };

              if (filtered.isEmpty) {
                return const AsyncStateView(
                  message:
                      'Nothing here yet. Generate your first track or lyrics to fill the library.',
                );
              }
              return Column(
                children: filtered.map((song) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SongCard(
                      song: song,
                      onTap: () => _playSong(song, songs),
                      trailing: IconButton(
                        onPressed: () => _deleteSong(song.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncStateView(message: error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _LibraryTab tab) {
    return ShayaChip(
      label: label,
      selected: _tab == tab,
      onTap: () => setState(() => _tab = tab),
    );
  }

  Future<void> _createPlaylist() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create playlist'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (created == null || created.trim().isEmpty) {
      return;
    }
    try {
      final playlist = await ref
          .read(playlistsRepositoryProvider)
          .createPlaylist(created.trim());
      ref.invalidate(playlistsProvider);
      if (!mounted) {
        return;
      }
      await router.push('/playlist/${playlist.id}');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteSong(String songId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(songsRepositoryProvider).deleteSong(songId);
      ref.invalidate(librarySongsProvider);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _playSong(Song song, List<Song> queue) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(playerControllerProvider).loadSong(song, queue: queue);
      if (!mounted) {
        return;
      }
      await router.push('/player');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

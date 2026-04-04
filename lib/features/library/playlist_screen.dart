import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final songs = ref.watch(librarySongsProvider).value ?? const <Song>[];

    return playlists.when(
      data: (items) {
        final matches = items.where((item) => item.id == playlistId).toList();
        final playlist = matches.isEmpty ? null : matches.first;
        if (playlist == null) {
          return const ShayaScreenScaffold(
            title: 'Playlist',
            child: AsyncStateView(message: 'Playlist not found.'),
          );
        }

        final playlistSongs = playlist.songIds
            .map((songId) {
              final songMatches = songs
                  .where((song) => song.id == songId)
                  .toList();
              return songMatches.isEmpty ? null : songMatches.first;
            })
            .whereType<Song>()
            .toList();

        return ShayaScreenScaffold(
          title: playlist.name,
          subtitle: '${playlistSongs.length} tracks',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PrimaryGradientButton(
                      label: 'Play all',
                      onPressed: playlistSongs.isEmpty
                          ? null
                          : () async {
                              await ref
                                  .read(playerControllerProvider)
                                  .loadSong(
                                    playlistSongs.first,
                                    queue: playlistSongs,
                                  );
                              if (!context.mounted) {
                                return;
                              }
                              await context.push('/player');
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryOutlineButton(
                      label: 'Shuffle',
                      icon: Icons.shuffle_rounded,
                      onPressed: playlistSongs.isEmpty
                          ? null
                          : () async {
                              final shuffled = <Song>[...playlistSongs]
                                ..shuffle();
                              await ref
                                  .read(playerControllerProvider)
                                  .loadSong(shuffled.first, queue: shuffled);
                              if (!context.mounted) {
                                return;
                              }
                              await context.push('/player');
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _renamePlaylist(
                      context,
                      ref,
                      playlist.id,
                      playlist.name,
                    ),
                    child: const Text('Rename'),
                  ),
                  TextButton(
                    onPressed: () => _deletePlaylist(context, ref, playlist.id),
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (playlistSongs.isEmpty)
                const AsyncStateView(
                  message:
                      'Add songs from your library to populate this playlist.',
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playlistSongs.length,
                  onReorder: (oldIndex, newIndex) async {
                    final ordered = [...playlist.songIds];
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final moved = ordered.removeAt(oldIndex);
                    ordered.insert(newIndex, moved);
                    await ref
                        .read(playlistsRepositoryProvider)
                        .updateSongOrder(playlist.id, ordered);
                    ref.invalidate(playlistsProvider);
                  },
                  itemBuilder: (context, index) {
                    final song = playlistSongs[index];
                    return ListTile(
                      key: ValueKey(song.id),
                      leading: Text('${index + 1}'),
                      title: Text(song.title),
                      subtitle: Text(song.genre.join(' · ')),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const ShayaScreenScaffold(
        title: 'Playlist',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ShayaScreenScaffold(
        title: 'Playlist',
        child: AsyncStateView(message: error.toString()),
      ),
    );
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename playlist'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) {
      return;
    }
    await ref
        .read(playlistsRepositoryProvider)
        .renamePlaylist(playlistId, result.trim());
    ref.invalidate(playlistsProvider);
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) async {
    await ref.read(playlistsRepositoryProvider).deletePlaylist(playlistId);
    ref.invalidate(playlistsProvider);
    if (!context.mounted) {
      return;
    }
    context.pop();
  }
}

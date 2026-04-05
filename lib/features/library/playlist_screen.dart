import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final songsAsync = ref.watch(librarySongsProvider);

    return playlistsAsync.when(
      data: (items) {
        final matches = items.where((item) => item.id == playlistId).toList();
        final playlist = matches.isEmpty ? null : matches.first;
        if (playlist == null) {
          return const ShayaScreenScaffold(
            title: 'Playlist',
            child: AsyncStateView(message: 'Playlist not found.'),
          );
        }

        return songsAsync.when(
          data: (songs) {
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
                                      .loadSong(
                                        shuffled.first,
                                        queue: shuffled,
                                      );
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _manageSongs(context, ref, playlist, songs),
                        child: const Text('Add songs'),
                      ),
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
                        onPressed: () =>
                            _deletePlaylist(context, ref, playlist.id),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (songs.isEmpty)
                    AsyncStateView(
                      message:
                          'Your library is empty right now. Add songs, videos, or lyrics first, then build playlists.',
                      actionLabel: 'Back to library',
                      onAction: () => context.go('/library'),
                    )
                  else if (playlistSongs.isEmpty)
                    AsyncStateView(
                      message:
                          'Add songs from your library to populate this playlist.',
                      actionLabel: 'Add songs',
                      onAction: () =>
                          _manageSongs(context, ref, playlist, songs),
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
                        return Padding(
                          key: ValueKey(song.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SongCard(
                            song: song,
                            onTap: () async {
                              await ref
                                  .read(playerControllerProvider)
                                  .loadSong(song, queue: playlistSongs);
                              if (!context.mounted) {
                                return;
                              }
                              await context.push('/player');
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Remove from playlist',
                                  onPressed: () =>
                                      _removeSong(context, ref, playlist, song),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.drag_handle_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Future<void> _manageSongs(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    List<Song> songs,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final selectedIds = <String>{...playlist.songIds};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0B0820),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose songs for ${playlist.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected songs stay in their current order. New songs are appended.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final selected = selectedIds.contains(song.id);
                          return CheckboxListTile(
                            value: selected,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF9F67FF),
                            title: Text(song.title),
                            subtitle: Text(
                              song.genre.isEmpty
                                  ? 'AI composition'
                                  : song.genre.join(' / '),
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                if (value ?? false) {
                                  selectedIds.add(song.id);
                                } else {
                                  selectedIds.remove(song.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryGradientButton(
                      label: 'Save selection',
                      onPressed: () async {
                        final orderedExisting = playlist.songIds
                            .where(selectedIds.contains)
                            .toList();
                        final newIds = songs
                            .where(
                              (song) =>
                                  selectedIds.contains(song.id) &&
                                  !playlist.songIds.contains(song.id),
                            )
                            .map((song) => song.id)
                            .toList();
                        final merged = [...orderedExisting, ...newIds];
                        await ref
                            .read(playlistsRepositoryProvider)
                            .updateSongOrder(playlist.id, merged);
                        ref.invalidate(playlistsProvider);
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${playlist.name} updated with ${merged.length} tracks.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Playlist renamed.')));
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

  Future<void> _removeSong(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    Song song,
  ) async {
    final updated = playlist.songIds.where((id) => id != song.id).toList();
    await ref
        .read(playlistsRepositoryProvider)
        .updateSongOrder(playlist.id, updated);
    ref.invalidate(playlistsProvider);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${song.title} removed.')));
  }
}

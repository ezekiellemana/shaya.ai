import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
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
            child: AsyncStateView(
              title: 'Playlist not found',
              message: 'This collection is no longer available.',
            ),
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
                  ShayaSurfaceCard(
                    showGlow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShayaSectionHeader(
                          title: 'Playlist controls',
                          subtitle:
                              'Play, shuffle, manage songs, or refine the playlist details.',
                        ),
                        const SizedBox(height: 16),
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
                                        final shuffled = <Song>[
                                          ...playlistSongs,
                                        ]..shuffle();
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
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _manageSongs(context, ref, playlist, songs),
                              icon: const Icon(Icons.playlist_add_rounded),
                              label: const Text('Add songs'),
                            ),
                            TextButton.icon(
                              onPressed: () => _renamePlaylist(
                                context,
                                ref,
                                playlist.id,
                                playlist.name,
                              ),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Rename'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _deletePlaylist(context, ref, playlist.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (songs.isEmpty)
                    AsyncStateView(
                      title: 'Library is empty',
                      message:
                          'Add songs, videos, or lyrics first, then build playlists.',
                      actionLabel: 'Back to library',
                      onAction: () => context.go('/library'),
                    )
                  else if (playlistSongs.isEmpty)
                    AsyncStateView(
                      title: 'No tracks yet',
                      message:
                          'Add songs from your library to populate this playlist.',
                      actionLabel: 'Add songs',
                      onAction: () =>
                          _manageSongs(context, ref, playlist, songs),
                    )
                  else
                    ShayaSurfaceCard(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShayaSectionHeader(
                            title: 'Track order',
                            subtitle:
                                'Drag handles to refine sequence without changing playback logic.',
                          ),
                          const SizedBox(height: 12),
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
                                        onPressed: () => _removeSong(
                                          context,
                                          ref,
                                          playlist,
                                          song,
                                        ),
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                        ),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.drag_handle_rounded,
                                          ),
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
            child: AsyncStateView(
              title: 'Playlist unavailable',
              message: error.toString(),
              tone: ShayaStateTone.error,
            ),
          ),
        );
      },
      loading: () => const ShayaScreenScaffold(
        title: 'Playlist',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ShayaScreenScaffold(
        title: 'Playlist',
        child: AsyncStateView(
          title: 'Playlists unavailable',
          message: 'The playlist list could not be loaded right now.',
          tone: ShayaStateTone.error,
        ),
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
                    ShayaSectionHeader(
                      title: 'Choose songs for ${playlist.name}',
                      subtitle:
                          'Selected songs stay in their current order. New songs are appended.',
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShayaSurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: CheckboxListTile(
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
                              ),
                            ),
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New playlist name'),
        ),
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

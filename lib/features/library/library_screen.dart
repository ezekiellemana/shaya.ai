import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

enum _LibraryTab { songs, videos, lyrics }

enum _SongMenuAction { addToPlaylist, delete }

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
    final playlists = playlistsAsync.asData?.value ?? const <Playlist>[];

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
            data: (items) => Column(
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
                      onPressed: () => _createPlaylist(),
                      child: const Text('Create'),
                    ),
                  ],
                ),
                if (items.isEmpty)
                  AsyncStateView(
                    message:
                        'No playlists yet. Create one to group tracks, videos, and lyric drafts.',
                    actionLabel: 'Create playlist',
                    onAction: () => _createPlaylist(),
                  )
                else
                  Column(
                    children: items
                        .map(
                          (playlist) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(playlist.name),
                            subtitle: Text('${playlist.songIds.length} tracks'),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                            ),
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
                      onTap: () => _playSong(song, filtered),
                      trailing: PopupMenuButton<_SongMenuAction>(
                        onSelected: (action) async {
                          switch (action) {
                            case _SongMenuAction.addToPlaylist:
                              await _showPlaylistPicker(song, playlists);
                            case _SongMenuAction.delete:
                              await _deleteSong(song.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _SongMenuAction.addToPlaylist,
                            child: Text('Add to playlist'),
                          ),
                          PopupMenuItem(
                            value: _SongMenuAction.delete,
                            child: Text('Delete from library'),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white70,
                        ),
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

  Future<void> _createPlaylist({
    List<String> initialSongIds = const [],
    bool openAfterCreate = true,
  }) async {
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
          .createPlaylist(created.trim(), songIds: initialSongIds);
      ref.invalidate(playlistsProvider);
      if (!mounted) {
        return;
      }
      if (openAfterCreate) {
        await router.push('/playlist/${playlist.id}');
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('${playlist.name} created.')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteSong(String songId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(songsRepositoryProvider).deleteSong(songId);
      await ref
          .read(playlistsRepositoryProvider)
          .removeSongFromAllPlaylists(songId);
      ref.invalidate(librarySongsProvider);
      ref.invalidate(playlistsProvider);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Song removed from your library.')),
      );
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

  Future<void> _showPlaylistPicker(Song song, List<Playlist> playlists) async {
    final messenger = ScaffoldMessenger.of(context);
    final mutablePlaylists = playlists
        .map((playlist) => playlist.copyWith(songIds: [...playlist.songIds]))
        .toList();
    final busyIds = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0820),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> togglePlaylist(Playlist playlist) async {
              final containsSong = playlist.songIds.contains(song.id);
              setModalState(() => busyIds.add(playlist.id));
              try {
                await ref
                    .read(playlistsRepositoryProvider)
                    .setSongMembership(
                      playlist,
                      song.id,
                      shouldInclude: !containsSong,
                    );
                final index = mutablePlaylists.indexWhere(
                  (item) => item.id == playlist.id,
                );
                if (index != -1) {
                  final updatedIds = <String>[...playlist.songIds];
                  if (containsSong) {
                    updatedIds.remove(song.id);
                  } else {
                    updatedIds.add(song.id);
                  }
                  mutablePlaylists[index] = playlist.copyWith(
                    songIds: updatedIds,
                  );
                }
                ref.invalidate(playlistsProvider);
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      containsSong
                          ? 'Removed from ${playlist.name}.'
                          : 'Added to ${playlist.name}.',
                    ),
                  ),
                );
              } catch (error) {
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => busyIds.remove(playlist.id));
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add "${song.title}" to a playlist',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a playlist to add or remove this song.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (mutablePlaylists.isEmpty)
                      AsyncStateView(
                        message:
                            'Create your first playlist to organize songs, videos, and lyric drafts.',
                        actionLabel: 'Create playlist',
                        onAction: () async {
                          Navigator.of(sheetContext).pop();
                          await _createPlaylist(
                            initialSongIds: [song.id],
                            openAfterCreate: false,
                          );
                        },
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: mutablePlaylists.length + 1,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: Colors.white12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                title: const Text('Create new playlist'),
                                subtitle: const Text(
                                  'Create a playlist and add this song immediately.',
                                ),
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _createPlaylist(
                                    initialSongIds: [song.id],
                                    openAfterCreate: false,
                                  );
                                },
                              );
                            }

                            final playlist = mutablePlaylists[index - 1];
                            final containsSong = playlist.songIds.contains(
                              song.id,
                            );
                            final busy = busyIds.contains(playlist.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: busy
                                  ? null
                                  : () => togglePlaylist(playlist),
                              leading: Icon(
                                containsSong
                                    ? Icons.check_circle_rounded
                                    : Icons.queue_music_rounded,
                                color: containsSong
                                    ? const Color(0xFF9F67FF)
                                    : Colors.white70,
                              ),
                              title: Text(playlist.name),
                              subtitle: Text(
                                '${playlist.songIds.length} tracks',
                              ),
                              trailing: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : containsSong
                                  ? const Text('Added')
                                  : const Text('Add'),
                            );
                          },
                        ),
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
}

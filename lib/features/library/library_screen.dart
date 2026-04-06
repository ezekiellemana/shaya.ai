import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
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
          ShayaSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep your music, video, and lyric drafts organized in one premium workspace.',
                    style: ShayaTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ShayaSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShayaSectionHeader(
                  title: 'Media filter',
                  subtitle: 'Switch views without losing your saved items.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tabChip('Songs', _LibraryTab.songs),
                    _tabChip('Videos', _LibraryTab.videos),
                    _tabChip('Lyrics', _LibraryTab.lyrics),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          playlistsAsync.when(
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShayaSectionHeader(
                  title: 'Playlists',
                  subtitle: 'Curate listening queues and reusable collections.',
                  action: TextButton(
                    onPressed: () => _createPlaylist(),
                    child: const Text('Create'),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  AsyncStateView(
                    title: 'No playlists yet',
                    message:
                        'Create one to group tracks, videos, and lyric drafts.',
                    actionLabel: 'Create playlist',
                    onAction: () => _createPlaylist(),
                  )
                else
                  Column(
                    children: items.map((playlist) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlaylistLibraryCard(
                          playlist: playlist,
                          onTap: () => context.push('/playlist/${playlist.id}'),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncStateView(
              title: 'Playlists unavailable',
              message: error.toString(),
              tone: ShayaStateTone.error,
            ),
          ),
          ShayaSectionHeader(
            title: switch (_tab) {
              _LibraryTab.songs => 'Songs',
              _LibraryTab.videos => 'Videos',
              _LibraryTab.lyrics => 'Lyrics',
            },
            subtitle: switch (_tab) {
              _LibraryTab.songs => 'Tracks with playable audio.',
              _LibraryTab.videos => 'Songs that already include video.',
              _LibraryTab.lyrics => 'Songs that contain saved lyric sections.',
            },
          ),
          const SizedBox(height: 12),
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
                return AsyncStateView(
                  title: 'Nothing in this view yet',
                  message:
                      'Generate your first ${switch (_tab) {
                        _LibraryTab.songs => 'track',
                        _LibraryTab.videos => 'video',
                        _LibraryTab.lyrics => 'lyric draft',
                      }} to fill this section.',
                );
              }

              return Column(
                children: filtered.map((song) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                          Icons.more_horiz_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncStateView(
              title: 'Library unavailable',
              message: error.toString(),
              tone: ShayaStateTone.error,
            ),
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
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Late Night Bongo Mix'),
          ),
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
                    ShayaSectionHeader(
                      title: 'Add "${song.title}"',
                      subtitle: 'Tap a playlist to add or remove this song.',
                    ),
                    const SizedBox(height: 16),
                    if (mutablePlaylists.isEmpty)
                      AsyncStateView(
                        title: 'Create your first playlist',
                        message:
                            'Start organizing songs, videos, and lyric drafts in curated collections.',
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
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ShayaSurfaceCard(
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _createPlaylist(
                                    initialSongIds: [song.id],
                                    openAfterCreate: false,
                                  );
                                },
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kPrimaryPurple.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create new playlist',
                                            style: ShayaTextStyles.songName,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Create one and add this song immediately.',
                                            style: ShayaTextStyles.metadata,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final playlist = mutablePlaylists[index - 1];
                            final containsSong = playlist.songIds.contains(
                              song.id,
                            );
                            final busy = busyIds.contains(playlist.id);
                            return ShayaSurfaceCard(
                              onTap: busy
                                  ? null
                                  : () => togglePlaylist(playlist),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: containsSong
                                          ? kPrimaryPurple.withValues(
                                              alpha: 0.18,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                    ),
                                    child: Icon(
                                      containsSong
                                          ? Icons.check_circle_rounded
                                          : Icons.queue_music_rounded,
                                      color: containsSong
                                          ? kPurpleLight
                                          : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          style: ShayaTextStyles.songName,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${playlist.songIds.length} tracks',
                                          style: ShayaTextStyles.metadata,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (busy)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Text(
                                      containsSong ? 'Added' : 'Add',
                                      style: ShayaTextStyles.metadata.copyWith(
                                        color: containsSong
                                            ? kPurpleLight
                                            : Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
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

class _PlaylistLibraryCard extends StatelessWidget {
  const _PlaylistLibraryCard({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShayaSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: kGradCard,
            ),
            child: const Icon(Icons.queue_music_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
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
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kPurpleLight),
        ],
      ),
    );
  }
}

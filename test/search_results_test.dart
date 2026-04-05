import 'package:flutter_test/flutter_test.dart';
import 'package:shaya_ai/features/search/search_results.dart';
import 'package:shaya_ai/shared/models/lyric_section.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';

void main() {
  final songs = [
    Song(
      id: 'song-afrobeat',
      userId: 'user-1',
      title: 'Sunset Anthem',
      prompt: 'Afrobeat celebration for a Dar es Salaam sunset',
      audioUrl: '',
      videoUrl: null,
      thumbnailUrl: '',
      genre: const ['Afrobeat'],
      mood: 'Happy',
      duration: 180,
      isPublic: false,
      contentKind: SongContentKind.song,
      lyricsTitle: null,
      lyricsLanguage: null,
      lyricsSections: const [],
      createdAt: DateTime.utc(2026, 4, 5),
    ),
    Song(
      id: 'song-lyrics',
      userId: 'user-1',
      title: 'Swahili Draft',
      prompt: 'Lyric sketch for a sunrise prayer',
      audioUrl: '',
      videoUrl: null,
      thumbnailUrl: '',
      genre: const ['Gospel'],
      mood: 'Calm',
      duration: 0,
      isPublic: false,
      contentKind: SongContentKind.lyrics,
      lyricsTitle: 'Asubuhi Prayer',
      lyricsLanguage: 'Swahili',
      lyricsSections: const [
        LyricSection(
          heading: 'Chorus',
          content: 'Asubuhi nuru ya Shaya inaamka mjini',
        ),
      ],
      createdAt: DateTime.utc(2026, 4, 5),
    ),
  ];

  final playlists = [
    Playlist(
      id: 'playlist-1',
      ownerId: 'user-1',
      name: 'Sunset Mix',
      isPublic: false,
      songIds: const ['song-afrobeat'],
      createdAt: DateTime.utc(2026, 4, 5),
    ),
  ];

  test('matches songs through genre and keeps related playlists', () {
    final results = buildSearchResults(
      query: 'Afrobeat',
      songs: songs,
      playlists: playlists,
    );

    expect(results.songs.map((song) => song.id), ['song-afrobeat']);
    expect(results.playlists.map((playlist) => playlist.id), ['playlist-1']);
  });

  test('matches lyric metadata and content text', () {
    final results = buildSearchResults(
      query: 'Swahili',
      songs: songs,
      playlists: playlists,
    );

    expect(results.songs.map((song) => song.id), ['song-lyrics']);
    expect(results.playlists, isEmpty);
  });

  test('matches playlist names even when songs do not match query', () {
    final results = buildSearchResults(
      query: 'Mix',
      songs: songs,
      playlists: playlists,
    );

    expect(results.playlists.map((playlist) => playlist.id), ['playlist-1']);
    expect(results.songs, isEmpty);
  });
}

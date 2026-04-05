import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';

class SearchResults {
  const SearchResults({
    required this.query,
    required this.songs,
    required this.playlists,
    required this.songIndex,
  });

  final String query;
  final List<Song> songs;
  final List<Playlist> playlists;
  final Map<String, Song> songIndex;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get isEmpty => songs.isEmpty && playlists.isEmpty;

  List<Song> songsForPlaylist(Playlist playlist) {
    return playlist.songIds
        .map((songId) => songIndex[songId])
        .whereType<Song>()
        .toList();
  }
}

SearchResults buildSearchResults({
  required String query,
  required List<Song> songs,
  required List<Playlist> playlists,
}) {
  final normalized = query.trim().toLowerCase();
  final songIndex = {for (final song in songs) song.id: song};

  final matchedSongs = normalized.isEmpty
      ? songs
      : songs.where((song) => _matchesSong(song, normalized)).toList();

  final matchedPlaylists = normalized.isEmpty
      ? playlists
      : playlists.where((playlist) {
          if (playlist.name.toLowerCase().contains(normalized)) {
            return true;
          }

          return playlist.songIds.any((songId) {
            final song = songIndex[songId];
            return song != null && _matchesSong(song, normalized);
          });
        }).toList();

  return SearchResults(
    query: query,
    songs: matchedSongs,
    playlists: matchedPlaylists,
    songIndex: songIndex,
  );
}

bool _matchesSong(Song song, String normalizedQuery) {
  final fields = <String>[
    song.title,
    song.prompt,
    song.mood ?? '',
    song.lyricsTitle ?? '',
    song.lyricsLanguage ?? '',
    song.contentKind.name,
    ...song.genre,
    ...song.lyricsSections.map((section) => section.heading),
    ...song.lyricsSections.map((section) => section.content),
  ];

  return fields.any((field) => field.toLowerCase().contains(normalizedQuery));
}

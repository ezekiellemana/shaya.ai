import 'dart:async';

import 'package:shaya_ai/core/app_exception.dart';
import 'package:shaya_ai/core/hive_cache.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/models/usage_quota.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeFunctionsClient {
  EdgeFunctionsClient(this._client);

  final SupabaseClient? _client;

  Future<Map<String, dynamic>> invokeJson(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final client = _client;
    if (client == null) {
      throw AppException.configuration(
        'Supabase is not configured. Add the required dart defines before testing server features.',
      );
    }

    try {
      final response = await client.functions.invoke(functionName, body: body);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw const AppException('Unexpected Edge Function response.');
    } on FunctionException catch (error) {
      throw AppException.fromStatus(
        error.status,
        details: error.details,
        fallbackMessage: error.reasonPhrase,
      );
    }
  }
}

class SongsRepository {
  SongsRepository({
    required SupabaseClient? client,
    required EncryptedHiveCache cache,
    required EdgeFunctionsClient edgeFunctionsClient,
  }) : _client = client,
       _cache = cache,
       _edgeFunctionsClient = edgeFunctionsClient;

  final SupabaseClient? _client;
  final EncryptedHiveCache _cache;
  final EdgeFunctionsClient _edgeFunctionsClient;

  Future<List<Song>> fetchHomeFeed() async {
    final client = _client;
    if (client == null) {
      return const [];
    }

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('songs')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(20),
    );
    return rows.map(Song.fromJson).toList();
  }

  Future<List<Song>> fetchLibrary() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return _cache.getCachedSongs();
    }

    try {
      final rows = List<Map<String, dynamic>>.from(
        await client
            .from('songs')
            .select()
            .eq('user_id', client.auth.currentUser!.id)
            .order('created_at', ascending: false),
      );
      final songs = rows.map(Song.fromJson).toList();
      await _cache.cacheSongs(songs);
      return songs;
    } catch (_) {
      return _cache.getCachedSongs();
    }
  }

  Future<Song?> fetchSongById(String id) async {
    final client = _client;
    if (client == null) {
      return null;
    }
    final row = await client.from('songs').select().eq('id', id).maybeSingle();
    if (row == null) {
      return null;
    }
    return Song.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Song>> searchLibrary(String query) async {
    final songs = await fetchLibrary();
    if (query.trim().isEmpty) {
      return songs;
    }

    final normalized = query.toLowerCase().trim();
    return songs.where((song) {
      return song.title.toLowerCase().contains(normalized) ||
          (song.mood ?? '').toLowerCase().contains(normalized) ||
          song.genre.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
  }

  Future<void> deleteSong(String songId) async {
    final client = _authenticatedClient;
    await client
        .from('songs')
        .delete()
        .eq('id', songId)
        .eq('user_id', client.auth.currentUser!.id);
  }

  Future<Song> generateMusic({
    required String prompt,
    required List<String> tags,
    String? lyricsBody,
  }) async {
    final response = await _edgeFunctionsClient.invokeJson(
      'generate-music',
      body: {
        'prompt': prompt,
        'tags': tags,
        if (lyricsBody != null && lyricsBody.isNotEmpty) 'lyrics': lyricsBody,
      },
    );
    final song = Song.fromJson(
      Map<String, dynamic>.from(response['song'] as Map<dynamic, dynamic>),
    );
    await _mergeSongIntoCache(song);
    return song;
  }

  Future<Song> generateVideo({
    required String songId,
    required String visualPrompt,
    required String quality,
  }) async {
    final response = await _edgeFunctionsClient.invokeJson(
      'generate-video',
      body: {
        'song_id': songId,
        'visual_prompt': visualPrompt,
        'quality': quality,
      },
    );
    final song = Song.fromJson(
      Map<String, dynamic>.from(response['song'] as Map<dynamic, dynamic>),
    );
    await _mergeSongIntoCache(song);
    return song;
  }

  Future<void> _mergeSongIntoCache(Song newSong) async {
    final existing = _cache.getCachedSongs();
    final merged = [
      newSong,
      ...existing.where((song) => song.id != newSong.id),
    ];
    await _cache.cacheSongs(merged);
  }

  SupabaseClient get _authenticatedClient {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AppException('Please sign in to continue.');
    }
    return client;
  }
}

class PlaylistsRepository {
  PlaylistsRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Playlist>> fetchPlaylists() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return const [];
    }

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('playlists')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false),
    );
    return rows.map(Playlist.fromJson).toList();
  }

  Future<Playlist> createPlaylist(
    String name, {
    List<String> songIds = const [],
  }) async {
    final client = _authenticatedClient;
    final row = Map<String, dynamic>.from(
      await client
          .from('playlists')
          .insert({
            'owner_id': client.auth.currentUser!.id,
            'name': name,
            'song_ids': songIds,
          })
          .select()
          .single(),
    );
    return Playlist.fromJson(row);
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    final client = _authenticatedClient;
    await client
        .from('playlists')
        .update({'name': name})
        .eq('id', playlistId)
        .eq('owner_id', client.auth.currentUser!.id);
  }

  Future<void> updateSongOrder(String playlistId, List<String> songIds) async {
    final client = _authenticatedClient;
    await client
        .from('playlists')
        .update({'song_ids': songIds})
        .eq('id', playlistId)
        .eq('owner_id', client.auth.currentUser!.id);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final client = _authenticatedClient;
    await client
        .from('playlists')
        .delete()
        .eq('id', playlistId)
        .eq('owner_id', client.auth.currentUser!.id);
  }

  SupabaseClient get _authenticatedClient {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AppException('Please sign in to continue.');
    }
    return client;
  }
}

class QuotaRepository {
  QuotaRepository(this._client);

  final SupabaseClient? _client;

  Future<UsageQuota?> fetchCurrentQuota() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return null;
    }

    final month = _currentMonth();
    final row = await client
        .from('usage_quotas')
        .select()
        .eq('user_id', user.id)
        .eq('month', month)
        .maybeSingle();

    if (row == null) {
      return UsageQuota(
        userId: user.id,
        month: month,
        songsGenerated: 0,
        videosGenerated: 0,
        lyricsGenerated: 0,
        lastRequestAt: null,
      );
    }
    return UsageQuota.fromJson(Map<String, dynamic>.from(row));
  }

  String _currentMonth() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}

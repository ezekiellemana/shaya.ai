import 'dart:convert';

import 'package:shaya_ai/core/app_exception.dart';
import 'package:shaya_ai/features/generate/generation_service.dart';
import 'package:shaya_ai/shared/models/profile_stats.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository({
    required SupabaseClient? client,
    required SongsRepository songsRepository,
    required PlaylistsRepository playlistsRepository,
    required QuotaRepository quotaRepository,
  }) : _client = client,
       _songsRepository = songsRepository,
       _playlistsRepository = playlistsRepository,
       _quotaRepository = quotaRepository;

  final SupabaseClient? _client;
  final SongsRepository _songsRepository;
  final PlaylistsRepository _playlistsRepository;
  final QuotaRepository _quotaRepository;

  Future<UserProfile?> fetchProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return null;
    }

    final row = await client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      return UserProfile(
        id: user.id,
        displayName:
            user.userMetadata?['display_name'] as String? ??
            user.email ??
            'Shaya user',
        photoUrl: user.userMetadata?['avatar_url'] as String?,
        subscriptionTier: SubscriptionTier.free,
        createdAt: DateTime.now(),
        preferredGenres: const [],
        preferredMood: null,
      );
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateDisplayName(String displayName) async {
    final client = _authenticatedClient;
    await client
        .from('users')
        .update({'display_name': displayName})
        .eq('id', client.auth.currentUser!.id);
  }

  Future<void> syncOnboardingPreferences({
    required List<String> genres,
    required String? mood,
  }) async {
    final client = _authenticatedClient;
    await client.from('users').upsert({
      'id': client.auth.currentUser!.id,
      'display_name':
          client.auth.currentUser!.userMetadata?['display_name'] ??
          client.auth.currentUser!.email,
      'preferred_genres': genres,
      'preferred_mood': mood,
    });
  }

  Future<ProfileStats> fetchProfileStats() async {
    final songs = await _songsRepository.fetchLibrary();
    final playlists = await _playlistsRepository.fetchPlaylists();
    return ProfileStats(
      songsGenerated: songs.where((song) => song.hasAudio).length,
      videosGenerated: songs.where((song) => song.hasVideo).length,
      lyricsGenerated: songs.where((song) => song.hasLyrics).length,
      playlistCount: playlists.length,
    );
  }

  Future<String> exportUserData() async {
    final profile = await fetchProfile();
    final songs = await _songsRepository.fetchLibrary();
    final playlists = await _playlistsRepository.fetchPlaylists();
    final quota = await _quotaRepository.fetchCurrentQuota();
    return const JsonEncoder.withIndent('  ').convert({
      'profile': profile?.toJson(),
      'songs': songs.map((song) => song.toJson()).toList(),
      'playlists': playlists.map((playlist) => playlist.toJson()).toList(),
      'quota': quota == null
          ? null
          : {
              'user_id': quota.userId,
              'month': quota.month,
              'songs_generated': quota.songsGenerated,
              'videos_generated': quota.videosGenerated,
              'lyrics_generated': quota.lyricsGenerated,
            },
    });
  }

  SupabaseClient get _authenticatedClient {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AppException('Please sign in to continue.');
    }
    return client;
  }
}

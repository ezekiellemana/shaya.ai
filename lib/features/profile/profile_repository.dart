import 'dart:convert';

import 'package:image_picker/image_picker.dart';
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
    required EdgeFunctionsClient edgeFunctionsClient,
  }) : _client = client,
       _songsRepository = songsRepository,
       _playlistsRepository = playlistsRepository,
       _quotaRepository = quotaRepository,
       _edgeFunctionsClient = edgeFunctionsClient;

  final SupabaseClient? _client;
  final SongsRepository _songsRepository;
  final PlaylistsRepository _playlistsRepository;
  final QuotaRepository _quotaRepository;
  final EdgeFunctionsClient _edgeFunctionsClient;
  static const _avatarBucket = 'avatars';
  static const _avatarObjectName = 'avatar';
  static const _avatarMaxBytes = 5 * 1024 * 1024;

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
      final externalPhotoUrl = _resolveExternalPhotoUrl(
        user.userMetadata?['avatar_url'] as String?,
      );
      return UserProfile(
        id: user.id,
        displayName:
            user.userMetadata?['display_name'] as String? ??
            user.email ??
            'Shaya user',
        photoUrl: externalPhotoUrl,
        subscriptionTier: SubscriptionTier.free,
        createdAt: DateTime.now(),
        preferredGenres: const [],
        preferredMood: null,
      );
    }

    final data = Map<String, dynamic>.from(row);
    final rawPhotoValue = data['photo_url'] as String?;
    final resolvedPhotoUrl = await _resolveProfilePhoto(rawPhotoValue);
    data['photo_url'] = resolvedPhotoUrl;
    return UserProfile.fromJson(data);
  }

  Future<void> updateDisplayName(String displayName) async {
    final client = _authenticatedClient;
    await client
        .from('users')
        .update({'display_name': displayName})
        .eq('id', client.auth.currentUser!.id);
  }

  Future<String?> uploadAvatar(XFile file) async {
    final client = _authenticatedClient;
    final contentType = _inferImageContentType(file.name);
    final bytes = await file.readAsBytes();
    if (bytes.length > _avatarMaxBytes) {
      throw const AppException('Choose an image smaller than 5 MB.');
    }

    final objectPath = '${client.auth.currentUser!.id}/$_avatarObjectName';
    await client.storage
        .from(_avatarBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: contentType,
          ),
        );

    await client
        .from('users')
        .update({'photo_url': objectPath})
        .eq('id', client.auth.currentUser!.id);

    return client.storage.from(_avatarBucket).createSignedUrl(objectPath, 3600);
  }

  Future<void> syncOnboardingPreferences({
    required List<String> genres,
    required String? mood,
  }) async {
    final client = _authenticatedClient;
    await client
        .from('users')
        .update({'preferred_genres': genres, 'preferred_mood': mood})
        .eq('id', client.auth.currentUser!.id);
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

  Future<void> deleteAccount({
    required String confirmationText,
    String? password,
  }) async {
    final payload = <String, dynamic>{'confirmation': confirmationText};
    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      payload['password'] = trimmedPassword;
    }

    await _edgeFunctionsClient.invokeJson('delete-account', body: payload);
  }

  SupabaseClient get _authenticatedClient {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AppException('Please sign in to continue.');
    }
    return client;
  }

  Future<String?> _resolveProfilePhoto(String? value) async {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final external = _resolveExternalPhotoUrl(trimmed);
    if (external != null) {
      return external;
    }

    try {
      return await _authenticatedClient.storage
          .from(_avatarBucket)
          .createSignedUrl(trimmed, 3600);
    } catch (_) {
      return null;
    }
  }

  String? _resolveExternalPhotoUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }

  String _inferImageContentType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    throw const AppException('Choose a JPG, PNG, or WEBP image.');
  }
}

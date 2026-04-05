import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_bootstrap.dart';
import 'package:shaya_ai/core/app_config.dart';
import 'package:shaya_ai/core/hive_cache.dart';
import 'package:shaya_ai/core/router.dart';
import 'package:shaya_ai/core/secure_storage.dart';
import 'package:shaya_ai/features/auth/auth_controller.dart';
import 'package:shaya_ai/features/auth/auth_repository.dart';
import 'package:shaya_ai/features/generate/generate_controller.dart';
import 'package:shaya_ai/features/generate/generation_service.dart';
import 'package:shaya_ai/features/lyrics/lyrics_controller.dart';
import 'package:shaya_ai/features/player/player_controller.dart';
import 'package:shaya_ai/features/profile/profile_repository.dart';
import 'package:shaya_ai/features/search/search_results.dart';
import 'package:shaya_ai/features/subscription/subscription_controller.dart';
import 'package:shaya_ai/shared/models/playlist.dart';
import 'package:shaya_ai/shared/models/profile_stats.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/models/usage_quota.dart';
import 'package:shaya_ai/shared/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw UnimplementedError('Bootstrap override required.'),
);

final appConfigProvider = Provider<AppConfig>(
  (ref) => ref.watch(appBootstrapProvider).config,
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => ref.watch(appBootstrapProvider).secureStore,
);

final hiveCacheProvider = Provider<EncryptedHiveCache>(
  (ref) => ref.watch(appBootstrapProvider).hiveCache,
);

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => ref.watch(appBootstrapProvider).client,
);

final edgeFunctionsClientProvider = Provider<EdgeFunctionsClient>(
  (ref) => EdgeFunctionsClient(ref.watch(supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    client: ref.watch(supabaseClientProvider),
    config: ref.watch(appConfigProvider),
  ),
);

final songsRepositoryProvider = Provider<SongsRepository>(
  (ref) => SongsRepository(
    client: ref.watch(supabaseClientProvider),
    cache: ref.watch(hiveCacheProvider),
    edgeFunctionsClient: ref.watch(edgeFunctionsClientProvider),
  ),
);

final playlistsRepositoryProvider = Provider<PlaylistsRepository>(
  (ref) => PlaylistsRepository(ref.watch(supabaseClientProvider)),
);

final quotaRepositoryProvider = Provider<QuotaRepository>(
  (ref) => QuotaRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    client: ref.watch(supabaseClientProvider),
    songsRepository: ref.watch(songsRepositoryProvider),
    playlistsRepository: ref.watch(playlistsRepositoryProvider),
    quotaRepository: ref.watch(quotaRepositoryProvider),
    edgeFunctionsClient: ref.watch(edgeFunctionsClientProvider),
  ),
);

final appSessionControllerProvider =
    ChangeNotifierProvider<AppSessionController>((ref) {
      final controller = AppSessionController(
        authRepository: ref.watch(authRepositoryProvider),
        profileRepository: ref.watch(profileRepositoryProvider),
        secureStore: ref.watch(secureStoreProvider),
        hiveCache: ref.watch(hiveCacheProvider),
      );
      unawaited(controller.initialize());
      ref.onDispose(controller.dispose);
      return controller;
    });

final playerControllerProvider = ChangeNotifierProvider<PlayerController>((
  ref,
) {
  final controller = PlayerController();
  ref.onDispose(controller.dispose);
  return controller;
});

final generateMusicControllerProvider =
    ChangeNotifierProvider<GenerateMusicController>(
      (ref) => GenerateMusicController(
        songsRepository: ref.watch(songsRepositoryProvider),
        quotaRepository: ref.watch(quotaRepositoryProvider),
        playerController: ref.watch(playerControllerProvider),
      ),
    );

final lyricsControllerProvider = ChangeNotifierProvider<LyricsController>(
  (ref) => LyricsController(
    edgeFunctionsClient: ref.watch(edgeFunctionsClientProvider),
    songsRepository: ref.watch(songsRepositoryProvider),
    playerController: ref.watch(playerControllerProvider),
  ),
);

final subscriptionControllerProvider =
    ChangeNotifierProvider<SubscriptionController>(
      (ref) => SubscriptionController(
        profileRepository: ref.watch(profileRepositoryProvider),
      ),
    );

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionController = ref.read(appSessionControllerProvider);
  return buildRouter(ref, sessionController);
});

final homeFeedProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(songsRepositoryProvider).fetchHomeFeed();
});

final librarySongsProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(songsRepositoryProvider).fetchLibrary();
});

final playlistsProvider = FutureProvider<List<Playlist>>((ref) {
  return ref.watch(playlistsRepositoryProvider).fetchPlaylists();
});

final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) async {
      final songs = await ref.watch(librarySongsProvider.future);
      final playlists = await ref.watch(playlistsProvider.future);
      return buildSearchResults(
        query: query,
        songs: songs,
        playlists: playlists,
      );
    });

final currentQuotaProvider = FutureProvider<UsageQuota?>((ref) {
  return ref.watch(quotaRepositoryProvider).fetchCurrentQuota();
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

final currentProfileStatsProvider = FutureProvider<ProfileStats>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfileStats();
});

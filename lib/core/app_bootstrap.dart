import 'package:flutter/foundation.dart';
import 'package:shaya_ai/core/app_config.dart';
import 'package:shaya_ai/core/hive_cache.dart';
import 'package:shaya_ai/core/secure_auth_storage.dart';
import 'package:shaya_ai/core/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBootstrap {
  AppBootstrap({
    required this.config,
    required this.secureStore,
    required this.hiveCache,
    required this.client,
  });

  final AppConfig config;
  final SecureStore secureStore;
  final EncryptedHiveCache hiveCache;
  final SupabaseClient? client;

  static Future<AppBootstrap> initialize() async {
    final config = AppConfig.fromEnvironment();
    final secureStore = SecureStore();
    final hiveCache = EncryptedHiveCache(secureStore);
    await hiveCache.initialize();

    SupabaseClient? client;
    if (config.isSupabaseConfigured) {
      final projectRef = Uri.parse(config.supabaseUrl).host.split('.').first;
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSessionLocalStorage(
            secureStore: secureStore,
            persistSessionKey: 'sb-$projectRef-auth-token',
          ),
          pkceAsyncStorage: SecureGotrueAsyncStorage(secureStore: secureStore),
        ),
        debug: kDebugMode,
      );
      client = Supabase.instance.client;
    }

    return AppBootstrap(
      config: config,
      secureStore: secureStore,
      hiveCache: hiveCache,
      client: client,
    );
  }
}

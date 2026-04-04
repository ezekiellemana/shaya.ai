import 'package:shaya_ai/core/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSessionLocalStorage extends LocalStorage {
  SecureSessionLocalStorage({
    required this.secureStore,
    required this.persistSessionKey,
  });

  final SecureStore secureStore;
  final String persistSessionKey;

  @override
  Future<String?> accessToken() => secureStore.read(persistSessionKey);

  @override
  Future<bool> hasAccessToken() async {
    final value = await secureStore.read(persistSessionKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    return secureStore.write(persistSessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return secureStore.delete(persistSessionKey);
  }
}

class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({required this.secureStore});

  final SecureStore secureStore;

  @override
  Future<String?> getItem({required String key}) => secureStore.read(key);

  @override
  Future<void> removeItem({required String key}) => secureStore.delete(key);

  @override
  Future<void> setItem({required String key, required String value}) {
    return secureStore.write(key, value);
  }
}

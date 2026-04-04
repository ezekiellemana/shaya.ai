import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  static const onboardingKey = 'shaya_onboarding_complete';
  static const preferredGenresKey = 'shaya_preferred_genres';
  static const preferredMoodKey = 'shaya_preferred_mood';
  static const hiveKey = 'shaya_hive_key';
  static const appLanguageKey = 'shaya_app_language';
  static const notificationsEnabledKey = 'shaya_notifications_enabled';

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> markOnboardingComplete() => write(onboardingKey, 'true');

  Future<bool> isOnboardingComplete() async {
    return (await read(onboardingKey)) == 'true';
  }

  Future<void> savePreferredGenres(List<String> genres) {
    return write(preferredGenresKey, jsonEncode(genres));
  }

  Future<List<String>> readPreferredGenres() async {
    final value = await read(preferredGenresKey);
    if (value == null || value.isEmpty) {
      return const [];
    }
    return List<String>.from(jsonDecode(value) as List<dynamic>);
  }

  Future<void> savePreferredMood(String mood) => write(preferredMoodKey, mood);

  Future<String?> readPreferredMood() => read(preferredMoodKey);

  Future<void> saveAppLanguage(String language) =>
      write(appLanguageKey, language);

  Future<String> readAppLanguage() async {
    return await read(appLanguageKey) ?? 'English';
  }

  Future<void> saveNotificationsEnabled(bool enabled) {
    return write(notificationsEnabledKey, enabled.toString());
  }

  Future<bool> readNotificationsEnabled() async {
    return (await read(notificationsEnabledKey)) != 'false';
  }

  Future<Uint8List> readOrCreateHiveKey(Uint8List Function() generator) async {
    final encoded = await read(hiveKey);
    if (encoded != null && encoded.isNotEmpty) {
      return Uint8List.fromList(base64Decode(encoded));
    }

    final freshKey = generator();
    await write(hiveKey, base64Encode(freshKey));
    return freshKey;
  }

  Future<void> clearSessionArtifacts() async {
    final all = await _storage.readAll();
    for (final entry in all.entries) {
      if (entry.key == onboardingKey ||
          entry.key == preferredGenresKey ||
          entry.key == preferredMoodKey ||
          entry.key == hiveKey) {
        continue;
      }
      await _storage.delete(key: entry.key);
    }
  }
}

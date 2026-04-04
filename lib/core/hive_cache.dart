import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shaya_ai/core/secure_storage.dart';
import 'package:shaya_ai/shared/models/song.dart';

class EncryptedHiveCache {
  EncryptedHiveCache(this._secureStore);

  final SecureStore _secureStore;
  late final Box<String> _songsBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    final key = await _secureStore.readOrCreateHiveKey(_generateKey);
    _songsBox = await Hive.openBox<String>(
      'shaya_song_cache',
      encryptionCipher: HiveAesCipher(key),
    );
  }

  Future<void> cacheSongs(List<Song> songs) async {
    final payload = songs.map((song) => jsonEncode(song.toJson())).toList();
    await _songsBox.put('library', jsonEncode(payload));
  }

  List<Song> getCachedSongs() {
    final raw = _songsBox.get('library');
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final payload = List<String>.from(jsonDecode(raw) as List<dynamic>);
    return payload
        .map(
          (entry) => Song.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> clearLibraryCache() => _songsBox.clear();

  Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }
}

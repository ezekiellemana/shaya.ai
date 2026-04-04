import 'package:flutter/foundation.dart';
import 'package:shaya_ai/features/generate/generation_service.dart';
import 'package:shaya_ai/features/player/player_controller.dart';
import 'package:shaya_ai/shared/models/lyric_section.dart';
import 'package:shaya_ai/shared/models/song.dart';

class LyricsController extends ChangeNotifier {
  LyricsController({
    required EdgeFunctionsClient edgeFunctionsClient,
    required SongsRepository songsRepository,
    required PlayerController playerController,
  }) : _edgeFunctionsClient = edgeFunctionsClient,
       _songsRepository = songsRepository,
       _playerController = playerController;

  final EdgeFunctionsClient _edgeFunctionsClient;
  final SongsRepository _songsRepository;
  final PlayerController _playerController;

  bool _isBusy = false;
  String? _errorMessage;
  String _title = '';
  String _language = 'English';
  List<LyricSection> _sections = const [];

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String get title => _title;
  String get language => _language;
  List<LyricSection> get sections => _sections;

  void updateSection(int index, String content) {
    if (index < 0 || index >= _sections.length) {
      return;
    }
    _sections = [
      for (var i = 0; i < _sections.length; i++)
        if (i == index)
          _sections[i].copyWith(content: content)
        else
          _sections[i],
    ];
    notifyListeners();
  }

  Future<void> generateLyrics({
    required String topic,
    required String mood,
    required String language,
  }) async {
    await _runBusy(() async {
      final response = await _edgeFunctionsClient.invokeJson(
        'generate-lyrics',
        body: {
          'mode': 'generate',
          'topic': topic,
          'mood': mood,
          'language': language,
        },
      );
      _hydrateFromResponse(response);
    });
  }

  Future<void> improveSection(int index) async {
    if (index < 0 || index >= _sections.length) {
      return;
    }
    await _runBusy(() async {
      final response = await _edgeFunctionsClient.invokeJson(
        'generate-lyrics',
        body: {
          'mode': 'improve_section',
          'title': _title,
          'language': _language,
          'sections': _sections.map((section) => section.toJson()).toList(),
          'target_index': index,
        },
      );
      _hydrateFromResponse(response);
    });
  }

  Future<void> translateLyrics() async {
    await _runBusy(() async {
      final response = await _edgeFunctionsClient.invokeJson(
        'generate-lyrics',
        body: {
          'mode': 'translate',
          'title': _title,
          'language': _language,
          'sections': _sections.map((section) => section.toJson()).toList(),
        },
      );
      _hydrateFromResponse(response);
    });
  }

  Future<Song> generateMusicFromLyrics() async {
    late final Song song;
    await _runBusy(() async {
      song = await _songsRepository.generateMusic(
        prompt: _title.isEmpty ? 'Generated from Shaya AI lyrics' : _title,
        tags: const [],
        lyricsBody: serializeLyrics(),
      );
      await _playerController.loadSong(song);
    });
    return song;
  }

  String serializeLyrics() {
    return [
      if (_title.isNotEmpty) _title,
      ..._sections.map((section) => '${section.heading}\n${section.content}'),
    ].join('\n\n');
  }

  void _hydrateFromResponse(Map<String, dynamic> response) {
    _title = response['title'] as String? ?? _title;
    _language = response['language'] as String? ?? _language;
    _sections = (response['sections'] as List<dynamic>? ?? const [])
        .map(
          (section) => LyricSection.fromJson(section as Map<String, dynamic>),
        )
        .toList();
    notifyListeners();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

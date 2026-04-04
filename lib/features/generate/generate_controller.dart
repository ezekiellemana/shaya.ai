import 'package:flutter/foundation.dart';
import 'package:shaya_ai/features/generate/generation_service.dart';
import 'package:shaya_ai/features/player/player_controller.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/models/usage_quota.dart';

class GenerateMusicController extends ChangeNotifier {
  GenerateMusicController({
    required SongsRepository songsRepository,
    required QuotaRepository quotaRepository,
    required PlayerController playerController,
  }) : _songsRepository = songsRepository,
       _quotaRepository = quotaRepository,
       _playerController = playerController;

  final SongsRepository _songsRepository;
  final QuotaRepository _quotaRepository;
  final PlayerController _playerController;

  final Set<String> _selectedTags = <String>{};
  bool _isBusy = false;
  String? _errorMessage;
  Song? _lastGeneratedSong;
  UsageQuota? _quota;

  Set<String> get selectedTags => _selectedTags;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  Song? get lastGeneratedSong => _lastGeneratedSong;
  UsageQuota? get quota => _quota;

  Future<void> refreshQuota() async {
    _quota = await _quotaRepository.fetchCurrentQuota();
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  Future<Song> submit({
    required String prompt,
    List<String> extraTags = const [],
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final song = await _songsRepository.generateMusic(
        prompt: prompt,
        tags: [
          ..._selectedTags,
          ...extraTags.where((tag) => tag.trim().isNotEmpty),
        ],
      );
      _lastGeneratedSong = song;
      await _playerController.loadSong(song);
      _quota = await _quotaRepository.fetchCurrentQuota();
      return song;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

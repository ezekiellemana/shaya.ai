import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shaya_ai/core/app_exception.dart';
import 'package:shaya_ai/shared/models/song.dart';

class PlayerController extends ChangeNotifier {
  PlayerController() {
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _audioPlayer.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _audioPlayer.durationStream.listen((duration) {
        _duration = duration;
        notifyListeners();
      }),
    );
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<Song> _queue = const [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  Song? get currentSong =>
      _queue.isEmpty ? null : _queue[_currentIndex.clamp(0, _queue.length - 1)];

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  double get progressRatio {
    final total = _duration?.inMilliseconds ?? 0;
    if (total == 0) {
      return 0;
    }
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Future<void> loadSong(Song song, {List<Song>? queue}) async {
    final effectiveQueue = queue ?? [song];
    final index = effectiveQueue.indexWhere((entry) => entry.id == song.id);
    _queue = effectiveQueue;
    _currentIndex = index == -1 ? 0 : index;
    final current = currentSong;
    if (current == null || current.audioUrl.isEmpty) {
      throw const AppException('This item does not have playable audio yet.');
    }
    await _audioPlayer.setUrl(current.audioUrl);
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> togglePlayback() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else if (currentSong != null) {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> skipNext() async {
    if (_currentIndex + 1 >= _queue.length) {
      return;
    }
    await loadSong(_queue[_currentIndex + 1], queue: _queue);
  }

  Future<void> skipPrevious() async {
    if (_currentIndex == 0) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    await loadSong(_queue[_currentIndex - 1], queue: _queue);
  }

  Future<void> toggleShuffle() async {
    await _audioPlayer.setShuffleModeEnabled(!_audioPlayer.shuffleModeEnabled);
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (_audioPlayer.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _audioPlayer.setLoopMode(nextMode);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }
}

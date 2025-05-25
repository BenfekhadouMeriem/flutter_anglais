import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  AudioPlayer get audioPlayer => _audioPlayer;

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
    }
    notifyListeners();
  }

  void stopAudio() {
    _isPlaying = false;
    _audioPlayer.stop();
    notifyListeners();
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Helper class untuk memutar nada dering panggilan masuk (Incoming Call Ringtone)
class RingtonePlayer {
  static final RingtonePlayer _instance = RingtonePlayer._internal();
  factory RingtonePlayer() => _instance;
  RingtonePlayer._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Memutar nada dering secara berulang (looping)
  Future<void> playRingtone({String assetPath = 'sounds/phone_ringing.mp3'}) async {
    try {
      if (_isPlaying) return;
      _isPlaying = true;
      final player = _audioPlayer;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('⚠️ Gagal memutar nada dering: $e');
      _isPlaying = false;
    }
  }

  /// Menghentikan nada dering
  Future<void> stop() async {
    try {
      _isPlaying = false;
      await _player?.stop();
    } catch (e) {
      debugPrint('⚠️ Gagal menghentikan nada dering: $e');
    }
  }

  /// Membersihkan resource audio
  void dispose() {
    _isPlaying = false;
    _player?.dispose();
    _player = null;
  }
}

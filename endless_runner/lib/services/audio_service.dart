import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import '../core/game_data.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _initialized = false;
  bool get isMusicEnabled => GameData().musicEnabled;
  bool get isSfxEnabled => GameData().sfxEnabled;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Set low latency for Android
      await AudioPlayer.global.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ));

      await FlameAudio.audioCache.loadAll([
        'jump.wav',
        'collect.wav',
        'crash.wav',
        'powerup.wav',
        'bgm.mp3',
      ]);
      _initialized = true;
    } catch (e) {
      debugPrint('Audio initialization failed (likely missing assets): $e');
    }
  }

  void playBgm() {
    if (!isMusicEnabled) return;
    try {
      // Ensure any existing BGM is stopped before starting
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play('bgm.mp3', volume: 0.4);
    } catch (e) {
      debugPrint('Error playing BGM: $e');
    }
  }

  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  void playSfx(String name, {double volume = 1.0}) {
    if (!isSfxEnabled) return;
    try {
      FlameAudio.play(name, volume: volume);
    } catch (e) {
      // Silently fail or log in debug mode to prevent game crash
      debugPrint('SFX "$name" not found or failed to play.');
    }
  }

  void updateBgmPitch(double worldSpeed) {
    // Disabled dynamic pitch to prevent audio lag and phasing issues
    return;
  }

  void toggleMusic() {
    GameData().musicEnabled = !GameData().musicEnabled;
    GameData().save();
    if (!GameData().musicEnabled) {
      stopBgm();
    } else {
      playBgm();
    }
  }

  void toggleSfx() {
    GameData().sfxEnabled = !GameData().sfxEnabled;
    GameData().save();
  }
}

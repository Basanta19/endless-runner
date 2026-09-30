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
    await _createPools();
  }

  /// Frequent sounds reuse a small set of players. FlameAudio.play() spins up
  /// a brand-new player on every call, which causes hitches on Android when
  /// coins are collected in quick succession.
  ///
  /// Every player is created and loaded up front (nothing is created during
  /// play) and uses PlayerMode.lowLatency — Android's SoundPool, which is made
  /// for short game sounds. Players are reused round-robin.
  static const Map<String, int> _pooledSfx = {
    'collect.wav': 4,
    'jump.wav': 2,
    'powerup.wav': 2,
    'crash.wav': 1,
  };
  final Map<String, _SfxChannel> _channels = {};

  Future<void> _createPools() async {
    for (final entry in _pooledSfx.entries) {
      if (_channels.containsKey(entry.key)) continue;
      try {
        final players = <AudioPlayer>[];
        for (int i = 0; i < entry.value; i++) {
          final p = AudioPlayer()..audioCache = FlameAudio.audioCache;
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource(entry.key));
          players.add(p);
        }
        _channels[entry.key] = _SfxChannel(players);
      } catch (e) {
        debugPrint('Audio pool for "${entry.key}" failed: $e');
      }
    }
  }

  void playBgm() {
    if (!isMusicEnabled) return;
    void log(Object e) => debugPrint('Error playing BGM: $e');
    try {
      // Ensure any existing BGM is stopped before starting. Both calls are
      // async, so failures arrive on the futures, not as a throw here.
      FlameAudio.bgm.stop().catchError(log);
      FlameAudio.bgm.play('bgm.mp3', volume: 0.4).catchError(log);
    } catch (e) {
      log(e);
    }
  }

  void stopBgm() {
    void log(Object e) => debugPrint('Error stopping BGM: $e');
    try {
      FlameAudio.bgm.stop().catchError(log);
    } catch (e) {
      log(e);
    }
  }

  void playSfx(String name, {double volume = 1.0}) {
    if (!isSfxEnabled) return;
    final channel = _channels[name];
    if (channel != null) {
      channel.play(volume);
      return;
    }
    // Fallback if pools aren't ready (e.g. init failed)
    FlameAudio.play(name, volume: volume).then<void>((_) {}).catchError(
          // Log only, never crash the game over a sound
          (Object e) => debugPrint('SFX "$name" failed to play: $e'),
        );
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

/// A few preloaded players for one sound, used in turn so overlapping
/// plays (e.g. a row of coins) don't cut each other off.
class _SfxChannel {
  final List<AudioPlayer> _players;
  final List<double> _volumes;
  int _next = 0;

  _SfxChannel(this._players) : _volumes = List.filled(_players.length, -1);

  void play(double volume) {
    final i = _next;
    _next = (_next + 1) % _players.length;
    final p = _players[i];
    // Method calls are delivered in order, so no awaiting needed here.
    // Nothing is awaited on the game loop; errors are only logged.
    void log(Object e) => debugPrint('SFX play failed: $e');
    if (_volumes[i] != volume) {
      _volumes[i] = volume;
      p.setVolume(volume).catchError(log);
    }
    p.stop().catchError(log); // restart if this player is still sounding
    p.resume().catchError(log);
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  double _volume = 0.7;

  // Sound effect paths
  static const String _tapSound = 'assets/sounds/tap.mp3';
  static const String _successSound = 'assets/sounds/success.mp3';
  static const String _errorSound = 'assets/sounds/error.mp3';
  static const String _notificationSound = 'assets/sounds/notification.mp3';
  static const String _radarPingSound = 'assets/sounds/radar_ping.mp3';
  static const String _userFoundSound = 'assets/sounds/user_found.mp3';
  static const String _messageSound = 'assets/sounds/message.mp3';
  static const String _buttonClickSound = 'assets/sounds/button_click.mp3';
  static const String _swipeSound = 'assets/sounds/swipe.mp3';
  static const String _confettiSound = 'assets/sounds/confetti.mp3';

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _volume = prefs.getDouble('sound_volume') ?? 0.7;
      
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing sound service: $e');
      }
    }
  }

  Future<void> _playSound(String soundPath) async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Silently handle sound errors to avoid crashes
      if (kDebugMode) {
        print('Error playing sound $soundPath: $e');
      }
    }
  }

  // Public methods for different sound effects
  Future<void> playTapSound() => _playSound(_tapSound);
  Future<void> playSuccessSound() => _playSound(_successSound);
  Future<void> playErrorSound() => _playSound(_errorSound);
  Future<void> playNotificationSound() => _playSound(_notificationSound);
  Future<void> playRadarPingSound() => _playSound(_radarPingSound);
  Future<void> playUserFoundSound() => _playSound(_userFoundSound);
  Future<void> playMessageSound() => _playSound(_messageSound);
  Future<void> playButtonClickSound() => _playSound(_buttonClickSound);
  Future<void> playSwipeSound() => _playSound(_swipeSound);
  Future<void> playConfettiSound() => _playSound(_confettiSound);
  Future<void> playToggleEffect() => _playSound(_tapSound);

  // Volume control
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sound_volume', _volume);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting volume: $e');
      }
    }
  }

  double get volume => _volume;

  // Sound toggle
  Future<void> toggleSound() async {
    try {
      _isSoundEnabled = !_isSoundEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', _isSoundEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling sound: $e');
      }
    }
  }

  bool get isSoundEnabled => _isSoundEnabled;

  // Dispose
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing sound service: $e');
      }
    }
  }
}

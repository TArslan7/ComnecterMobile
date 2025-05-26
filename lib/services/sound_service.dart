
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playRadarPing() async {
    await _player.play(AssetSource('audio/radar_ping.mp3'));
  }

  static Future<void> playMatch() async {
    await _player.play(AssetSource('audio/match_sound.mp3'));
  }

  static Future<void> playMessageReceived() async {
    await _player.play(AssetSource('audio/message_received.mp3'));
  }
}

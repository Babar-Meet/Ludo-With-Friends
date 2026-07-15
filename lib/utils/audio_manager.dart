import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  // Pool of players for rapid token movement to prevent MediaPlayer dropouts
  static final List<AudioPlayer> _movePlayers = List.generate(8, (_) => AudioPlayer());
  static int _moveIndex = 0;
  
  static final AudioPlayer _dicePlayer = AudioPlayer();
  static final AudioPlayer _eventPlayer = AudioPlayer();

  static Future<void> playMove({String? filename}) async {
    try {
      final player = _movePlayers[_moveIndex];
      _moveIndex = (_moveIndex + 1) % _movePlayers.length;
      await player.play(AssetSource('audio/${filename ?? "move_default.wav"}'), volume: 0.2);
    } catch (e) {
      // Ignore if audio fails to load
    }
  }

  static Future<void> playDice({String? filename}) async {
    try {
      await _dicePlayer.stop();
      await _dicePlayer.play(AssetSource('audio/${filename ?? "dice_glass.wav"}'), volume: 0.5);
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playCapture({String? filename}) async {
    try {
      await _eventPlayer.stop();
      await _eventPlayer.play(AssetSource('audio/${filename ?? "capture_zap.wav"}'), volume: 0.6);
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playWin({String? filename}) async {
    try {
      await _eventPlayer.stop();
      await _eventPlayer.play(AssetSource('audio/${filename ?? "win_retro.wav"}'), volume: 0.6);
    } catch (e) {
      // Ignore
    }
  }
}

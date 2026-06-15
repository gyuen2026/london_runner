import 'package:flutter_tts/flutter_tts.dart';

class VoiceCoach {
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.48);
  }

  Future<void> speak(String message) async {
    if (message.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(message);
  }
}

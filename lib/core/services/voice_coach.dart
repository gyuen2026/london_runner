import 'package:flutter_tts/flutter_tts.dart';

import 'voice_settings.dart';

class VoiceCoach {
  final FlutterTts _tts = FlutterTts();
  final VoiceSettings settings = VoiceSettings();

  String? _lastMessage;
  DateTime? _lastSpokenAt;

  Future<void> init() async {
    await settings.load();
    await _applyVoice();
  }

  Future<void> _applyVoice() async {
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);

    if (settings.mode == VoiceMode.off) return;

    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final langPrefix = settings.language.split('-').first.toLowerCase();
      final matches = voices.whereType<Map>().where((v) {
        final locale = (v['locale']?.toString() ?? '').toLowerCase();
        return locale.startsWith(langPrefix);
      }).toList();
      if (matches.isEmpty) return;

      Map? pick;
      if (settings.mode == VoiceMode.female) {
        pick = matches.cast<Map?>().firstWhere(
              (v) {
                final name = (v?['name']?.toString() ?? '').toLowerCase();
                return name.contains('female') ||
                    name.contains('samantha') ||
                    name.contains('karen') ||
                    name.contains('moira');
              },
              orElse: () => matches.first,
            );
      } else {
        pick = matches.cast<Map?>().firstWhere(
              (v) {
                final name = (v?['name']?.toString() ?? '').toLowerCase();
                return name.contains('male') ||
                    name.contains('daniel') ||
                    name.contains('tom');
              },
              orElse: () => matches.first,
            );
      }
      if (pick != null) {
        await _tts.setVoice({'name': pick['name'], 'locale': pick['locale']});
      }
    } catch (_) {}
  }

  Future<void> setMode(VoiceMode mode) async {
    await settings.setMode(mode);
    await _applyVoice();
  }

  /// Speaks only when enabled and message changed (avoids 18s repeat loop).
  Future<void> speak(String message, {bool force = false}) async {
    final text = message.trim();
    if (text.isEmpty || !settings.enabled) return;

    final now = DateTime.now();
    if (!force &&
        text == _lastMessage &&
        _lastSpokenAt != null &&
        now.difference(_lastSpokenAt!) < const Duration(seconds: 90)) {
      return;
    }

    _lastMessage = text;
    _lastSpokenAt = now;
    await _tts.stop();
    await _tts.speak(text);
  }
}

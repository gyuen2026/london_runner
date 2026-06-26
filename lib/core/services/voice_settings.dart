import 'package:shared_preferences/shared_preferences.dart';

enum VoiceMode { off, female, male }

/// Persisted voice coach preferences.
class VoiceSettings {
  static const _keyMode = 'voice_mode';
  static const _keyLang = 'voice_lang';

  VoiceMode _mode = VoiceMode.female;
  String _language = 'en-GB';

  VoiceMode get mode => _mode;
  String get language => _language;
  bool get enabled => _mode != VoiceMode.off;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyMode);
    _mode = VoiceMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => VoiceMode.female,
    );
    _language = p.getString(_keyLang) ?? 'en-GB';
  }

  Future<void> setMode(VoiceMode mode) async {
    _mode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyMode, mode.name);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyLang, lang);
  }
}

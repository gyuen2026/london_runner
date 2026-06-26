import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Apple Watch–style UI sounds (tap, workout start, success).
class UiSound {
  UiSound._();
  static final UiSound instance = UiSound._();

  Future<void> init() async {}

  Future<void> tap() => _play(SystemSoundType.click);

  Future<void> workoutStart() => _play(SystemSoundType.click);

  Future<void> success() => _play(SystemSoundType.alert);

  Future<void> _play(SystemSoundType type) async {
    if (kIsWeb) return;
    try {
      await SystemSound.play(type);
    } catch (_) {}
  }
}

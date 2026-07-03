/// Formats live pedestrian-signal countdown copy for AR / voice.
String formatSignalCountdown({required String labelKo, required int seconds}) {
  return '$labelKo $seconds초';
}

String countdownLabelFromColor(String color) {
  final c = color.toUpperCase();
  if (c.contains('RED')) return '초록 불까지';
  return '빨간 불까지';
}

String countdownLabelFromPhase(String phase) {
  final p = phase.toLowerCase();
  if (p == 'red') return '초록 불까지';
  return '빨간 불까지';
}

String phaseLabelKo(String color) {
  final c = color.toUpperCase();
  if (c.contains('RED')) return '빨간불';
  if (c.contains('AMBER') || c.contains('YELLOW')) return '주황불';
  return '초록불';
}

String phaseLabelFromLivePhase(String phase) {
  final p = phase.toLowerCase();
  if (p == 'red') return '빨간불';
  if (p == 'amber') return '주황불';
  return '초록불';
}

/// Remaining whole seconds until [phaseEndsAt]; 0 when elapsed or null.
int countdownSecondsUntil(DateTime? phaseEndsAt) {
  if (phaseEndsAt == null) return 0;
  final rem = phaseEndsAt.difference(DateTime.now()).inSeconds;
  return rem.clamp(0, 99);
}

DateTime? parsePhaseEndsAt(Object? raw) {
  if (raw == null) return null;
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

/// Flip to the next pedestrian phase when local countdown reaches zero.
({String phase, String label}) nextSignalPhaseAfterZero(String currentPhase) {
  final p = currentPhase.toLowerCase();
  if (p == 'green' || p == 'amber') {
    return (phase: 'red', label: '초록 불까지');
  }
  return (phase: 'green', label: '빨간 불까지');
}

import 'package:health/health.dart';

/// Reads heart rate from HealthKit (iOS) / Health Connect (Android).
class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    await _health.configure();
    const types = [HealthDataType.HEART_RATE];
    const access = [HealthDataAccess.READ];
    return _health.requestAuthorization(types, permissions: access);
  }

  /// Latest heart rate (bpm) in last 2 minutes, or 0 if unavailable.
  Future<int> latestHeartRate() async {
    try {
      final ok = await requestPermissions();
      if (!ok) return 0;

      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(minutes: 2)),
        endTime: now,
      );
      if (data.isEmpty) return 0;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final val = data.first.value;
      if (val is NumericHealthValue) {
        return val.numericValue.round();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

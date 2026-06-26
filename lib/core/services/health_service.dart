import 'package:health/health.dart';

/// Reads heart rate and running history from HealthKit (iOS) / Health Connect (Android).
class HealthService {
  final Health _health = Health();

  static const _runTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.HEART_RATE,
  ];

  Future<bool> requestPermissions() async {
    await _health.configure();
    const access = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];
    return _health.requestAuthorization(_runTypes, permissions: access);
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

  /// Average running pace (min/km) from recent workouts, or null if unavailable.
  Future<double?> averageRunPaceMinPerKm({int lookbackDays = 60}) async {
    try {
      final ok = await requestPermissions();
      if (!ok) return null;

      final now = DateTime.now();
      final start = now.subtract(Duration(days: lookbackDays));
      final workouts = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );
      if (workouts.isEmpty) return null;

      final paces = <double>[];
      for (final w in workouts) {
        final val = w.value;
        if (val is! WorkoutHealthValue) continue;

        final type = val.workoutActivityType;
        final isRun = type == HealthWorkoutActivityType.RUNNING ||
            type == HealthWorkoutActivityType.WALKING ||
            type == HealthWorkoutActivityType.HIKING;
        if (!isRun) continue;

        final durationMin = w.dateTo.difference(w.dateFrom).inSeconds / 60.0;
        if (durationMin < 3) continue;

        var km = val.totalDistance?.toDouble();
        if (km != null && km > 1000) km = km / 1000; // metres → km
        if (km == null || km < 0.3) continue;
        paces.add(durationMin / km);
      }

      if (paces.isEmpty) return null;
      paces.sort();
      return paces[paces.length ~/ 2]; // median pace
    } catch (_) {
      return null;
    }
  }
}

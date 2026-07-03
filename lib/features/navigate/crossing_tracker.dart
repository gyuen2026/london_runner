import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/utils/geo.dart';
import 'package:london_runner/features/commute/models/crosswalk_point.dart';

class CrossingTracker {
  CrossingTracker(this.crossings);

  final List<CrosswalkPoint> crossings;

  CrosswalkPoint? nextCrossing(LatLng user) {
    CrosswalkPoint? best;
    var bestM = double.infinity;
    for (final c in crossings) {
      final m = _distM(user, c);
      if (m < bestM) {
        bestM = m;
        best = c;
      }
    }
    if (best == null) return null;
    // If closest is behind us (already passed), pick next along route order
    final passed = countPassed(user);
    for (final c in crossings) {
      if (c.index > passed) return c;
    }
    return best;
  }

  List<CrosswalkPoint> upcoming(LatLng user, {int limit = 4}) {
    final passed = countPassed(user);
    return crossings.where((c) => c.index > passed).take(limit).toList();
  }

  double distanceToCrossingM(LatLng user, CrosswalkPoint c) => _distM(user, c);

  int countPassed(LatLng user) {
    var passed = 0;
    for (final c in crossings) {
      if (_distM(user, c) <= 40) passed = c.index;
    }
    return passed;
  }

  double _distM(LatLng user, CrosswalkPoint c) =>
      distanceKm(user.latitude, user.longitude, c.lat, c.lon) * 1000;
}

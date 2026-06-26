import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/utils/geo.dart';
class RouteTurn {
  const RouteTurn({
    required this.pointIndex,
    required this.location,
    required this.instruction,
    required this.distanceFromStartM,
    required this.bearingAfter,
  });

  final int pointIndex;
  final LatLng location;
  final String instruction;
  final double distanceFromStartM;
  final double bearingAfter;
}

class RouteProgress {
  const RouteProgress({
    required this.segmentIndex,
    required this.locationOnRoute,
    required this.distanceRemainingM,
    required this.distanceToNextTurnM,
    required this.nextTurn,
    required this.bearingDeg,
    required this.offRouteM,
  });

  final int segmentIndex;
  final LatLng locationOnRoute;
  final double distanceRemainingM;
  final double distanceToNextTurnM;
  final RouteTurn? nextTurn;
  final double bearingDeg;
  final double offRouteM;

  String get primaryInstruction {
    if (distanceRemainingM < 35) return 'You have arrived';
    final turn = nextTurn;
    if (turn == null) return 'Continue on route';
    if (distanceToNextTurnM > 250) return 'Continue straight';
    if (distanceToNextTurnM > 80) {
      return 'In ${distanceToNextTurnM.round()} m · ${turn.instruction}';
    }
    return turn.instruction;
  }

  String get secondaryInstruction {
    if (distanceRemainingM < 35) return 'Finish strong';
    final turn = nextTurn;
    if (turn == null) {
      return '${(distanceRemainingM / 1000).toStringAsFixed(1)} km to destination';
    }
    if (distanceToNextTurnM <= 80) {
      return 'Then ${(distanceRemainingM / 1000).toStringAsFixed(1)} km to destination';
    }
    return '${(distanceRemainingM / 1000).toStringAsFixed(1)} km · turn in ${(distanceToNextTurnM / 1000).toStringAsFixed(1)} km';
  }
}

class RouteNavigator {
  RouteNavigator(List<LatLng> points, {this.offRouteThresholdM = 45})
      : _points = points.length >= 2 ? points : [const LatLng(51.5074, -0.1278), const LatLng(51.5074, -0.1278)] {
    _cumDistM = _buildCumulativeDistances();
    _turns = _computeTurns();
  }

  final List<LatLng> _points;
  final double offRouteThresholdM;
  late final List<double> _cumDistM;
  late final List<RouteTurn> _turns;

  List<LatLng> get points => _points;
  double get totalDistanceM => _cumDistM.isEmpty ? 0 : _cumDistM.last;
  List<RouteTurn> get turns => _turns;

  RouteProgress progress(LatLng user) {
    final snap = _snapToRoute(user);
    final remaining = math.max(0.0, totalDistanceM - snap.distanceAlongM);
    final next = _turns.cast<RouteTurn?>().firstWhere(
          (t) => t!.distanceFromStartM > snap.distanceAlongM + 15,
          orElse: () => null,
        );
    final distToTurn = next == null
        ? remaining
        : math.max(0.0, next.distanceFromStartM - snap.distanceAlongM);

    return RouteProgress(
      segmentIndex: snap.segmentIndex,
      locationOnRoute: snap.pointOnRoute,
      distanceRemainingM: remaining,
      distanceToNextTurnM: distToTurn,
      nextTurn: next,
      bearingDeg: snap.bearingDeg,
      offRouteM: snap.offRouteM,
    );
  }

  List<LatLng> completedPortion(int throughIndex) {
    if (_points.length < 2) return [];
    final end = (throughIndex + 1).clamp(1, _points.length);
    return _points.sublist(0, end);
  }

  List<LatLng> upcomingPortion(int fromIndex) {
    if (_points.length < 2) return _points;
    final start = fromIndex.clamp(0, _points.length - 1);
    return _points.sublist(start);
  }

  List<double> _buildCumulativeDistances() {
    final cum = <double>[0];
    for (var i = 1; i < _points.length; i++) {
      cum.add(cum.last + _segM(_points[i - 1], _points[i]));
    }
    return cum;
  }

  List<RouteTurn> _computeTurns() {
    if (_points.length < 3) return [];
    final turns = <RouteTurn>[];
    double? prevBearing;
    for (var i = 1; i < _points.length; i++) {
      final segM = _segM(_points[i - 1], _points[i]);
      if (segM < 18) continue;
      final bearing = _bearing(_points[i - 1], _points[i]);
      if (prevBearing != null) {
        var delta = bearing - prevBearing;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        if (delta.abs() >= 28) {
          turns.add(RouteTurn(
            pointIndex: i,
            location: _points[i],
            instruction: _turnLabel(delta),
            distanceFromStartM: _cumDistM[i],
            bearingAfter: bearing,
          ));
        }
      }
      prevBearing = bearing;
    }
    return turns;
  }

  _Snap _snapToRoute(LatLng user) {
    var bestDist = double.infinity;
    var bestSeg = 0;
    var bestT = 0.0;
    var bestPoint = _points.first;
    var bestBearing = 0.0;

    for (var i = 0; i < _points.length - 1; i++) {
      final a = _points[i];
      final b = _points[i + 1];
      final snap = _projectOnSegment(user, a, b);
      if (snap.distanceM < bestDist) {
        bestDist = snap.distanceM;
        bestSeg = i;
        bestT = snap.t;
        bestPoint = snap.point;
        bestBearing = _bearing(a, b);
      }
    }

    final along = _cumDistM[bestSeg] + bestT * _segM(_points[bestSeg], _points[bestSeg + 1]);
    return _Snap(
      segmentIndex: bestSeg,
      pointOnRoute: bestPoint,
      distanceAlongM: along,
      offRouteM: bestDist,
      bearingDeg: bestBearing,
    );
  }

  _Projected _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;
    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
    final clamped = t.clamp(0.0, 1.0);
    final point = LatLng(ay + dy * clamped, ax + dx * clamped);
    final distM = distanceKm(p.latitude, p.longitude, point.latitude, point.longitude) * 1000;
    return _Projected(point: point, t: clamped, distanceM: distM);
  }

  double _segM(LatLng a, LatLng b) =>
      distanceKm(a.latitude, a.longitude, b.latitude, b.longitude) * 1000;

  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _turnLabel(double deltaDeg) {
    if (deltaDeg.abs() < 28) return 'Continue straight';
    if (deltaDeg >= 135) return 'Turn around';
    if (deltaDeg >= 45) return 'Turn right';
    if (deltaDeg <= -45) return 'Turn left';
    if (deltaDeg > 0) return 'Bear right';
    return 'Bear left';
  }
}

class _Snap {
  const _Snap({
    required this.segmentIndex,
    required this.pointOnRoute,
    required this.distanceAlongM,
    required this.offRouteM,
    required this.bearingDeg,
  });

  final int segmentIndex;
  final LatLng pointOnRoute;
  final double distanceAlongM;
  final double offRouteM;
  final double bearingDeg;
}

class _Projected {
  const _Projected({required this.point, required this.t, required this.distanceM});

  final LatLng point;
  final double t;
  final double distanceM;
}

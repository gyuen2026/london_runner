import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/models/crosswalk_point.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/studio/studio_ui.dart';

Color crosswalkColor(String? signalColor) {
  final c = (signalColor ?? 'GREEN').toUpperCase();
  if (c.contains('RED')) return AppTheme.signalRed;
  if (c.contains('AMBER') || c.contains('YELLOW')) return AppTheme.signalAmber;
  return StudioTheme.neon;
}

Widget crosswalkMarkerWidget({
  required int index,
  Color? color,
  bool active = false,
  double size = 28,
}) {
  final c = color ?? StudioTheme.neon;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: active ? size + 4 : size,
        height: active ? size + 4 : size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: c, width: active ? 3 : 2),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.directions_walk, color: c, size: active ? 16 : 14),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$index',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
    ],
  );
}

List<Marker> flutterCrosswalkMarkers(
  List<CrosswalkPoint> crossings, {
  int? activeIndex,
  Map<int, String>? signalColors,
}) {
  return [
    for (final c in crossings)
      Marker(
        point: LatLng(c.lat, c.lon),
        width: 36,
        height: 48,
        alignment: Alignment.topCenter,
        child: crosswalkMarkerWidget(
          index: c.index,
          color: crosswalkColor(signalColors?[c.index]),
          active: c.index == activeIndex,
        ),
      ),
  ];
}

Set<gmaps.Marker> googleCrosswalkMarkers(
  List<CrosswalkPoint> crossings, {
  int? activeIndex,
  Map<int, String>? signalColors,
}) {
  return {
    for (final c in crossings)
      gmaps.Marker(
        markerId: gmaps.MarkerId('xing_${c.index}'),
        position: toGoogleLatLng(LatLng(c.lat, c.lon)),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _googleHue(signalColors?[c.index]),
        ),
        infoWindow: gmaps.InfoWindow(title: '횡단보도 ${c.index}'),
        zIndex: c.index == activeIndex ? 2 : 1,
      ),
  };
}

double _googleHue(String? color) {
  final c = (color ?? 'GREEN').toUpperCase();
  if (c.contains('RED')) return gmaps.BitmapDescriptor.hueRed;
  if (c.contains('AMBER') || c.contains('YELLOW')) return gmaps.BitmapDescriptor.hueOrange;
  return gmaps.BitmapDescriptor.hueGreen;
}

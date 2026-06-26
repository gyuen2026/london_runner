import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
MapOptions navigationMapOptions({
  required LatLng initialCenter,
  double initialZoom = 17,
  double initialRotation = 0,
}) {
  return MapOptions(
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    initialRotation: initialRotation,
    minZoom: 14,
    maxZoom: 19,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
      scrollWheelVelocity: 0.02,
    ),
  );
}

void moveNavigationCamera(
  MapController controller,
  LatLng user,
  double bearingDeg, {
  double zoom = 17,
}) {
  controller.moveAndRotate(user, zoom, -bearingDeg);
}

Widget navUserMarker() {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: AppTheme.signalGreen,
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0)],
    ),
    child: const Icon(Icons.navigation, color: Colors.black, size: 18),
  );
}

/// Snappy pinch / scroll-wheel zoom — instant tile swap on web.
MapOptions fastMapOptions({
  LatLng? initialCenter,
  double initialZoom = 14,
  CameraFit? initialCameraFit,
  void Function(TapPosition, LatLng)? onTap,
}) {
  return MapOptions(
    initialCenter: initialCenter ?? const LatLng(51.5074, -0.1278),
    initialZoom: initialZoom,
    initialCameraFit: initialCameraFit,
    onTap: onTap,
    minZoom: 10,
    maxZoom: 19,
    interactionOptions: InteractionOptions(
      flags: InteractiveFlag.all,
      scrollWheelVelocity: kIsWeb ? 0.028 : 0.015,
      pinchZoomThreshold: 0.15,
      enableMultiFingerGestureRace: true,
    ),
  );
}

class DarkMapTileLayer extends StatelessWidget {
  const DarkMapTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.gyuen2026.geengreen',
      retinaMode: false,
      keepBuffer: 2,
      panBuffer: 1,
      maxNativeZoom: 19,
      tileDisplay: const TileDisplay.instantaneous(),
    );
  }
}

Polyline routePolyline(List<LatLng> points, {required Color color, double width = 5}) {
  return Polyline(
    points: points,
    strokeWidth: width,
    color: color,
    borderStrokeWidth: 2,
    borderColor: Colors.black,
  );
}

Widget userLocationMarker({double bearing = 0}) {
  return Transform.rotate(
    angle: bearing * 3.1415926535 / 180,
    child: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.signalGreen,
        border: Border.all(color: Colors.black, width: 2),
      ),
    ),
  );
}

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({super.key, required this.controller});

  final MapController controller;

  void _zoom(double delta) {
    final cam = controller.camera;
    controller.move(cam.center, (cam.zoom + delta).clamp(10.0, 19.0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomBtn(label: '+', onTap: () => _zoom(2)),
        const SizedBox(height: 2),
        _ZoomBtn(label: '−', onTap: () => _zoom(-2)),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.pixelBorder, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.pixelFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.signalGreen,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'package:london_runner/config/api_config.dart';

/// Unified map camera — Google Maps when key set, else flutter_map [MapController].
class AdaptiveMapController {
  MapController? _flutter;
  gmaps.GoogleMapController? _google;

  bool get usesGoogle => ApiConfig.hasGoogleMaps;

  MapController get flutter => _flutter ??= MapController();

  void attachGoogle(gmaps.GoogleMapController controller) {
    _google = controller;
  }

  void dispose() {
    _flutter?.dispose();
    _google?.dispose();
    _google = null;
  }

  Future<void> move(LatLng center, double zoom) async {
    if (usesGoogle && _google != null) {
      await _google!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(center.latitude, center.longitude),
          zoom,
        ),
      );
      return;
    }
    _flutter?.move(center, zoom);
  }

  Future<void> fitBounds(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) async {
    if (points.isEmpty) return;
    if (points.length == 1) {
      await move(points.first, 16);
      return;
    }
    if (usesGoogle && _google != null) {
      var minLat = points.first.latitude;
      var maxLat = minLat;
      var minLon = points.first.longitude;
      var maxLon = minLon;
      for (final p in points.skip(1)) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLon = math.min(minLon, p.longitude);
        maxLon = math.max(maxLon, p.longitude);
      }
      final pad = math.max(padding.left, math.max(padding.top, math.max(padding.right, padding.bottom)));
      await _google!.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(minLat, minLon),
            northeast: gmaps.LatLng(maxLat, maxLon),
          ),
          pad,
        ),
      );
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _flutter?.fitCamera(CameraFit.bounds(bounds: bounds, padding: padding));
  }

  Future<void> fitCoordinates(
    List<LatLng> coordinates, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) =>
      fitBounds(coordinates, padding: padding);

  Future<void> moveAndRotate(
    LatLng center,
    double bearingDeg, {
    double zoom = 17,
  }) async {
    if (usesGoogle && _google != null) {
      await _google!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(center.latitude, center.longitude),
            zoom: zoom,
            bearing: bearingDeg,
          ),
        ),
      );
      return;
    }
    _flutter?.moveAndRotate(center, zoom, -bearingDeg);
  }

  void zoomBy(double delta) {
    if (usesGoogle && _google != null) {
      _google!.getZoomLevel().then((z) {
        final next = (z + delta).clamp(10.0, 19.0);
        _google!.animateCamera(gmaps.CameraUpdate.zoomTo(next));
      });
      return;
    }
    final cam = _flutter?.camera;
    if (cam != null) {
      _flutter!.move(cam.center, (cam.zoom + delta).clamp(10.0, 19.0));
    }
  }
}

gmaps.LatLng toGoogleLatLng(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

List<gmaps.LatLng> toGooglePath(List<LatLng> points) =>
    points.map(toGoogleLatLng).toList();

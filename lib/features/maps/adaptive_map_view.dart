import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'package:london_runner/config/api_config.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/navigate/map_layers.dart';

/// Google Maps tiles when [ApiConfig.hasGoogleMaps], else Carto via flutter_map.
class AdaptiveMapView extends StatelessWidget {
  const AdaptiveMapView({
    super.key,
    required this.controller,
    this.initialCenter,
    this.initialZoom = 14,
    this.initialBearing = 0,
    this.minZoom = 10,
    this.maxZoom = 19,
    this.interactionFlags,
    this.onTap,
    this.polylines = const [],
    this.flutterMarkers = const [],
    this.googleMarkers = const {},
    this.googlePolylines = const {},
    this.mapType = gmaps.MapType.normal,
  });

  final AdaptiveMapController controller;
  final LatLng? initialCenter;
  final double initialZoom;
  final double initialBearing;
  final double minZoom;
  final double maxZoom;
  final int? interactionFlags;
  final void Function(TapPosition, LatLng)? onTap;
  final List<Polyline> polylines;
  final List<Marker> flutterMarkers;
  final Set<gmaps.Marker> googleMarkers;
  final Set<gmaps.Polyline> googlePolylines;
  final gmaps.MapType mapType;

  LatLng get _center => initialCenter ?? const LatLng(51.5074, -0.1278);

  @override
  Widget build(BuildContext context) {
    if (ApiConfig.hasGoogleMaps) {
      return _GoogleBody(
        controller: controller,
        center: _center,
        zoom: initialZoom,
        bearing: initialBearing,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onTap: onTap,
        markers: googleMarkers,
        polylines: googlePolylines,
        mapType: mapType,
      );
    }
    return _FlutterBody(
      controller: controller,
      center: _center,
      zoom: initialZoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
      interactionFlags: interactionFlags,
      onTap: onTap,
      polylines: polylines,
      markers: flutterMarkers,
    );
  }
}

class _GoogleBody extends StatefulWidget {
  const _GoogleBody({
    required this.controller,
    required this.center,
    required this.zoom,
    required this.bearing,
    required this.minZoom,
    required this.maxZoom,
    this.onTap,
    required this.markers,
    required this.polylines,
    required this.mapType,
  });

  final AdaptiveMapController controller;
  final LatLng center;
  final double zoom;
  final double bearing;
  final double minZoom;
  final double maxZoom;
  final void Function(TapPosition, LatLng)? onTap;
  final Set<gmaps.Marker> markers;
  final Set<gmaps.Polyline> polylines;
  final gmaps.MapType mapType;

  @override
  State<_GoogleBody> createState() => _GoogleBodyState();
}

class _GoogleBodyState extends State<_GoogleBody> {
  @override
  Widget build(BuildContext context) {
    final map = gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: toGoogleLatLng(widget.center),
        zoom: widget.zoom,
        bearing: widget.bearing,
      ),
      minMaxZoomPreference: gmaps.MinMaxZoomPreference(widget.minZoom, widget.maxZoom),
      mapType: widget.mapType,
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      onMapCreated: widget.controller.attachGoogle,
      onTap: widget.onTap == null
          ? null
          : (pos) => widget.onTap!(
                TapPosition(Offset.zero, Offset.zero),
                LatLng(pos.latitude, pos.longitude),
              ),
    );

    return map;
  }
}

class _FlutterBody extends StatelessWidget {
  const _FlutterBody({
    required this.controller,
    required this.center,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    this.interactionFlags,
    this.onTap,
    required this.polylines,
    required this.markers,
  });

  final AdaptiveMapController controller;
  final LatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final int? interactionFlags;
  final void Function(TapPosition, LatLng)? onTap;
  final List<Polyline> polylines;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    final flags = interactionFlags ??
        (InteractiveFlag.drag |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.scrollWheelZoom |
            InteractiveFlag.doubleTapZoom);

    final map = FlutterMap(
      mapController: controller.flutter,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onTap: onTap,
        interactionOptions: InteractionOptions(
          flags: flags,
          scrollWheelVelocity: kIsWeb ? 0.022 : 0.015,
          pinchZoomThreshold: 0.12,
          enableMultiFingerGestureRace: true,
        ),
      ),
      children: [
        const LightMapTileLayer(),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );

    return map;
  }
}

/// Zoom +/- for either map backend.
class AdaptiveMapZoomControls extends StatelessWidget {
  const AdaptiveMapZoomControls({super.key, required this.controller});

  final AdaptiveMapController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.usesGoogle) {
      return MapZoomControls(controller: controller.flutter);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoogleZoomBtn(label: '+', onTap: () => controller.zoomBy(1)),
        const SizedBox(height: 2),
        _GoogleZoomBtn(label: '−', onTap: () => controller.zoomBy(-1)),
      ],
    );
  }
}

class _GoogleZoomBtn extends StatelessWidget {
  const _GoogleZoomBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

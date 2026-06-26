import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'map_layers.dart';
import 'navigate_ui.dart';
import 'run_screen.dart';
class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({
    super.key,
    required this.route,
    required this.paceMinPerKm,
  });

  final RouteOption route;
  final double paceMinPerKm;

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final _mapController = MapController();

  List<LatLng> get _points => widget.route.polyline
      .map((p) => LatLng(p['lat']!, p['lon']!))
      .where((p) => p.latitude != 0 || p.longitude != 0)
      .toList();

  @override
  Widget build(BuildContext context) {
    final pts = _points;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('#${widget.route.rank} ${widget.route.name}'),
      ),
      body: Stack(
        children: [
          if (pts.length < 2)
            const Center(child: Text('No map data'))
          else
            FlutterMap(
              mapController: _mapController,
              options: fastMapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: pts,
                  padding: const EdgeInsets.all(64),
                ),
              ),
              children: [
                const DarkMapTileLayer(),
                PolylineLayer(
                  polylines: [routePolyline(pts, color: AppTheme.runGreen, width: 6)],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pts.first,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    Marker(
                      point: pts.last,
                      width: 24,
                      height: 24,
                      child: const Icon(Icons.flag, color: AppTheme.runGreen, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          Positioned(
            right: 12,
            bottom: 160,
            child: MapZoomControls(controller: _mapController),
          ),
          RoutePreviewSheet(
            distanceKm: widget.route.distanceKm,
            durationMin: widget.route.estimatedDurationMin,
            greenPct: widget.route.greenWaveScore,
            onStart: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RunScreen(
                    route: widget.route,
                    paceMinPerKm: widget.paceMinPerKm,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

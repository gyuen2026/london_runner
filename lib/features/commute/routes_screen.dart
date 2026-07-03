import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/navigate/run_screen.dart';
import 'package:london_runner/features/search/models/place_location.dart';
import 'package:london_runner/features/studio/studio_ui.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({
    super.key,
    required this.routes,
    required this.paceMinPerKm,
    required this.from,
    required this.to,
  });

  final List<RouteOption> routes;
  final double paceMinPerKm;
  final PlaceLocation from;
  final PlaceLocation to;

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late int _selected;
  final _mapController = AdaptiveMapController();

  @override
  void initState() {
    super.initState();
    _selected = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteMap());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  RouteOption get _route => widget.routes[_selected];

  List<LatLng> get _routePoints => _route.polyline
      .map((p) => LatLng(p['lat']!, p['lon']!))
      .where((p) => p.latitude != 0 || p.longitude != 0)
      .toList();

  void _fitRouteMap() {
    final pts = _routePoints;
    if (pts.length < 2) return;
    _mapController.fitCoordinates(pts, padding: const EdgeInsets.all(40));
  }

  void _startRun() {
    UiSound.instance.workoutStart();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RunScreen(
          route: _route,
          paceMinPerKm: _route.suggestedPaceMinPerKm ?? widget.paceMinPerKm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioHeader(
              showBack: true,
              onQr: () => showStudioQrDialog(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  StudioRouteInputCard(
                    fromLabel: widget.from.titleLine,
                    toLabel: widget.to.titleLine,
                    onFromTap: () => Navigator.pop(context),
                    onToTap: () => Navigator.pop(context),
                    subtitle: 'Green-wave pathways ranked by signal sync.',
                  ),
                  StudioPathwayHeader(count: widget.routes.length),
                  ...List.generate(widget.routes.length, (i) {
                    return StudioPathwayCard(
                      route: widget.routes[i],
                      selected: i == _selected,
                      onTap: () {
                        UiSound.instance.tap();
                        setState(() => _selected = i);
                        _fitRouteMap();
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  StudioPreviewMap(
                    controller: _mapController,
                    points: _routePoints,
                    crossings: _route.crossings,
                  ),
                  if (_route.crossings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '횡단보도 ${_route.crossings.length}곳 — 지도에 보행 신호 표시',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: StudioTheme.neon,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StudioTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: StudioTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 14, color: StudioTheme.neon),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                '실시간 GPS 측정 자동 대기 (GPS ACTIVE)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: StudioTheme.neon),
                              ),
                            ),
                            Text(
                              '연결 대기중',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GO를 누르면 실제 GPS로 경로·속도를 추적합니다. '
                          '심박수는 페이스 기반 추정 · GPS 오차 < 5m',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: StudioGoButton(onPressed: _startRun),
            ),
          ],
        ),
      ),
    );
  }
}

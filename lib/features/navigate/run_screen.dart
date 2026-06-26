import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/services/health_service.dart';
import 'package:london_runner/core/services/location_service.dart';
import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/services/voice_coach.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/utils/geo.dart';
import 'package:london_runner/features/commute/london_runner_api.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'map_layers.dart';
import 'navigate_ui.dart';
import 'route_navigation.dart';
class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.route,
    required this.paceMinPerKm,
  });

  final RouteOption route;
  final double paceMinPerKm;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  final _api = LondonRunnerApi();
  final _location = LocationService();
  final _health = HealthService();
  final _voice = VoiceCoach();
  final _mapController = MapController();

  late final RouteNavigator _navigator;
  late final List<LatLng> _routePoints;
  late final DateTime _startedAt;

  StreamSubscription<Position>? _posSub;
  Timer? _pollTimer;
  Timer? _clockTimer;

  double? _lat;
  double? _lon;
  double _speedKmh = 0;
  int _hr = 0;
  RouteProgress? _progress;
  String _coachText = '';
  String _signalColor = '—';
  String? _lastError;
  Duration _elapsed = Duration.zero;
  double _runDistanceM = 0;
  LatLng? _lastRunPoint;
  bool _runComplete = false;
  String? _lastAnnouncedTurn;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _routePoints = widget.route.polyline
        .map((p) => LatLng(p['lat']!, p['lon']!))
        .where((p) => p.latitude != 0 || p.longitude != 0)
        .toList();
    _navigator = RouteNavigator(_routePoints);
    _start();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  Future<void> _start() async {
    await _voice.init();
    try {
      await _location.ensurePermission();
      _posSub = _location.positionStream().listen(_onPosition);
      _pollTimer = Timer.periodic(const Duration(seconds: 18), (_) => _poll());
      _poll();
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  void _onPosition(Position pos) {
    final user = LatLng(pos.latitude, pos.longitude);
    final progress = _navigator.progress(user);

    if (_lastRunPoint != null) {
      _runDistanceM += distanceKm(
            _lastRunPoint!.latitude,
            _lastRunPoint!.longitude,
            user.latitude,
            user.longitude,
          ) *
          1000;
    }
    _lastRunPoint = user;

    if (progress.distanceRemainingM < 35 && !_runComplete) {
      _runComplete = true;
      UiSound.instance.success();
    }

    _maybeAnnounceTurn(progress);

    setState(() {
      _lat = pos.latitude;
      _lon = pos.longitude;
      _speedKmh = pos.speed >= 0 ? pos.speed * 3.6 : 0;
      _progress = progress;
    });

    moveNavigationCamera(_mapController, user, progress.bearingDeg);
  }

  void _maybeAnnounceTurn(RouteProgress progress) {
    final turn = progress.nextTurn;
    if (turn == null) return;
    if (progress.distanceToNextTurnM > 80 || progress.distanceToNextTurnM < 8) return;
    final key = '${turn.instruction}@${turn.distanceFromStartM.round()}';
    if (_lastAnnouncedTurn == key) return;
    _lastAnnouncedTurn = key;
    _voice.speak('In ${progress.distanceToNextTurnM.round()} meters, ${turn.instruction}');
  }

  Future<void> _poll() async {
    if (_lat == null || _lon == null) return;
    try {
      final hr = await _health.latestHeartRate();
      final status = await _api.checkStatus(
        lat: _lat!,
        lon: _lon!,
        hr: hr,
        pace: widget.paceMinPerKm,
        speedKmh: _speedKmh,
      );
      final voice = status['voice_instruction']?.toString() ?? '';
      final signal = status['signal'] as Map<String, dynamic>?;
      final color = signal?['predicted_color']?.toString() ?? '—';
      setState(() {
        _hr = hr;
        _coachText = voice;
        _signalColor = color;
        _lastError = null;
      });
      if (voice.isNotEmpty) await _voice.speak(voice);
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  Color get _signalUiColor {
    final c = _signalColor.toUpperCase();
    if (c.contains('GREEN')) return AppTheme.signalGreen;
    if (c.contains('RED')) return AppTheme.signalRed;
    return AppTheme.signalAmber;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  String get _livePace {
    if (_speedKmh <= 0.5) return '—';
    return (60 / _speedKmh).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final user = _lat != null && _lon != null ? LatLng(_lat!, _lon!) : null;
    final offRoute = progress != null && progress.offRouteM > _navigator.offRouteThresholdM;
    final completed = progress != null
        ? _navigator.completedPortion(progress.segmentIndex)
        : <LatLng>[];
    final upcoming = progress != null
        ? [if (completed.isNotEmpty) completed.last, ..._navigator.upcomingPortion(progress.segmentIndex)]
        : _routePoints;
    final remainingKm = progress != null ? progress.distanceRemainingM / 1000 : widget.route.distanceKm;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          if (_routePoints.length >= 2)
            FlutterMap(
              mapController: _mapController,
              options: navigationMapOptions(
                initialCenter: _routePoints.first,
                initialRotation: progress?.bearingDeg != null ? -progress!.bearingDeg : 0,
              ),
              children: [
                const DarkMapTileLayer(),
                if (completed.length >= 2)
                  PolylineLayer(polylines: [
                    routePolyline(completed, color: AppTheme.textSecondary.withValues(alpha: 0.35), width: 4),
                  ]),
                if (upcoming.length >= 2)
                  PolylineLayer(polylines: [
                    routePolyline(upcoming, color: AppTheme.runGreen, width: 6),
                  ]),
                if (user != null)
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      Marker(
                        point: user,
                        width: 32,
                        height: 32,
                        child: navUserMarker(),
                      ),
                    ],
                  ),
              ],
            )
          else
            const Center(child: Text('No route data')),

          NavigateRunLayout(
            onClose: () => Navigator.of(context).pop(),
            signalColor: _signalUiColor,
            signalLabel: _signalColor,
            progressData: progress,
            offRoute: offRoute,
            greenPct: progress != null ? widget.route.greenWaveScore : null,
            remainingKm: progress != null ? remainingKm : null,
            coachText: _coachText,
            time: _formatDuration(_elapsed),
            distanceKm: (_runDistanceM / 1000).toStringAsFixed(2),
            pace: _livePace,
            heartRate: _hr > 0 ? '$_hr' : '—',
            errorText: _lastError,
            runComplete: _runComplete,
            greenWaveScore: widget.route.greenWaveScore,
            onRunCompleteDismiss: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

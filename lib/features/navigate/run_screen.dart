import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/maps/adaptive_map_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/services/health_service.dart';
import 'package:london_runner/core/services/location_service.dart';
import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/services/voice_coach.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/utils/geo.dart';
import 'package:london_runner/core/utils/signal_countdown.dart';
import 'package:london_runner/features/commute/london_runner_api.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'package:london_runner/features/studio/studio_ui.dart';
import 'package:london_runner/features/navigate/crossing_tracker.dart';
import 'package:london_runner/features/navigate/crosswalk_markers.dart';
import 'map_layers.dart';
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
  final _mapController = AdaptiveMapController();

  late final RouteNavigator _navigator;
  late final List<LatLng> _routePoints;
  late final CrossingTracker _crossingTracker;
  late final DateTime _startedAt;

  StreamSubscription<Position>? _posSub;
  Timer? _pollTimer;
  Timer? _clockTimer;

  double? _lat;
  double? _lon;
  double _speedKmh = 0;
  int _hr = 70;
  RouteProgress? _progress;
  String _coachText = '';
  String _signalColor = 'GREEN';
  String _signalLivePhase = 'green';
  String _signalCountdownLabel = '빨간 불까지';
  int _signalSec = 8;
  DateTime? _signalPhaseEndsAt;
  final Map<int, String> _crossingColors = {};
  final Map<int, String> _crossingLivePhases = {};
  final Map<int, String> _crossingCountdownLabels = {};
  final Map<int, int> _crossingCountdownSecs = {};
  final Map<int, DateTime?> _crossingPhaseEndsAt = {};
  String? _lastError;
  Duration _elapsed = Duration.zero;
  double _runDistanceM = 0;
  LatLng? _lastRunPoint;
  bool _runComplete = false;
  bool _paused = false;
  bool _arMode = false;
  int _signalsPassed = 0;
  int _waitOffsetSec = 8;
  int _busDelaySec = 45;
  String _jamcamDensity = '—';
  String? _lastAnnouncedTurn;
  String? _lastSpokenAlert;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _routePoints = widget.route.polyline
        .map((p) => LatLng(p['lat']!, p['lon']!))
        .where((p) => p.latitude != 0 || p.longitude != 0)
        .toList();
    _navigator = RouteNavigator(_routePoints);
    _crossingTracker = CrossingTracker(widget.route.crossings);
    _start();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
        _tickSignalCountdown();
        _tickCrossingCountdowns();
      });
    });
  }

  Future<void> _start() async {
    await _voice.init();
    try {
      await _location.ensurePermission();
      _posSub = _location.positionStream().listen(_onPosition);
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
      _poll();
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  void _onPosition(Position pos) {
    if (_paused) return;
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
      _signalsPassed = widget.route.crossings.isNotEmpty
          ? _crossingTracker.countPassed(user)
          : progress.segmentIndex.clamp(0, widget.route.pedSignalsOnPath);
    });

    _mapController.moveAndRotate(user, progress.bearingDeg);
  }

  void _maybeAnnounceTurn(RouteProgress progress) {
    final turn = progress.nextTurn;
    if (turn == null) return;
    if (progress.distanceToNextTurnM > 80 || progress.distanceToNextTurnM < 8) return;
    final key = '${turn.instruction}@${turn.distanceFromStartM.round()}';
    if (_lastAnnouncedTurn == key) return;
    _lastAnnouncedTurn = key;
    _voice.speak('${progress.distanceToNextTurnM.round()}미터 앞 ${turn.instruction}');
  }

  void _tickSignalCountdown() {
    if (_signalPhaseEndsAt != null) {
      final rem = countdownSecondsUntil(_signalPhaseEndsAt);
      if (rem != _signalSec) _signalSec = rem;
      if (rem == 0) _flipMainSignalPhase();
      return;
    }
    if (_signalSec > 0) _signalSec--;
    if (_signalSec == 0) _flipMainSignalPhase();
  }

  void _tickCrossingCountdowns() {
    for (final index in _crossingCountdownSecs.keys.toList()) {
      final endsAt = _crossingPhaseEndsAt[index];
      if (endsAt != null) {
        final rem = countdownSecondsUntil(endsAt);
        _crossingCountdownSecs[index] = rem;
        if (rem == 0) _flipCrossingPhase(index);
        continue;
      }
      final sec = _crossingCountdownSecs[index]!;
      if (sec > 0) {
        _crossingCountdownSecs[index] = sec - 1;
      }
      if (sec == 0) _flipCrossingPhase(index);
    }
  }

  void _flipMainSignalPhase() {
    final next = nextSignalPhaseAfterZero(_signalLivePhase);
    _signalLivePhase = next.phase;
    _signalCountdownLabel = next.label;
    _signalColor = next.phase.toUpperCase();
    _signalSec = next.phase == 'red' ? _waitOffsetSec.clamp(8, 60) : 18;
    _signalPhaseEndsAt = DateTime.now().add(Duration(seconds: _signalSec));
  }

  void _flipCrossingPhase(int index) {
    final phase = _crossingLivePhases[index] ?? 'green';
    final next = nextSignalPhaseAfterZero(phase);
    _crossingLivePhases[index] = next.phase;
    _crossingCountdownLabels[index] = next.label;
    _crossingColors[index] = next.phase.toUpperCase();
    final sec = next.phase == 'red' ? 25 : 15;
    _crossingCountdownSecs[index] = sec;
    _crossingPhaseEndsAt[index] = DateTime.now().add(Duration(seconds: sec));
  }

  void _applySignalFromApi(Map<String, dynamic>? signal, {int? crossingIndex}) {
    if (signal == null) return;
    final phase = signal['phase']?.toString() ?? 'green';
    final color = signal['predicted_color']?.toString() ?? phase.toUpperCase();
    final label = signal['countdown_label_ko']?.toString() ?? countdownLabelFromPhase(phase);
    final sec = (signal['seconds_display'] as num?)?.round() ?? 8;
    final endsAt = parsePhaseEndsAt(signal['phase_ends_at']) ??
        DateTime.now().add(Duration(seconds: sec.clamp(1, 99)));

    if (crossingIndex != null) {
      _crossingColors[crossingIndex] = color;
      _crossingLivePhases[crossingIndex] = phase;
      _crossingCountdownLabels[crossingIndex] = label;
      _crossingCountdownSecs[crossingIndex] = countdownSecondsUntil(endsAt);
      _crossingPhaseEndsAt[crossingIndex] = endsAt;
      return;
    }

    _signalColor = color;
    _signalLivePhase = phase;
    _signalCountdownLabel = label;
    _signalSec = countdownSecondsUntil(endsAt);
    _signalPhaseEndsAt = endsAt;
  }

  Future<void> _poll() async {
    if (_lat == null || _lon == null || _paused) return;
    try {
      final hr = await _health.latestHeartRate();
      final user = LatLng(_lat!, _lon!);
      final next = _crossingTracker.nextCrossing(user);

      final status = await _api.checkStatus(
        lat: _lat!,
        lon: _lon!,
        hr: hr,
        pace: widget.paceMinPerKm,
        speedKmh: _speedKmh,
        crossingLat: next?.lat,
        crossingLon: next?.lon,
        crossingIndex: next?.index,
      );
      final voice = status['voice_instruction']?.toString() ?? '';
      final signal = status['signal'] as Map<String, dynamic>?;

      await _pollUpcomingCrossings(hr);

      setState(() {
        _applySignalFromApi(signal);
        _hr = hr > 0 ? hr : _estimateHr();
        _coachText = voice;
        _waitOffsetSec = (signal?['estimated_wait_sec'] as num?)?.round() ?? _waitOffsetSec;
        _busDelaySec = widget.route.signalWaitTotalSec > 0
            ? (widget.route.signalWaitTotalSec / 10).round().clamp(15, 90)
            : 45;
        final jam = signal?['jamcam_check'] as Map<String, dynamic>?;
        if (jam != null) {
          _jamcamDensity = jam['verified'] == true ? 'JamCam 확인' : '14명 밀집';
        }
        _lastError = null;
      });
      final alert = formatSignalCountdown(
        labelKo: _signalCountdownLabel,
        seconds: _signalSec,
      );
      if (alert.isNotEmpty && alert != _lastSpokenAlert) {
        _lastSpokenAlert = alert;
        await _voice.speak(alert);
      } else if (voice.isNotEmpty && _lastSpokenAlert == null) {
        await _voice.speak(voice);
      }
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  Future<void> _pollUpcomingCrossings(int hr) async {
    if (_lat == null || _lon == null) return;
    final user = LatLng(_lat!, _lon!);
    final upcoming = _crossingTracker.upcoming(user, limit: 4);
    for (final c in upcoming) {
      try {
        final status = await _api.checkStatus(
          lat: _lat!,
          lon: _lon!,
          hr: hr,
          pace: widget.paceMinPerKm,
          speedKmh: _speedKmh,
          crossingLat: c.lat,
          crossingLon: c.lon,
          crossingIndex: c.index,
        );
        final signal = status['signal'] as Map<String, dynamic>?;
        if (signal == null) continue;
        _applySignalFromApi(signal, crossingIndex: c.index);
      } catch (_) {}
    }
  }

  int _estimateHr() {
    if (_speedKmh <= 0.5) return 70;
    return (110 + _speedKmh * 2).round().clamp(70, 185);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _livePace {
    if (_speedKmh <= 0.5) return '—:—';
    final min = 60 / _speedKmh;
    final m = min.floor();
    final sec = ((min - m) * 60).round().toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String get _targetPaceLabel {
    final p = widget.paceMinPerKm;
    final m = p.floor();
    final sec = ((p - m) * 60).round().toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String get _navPrimary {
    final p = _progress;
    if (p == null) return '180m 앞 / Start running from your origin location';
    if (p.distanceRemainingM < 35) return '도착지에 거의 도달했습니다';
    final d = p.distanceToNextTurnM.round();
    return '${d}m 앞 / ${p.primaryInstruction}';
  }

  String get _navSecondary {
    final p = _progress;
    if (p == null) return 'GPS 연결 중…';
    return p.secondaryInstruction;
  }

  String get _signalCountdown {
    return formatSignalCountdown(labelKo: _signalCountdownLabel, seconds: _signalSec);
  }

  String get _signalPhaseKo => phaseLabelFromLivePhase(_signalLivePhase);

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
    final completed = progress != null
        ? _navigator.completedPortion(progress.segmentIndex)
        : <LatLng>[];
    final upcoming = progress != null
        ? [if (completed.isNotEmpty) completed.last, ..._navigator.upcomingPortion(progress.segmentIndex)]
        : _routePoints;
    final remainingKm = progress != null
        ? progress.distanceRemainingM / 1000
        : widget.route.distanceKm;
    final totalSignals = widget.route.crossings.isNotEmpty
        ? widget.route.crossings.length
        : (widget.route.pedSignalsOnPath > 0 ? widget.route.pedSignalsOnPath : 28);
    final greenLinked = widget.route.signalStops.clamp(0, totalSignals);
    final userPoint = user;
    final nextXing = userPoint != null ? _crossingTracker.nextCrossing(userPoint) : null;
    final xingMarkers = flutterCrosswalkMarkers(
      widget.route.crossings,
      activeIndex: nextXing?.index,
      signalColors: _crossingColors,
    );
    final googleXing = googleCrosswalkMarkers(
      widget.route.crossings,
      activeIndex: nextXing?.index,
      signalColors: _crossingColors,
    );

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          if (_arMode && _routePoints.length >= 2)
            AdaptiveMapView(
              controller: _mapController,
              initialCenter: _routePoints.first,
              initialZoom: 17,
              initialBearing: progress?.bearingDeg ?? 0,
              minZoom: 14,
              maxZoom: 19,
              interactionFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              polylines: [
                if (completed.length >= 2)
                  routePolyline(completed, color: AppTheme.textSecondary.withValues(alpha: 0.35), width: 4),
                if (upcoming.length >= 2)
                  routePolyline(upcoming, color: StudioTheme.neon, width: 6),
              ],
              flutterMarkers: [
                ...xingMarkers,
                if (user != null)
                  Marker(
                    point: user,
                    width: 32,
                    height: 32,
                    child: navUserMarker(),
                  ),
              ],
              googlePolylines: {
                if (completed.length >= 2)
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('done'),
                    points: toGooglePath(completed),
                    color: AppTheme.textSecondary.withValues(alpha: 0.35),
                    width: 4,
                  ),
                if (upcoming.length >= 2)
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('ahead'),
                    points: toGooglePath(upcoming),
                    color: StudioTheme.neon,
                    width: 6,
                  ),
              },
              googleMarkers: {
                ...googleXing,
                if (user != null)
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('user'),
                    position: toGoogleLatLng(user),
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
                    rotation: progress?.bearingDeg ?? 0,
                    flat: true,
                  ),
              },
            ),

          if (!_arMode)
            StudioWorkoutDashboard(
              navPrimary: _navPrimary,
              navSecondary: _navSecondary,
              time: _formatDuration(_elapsed),
              distanceKm: remainingKm.toStringAsFixed(2),
              pace: _livePace,
              heartRate: '$_hr',
              signalsPassed: _signalsPassed,
              signalsTotal: totalSignals,
              greenLinked: greenLinked,
              greenWavePct: widget.route.greenWaveScore,
              signalCountdown: _signalCountdown,
              onPause: () => setState(() => _paused = !_paused),
              onEnd: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),

          if (_arMode)
            StudioArCockpitOverlay(
              arMode: _arMode,
              onToggleAr: (v) => setState(() => _arMode = v),
              paceLabel: _livePace,
              targetPace: _targetPaceLabel,
              signalPhaseLabel: _signalPhaseKo,
              signalCountdownLabel: _signalCountdownLabel,
              signalCountdownSec: _signalSec,
              busDelaySec: _busDelaySec,
              jamcamDensity: _jamcamDensity,
              offsetSec: _waitOffsetSec,
              navPrimary: _navPrimary,
              timeLabel: _formatDuration(_elapsed),
              distanceLabel: remainingKm.toStringAsFixed(2),
              heartRateLabel: '$_hr',
              signalsPassed: _signalsPassed,
              signalsTotal: totalSignals,
              greenWavePct: widget.route.greenWaveScore.round(),
              upcomingCrossings: userPoint != null
                  ? _crossingTracker.upcoming(userPoint, limit: 4)
                  : widget.route.crossings.take(4).toList(),
              crossingCountdownLabels: _crossingCountdownLabels,
              crossingCountdownSecs: _crossingCountdownSecs,
            ),

          if (!_arMode)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _arMode = true),
                  icon: const Icon(Icons.view_in_ar, color: StudioTheme.neon, size: 18),
                  label: const Text('3D AR', style: TextStyle(color: StudioTheme.neon, fontSize: 12)),
                ),
              ),
            ),

          if (_runComplete)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: StudioCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: StudioTheme.neon, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'Run Complete · ${widget.route.greenWaveScore.round()}% green',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        style: FilledButton.styleFrom(backgroundColor: StudioTheme.neon, foregroundColor: Colors.black),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_lastError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Text(_lastError!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

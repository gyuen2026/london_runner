import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/commute_places_store.dart';
import 'package:london_runner/features/commute/london_runner_api.dart';
import 'package:london_runner/features/commute/routes_screen.dart';
import 'package:london_runner/features/search/models/place_location.dart';
import 'package:london_runner/features/search/place_picker_screen.dart';
import 'package:london_runner/features/studio/studio_ui.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  static const demoHome = PlaceLocation(
    lat: 51.4940,
    lon: -0.0480,
    label: 'Rotherhithe, London, SE16, United Kingdom',
    name: 'Home (SE16)',
  );
  static const demoOffice = PlaceLocation(
    lat: 51.4952,
    lon: -0.1441,
    label: 'Victoria Station, London, SW1V, United Kingdom',
    name: 'Victoria Station',
  );

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _api = LondonRunnerApi();
  final _commuteStore = CommutePlacesStore();
  final _mapController = AdaptiveMapController();

  PlaceLocation? _home;
  PlaceLocation? _office;
  PlaceLocation? _start;
  PlaceLocation? _end;

  TimeOfDay _arriveBy = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = false;
  String? _error;

  int _scanStage = 0;
  double _scanProgress = 0.08;
  int _scanElapsed = 0;
  Timer? _scanTicker;
  bool _scanCancelled = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _api.warmup(timeout: const Duration(seconds: 20));
  }

  @override
  void dispose() {
    _scanTicker?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    var home = await _commuteStore.loadHome();
    var office = await _commuteStore.loadOffice();
    home ??= SetupScreen.demoHome;
    office ??= SetupScreen.demoOffice;
    if (!mounted) return;
    setState(() {
      _home = home;
      _office = office;
      _start = home;
      _end = office;
    });
    _fitMap();
  }

  void _fitMap() {
    final s = _start;
    final e = _end;
    if (s == null || e == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCoordinates(
        [LatLng(s.lat, s.lon), LatLng(e.lat, e.lon)],
        padding: const EdgeInsets.all(48),
      );
    });
  }

  void _startScanProgress() {
    _scanTicker?.cancel();
    _scanStage = 0;
    _scanProgress = 0.08;
    _scanElapsed = 0;
    _scanCancelled = false;
    _scanTicker = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted || !_loading) {
        t.cancel();
        return;
      }
      setState(() {
        _scanElapsed++;
        if (_scanStage < 3 && _scanElapsed % 3 == 0) _scanStage++;
        _scanProgress = (_scanProgress + 0.06).clamp(0.08, 0.92);
      });
    });
  }

  void _stopScanProgress() {
    _scanTicker?.cancel();
    _scanTicker = null;
  }

  Future<void> _pickPlace({required bool isFrom}) async {
    final initial = isFrom ? _start : _end;
    final result = await Navigator.of(context).push<PlaceLocation>(
      MaterialPageRoute(
        builder: (_) => PlacePickerScreen(
          title: isFrom ? 'Origin' : 'Destination',
          initial: initial,
          biasLat: _start?.lat,
          biasLon: _start?.lon,
          pinColor: isFrom ? StudioTheme.neon : AppTheme.signalRed,
          instantConfirm: true,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _start = result;
      } else {
        _end = result;
      }
    });
    _fitMap();
  }

  void _loadDemo() {
    UiSound.instance.tap();
    setState(() {
      _start = SetupScreen.demoHome;
      _end = SetupScreen.demoOffice;
      _home = SetupScreen.demoHome;
      _office = SetupScreen.demoOffice;
    });
    _commuteStore.saveHome(SetupScreen.demoHome);
    _commuteStore.saveOffice(SetupScreen.demoOffice);
    _fitMap();
  }

  Future<void> _findGreenCommute() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      setState(() => _error = '출발지와 도착지를 선택해 주세요');
      return;
    }

    await UiSound.instance.workoutStart();
    setState(() {
      _loading = true;
      _error = null;
    });
    _startScanProgress();

    try {
      final routes = await _api.fetchGreenCommute(
        startLat: start.lat,
        startLon: start.lon,
        endLat: end.lat,
        endLon: end.lon,
        arriveHour: _arriveBy.hour,
        arriveMinute: _arriveBy.minute,
        commuteType: 'work',
        fast: true,
      );
      if (!mounted || _scanCancelled) return;

      if (routes.isEmpty) {
        setState(() => _error = 'No routes found — try a later arrival time');
        return;
      }

      await UiSound.instance.success();
      if (!mounted || _scanCancelled) return;
      final bestPace = routes.first.suggestedPaceMinPerKm ?? 5.25;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutesScreen(
            routes: routes,
            paceMinPerKm: bestPace,
            from: start,
            to: end,
          ),
        ),
      );
    } catch (e) {
      if (mounted && !_scanCancelled) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _stopScanProgress();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancelScan() {
    _scanCancelled = true;
    _stopScanProgress();
    setState(() => _loading = false);
  }

  List<LatLng> get _mapPoints {
    final s = _start;
    final e = _end;
    if (s == null || e == null) return [];
    return [LatLng(s.lat, s.lon), LatLng(e.lat, e.lon)];
  }

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final end = _end;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioHeader(
                  onQr: () => showStudioQrDialog(context),
                  onHud: () {},
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      StudioRouteInputCard(
                        fromLabel: start?.titleLine ?? '',
                        toLabel: end?.titleLine ?? '',
                        onFromTap: () => _pickPlace(isFrom: true),
                        onToTap: () => _pickPlace(isFrom: false),
                        onSparkle: _loading ? null : _findGreenCommute,
                      ),
                      const SizedBox(height: 12),
                      StudioPreviewMap(
                        controller: _mapController,
                        points: _mapPoints,
                        center: start != null ? LatLng(start.lat, start.lon) : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadDemo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StudioTheme.neon,
                          side: const BorderSide(color: StudioTheme.neon),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Load Home → Office Demo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: StudioGoButton(loading: _loading, onPressed: _findGreenCommute),
                ),
              ],
            ),
            if (_loading)
              Container(
                color: Colors.black.withValues(alpha: 0.72),
                child: Center(
                  child: StudioCard(
                    child: SizedBox(
                      width: 280,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: _scanProgress.clamp(0.04, 0.98),
                              strokeWidth: 5,
                              color: StudioTheme.neon,
                              backgroundColor: AppTheme.surfaceElevated,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            const ['Connecting', 'Mapping route', 'Syncing signals', 'Optimizing green wave'][
                                _scanStage.clamp(0, 3)],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _scanElapsed > 12 ? 'Waking server — first load ~30s' : 'Computing pathways…',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                          ),
                          TextButton(onPressed: _cancelScan, child: const Text('Cancel')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

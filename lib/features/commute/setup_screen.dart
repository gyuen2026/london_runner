import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
import 'package:london_runner/features/commute/commute_places_store.dart';
import 'package:london_runner/features/commute/london_runner_api.dart';
import 'package:london_runner/features/commute/widgets/speed_ui.dart';
import 'package:london_runner/features/commute/widgets/watch_ui.dart';
import 'package:london_runner/features/search/models/place_location.dart';
import 'package:london_runner/features/search/place_picker_screen.dart';
import 'routes_screen.dart';
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

  PlaceLocation? _home;
  PlaceLocation? _office;
  PlaceLocation? _start;
  PlaceLocation? _end;

  TimeOfDay _arriveBy = const TimeOfDay(hour: 9, minute: 0);
  bool _toWork = true;
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
    // Best-effort pre-warm; don't block UI.
    _api.warmup(timeout: const Duration(seconds: 20));
  }

  @override
  void dispose() {
    _scanTicker?.cancel();
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
      _applyCommuteDirection();
    });
  }

  void _applyCommuteDirection() {
    if (_toWork) {
      _start = _home;
      _end = _office;
    } else {
      _start = _office;
      _end = _home;
    }
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
        if (_scanStage < WatchScanOverlay.stages.length - 1 && _scanElapsed % 3 == 0) {
          _scanStage++;
        }
        _scanProgress = (_scanProgress + 0.06).clamp(0.08, 0.92);
      });
    });
  }

  void _stopScanProgress() {
    _scanTicker?.cancel();
    _scanTicker = null;
  }

  Future<void> _pickCommutePlace({required bool isHome}) async {
    final result = await Navigator.of(context).push<PlaceLocation>(
      MaterialPageRoute(
        builder: (_) => PlacePickerScreen(
          title: isHome ? 'Home' : 'Office',
          initial: isHome ? _home : _office,
          biasLat: _start?.lat,
          biasLon: _start?.lon,
          pinColor: AppTheme.activityGreen,
          instantConfirm: true,
        ),
      ),
    );
    if (result == null) return;
    if (isHome) {
      await _commuteStore.saveHome(result);
      setState(() => _home = result);
    } else {
      await _commuteStore.saveOffice(result);
      setState(() => _office = result);
    }
    _applyCommuteDirection();
  }

  Future<void> _pickArriveTime() async {
    final picked = await showTimePicker(context: context, initialTime: _arriveBy);
    if (picked != null) {
      UiSound.instance.tap();
      setState(() => _arriveBy = picked);
    }
  }

  Future<void> _findGreenCommute() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      setState(() => _error = 'Set home and office first');
      return;
    }

    await UiSound.instance.workoutStart();
    setState(() {
      _loading = true;
      _error = null;
    });
    _startScanProgress();

    try {
      // Resilient fetch: auto-retry once after warmup on cold-start timeout.
      final routes = await _api.fetchGreenCommute(
        startLat: start.lat,
        startLon: start.lon,
        endLat: end.lat,
        endLon: end.lon,
        arriveHour: _arriveBy.hour,
        arriveMinute: _arriveBy.minute,
        commuteType: _toWork ? 'work' : 'home',
        fast: true,
      );
      if (!mounted || _scanCancelled) return;

      if (routes.isEmpty) {
        setState(() => _error = 'No routes found — try a later arrival time');
        return;
      }

      final arriveLabel = MaterialLocalizations.of(context).formatTimeOfDay(_arriveBy);
      setState(() => _scanProgress = 1.0);
      await UiSound.instance.success();
      if (!mounted || _scanCancelled) return;
      final bestPace = routes.first.suggestedPaceMinPerKm ?? 5.5;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutesScreen(
            routes: routes,
            paceMinPerKm: bestPace,
            title: 'Routes',
            subtitle: 'Arrive by $arriveLabel',
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

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final end = _end;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(child: GeenGreenLogo()),
                      WatchCornerButton(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        onTap: () => _pickCommutePlace(isHome: true),
                      ),
                      const SizedBox(width: 8),
                      WatchCornerButton(
                        icon: Icons.work_outline,
                        label: 'Office',
                        onTap: () => _pickCommutePlace(isHome: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    children: [
                      Text(
                        'Outdoor Run',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Green wave route · arrive on time',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      GlassPanel(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DirectionPill(
                                label: 'To Work',
                                active: _toWork,
                                onTap: () {
                                  if (_toWork) return;
                                  UiSound.instance.tap();
                                  setState(() {
                                    _toWork = true;
                                    _applyCommuteDirection();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DirectionPill(
                                label: 'To Home',
                                active: !_toWork,
                                onTap: () {
                                  if (!_toWork) return;
                                  UiSound.instance.tap();
                                  setState(() {
                                    _toWork = false;
                                    _applyCommuteDirection();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SpeedRouteCard(
                        toWork: _toWork,
                        fromLabel: start?.titleLine ?? 'Set start',
                        fromSub: start?.addressLine ?? '',
                        toLabel: end?.titleLine ?? 'Set end',
                        toSub: end?.addressLine ?? '',
                        onFromTap: () => _pickCommutePlace(isHome: _toWork),
                        onToTap: () => _pickCommutePlace(isHome: !_toWork),
                      ),
                      const SizedBox(height: 20),
                      Text('Arrive by', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 10),
                      SpeedTimeChips(
                        selected: _arriveBy,
                        onSelected: (t) => setState(() => _arriveBy = t),
                        onCustom: _pickArriveTime,
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Web demo · SE16 → Victoria',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(_error!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SpeedGoButton(
                    label: 'Start Run',
                    loading: _loading,
                    loadingLabel: 'Planning route…',
                    onPressed: _findGreenCommute,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            WatchScanOverlay(
              stage: WatchScanOverlay.stages[_scanStage.clamp(0, WatchScanOverlay.stages.length - 1)],
              progress: _scanProgress,
              elapsedSec: _scanElapsed,
              onCancel: _cancelScan,
            ),
        ],
      ),
    );
  }
}

class _DirectionPill extends StatelessWidget {
  const _DirectionPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.runGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: active ? Colors.black : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

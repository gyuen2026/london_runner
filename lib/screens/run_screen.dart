import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/route_option.dart';
import '../services/health_service.dart';
import '../services/location_service.dart';
import '../services/london_runner_api.dart';
import '../services/voice_coach.dart';

/// ④ GPS + HR → check-status  ⑤ GREEN/RED report
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

  StreamSubscription<Position>? _posSub;
  Timer? _pollTimer;

  double? _lat;
  double? _lon;
  int _hr = 0;
  String _coachText = '러닝 시작…';
  String _signalText = '';
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _voice.init();
    try {
      await _location.ensurePermission();
      _posSub = _location.positionStream().listen(_onPosition);
      _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  void _onPosition(Position pos) {
    setState(() {
      _lat = pos.latitude;
      _lon = pos.longitude;
    });
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
      );
      final voice = status['voice_instruction']?.toString() ?? '';
      final signal = status['signal'] as Map<String, dynamic>?;
      final color = signal?['predicted_color']?.toString() ?? '?';
      final green = signal?['green_probability'];
      setState(() {
        _hr = hr;
        _coachText = voice;
        _signalText = 'Signal: $color · green $green';
        _lastError = null;
      });
      if (voice.isNotEmpty) await _voice.speak(voice);
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  Future<void> _report(String color) async {
    if (_lat == null || _lon == null) return;
    try {
      await _api.reportSignal(lat: _lat!, lon: _lon!, color: color);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$color 제보 완료')),
      );
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.route.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('④ 실시간 위치 + 심박 → /check-status (20초마다)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Lat: ${_lat?.toStringAsFixed(5) ?? "…"}'),
            Text('Lon: ${_lon?.toStringAsFixed(5) ?? "…"}'),
            Text('HR: $_hr bpm'),
            Text('Pace target: ${widget.paceMinPerKm} min/km'),
            const SizedBox(height: 12),
            Text(_signalText, style: const TextStyle(color: Colors.lightGreenAccent)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_coachText),
              ),
            ),
            const Text('⑤ 신호 색 제보 (검증용)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _report('GREEN'),
                    child: const Text('GREEN'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _report('RED'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
                    child: const Text('RED'),
                  ),
                ),
              ],
            ),
            if (_lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_lastError!, style: const TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
      ),
    );
  }
}

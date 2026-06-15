import 'package:flutter/material.dart';

import '../models/route_option.dart';
import '../services/location_service.dart';
import '../services/london_runner_api.dart';
import 'run_screen.dart';
import 'routes_screen.dart';

/// Setup: start / end / pace / distance → fetch routes
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _api = LondonRunnerApi();
  final _location = LocationService();

  final _startLat = TextEditingController(text: '51.5074');
  final _startLon = TextEditingController(text: '-0.1278');
  final _endLat = TextEditingController(text: '51.5150');
  final _endLon = TextEditingController(text: '-0.1200');
  final _pace = TextEditingController(text: '5.5');
  final _dist = TextEditingController(text: '5.0');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _startLat.dispose();
    _startLon.dispose();
    _endLat.dispose();
    _endLon.dispose();
    _pace.dispose();
    _dist.dispose();
    super.dispose();
  }

  Future<void> _useGpsAsStart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await _location.currentPosition();
      _startLat.text = pos.latitude.toStringAsFixed(5);
      _startLon.text = pos.longitude.toStringAsFixed(5);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _findRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await _api.fetchRoutes(
        startLat: double.parse(_startLat.text),
        startLon: double.parse(_startLon.text),
        endLat: double.parse(_endLat.text),
        endLon: double.parse(_endLon.text),
        pace: double.parse(_pace.text),
        dist: double.parse(_dist.text),
      );
      if (!mounted) return;
      if (routes.isEmpty) {
        setState(() => _error = 'No routes returned');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutesScreen(
            routes: routes,
            paceMinPerKm: double.parse(_pace.text),
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('London Runner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('③ 출발 / 목적지 / 페이스 / 거리 → Render API',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _field('Start lat', _startLat),
          _field('Start lon', _startLon),
          OutlinedButton.icon(
            onPressed: _loading ? null : _useGpsAsStart,
            icon: const Icon(Icons.my_location),
            label: const Text('현재 GPS → 출발지'),
          ),
          const SizedBox(height: 8),
          _field('End lat', _endLat),
          _field('End lon', _endLon),
          _field('Pace (min/km)', _pace),
          _field('Distance (km)', _dist),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _findRoutes,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('경로 5개 받기'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

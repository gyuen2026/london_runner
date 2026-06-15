import 'package:flutter/material.dart';

import '../models/place_location.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/london_runner_api.dart';
import 'place_picker_screen.dart';
import 'routes_screen.dart';

/// Setup: start / end by place name + map, pace / distance → fetch routes.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _api = LondonRunnerApi();
  final _location = LocationService();
  final _geocoding = GeocodingService();

  PlaceLocation? _start = const PlaceLocation(
    lat: 51.5074,
    lon: -0.1278,
    label: 'Trafalgar Square, London, United Kingdom',
    name: 'Trafalgar Square',
  );
  PlaceLocation? _end = const PlaceLocation(
    lat: 51.5194,
    lon: -0.1270,
    label: 'British Museum, London, United Kingdom',
    name: 'British Museum',
  );

  final _pace = TextEditingController(text: '5.5');
  final _dist = TextEditingController(text: '5.0');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pace.dispose();
    _dist.dispose();
    super.dispose();
  }

  Future<void> _pickPlace({required bool isStart}) async {
    final result = await Navigator.of(context).push<PlaceLocation>(
      MaterialPageRoute(
        builder: (_) => PlacePickerScreen(
          title: isStart ? '출발지' : '목적지',
          initial: isStart ? _start : _end,
          pinColor: isStart ? Colors.green : Colors.red,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isStart) {
          _start = result;
        } else {
          _end = result;
        }
      });
    }
  }

  Future<void> _useGpsAsStart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await _location.currentPosition();
      final place = await _geocoding.reverse(pos.latitude, pos.longitude);
      setState(() => _start = place);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _findRoutes() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      setState(() => _error = '출발지와 목적지를 선택해 주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await _api.fetchRoutes(
        startLat: start.lat,
        startLon: start.lon,
        endLat: end.lat,
        endLon: end.lon,
        pace: double.parse(_pace.text),
        dist: double.parse(_dist.text),
      );
      if (!mounted) return;
      if (routes.isEmpty) {
        setState(() => _error = '경로를 찾지 못했습니다');
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

  Widget _placeTile({
    required String label,
    required PlaceLocation? place,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.place, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          place?.shortLabel ?? '탭해서 선택',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('London Runner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '출발 / 목적지 검색 → 지도에서 확인',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _placeTile(
            label: '출발지',
            place: _start,
            color: Colors.green,
            onTap: () => _pickPlace(isStart: true),
          ),
          OutlinedButton.icon(
            onPressed: _loading ? null : _useGpsAsStart,
            icon: const Icon(Icons.my_location),
            label: const Text('현재 위치 → 출발지'),
          ),
          const SizedBox(height: 8),
          _placeTile(
            label: '목적지',
            place: _end,
            color: Colors.red,
            onTap: () => _pickPlace(isStart: false),
          ),
          const SizedBox(height: 12),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

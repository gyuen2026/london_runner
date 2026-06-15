import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_location.dart';
import '../services/geocoding_service.dart';

/// Google Maps–style: search by name → preview on map → confirm.
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({
    super.key,
    required this.title,
    this.initial,
    this.pinColor = Colors.red,
  });

  final String title;
  final PlaceLocation? initial;
  final Color pinColor;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final _searchCtrl = TextEditingController();
  final _mapController = MapController();
  final _geocoding = GeocodingService();

  Timer? _debounce;
  List<PlaceLocation> _suggestions = [];
  PlaceLocation? _selected;
  bool _searching = false;
  String? _error;

  static const _londonCenter = LatLng(51.5074, -0.1278);

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    if (widget.initial != null) {
      _searchCtrl.text = widget.initial!.shortLabel;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _moveMapToSelected());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _moveMapToSelected() {
    final s = _selected;
    if (s == null) return;
    _mapController.move(LatLng(s.lat, s.lon), 15);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _geocoding.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectSuggestion(PlaceLocation place) async {
    setState(() {
      _selected = place;
      _suggestions = [];
      _searchCtrl.text = place.shortLabel;
    });
    _mapController.move(LatLng(place.lat, place.lon), 16);
  }

  Future<void> _onMapTap(TapPosition tap, LatLng point) async {
    setState(() => _searching = true);
    try {
      final place = await _geocoding.reverse(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _selected = place;
        _searchCtrl.text = place.shortLabel;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selected = PlaceLocation(
          lat: point.latitude,
          lon: point.longitude,
          label: '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
        );
        _searching = false;
      });
    }
  }

  void _confirm() {
    final s = _selected;
    if (s == null) {
      setState(() => _error = '지도에서 위치를 선택해 주세요');
      return;
    }
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final pin = _selected;
    final center = pin != null ? LatLng(pin.lat, pin.lon) : _londonCenter;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} 선택')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '예: British Museum, Trafalgar Square',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _suggestions = []);
                            },
                          )
                        : null),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _runSearch,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, i) {
                  final p = _suggestions[i];
                  return ListTile(
                    leading: Icon(Icons.place, color: widget.pinColor),
                    title: Text(p.shortLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      p.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _selectSuggestion(p),
                  );
                },
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: pin != null ? 15 : 13,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.londonrunner.app',
                    ),
                    if (pin != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(pin.lat, pin.lon),
                            width: 48,
                            height: 48,
                            child: Icon(Icons.location_pin, size: 48, color: widget.pinColor),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              pin != null
                  ? pin.label
                  : '검색하거나 지도를 탭해서 위치를 고르세요',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _confirm,
                child: Text('${widget.title}로 설정'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

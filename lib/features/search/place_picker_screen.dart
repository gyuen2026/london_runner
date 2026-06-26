import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/utils/geo.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
import 'package:london_runner/features/navigate/map_layers.dart';
import 'package:london_runner/features/navigate/navigate_ui.dart';
import 'package:london_runner/features/search/geocoding_service.dart';
import 'package:london_runner/features/search/models/place_location.dart';
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({
    super.key,
    required this.title,
    this.initial,
    this.biasLat,
    this.biasLon,
    this.pinColor = AppTheme.accentRun,
    this.instantConfirm = false,
  });

  final String title;
  final PlaceLocation? initial;
  final double? biasLat;
  final double? biasLon;
  final Color pinColor;
  /// Tap search result → immediately save & pop (speed mode).
  final bool instantConfirm;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveMapToSelected();
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _mapCenter {
    if (_selected != null) return LatLng(_selected!.lat, _selected!.lon);
    if (widget.biasLat != null && widget.biasLon != null) {
      return LatLng(widget.biasLat!, widget.biasLon!);
    }
    return _londonCenter;
  }

  void _moveMapToSelected() {
    final s = _selected;
    if (s == null) return;
    _mapController.move(LatLng(s.lat, s.lon), 16);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      var results = await _geocoding.search(
        query,
        nearLat: widget.biasLat,
        nearLon: widget.biasLon,
        limit: 25,
      );
      results = _sortByDistanceIfNeeded(results);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
      if (results.isNotEmpty) {
        final first = results.first;
        _mapController.move(LatLng(first.lat, first.lon), 14);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  List<PlaceLocation> _sortByDistanceIfNeeded(List<PlaceLocation> items) {
    if (widget.biasLat == null || widget.biasLon == null || items.isEmpty) {
      return items;
    }
    final enriched = items.map((p) {
      if (p.distanceM != null) return p;
      final m = (distanceKm(widget.biasLat!, widget.biasLon!, p.lat, p.lon) * 1000).round();
      return PlaceLocation(
        lat: p.lat,
        lon: p.lon,
        label: p.label,
        name: p.name,
        distanceM: m,
        category: p.category,
      );
    }).toList();
    enriched.sort((a, b) => (a.distanceM ?? 999999).compareTo(b.distanceM ?? 999999));
    return enriched;
  }

  void _selectPlace(PlaceLocation place, {bool confirm = false}) {
    if (widget.instantConfirm || confirm) {
      Navigator.of(context).pop(place);
      return;
    }
    setState(() {
      _selected = place;
      _searchCtrl.text = place.titleLine;
    });
    _mapController.move(LatLng(place.lat, place.lon), 17);
  }

  Future<void> _onMapTap(TapPosition tap, LatLng point) async {
    setState(() => _searching = true);
    try {
      final place = await _geocoding.reverse(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _selected = place;
        _suggestions = [];
        _searchCtrl.text = place.shortLabel;
        _searching = false;
      });
      _mapController.move(point, 17);
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
      setState(() => _error = '검색 결과 또는 지도에서 장소를 선택해 주세요');
      return;
    }
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final showResults = _suggestions.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
            FlutterMap(
              mapController: _mapController,
              options: fastMapOptions(
                initialCenter: _mapCenter,
                initialZoom: selected != null ? 15 : 13,
                onTap: _onMapTap,
              ),
            children: [
              const DarkMapTileLayer(),
              if (_suggestions.isNotEmpty)
                MarkerLayer(
                  markers: _suggestions.map((p) {
                    final isSelected = selected != null &&
                        (p.lat - selected.lat).abs() < 0.00001 &&
                        (p.lon - selected.lon).abs() < 0.00001;
                    return Marker(
                      point: LatLng(p.lat, p.lon),
                      width: isSelected ? 44 : 32,
                      height: isSelected ? 44 : 32,
                      child: GestureDetector(
                        onTap: () => _selectPlace(p),
                        child: Icon(
                          Icons.location_on,
                          size: isSelected ? 44 : 32,
                          color: isSelected ? widget.pinColor : widget.pinColor.withValues(alpha: 0.55),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(selected.lat, selected.lon),
                      width: 52,
                      height: 52,
                      child: Icon(Icons.location_pin, size: 52, color: widget.pinColor),
                    ),
                  ],
                ),
            ],
          ),

          MapSearchTopBar(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            searching: _searching,
            hintText: 'Search London (3+ chars)',
            onChanged: _onSearchChanged,
            onSubmitted: _runSearch,
            onClear: () {
              _searchCtrl.clear();
              setState(() => _suggestions = []);
            },
          ),

          if (showResults)
            DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.22,
              maxChildSize: 0.72,
              snap: true,
              builder: (context, scrollController) {
                return PlaceSearchResultsSheet(
                  title: widget.title,
                  suggestions: _suggestions,
                  selected: selected,
                  pinColor: widget.pinColor,
                  scrollController: scrollController,
                  onSelect: _selectPlace,
                );
              },
            )
          else if (selected != null)
            PlaceConfirmSheet(
              place: selected,
              confirmLabel: 'Set as ${widget.title}',
              onConfirm: _confirm,
            ),

          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: showResults ? MediaQuery.of(context).size.height * 0.4 : 120,
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                borderRadius: 0,
                child: Text(_error!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 13)),
              ),
            ),

          Positioned(
            right: 12,
            bottom: showResults ? MediaQuery.of(context).size.height * 0.42 : 100,
            child: MapZoomControls(controller: _mapController),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/utils/geo.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/maps/adaptive_map_view.dart';
import 'package:london_runner/features/maps/map_overlay_barrier.dart';
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
  final _mapController = AdaptiveMapController();
  final _geocoding = GeocodingService();

  Timer? _debounce;
  List<PlaceLocation> _suggestions = [];
  PlaceLocation? _selected;
  bool _searching = false;
  String? _error;

  static const _londonCenter = LatLng(51.5074, -0.1278);
  static const _maxMapPins = 10;

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
      _unfocusSearch();
      if (results.isNotEmpty) {
        _fitResultsOnMap(results);
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

  void _fitResultsOnMap(List<PlaceLocation> results) {
    final pins = results.take(_maxMapPins).toList();
    _mapController.fitBounds(
      pins.map((p) => LatLng(p.lat, p.lon)).toList(),
      padding: const EdgeInsets.fromLTRB(56, 120, 56, 240),
    );
  }

  void _unfocusSearch() => FocusScope.of(context).unfocus();

  void _onBack() {
    if (_suggestions.isNotEmpty) {
      setState(() {
        _suggestions = [];
        _error = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _selectPlace(PlaceLocation place, {bool confirm = false}) {
    if (widget.instantConfirm || confirm) {
      Navigator.of(context).pop(place);
      return;
    }
    setState(() {
      _selected = place;
      _suggestions = [];
      _searchCtrl.text = place.titleLine;
    });
    _unfocusSearch();
    _mapController.move(LatLng(place.lat, place.lon), 17);
  }

  Future<void> _onMapTap(TapPosition tap, LatLng point) async {
    _unfocusSearch();
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
      if (widget.instantConfirm) {
        Navigator.of(context).pop(place);
      }
    } catch (e) {
      if (!mounted) return;
      final fallback = PlaceLocation(
        lat: point.latitude,
        lon: point.longitude,
        label: '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      );
      setState(() {
        _selected = fallback;
        _searching = false;
      });
      if (widget.instantConfirm) {
        Navigator.of(context).pop(fallback);
      }
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
    final mapPins = _suggestions.take(_maxMapPins).toList();
    final topInset = MediaQuery.of(context).padding.top + 72;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AdaptiveMapView(
              controller: _mapController,
              initialCenter: _mapCenter,
              initialZoom: selected != null ? 15 : 13,
              onTap: _onMapTap,
              flutterMarkers: [
                for (var i = 0; i < mapPins.length; i++)
                  _buildSearchMarker(
                    index: i + 1,
                    place: mapPins[i],
                    selected: selected,
                  ),
                if (selected != null &&
                    !mapPins.any((p) =>
                        (p.lat - selected.lat).abs() < 0.00001 &&
                        (p.lon - selected.lon).abs() < 0.00001))
                  Marker(
                    point: LatLng(selected.lat, selected.lon),
                    width: 32,
                    height: 32,
                    child: Icon(Icons.location_on, color: widget.pinColor, size: 32),
                  ),
              ],
              googleMarkers: _buildGoogleMarkers(mapPins, selected),
            ),
          ),

          mapOverlayBarrier(
            Align(
              alignment: Alignment.topCenter,
              child: MapSearchTopBar(
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
                onBack: _onBack,
              ),
            ),
          ),

          if (showResults)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: sheetHeight,
              child: mapOverlayBarrier(
                PlaceSearchResultsSheet(
                  title: widget.title,
                  suggestions: _suggestions,
                  selected: selected,
                  pinColor: widget.pinColor,
                  onSelect: _selectPlace,
                ),
              ),
            )
          else if (selected != null && !widget.instantConfirm)
            Align(
              alignment: Alignment.bottomCenter,
              child: mapOverlayBarrier(
                PlaceConfirmSheet(
                  place: selected,
                  confirmLabel: 'Set as ${widget.title}',
                  onConfirm: _confirm,
                ),
              ),
            ),

          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: showResults ? sheetHeight + 12 : 120,
              child: mapOverlayBarrier(
                GlassPanel(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 0,
                  child: Text(_error!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 13)),
                ),
              ),
            ),

          Positioned(
            top: topInset,
            right: 12,
            child: mapOverlayBarrier(
              AdaptiveMapZoomControls(controller: _mapController),
            ),
          ),
        ],
      ),
    );
  }

  Set<gmaps.Marker> _buildGoogleMarkers(List<PlaceLocation> pins, PlaceLocation? selected) {
    final markers = <gmaps.Marker>{};
    for (var i = 0; i < pins.length; i++) {
      final place = pins[i];
      final isSelected = selected != null &&
          (place.lat - selected.lat).abs() < 0.00001 &&
          (place.lon - selected.lon).abs() < 0.00001;
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId('pin_$i'),
        position: toGoogleLatLng(LatLng(place.lat, place.lon)),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? gmaps.BitmapDescriptor.hueGreen : gmaps.BitmapDescriptor.hueOrange,
        ),
        infoWindow: gmaps.InfoWindow(title: '${i + 1}', snippet: place.shortLabel),
        onTap: () => _selectPlace(place),
      ));
    }
    if (selected != null &&
        !pins.any((p) =>
            (p.lat - selected.lat).abs() < 0.00001 && (p.lon - selected.lon).abs() < 0.00001)) {
      markers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('selected'),
        position: toGoogleLatLng(LatLng(selected.lat, selected.lon)),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
        infoWindow: gmaps.InfoWindow(title: selected.shortLabel),
      ));
    }
    return markers;
  }

  Marker _buildSearchMarker({
    required int index,
    required PlaceLocation place,
    required PlaceLocation? selected,
  }) {
    final isSelected = selected != null &&
        (place.lat - selected.lat).abs() < 0.00001 &&
        (place.lon - selected.lon).abs() < 0.00001;
    return Marker(
      point: LatLng(place.lat, place.lon),
      width: 36,
      height: 48,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _selectPlace(place),
        child: searchResultMarker(
          index: index,
          selected: isSelected,
          accent: widget.pinColor,
        ),
      ),
    );
  }
}

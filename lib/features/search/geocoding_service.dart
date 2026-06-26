import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:london_runner/config/api_config.dart';
import 'package:london_runner/features/search/models/place_location.dart';
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <String, _CacheEntry>{};
  static const _cacheTtl = Duration(minutes: 5);

  String _cacheKey(String query, double? nearLat, double? nearLon, int limit) {
    final bias = nearLat != null && nearLon != null
        ? '${nearLat.toStringAsFixed(3)}|${nearLon.toStringAsFixed(3)}'
        : 'none';
    return '${query.trim().toLowerCase()}|$bias|$limit';
  }

  Future<List<PlaceLocation>> search(
    String query, {
    double? nearLat,
    double? nearLon,
    int limit = 25,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final key = _cacheKey(trimmed, nearLat, nearLon, limit);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.results;
    }

    final uri = ApiConfig.geocodeSearch(
      q: trimmed,
      limit: limit,
      nearLat: nearLat,
      nearLon: nearLon,
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? [])
        .map((e) => PlaceLocation.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache[key] = _CacheEntry(at: DateTime.now(), results: results);
    if (_cache.length > 64) {
      _cache.remove(_cache.keys.first);
    }
    return results;
  }

  Future<PlaceLocation> reverse(double lat, double lon) async {
    final uri = ApiConfig.geocodeReverse(lat: lat, lon: lon);
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      return PlaceLocation(
        lat: lat,
        lon: lon,
        label: '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
      );
    }
    return PlaceLocation.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}

class _CacheEntry {
  _CacheEntry({required this.at, required this.results});

  final DateTime at;
  final List<PlaceLocation> results;
}

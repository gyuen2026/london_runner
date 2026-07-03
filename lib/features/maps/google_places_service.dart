import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:london_runner/config/api_config.dart';
import 'package:london_runner/features/search/models/place_location.dart';

/// Direct Google Places (New) — used when Flutter has GOOGLE_MAPS_API_KEY.
class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static bool get available => ApiConfig.hasGoogleMaps;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': ApiConfig.googleMapsApiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location,places.primaryType',
      };

  Future<List<PlaceLocation>> search(
    String query, {
    double? nearLat,
    double? nearLon,
    int limit = 20,
  }) async {
    if (!available) return [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final biasLat = nearLat ?? 51.5074;
    final biasLon = nearLon ?? -0.1278;
    final tight = nearLat != null && nearLon != null;
    final radius = tight ? 5000.0 : 25000.0;
    final queries = _expandQueries(trimmed);

    final seen = <String>{};
    final out = <PlaceLocation>[];

    for (final q in queries) {
      final textQuery = q.toLowerCase().contains('london') ? q : '$q, London, UK';
      final body = {
        'textQuery': textQuery,
        'maxResultCount': limit.clamp(1, 20),
        'languageCode': 'en',
        'regionCode': 'GB',
        'locationBias': {
          'circle': {
            'center': {'latitude': biasLat, 'longitude': biasLon},
            'radius': radius,
          },
        },
      };

      final res = await _client
          .post(
            Uri.parse('https://places.googleapis.com/v1/places:searchText'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) continue;

      final places =
          (jsonDecode(res.body) as Map<String, dynamic>)['places'] as List<dynamic>? ?? [];
      for (final p in places) {
        final map = p as Map<String, dynamic>;
        final loc = map['location'] as Map<String, dynamic>? ?? {};
        final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
        final lon = (loc['longitude'] as num?)?.toDouble() ?? 0;
        final key = '${lat.toStringAsFixed(4)}:${lon.toStringAsFixed(4)}';
        if (seen.contains(key)) continue;
        seen.add(key);
        final name = (map['displayName'] as Map?)?['text']?.toString() ?? 'Location';
        final label = map['formattedAddress']?.toString() ?? name;
        out.add(
          PlaceLocation(
            lat: lat,
            lon: lon,
            label: label,
            name: name,
            category: map['primaryType']?.toString() ?? 'google_places',
            distanceM: _distM(biasLat, biasLon, lat, lon),
          ),
        );
      }
      if (out.length >= limit) break;
    }

    out.sort((a, b) => (a.distanceM ?? 999999).compareTo(b.distanceM ?? 999999));
    return out.take(limit).toList();
  }

  static List<String> _expandQueries(String raw) {
    final lower = raw.toLowerCase().trim();
    const aliases = {
      'm&s': ['marks and spencer', 'marks spencer'],
      'm & s': ['marks and spencer'],
      'ms': ['marks and spencer'],
    };
    final out = <String>[raw];
    if (aliases.containsKey(lower)) {
      out.addAll(aliases[lower]!);
    }
    final compact = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (aliases.containsKey(compact)) {
      out.addAll(aliases[compact]!);
    }
    return out.toSet().toList();
  }

  Future<PlaceLocation> reverse(double lat, double lon) async {
    if (!available) {
      return PlaceLocation(lat: lat, lon: lon, label: '$lat, $lon');
    }
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lon&key=${ApiConfig.googleMapsApiKey}&language=en',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) {
      return PlaceLocation(lat: lat, lon: lon, label: '$lat, $lon');
    }
    final results =
        (jsonDecode(res.body) as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      return PlaceLocation(lat: lat, lon: lon, label: '$lat, $lon');
    }
    final first = results.first as Map<String, dynamic>;
    final formatted = first['formatted_address']?.toString() ?? '$lat, $lon';
    return PlaceLocation(
      lat: lat,
      lon: lon,
      label: formatted,
      name: formatted.split(',').first.trim(),
    );
  }

  int _distM(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return (r * 2 * math.asin(math.sqrt(a))).round();
  }
}

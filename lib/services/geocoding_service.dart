import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/place_location.dart';

class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PlaceLocation>> search(String query) async {
    if (query.trim().length < 2) return [];
    final uri = ApiConfig.geocodeSearch(q: query.trim());
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('주소 검색 실패 (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => PlaceLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlaceLocation> reverse(double lat, double lon) async {
    final uri = ApiConfig.geocodeReverse(lat: lat, lon: lon);
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
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

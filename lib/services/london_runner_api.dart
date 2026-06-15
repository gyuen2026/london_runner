import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/route_option.dart';

class LondonRunnerApi {
  LondonRunnerApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// ③ GET /routes/recommend — 5 routes
  Future<List<RouteOption>> fetchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    double pace = 5.5,
    double dist = 5.0,
  }) async {
    final uri = ApiConfig.routesRecommend(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      pace: pace,
      dist: dist,
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('routes/recommend ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? [];
    return routes
        .map((r) => RouteOption.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// ④ GET /routes/check-status — live GPS + HR coaching
  Future<Map<String, dynamic>> checkStatus({
    required double lat,
    required double lon,
    int hr = 0,
    double pace = 0,
    double speedKmh = 0,
  }) async {
    final uri = ApiConfig.checkStatus(
      lat: lat,
      lon: lon,
      hr: hr,
      pace: pace,
      speedKmh: speedKmh,
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('check-status ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ⑤ POST /signals/report — crowd GREEN/RED for validation
  Future<void> reportSignal({
    required double lat,
    required double lon,
    required String color,
    double waitedSec = 0,
  }) async {
    final res = await _client
        .post(
          ApiConfig.signalReport(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'lat': lat,
            'lon': lon,
            'reported_color': color,
            'waited_sec': waitedSec,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('signals/report ${res.statusCode}: ${res.body}');
    }
  }
}

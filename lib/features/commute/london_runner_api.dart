import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:london_runner/config/api_config.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
class LondonRunnerApi {
  LondonRunnerApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static bool _warmedUp = false;

  /// Wake Render before green-commute (cuts cold-start wait on first GO).
  Future<void> warmup({
    bool force = false,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (_warmedUp && !force) return;
    try {
      await _client.get(ApiConfig.root()).timeout(timeout);
      _warmedUp = true;
    } catch (_) {
      // Still try green-commute — loader shows staged progress.
    }
  }

  bool _retryable(Object e) {
    final msg = e.toString();
    return msg.contains('TimeoutException') ||
        msg.contains('timed out') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('ClientException') ||
        msg.contains('Failed to fetch') ||
        msg.contains('green-commute 5') ||
        msg.contains('green-commute 502') ||
        msg.contains('green-commute 503') ||
        msg.contains('green-commute 504');
  }

  String _friendlyError(Object e, {required String endpoint}) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return 'Server waking up — tap Start again in ~30s';
    }
    if (msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException') ||
        msg.contains('Failed to fetch')) {
      return 'Cannot reach server — check network and retry';
    }
    if (msg.contains('green-commute 5')) {
      return 'Server busy — retry in a moment';
    }
    return msg.replaceFirst('Exception: ', '').replaceFirst('$endpoint ', '');
  }

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
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) {
        throw Exception('routes/recommend ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>? ?? [];
      return routes
          .map((r) => RouteOption.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_friendlyError(e, endpoint: 'routes/recommend'));
    }
  }

  /// Green Wave Commute — #1 signal accuracy mode
  Future<List<RouteOption>> fetchGreenCommute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required int arriveHour,
    required int arriveMinute,
    String commuteType = 'work',
    bool fast = true,
  }) async {
    return fetchGreenCommuteResilient(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      arriveHour: arriveHour,
      arriveMinute: arriveMinute,
      commuteType: commuteType,
      fast: fast,
    );
  }

  /// Warmup then fetch; one automatic retry after cold-start / timeout.
  Future<List<RouteOption>> fetchGreenCommuteResilient({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required int arriveHour,
    required int arriveMinute,
    String commuteType = 'work',
    bool fast = true,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await warmup(force: true);
      }
      try {
        return await _fetchGreenCommuteOnce(
          startLat: startLat,
          startLon: startLon,
          endLat: endLat,
          endLon: endLon,
          arriveHour: arriveHour,
          arriveMinute: arriveMinute,
          commuteType: commuteType,
          fast: fast,
          timeout: Duration(seconds: attempt == 0 ? 75 : 90),
        );
      } catch (e) {
        lastError = e;
        if (attempt == 1 || !_retryable(e)) rethrow;
      }
    }
    throw Exception(_friendlyError(lastError!, endpoint: 'green-commute'));
  }

  Future<List<RouteOption>> _fetchGreenCommuteOnce({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required int arriveHour,
    required int arriveMinute,
    String commuteType = 'work',
    bool fast = true,
    Duration timeout = const Duration(seconds: 75),
  }) async {
    final uri = ApiConfig.greenCommute(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      arriveHour: arriveHour,
      arriveMinute: arriveMinute,
      commuteType: commuteType,
      fast: fast,
    );
    try {
      final res = await _client.get(uri).timeout(timeout);
      if (res.statusCode != 200) {
        throw Exception('green-commute ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      final routes = data['routes'] as List<dynamic>? ?? [];
      return routes
          .map((r) => RouteOption.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_friendlyError(e, endpoint: 'green-commute'));
    }
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

  /// Crowd signal report + validation
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

  /// Background collector health (Supabase bus/signal data pipeline)
  Future<Map<String, dynamic>> fetchCollectorStatus() async {
    final res = await _client.get(ApiConfig.collectorStatus()).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('collector/status ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

/// ② API base URL — Render backend (P12606)
class ApiConfig {
  static const String baseUrl = 'https://london-runner-api.onrender.com';

  /// Client-side Google Maps / Places — pass via --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static bool get hasGoogleMaps => googleMapsApiKey.isNotEmpty;

  /// Public Flutter web — anyone can scan QR (Render /app or custom host).
  static const String webPublicUrl = String.fromEnvironment(
    'WEB_PUBLIC_URL',
    defaultValue: 'https://london-runner-api.onrender.com/app/',
  );

  static bool get hasPublicWebApp => webPublicUrl.isNotEmpty;

  static Uri root() => Uri.parse('$baseUrl/');

  static Uri routesRecommend({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    double pace = 5.5,
    double dist = 5.0,
  }) {
    return Uri.parse('$baseUrl/routes/recommend').replace(queryParameters: {
      'start_lat': startLat.toString(),
      'start_lon': startLon.toString(),
      'end_lat': endLat.toString(),
      'end_lon': endLon.toString(),
      'pace': pace.toString(),
      'dist': dist.toString(),
    });
  }

  static Uri greenCommute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required int arriveHour,
    required int arriveMinute,
    String commuteType = 'work',
    bool fast = true,
  }) {
    return Uri.parse('$baseUrl/routes/green-commute').replace(queryParameters: {
      'start_lat': startLat.toString(),
      'start_lon': startLon.toString(),
      'end_lat': endLat.toString(),
      'end_lon': endLon.toString(),
      'arrive_hour': arriveHour.toString(),
      'arrive_minute': arriveMinute.toString(),
      'commute_type': commuteType,
      'fast': fast ? '1' : '0',
    });
  }

  static Uri checkStatus({
    required double lat,
    required double lon,
    int hr = 0,
    double pace = 0,
    double speedKmh = 0,
    double? crossingLat,
    double? crossingLon,
    int? crossingIndex,
  }) {
    final params = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
      'hr': hr.toString(),
      'pace': pace.toString(),
      'speed_kmh': speedKmh.toString(),
    };
    if (crossingLat != null && crossingLon != null) {
      params['crossing_lat'] = crossingLat.toString();
      params['crossing_lon'] = crossingLon.toString();
    }
    if (crossingIndex != null) {
      params['crossing_index'] = crossingIndex.toString();
    }
    return Uri.parse('$baseUrl/routes/check-status').replace(queryParameters: params);
  }

  static Uri signalReport() => Uri.parse('$baseUrl/signals/report');

  static Uri collectorStatus() => Uri.parse('$baseUrl/collector/status');

  static Uri geocodeSearch({
    required String q,
    int limit = 25,
    double? nearLat,
    double? nearLon,
  }) {
    final params = <String, String>{
      'q': q,
      'limit': limit.toString(),
    };
    if (nearLat != null && nearLon != null) {
      params['near_lat'] = nearLat.toString();
      params['near_lon'] = nearLon.toString();
    }
    return Uri.parse('$baseUrl/geocode/search').replace(queryParameters: params);
  }

  static Uri geocodeReverse({required double lat, required double lon}) {
    return Uri.parse('$baseUrl/geocode/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });
  }

  static Uri geocodeStatus() => Uri.parse('$baseUrl/geocode/status');
}

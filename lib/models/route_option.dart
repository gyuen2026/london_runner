class RouteOption {
  RouteOption({
    required this.routeId,
    required this.name,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.signalStops,
    required this.signalWaitTotalSec,
    required this.score,
    required this.description,
    required this.polyline,
  });

  final String routeId;
  final String name;
  final double distanceKm;
  final double estimatedDurationMin;
  final int signalStops;
  final int signalWaitTotalSec;
  final double score;
  final String description;
  final List<Map<String, double>> polyline;

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    final rawPoly = json['polyline'] as List<dynamic>? ?? [];
    return RouteOption(
      routeId: json['route_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Route',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      estimatedDurationMin: (json['estimated_duration_min'] as num?)?.toDouble() ?? 0,
      signalStops: (json['signal_stops'] as num?)?.toInt() ?? 0,
      signalWaitTotalSec: (json['signal_wait_total_sec'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      polyline: rawPoly
          .map((p) => {
                'lat': (p['lat'] as num).toDouble(),
                'lon': (p['lon'] as num).toDouble(),
              })
          .toList(),
    );
  }
}

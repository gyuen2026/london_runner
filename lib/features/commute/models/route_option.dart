class RouteOption {
  RouteOption({
    required this.routeId,
    required this.name,
    required this.badge,
    required this.rank,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.signalStops,
    required this.pedSignalsOnPath,
    required this.signalWaitTotalSec,
    required this.score,
    required this.turns,
    required this.greenWaveScore,
    required this.description,
    required this.polyline,
    this.suggestedPaceMinPerKm,
    this.departAtLabel,
    this.arriveByLabel,
    this.mode,
  });

  final String routeId;
  final String name;
  final String badge;
  final int rank;
  final double distanceKm;
  final double estimatedDurationMin;
  final int signalStops;
  final int pedSignalsOnPath;
  final int signalWaitTotalSec;
  final double score;
  final int turns;
  final double greenWaveScore;
  final String description;
  final List<Map<String, double>> polyline;
  final double? suggestedPaceMinPerKm;
  final String? departAtLabel;
  final String? arriveByLabel;
  final String? mode;

  bool get isGreenCommute => mode == 'green_commute';

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    final rawPoly = json['polyline'] as List<dynamic>? ?? [];
    return RouteOption(
      routeId: json['route_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Route',
      badge: json['badge']?.toString() ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      estimatedDurationMin: (json['estimated_duration_min'] as num?)?.toDouble() ?? 0,
      signalStops: (json['signal_stops'] as num?)?.toInt() ?? 0,
      pedSignalsOnPath: (json['ped_signals_on_path'] as num?)?.toInt() ?? 0,
      signalWaitTotalSec: (json['signal_wait_total_sec'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      turns: (json['turns'] as num?)?.toInt() ?? 0,
      greenWaveScore: (json['green_wave_score'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      suggestedPaceMinPerKm: (json['suggested_pace_min_per_km'] as num?)?.toDouble(),
      departAtLabel: json['depart_at_label']?.toString(),
      arriveByLabel: json['arrive_by_label']?.toString(),
      mode: json['mode']?.toString(),
      polyline: rawPoly
          .map((p) => {
                'lat': (p['lat'] as num).toDouble(),
                'lon': (p['lon'] as num).toDouble(),
              })
          .toList(),
    );
  }
}

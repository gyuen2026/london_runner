class CrosswalkPoint {
  const CrosswalkPoint({
    required this.lat,
    required this.lon,
    required this.index,
    this.id,
  });

  final double lat;
  final double lon;
  final int index;
  final int? id;

  factory CrosswalkPoint.fromJson(Map<String, dynamic> json) {
    return CrosswalkPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      index: (json['index'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt(),
    );
  }
}

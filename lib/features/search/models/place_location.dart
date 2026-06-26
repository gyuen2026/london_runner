class PlaceLocation {
  const PlaceLocation({
    required this.lat,
    required this.lon,
    required this.label,
    this.name,
    this.distanceM,
    this.category,
  });

  final double lat;
  final double lon;
  /// Full address (Google Maps–style subtitle).
  final String label;
  final String? name;
  final int? distanceM;
  final String? category;

  /// Primary line — business / street name (never bare house number).
  String get titleLine {
    final n = name?.trim();
    if (n != null && n.isNotEmpty && !_isHouseNumberOnly(n)) return n;
    for (final part in label.split(',')) {
      final p = part.trim();
      if (p.isNotEmpty && !_isHouseNumberOnly(p)) return p;
    }
    return label.split(',').first.trim();
  }

  /// Full formatted address for list subtitle & confirmation.
  String get addressLine => label;

  String get shortLabel => titleLine;

  String get distanceLabel {
    if (distanceM == null) return '';
    if (distanceM! < 1000) return '$distanceM m';
    return '${(distanceM! / 1000).toStringAsFixed(1)} km';
  }

  static bool _isHouseNumberOnly(String s) =>
      RegExp(r'^[\d\s\-]+$').hasMatch(s.trim());

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      label: json['label']?.toString() ?? '',
      name: json['name']?.toString(),
      distanceM: (json['distance_m'] as num?)?.toInt(),
      category: json['category']?.toString(),
    );
  }
}

class PlaceLocation {
  const PlaceLocation({
    required this.lat,
    required this.lon,
    required this.label,
    this.name,
  });

  final double lat;
  final double lon;
  final String label;
  final String? name;

  String get shortLabel {
    if (name != null && name!.isNotEmpty) return name!;
    final parts = label.split(',');
    return parts.take(2).join(', ').trim();
  }

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      label: json['label']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

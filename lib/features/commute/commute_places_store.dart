import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:london_runner/features/search/models/place_location.dart';
class CommutePlacesStore {
  static const _homeKey = 'commute_home';
  static const _officeKey = 'commute_office';

  Future<PlaceLocation?> loadHome() => _load(_homeKey);
  Future<PlaceLocation?> loadOffice() => _load(_officeKey);

  Future<void> saveHome(PlaceLocation p) => _save(_homeKey, p);
  Future<void> saveOffice(PlaceLocation p) => _save(_officeKey, p);

  Future<PlaceLocation?> _load(String key) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null) return null;
    return PlaceLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _save(String key, PlaceLocation place) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      key,
      jsonEncode({
        'lat': place.lat,
        'lon': place.lon,
        'label': place.label,
        'name': place.name,
      }),
    );
  }
}

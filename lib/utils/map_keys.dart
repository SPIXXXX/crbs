import 'package:flutter/foundation.dart' show kIsWeb;

String? getMapKey() {
  // Read from compile-time environment variable. Web-injected keys are
  // intentionally ignored because web builds prefer public OSM tiles.
  const envKey = String.fromEnvironment('MAPS_API_KEY', defaultValue: '');
  return envKey.isNotEmpty ? envKey : null;
}

String getTileUrlTemplate() {
  final key = getMapKey();
  // Prefer the public OpenStreetMap tiles on web builds to avoid
  // MapTiler access/plan issues that can return HTTP 404 for some keys.
  if (kIsWeb) {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  if (key != null && key.isNotEmpty) {
    // Use MapTiler OpenStreetMap style tiles when a key is available
    return 'https://api.maptiler.com/maps/openstreetmap/{z}/{x}/{y}.png?key=$key';
  }

  return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

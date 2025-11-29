import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static const String _savedLocationsKey = 'saved_locations';
  static const String _lastLocationKey = 'last_location';

  // Save a location to the saved locations list
  static Future<void> saveLocation(LatLng location, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocations = await getSavedLocations();
    
    // Add the new location
    savedLocations.add({
      'lat': location.latitude,
      'lng': location.longitude,
      'name': name ?? 'Ubicación guardada ${savedLocations.length + 1}',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Save back to shared preferences
    await prefs.setStringList(
      _savedLocationsKey,
      savedLocations.map((loc) => _encodeLocation(loc)).toList(),
    );
  }

  // Get all saved locations
  static Future<List<Map<String, dynamic>>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locations = prefs.getStringList(_savedLocationsKey) ?? [];
    
    return locations
        .map((loc) => _decodeLocation(loc))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Save the last known user location
  static Future<void> saveLastLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastLocationKey,
      '${location.latitude},${location.longitude}',
    );
  }

  // Get the last known user location
  static Future<LatLng?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationString = prefs.getString(_lastLocationKey);
    
    if (locationString == null) return null;
    
    final parts = locationString.split(',');
    if (parts.length != 2) return null;
    
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    
    if (lat == null || lng == null) return null;
    
    return LatLng(lat, lng);
  }

  // Helper method to encode location to string
  static String _encodeLocation(Map<String, dynamic> location) {
    return '${location['lat']},${location['lng']},${location['name']},${location['timestamp']}';
  }

  // Helper method to decode location from string
  static Map<String, dynamic>? _decodeLocation(String locationString) {
    try {
      final parts = locationString.split(',');
      if (parts.length < 4) return null;
      
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      
      if (lat == null || lng == null) return null;
      
      return {
        'lat': lat,
        'lng': lng,
        'name': parts[2],
        'timestamp': parts[3],
      };
    } catch (e) {
      return null;
    }
  }
}

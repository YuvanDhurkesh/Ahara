import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationUtil {
  /// Fetches the current position of the user.
  /// Handles permission requests automatically.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return null;
    }
  }

  /// Converts coordinates into a human-readable city/area name.
  /// Uses Nominatim (OSM) HTTP API — works on Flutter Web and native.
  static Future<String?> getAddressFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'AharaApp/1.0 (com.ahara.app)',
        'Accept-Language': 'en',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Return city/town/village in decreasing specificity
          return address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['suburb'] as String? ??
              address['county'] as String? ??
              data['display_name']?.toString().split(',').first;
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    return null;
  }

  /// Calculates distance between two points in kilometers.
  static double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentLocation() async {
    // Check if permission is granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // If denied, request permission
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      debugPrint('Location permission granted');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      return position;
    } else {
      // Handle the case where permission is not granted (e.g., throw an exception)
      throw Exception('Location permission not granted');
    }
  }

  Future<LatLng?> initializeMapCenter() async {
    debugPrint('Initializing map center...');
    try {
      Position position = await getCurrentLocation();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error initializing map center: $e');
      return null; // Return null on error
    }
  }
}

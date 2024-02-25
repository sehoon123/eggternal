import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

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
      debugPrint('Location permission granted in getCurrentLocation()');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      return position;
    } else {
      // Handle the case where permission is not granted (e.g., throw an exception)
      throw Exception('Location permission not granted');
    }
  }

  Future<LatLng?> getCurrentLatLng() async {
    Position position = await getCurrentLocation();
    return LatLng(position.latitude, position.longitude);
  }

  Stream<Position> getPositionStream() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter:
          30, // Only emit a new position if the device has moved at least 30 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  void startTrackingLocation({required Function(LatLng) onLocationUpdate}) {
    _positionStreamSubscription = getPositionStream().listen(
      (Position position) {
        debugPrint('New location: ${position.latitude}, ${position.longitude}');
        debugPrint('Type of latitude: ${position.latitude.runtimeType}');
        debugPrint('Type of longitude: ${position.longitude.runtimeType}');

        onLocationUpdate(LatLng(position.latitude, position.longitude));
      },
      onError: (error) {
        debugPrint('Error getting location: $error');
      },
    );
  }

  // Method to stop tracking the user's location
  void stopTrackingLocation() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}

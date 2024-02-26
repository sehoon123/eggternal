import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eggciting/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _userLocation;
  final LocationService _locationService = LocationService();

  LatLng? get userLocation => _userLocation;

  void startTrackingLocation() {
    _locationService.startTrackingLocation(onLocationUpdate: (LatLng newPosition) {
      _userLocation = newPosition;
      notifyListeners();
    });
  }

  void stopTrackingLocation() {
    _locationService.stopTrackingLocation();
  }
}

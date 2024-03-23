
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlobalLocationData {
  static final GlobalLocationData _instance = GlobalLocationData._internal();

  // The current location stream
  final StreamController<LatLng> _locationController = StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  // The current location
  LatLng? _currentLocation;

  LatLng? get currentLocation => _currentLocation;

  set currentLocation(LatLng? location) {
    _currentLocation = location;
    if (location != null) {
      _locationController.add(location);
    }
  }

  factory GlobalLocationData() {
    return _instance;
  }

  GlobalLocationData._internal();
}

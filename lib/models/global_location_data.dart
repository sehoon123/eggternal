import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlobalLocationData {
  static final GlobalLocationData _instance = GlobalLocationData._internal();

  // The current location stream
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  // The current location
  LatLng? _currentLocation;

  LatLng? _lastKnownLocation;

  // ValueNotifier for the current location
  final ValueNotifier<LatLng?> currentLocationNotifier =
      ValueNotifier<LatLng?>(null);

  LatLng? get currentLocation => _currentLocation;

  set currentLocation(LatLng? location) {
    _currentLocation = location;
    currentLocationNotifier.value = location; // Update the ValueNotifier
    if (location != null) {
      _locationController.add(location);
      _lastKnownLocation = location;
    }
  }

  LatLng? get lastKnownLocation => _lastKnownLocation;

  factory GlobalLocationData() {
    return _instance;
  }

  GlobalLocationData._internal();
}

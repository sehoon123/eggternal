import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlobalLocationData {
  static final GlobalLocationData _instance = GlobalLocationData._internal();

  // The current location
  LatLng? currentLocation;

  factory GlobalLocationData() {
    return _instance;
  }

  GlobalLocationData._internal();
}


import 'dart:async';

import 'package:eggciting/models/user_locationl.dart';
import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  final StreamController<UserLocation> _locationController =
      StreamController<UserLocation>();

  Stream<UserLocation> get locationStream => _locationController.stream;

  LocationService() {
    location.requestPermission().then((status) {
      if (status == PermissionStatus.granted) {
        location.onLocationChanged.listen((locationData) {
          _locationController.add(UserLocation(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!,
          ));
        });
      }
    });
  }
}

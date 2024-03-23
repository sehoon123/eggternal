import 'dart:async';
import 'package:eggciting/models/user_locationl.dart';
import 'package:eggciting/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHandler {
  static const locationChannel = MethodChannel('locationPlatform');
  final _eventChannel = const EventChannel('com.dts.eggciting/location');
  StreamSubscription? subscription;
  bool useBackgroundNotifications =
      false; // This flag should be set based on user preference

  void startLocationUpdates() {
    if (useBackgroundNotifications) {
      // Existing code for background notifications
      NotificationService notificationService = NotificationService();
      subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          debugPrint('Flutter Received: $event');
          final parts = event.toString().split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              GlobalLocationData().currentLocation = LatLng(lat, lng);
              notificationService.monitorLocationAndTriggerNotification();
            }
          }
        },
        onError: (Object obj, StackTrace stackTrace) {
          debugPrint('Error: $obj');
          debugPrint('Stack: $stackTrace');
        },
      );

      try {
        locationChannel.invokeMethod('getLocation');
      } on PlatformException catch (e) {
        debugPrint('Error: ${e.message}');
      }
    } else {
      // Use LocationService for location updates
      // Assuming you have a LocationService class similar to the one described in previous responses
      LocationService locationService = LocationService();
      NotificationService notificationService = NotificationService();
      subscription = locationService.locationStream.listen(
        (UserLocation location) {
          GlobalLocationData().currentLocation =
              LatLng(location.latitude, location.longitude);
          notificationService.monitorLocationAndTriggerNotification();
          // Here you can trigger any action you need with the updated location
        },
        onError: (Object obj, StackTrace stackTrace) {
          debugPrint('Error: $obj');
          debugPrint('Stack: $stackTrace');
        },
      );
    }
  }

  void stopLocationUpdates() {
    subscription?.cancel();
  }

  void updateUseBackgroundNotifications(bool newValue) {
    useBackgroundNotifications = newValue;
    // Stop the current location updates
    stopLocationUpdates();
    // Start location updates based on the new preference
    startLocationUpdates();
  }
}

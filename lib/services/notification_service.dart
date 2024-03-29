import 'dart:async';
import 'dart:convert';

import 'package:eggciting/models/global_location_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimecapsuleLocation {
  final String id;
  final String location;
  final String username;
  final String title;
  final String dueDate;

  TimecapsuleLocation(
      {required this.id,
      required this.location,
      required this.username,
      required this.title,
      required this.dueDate});

  factory TimecapsuleLocation.fromJson(Map<String, dynamic> json) {
    return TimecapsuleLocation(
      id: json['id'],
      location: json['location'],
      username: json['username'],
      title: json['title'],
      dueDate: json['dueDate'],
    );
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Location location = Location();
  Map<String, DateTime> notifiedLocations = <String,
      DateTime>{}; // Map to track notified locations and their last notification time

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }

  Future<void> saveNotifiedLocation(String locationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifiedLocation_$locationId',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, DateTime>> getNotifiedLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, DateTime> notifiedLocations = {};

    // Retrieve all keys from SharedPreferences
    Set<String> keys = prefs.getKeys();

    // Filter keys that match the pattern 'notifiedLocation_*'
    Iterable<String> notifiedLocationKeys =
        keys.where((key) => key.startsWith('notifiedLocation_'));

    // Iterate over each key, decode the date string, and add to the map
    for (String key in notifiedLocationKeys) {
      String? storedDateString = prefs.getString(key);
      if (storedDateString != null) {
        DateTime storedDate = DateTime.parse(storedDateString);
        // Extract the locationId from the key itself
        String locationId = key.substring('notifiedLocation_'.length);
        // Add the locationId and the stored date to the map
        notifiedLocations[locationId] = storedDate;
      }
    }

    return notifiedLocations;
  }

  Future<void> monitorLocationAndTriggerNotification() async {
    // Request location permissions
    final location = GlobalLocationData().currentLocation;

    debugPrint('Current Location in monitor : $location');

    List<TimecapsuleLocation> storedLocations = await getStoredLocations();
    List<TimecapsuleLocation> nearbyLocations = [];
    Map<String, DateTime> notifiedLocations = await getNotifiedLocations();

    for (var storedLocation in storedLocations) {
      List<String> coordinates = storedLocation.location.split(',');
      double targetLatitude = double.parse(coordinates[0]);
      double targetLongitude = double.parse(coordinates[1]);

      if (isNearTargetLocation(
            location,
            targetLatitude,
            targetLongitude,
          ) &&
          (!notifiedLocations.containsKey(storedLocation.id) ||
              DateTime.now()
                      .difference(notifiedLocations[storedLocation.id]!)
                      .inHours >
                  2) &&
          DateTime.now().isAfter(DateTime.parse(storedLocation.dueDate))) {
        nearbyLocations.add(storedLocation);
        // debugPrint(
        //     'date After ${DateTime.now().isAfter(DateTime.parse(storedLocation.dueDate))}');
        await saveNotifiedLocation(storedLocation.id);
      }
    }
    if (nearbyLocations.isNotEmpty) {
      debugPrint('Nearby Locations: $nearbyLocations');
      await showNotification();
    }
  }

  bool isNearTargetLocation(
      LatLng? currentLocation, double targetLatitude, double targetLongitude) {
    // Define the threshold for "near" (e.g., 1 kilometer)
    const double nearThreshold = 300; // You can adjust this value as needed

    // Calculate the distance using GeoFirePoint.distanceBetween
    double distance = GeoFirePoint.distanceBetween(
      to: Coordinates(targetLatitude, targetLongitude),
      from: Coordinates(
          currentLocation?.latitude ?? 0.0, currentLocation?.longitude ?? 0.0),
    );

    // Check if the distance is less than or equal to the threshold
    return distance * 1000 <= nearThreshold;
  }

  Future<void> showNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await notificationsPlugin.show(0, 'Location Alert',
        'You are near the target location.', platformChannelSpecifics);
  }

  Future<List<TimecapsuleLocation>> getStoredLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<TimecapsuleLocation> locations = [];

    // Retrieve all keys from SharedPreferences
    Set<String> keys = prefs.getKeys();

    // Filter keys that match the pattern 'postDetails_*'
    Iterable<String> postDetailsKeys =
        keys.where((key) => key.startsWith('postDetails_'));

    // Iterate over each key, decode the JSON string, and add to the list
    for (String key in postDetailsKeys) {
      String? storedDetails = prefs.getString(key);
      if (storedDetails != null) {
        Map<String, dynamic> details = jsonDecode(storedDetails);
        // Extract the postKey from the key itself
        String postKey = key.substring('postDetails_'.length);
        // Create a TimecapsuleLocation object and add it to the list
        locations.add(
          TimecapsuleLocation(
            id: postKey,
            location: details['location'],
            username: details['username'],
            title: details['title'],
            dueDate: details['dueDate'],
          ),
        );
      }
    }

    return locations;
  }
}

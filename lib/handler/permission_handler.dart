import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<void> requestPermissions(BuildContext context) async {
    if (await Permission.location.isGranted &&
        await Permission.photos.isGranted) {
      // Permissions are already granted, proceed
    } else {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.photos,
        // ... Add other required permissions
      ].request();

      debugPrint(statuses.toString());

      // Handle the results of the request
      // Example: For simplicity, let's assume all permissions are mandatory
      if (statuses[Permission.location]!.isGranted &&
          statuses[Permission.photos]!.isGranted) {
        // All permissions are granted, proceed
      } else {
        if (await Permission.location.shouldShowRequestRationale ||
            await Permission.photos.shouldShowRequestRationale) {
          // Some permissions were denied. Guide the user to settings
          _showPermissionRationaleDialog(
              context); // Implement this function below
        } else {
          // Permissions are permanently denied. Guide the user to settings
          _showSettingsDialog(context); // Implement this function below
        }
      }
    }
  }

  // Implement a dialog to explain and enable manual permissions
  static void _showPermissionRationaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Needed'),
          content: const Text(
              'This app requires location and photo permissions to function properly. Please grant these permissions in your settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                requestPermissions(context);
              },
            ),
          ],
        );
      },
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Needed'),
          content: const Text(
              'This app requires location and photo permissions to function properly. Please grant these permissions in your settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings(); // Open app settings
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

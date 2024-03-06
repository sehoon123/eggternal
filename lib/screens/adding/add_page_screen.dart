import 'package:eggciting/screens/adding/map_selection_screen.dart'; // Make sure to import MapSelectionScreen
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddPageScreen extends StatefulWidget {
  const AddPageScreen({super.key});

  @override
  _AddPageScreenState createState() => _AddPageScreenState();
}

class _AddPageScreenState extends State<AddPageScreen> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedLocation != null)
              Center(
                child: Text(
                  'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Navigate to the MapSelectionScreen and wait for the result
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MapSelectionScreen()),
                );
                // Update the state with the selected location
                setState(() {
                  selectedLocation = result;
                });
              },
              child: const Text('Select Location on Map'),
            ),
          ],
        ),
      ),
    );
  }
}

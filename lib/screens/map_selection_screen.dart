import 'package:eggciting/services/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  late LocationProvider _locationProvider; // Reference to LocationProvider

  @override
  void initState() {
    super.initState();
    _locationProvider = Provider.of<LocationProvider>(context, listen: false); // Store reference
    _locationProvider.startTrackingLocation();
  }

  @override
  void dispose() {
    _locationProvider.stopTrackingLocation(); // Use stored reference
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = _locationProvider.userLocation; // Use stored reference
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: GoogleMap(
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _controller = controller;
          if (userLocation != null) {
            _controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: userLocation,
                  zoom:   14,
                ),
              ),
            );
          }
        },
        onTap: (position) {
          setState(() {
            _selectedPosition = position;
            _markers.clear();
            _markers.add(Marker(
              markerId: const MarkerId('selectedLocation'),
              position: position,
            ));
          });
        },
        markers: _markers,
        initialCameraPosition: userLocation != null
            ? CameraPosition(
                target: userLocation,
                zoom:   14,
              )
            : const CameraPosition(
                target: LatLng(0,   0), // Default location
                zoom:  14,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _selectedPosition);
        },
        child: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
}

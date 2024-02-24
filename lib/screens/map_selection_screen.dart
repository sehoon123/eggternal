import 'package:eggternal/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _initializeCenter();
  }

  void _initializeCenter() async {
    final LocationService locationService = LocationService();
    LatLng? center = await locationService.getCurrentLatLng();

    setState(() {
      _initialPosition = center;
    });

    if (center != null && _controller != null) {
      _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 14.0, // You can adjust the zoom level as needed
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: GoogleMap(
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _controller = controller;
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
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco
          zoom: 10,
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

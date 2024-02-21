import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
    _getCurrentLocation().then((position) {
      setState(() {
        _initialPosition = position;
      });
    });
  }

  Future<LatLng> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: GoogleMap(
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

import 'package:eggciting/services/location_service.dart';
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
  final LocationService locationService = LocationService();
  bool _mapCentered = false;

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  @override
  void dispose() {
    locationService.stopTrackingLocation();
    super.dispose();
  }

  void _startTrackingLocation() {
    debugPrint("Ping");
    locationService.startTrackingLocation(
        onLocationUpdate: (LatLng newPosition) {
      setState(() {
        _selectedPosition = newPosition;
        if (!_mapCentered) {
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('current Location'),
            position: newPosition,
          ));
          _controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPosition,
                zoom: 18,
              ),
            ),
          );
          _mapCentered = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: GoogleMap(
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _controller = controller;
          if (_selectedPosition != null) {
            _controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _selectedPosition!,
                  zoom: 14,
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
        initialCameraPosition: _selectedPosition != null
            ? CameraPosition(
                target: _selectedPosition!,
                zoom: 14,
              )
            : const CameraPosition(
                target: LatLng(0, 0), // San Francisco
                zoom: 14,
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

import 'dart:async';

import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/screens/adding/new_adding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  MapSelectionScreenState createState() => MapSelectionScreenState();
}

class MapSelectionScreenState extends State<MapSelectionScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  // late LocationProvider _locationProvider;
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsPlaces _places =
      GoogleMapsPlaces(apiKey: dotenv.env['androidGeoApiKey']!);
  List<Prediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // _locationProvider = Provider.of<LocationProvider>(context, listen: false);
    // _locationProvider.startTrackingLocation();
    Timer(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Location'),
            content: const Text('Please select a location on the map.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  void dispose() {
    // _locationProvider.stopTrackingLocation();
    super.dispose();
  }

  void _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }
    final response = await _places.autocomplete(query);
    setState(() {
      _predictions = response.predictions;
    });
  }

  void _moveToSearchedPlace(String placeId) async {
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 20),
      ),
    );
    setState(() {
      _selectedPosition = LatLng(lat, lng);
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selectedLocation'),
        position: LatLng(lat, lng),
      ));
    });
  }

  Future<void> _moveToCurrentUserLocation() async {
    bool serviceEnabled;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // When we reach here, permissions are granted and we can continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final userLocation = _locationProvider.userLocation;
    final userLocation = GlobalLocationData().currentLocation;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
                if (userLocation != null) {
                  _controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: userLocation,
                        zoom: 20,
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
                FocusScope.of(context).unfocus();
              },
              markers: _markers,
              initialCameraPosition: userLocation != null
                  ? CameraPosition(
                      target: userLocation,
                      zoom: 20,
                    )
                  : const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 20,
                    ),
            ),
            Positioned(
              top: 10,
              right: 15,
              left: 15,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _searchPlace,
                    onSubmitted: (value) {
                      // Check if there are any predictions
                      if (_predictions.isNotEmpty) {
                        // Use the first prediction's placeId to move the screen to that location
                        _moveToSearchedPlace(_predictions.first.placeId!);
                        // Optionally, set the search bar text to the first prediction's description
                        _searchController.clear();
                        // Clear the predictions list to hide the suggestions dropdown
                        setState(() {
                          _predictions = [];
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for a place...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                  if (_predictions.isNotEmpty)
                    Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_predictions[index].description ??
                                'No description'),
                            onTap: () {
                              _moveToSearchedPlace(
                                  _predictions[index].placeId!);
                              _searchController.clear();
                              setState(() {
                                _predictions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Bottom left floating action button
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                heroTag: "fab1",
                onPressed: _moveToCurrentUserLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
            // Bottom right floating action button
            Positioned(
              bottom: 10,
              left: 10,
              child: FloatingActionButton(
                heroTag: "fab2",
                onPressed: () {
                  if (_selectedPosition != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewAddingPage(
                          selectedLocation: _selectedPosition!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a location'),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.check),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

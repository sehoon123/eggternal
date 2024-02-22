import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:eggternal/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eggternal/screens/post_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _center = const LatLng(37.521563, 126.677433);
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    _initializeCenter();
    _initializeUserLocation();
  }

  // Function to Initialize the Map with User Location
  void _initializeCenter() async {
    final LocationService locationService = LocationService();
    LatLng? center = await locationService.initializeMapCenter();

    if (center != null) {
      setState(() {
        _center = center;
      });
    }
  }

  // Function to Initialize the User's Location
  void _initializeUserLocation() async {
    final LocationService locationService = LocationService();

    try {
      Position location = await locationService.getCurrentLocation();
      setState(() {
        userLocation = LatLng(location.latitude, location.longitude);
      });
    } catch (e) {
      debugPrint('Error initializing user location: $e');
    }
  }

  // Function when Map is Created
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              markers: snapshot.data!.docs.map((doc) {
                final post = Post.fromFirestore(doc);
                Coordinates postLocation = Coordinates(
                  post.location.latitude,
                  post.location.longitude,
                );

                double distance = userLocation != null
                    ? GeoFirePoint.distanceBetween(
                        to: postLocation,
                        from: Coordinates(
                          userLocation!.latitude,
                          userLocation!.longitude,
                        ),
                      )
                    : double.infinity;

                return Marker(
                  markerId: MarkerId(doc.id),
                  position:
                      LatLng(post.location.latitude, post.location.longitude),
                  infoWindow: InfoWindow(
                    title: post.text,
                    snippet: 'Distance: ${distance.toStringAsFixed(2)} meters',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(post: post),
                      ),
                    );
                  },
                );
              }).toSet(),
            );
          }
        },
      ),
    );
  }
}

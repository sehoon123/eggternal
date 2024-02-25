import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:eggternal/services/location_service.dart';
import 'package:eggternal/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eggternal/screens/post_details_screen.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? userLocation;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final LocationService locationService = LocationService();
  bool _mapCentered = false;

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
    _startTrackingLocation();
  }

  @override
  void dispose() {
    locationService.stopTrackingLocation();
    super.dispose();
  }

  void _startTrackingLocation() {
    locationService.startTrackingLocation(
        onLocationUpdate: (LatLng newLocation) {
      if (!_mapCentered) {
        setState(() {
          userLocation = newLocation;
          _mapCentered = true;
        });
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLocation, zoom: 12),
          ),
        );
      }
    });
  }

  // Function to Initialize the Map with User Location

  // Function to Initialize the User's Location
  void _initializeUserLocation() async {
    final LocationService locationService = LocationService();

    try {
      LatLng? location = await locationService.getCurrentLatLng();
      setState(() {
        userLocation = location;
      });
    } catch (e) {
      debugPrint('Error initializing user location: $e');
    }
  }

  // Function when Map is Created
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: userLocation ?? const LatLng(40.689167, -74.044444),
            zoom: 12),
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
        stream: Provider.of<PostsProvider>(context).postsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: userLocation ?? const LatLng(0, 0),
                zoom: 12,
              ),
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
                    snippet: 'Distance: ${distance.toStringAsFixed(2)}km',
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

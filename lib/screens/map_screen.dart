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
  late GoogleMapController _mapController;
  LatLng? _initialPosition;
  LatLng? userLocation;
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCenter();
  }

  // Function to Initialize the Map with User Location
  void _initializeCenter() async {
    final LocationService locationService = LocationService();
    LatLng? center = await locationService.getCurrentLatLng();

    debugPrint('Center: $center');

      setState(() {
        _initialPosition = center;
      });

    if (center != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 14.0, // Adjust the zoom level as needed
          ),
        ),
      );
    }
  }

  // Function when Map is Created
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
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                  target: _initialPosition ?? const LatLng(0, 0), zoom: 12),
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

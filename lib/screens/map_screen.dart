import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eggternal/screens/post_details_screen.dart'; // Make sure the path is correct

// ... Your Post Model (ensure it can handle Firestore interactions) ... 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _center = const LatLng(37.521563, 126.677433);

  // Function to Initialize the Map with User Location
  void _initCenter() async {
    Position position = await _getCurrentLocation();
    setState(() {
      _center = LatLng(position.latitude, position.longitude); 
    });
  }

  // Function to handle Current Location
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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
  void initState() {
    super.initState();
    _initCenter();
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
                return Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(post.location.latitude, post.location.longitude),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(
                          text: post.text,
                          imageUrls: post.imageUrls,
                          location: post.location,
                        ),
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

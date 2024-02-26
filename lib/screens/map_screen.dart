import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eggciting/screens/post_details_screen.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final bool _mapCentered = false;

  @override
  void initState() {
    super.initState();
    // Access the LocationProvider without listening for changes
    Provider.of<LocationProvider>(context, listen: false)
        .startTrackingLocation();
  }

  @override
  void dispose() {
    // Access the LocationProvider without listening for changes
    Provider.of<LocationProvider>(context, listen: false)
        .stopTrackingLocation();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final userLocation =
        Provider.of<LocationProvider>(context, listen: false).userLocation;
    if (userLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 12)));
    }
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
            final userLocation =
                Provider.of<LocationProvider>(context, listen: false)
                    .userLocation;
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
                          userLocation.latitude,
                          userLocation.longitude,
                        ),
                      )
                    : double.infinity;

                return Marker(
                  markerId: MarkerId(doc.id),
                  position:
                      LatLng(post.location.latitude, post.location.longitude),
                  infoWindow: InfoWindow(
                    title: post.title,
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

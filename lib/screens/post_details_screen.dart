
import 'package:eggternal/models/post.dart';
import 'package:eggternal/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late LatLng? userLocation;
  bool isLoading = true;
  final LocationService locationService = LocationService();

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
    locationService.startTrackingLocation(onLocationUpdate: (LatLng newPosition) {
      setState(() {
        userLocation = LatLng(newPosition.latitude, newPosition.longitude);
        isLoading = false;
      });
    });
  }


  // Future<void> initializeUserLocation() async {
  //   LocationService locationService = LocationService();
  //   debugPrint('Initializing user location...');

  //   try {
  //     debugPrint('location initialized:  0000');
  //     LatLng? location = await locationService.getCurrentLatLng();
  //     debugPrint('location initialized: $location');
  //     if (location != null) {
  //       setState(() {
  //         userLocation = location;
  //         isLoading = false;
  //         debugPrint('User location initialized: $userLocation');
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Error initializing user location in postDetail: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // Check if userLocation is null, show a loading indicator or handle accordingly
    double distance =  100.0; // in meters

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Coordinates postLocation = Coordinates(
      widget.post.location.latitude,
      widget.post.location.longitude,
    );

    distance = GeoFirePoint.distanceBetween(
      to: postLocation,
      from: Coordinates(userLocation!.latitude, userLocation!.longitude),
    );

    // Set your threshold distance
    double thresholdDistance =  30.0; // in meters

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.post.text),
            const SizedBox(height:  16.0),
            // Display location information
            Text(
                'Post Location: ${postLocation.latitude}, ${postLocation.longitude}'),
            // Display user's location if available
            if (userLocation == null || isLoading) ...[
              const Text('Loading user location...'),
              const LinearProgressIndicator(),
            ] else ...[
              Text(
                  'User Location: ${userLocation!.latitude}, ${userLocation!.longitude}'),
              // Display distance information
              Text('Distance from user: ${distance <=   1 ? '${(distance *  1000).toStringAsFixed(0)} meters' : '${distance.toStringAsFixed(2)} km'}'),
              // Add additional information about the location as needed
              const SizedBox(height:  16.0),
              // Replace the image view section with a map showing the post's location
              Expanded(
                child: GoogleMap(
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.post.location.latitude, widget.post.location.longitude),
                    zoom:  14.0,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('postMarker'),
                      position: LatLng(widget.post.location.latitude, widget.post.location.longitude),
                      infoWindow: InfoWindow(
                        title: 'Post Location',
                        snippet: 'This is where the post is located.',
                      ),
                    ),
                  },
                ),
              ),
              // Check if the user is within the allowed distance
              if (distance <= thresholdDistance)
                ElevatedButton(
                  onPressed: () {
                    // Implement the logic for opening the post or any other interaction
                    // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => OpenPostScreen(post: post)));
                  },
                  child: const Text('Open Post'),
                )
              else
                const Text('You are too far away to interact with this post.'),
            ],
          ],
        ),
      ),
    );
  }
}

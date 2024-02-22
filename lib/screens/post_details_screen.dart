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

  @override
  void initState() {
    super.initState();
    initializeUserLocation();
  }

  Future<void> initializeUserLocation() async {
    LocationService locationService = LocationService();
    debugPrint('Initializing user location...');

    try {
      debugPrint('location initialized: 0000');
      LatLng? location = await locationService.initializeMapCenter();
      debugPrint('location initialized: $location');
      if (location != null) {
        setState(() {
          userLocation = location;
          isLoading = false;
          debugPrint('User location initialized: $userLocation');
        });
      }
    } catch (e) {
      debugPrint('Error initializing user location in postDetail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if userLocation is null, show a loading indicator or handle accordingly
    double distance = 100.0; // in meters

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
    double thresholdDistance = 30.0; // in meters

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
            const SizedBox(height: 16.0),
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
              Text('Distance from user: $distance meters'),
              // Add additional information about the location as needed
              const SizedBox(height: 16.0),
              Expanded(
                child: widget.post.imageUrls.isNotEmpty
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        itemCount: widget.post.imageUrls.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.network(widget.post.imageUrls[index]),
                          );
                        },
                      )
                    : const Center(child: Text('No Images')),
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

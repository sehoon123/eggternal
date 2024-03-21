import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/opening/ar_test.dart';
import 'package:eggciting/screens/opening/post_view.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share/share.dart';
import 'package:provider/provider.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool _isReadyToOpen(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now());
    return difference.inDays < 0 ||
        (difference.inDays == 0 && difference.inHours <= 0);
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = GlobalLocationData().currentLocation;
    double distance = userLocation != null
        ? GeoFirePoint.distanceBetween(
            to: Coordinates(
              widget.post.location.latitude,
              widget.post.location.longitude,
            ),
            from: Coordinates(
              userLocation.latitude,
              userLocation.longitude,
            ),
          )
        : double.infinity;

    // Set your threshold distance
    double thresholdDistance = 30.0; // in meters

    // Check if the post is ready to open based on time
    bool isReadyToOpen = _isReadyToOpen(widget.post.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          IconButton(
            onPressed: () {
              Share.share('Check out this post: ${widget.post.title}');
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.title,
                style: const TextStyle(fontSize: 30.0),
              ),
              const SizedBox(height: 16.0),
              // Display user's location if available
              if (userLocation == null) ...[
                const Text('Loading user location...'),
                const LinearProgressIndicator(),
              ] else ...[
                // Display distance information
                Text(
                    'Distance from user: ${distance <= 1 ? '${(distance * 1000).toStringAsFixed(0)} meters' : '${distance.toStringAsFixed(2)} km'}'),
                // Add additional information about the location as needed
                const SizedBox(height: 16.0),
                // Replace the image view section with a map showing the post's location
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: GoogleMap(
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.post.location.latitude,
                            widget.post.location.longitude),
                        zoom: 14.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('postMarker'),
                          position: LatLng(widget.post.location.latitude,
                              widget.post.location.longitude),
                          infoWindow: const InfoWindow(
                            title: 'Post Location',
                            snippet: 'This is where the post is located.',
                          ),
                        ),
                      },
                    ),
                  ),
                ),
                // Check if the user is within the allowed distance
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  width:
                      double.infinity, // Makes the button fit the device width
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0), // Adjust the padding as needed
                    child: ElevatedButton(
                      onPressed: distance * 1000 <= thresholdDistance &&
                              isReadyToOpen
                          ? () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ARViewPage(post: widget.post)));
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (context) => DisplayPostScreen(
                              //             post: widget.post)));
                            }
                          : null, // Disables the button if distance is greater than thresholdDistance
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey; // Color for disabled state
                            }
                            return Theme.of(context)
                                .primaryColor; // Default color
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors
                                  .black; // Ensures text color is visible on grey background
                            }
                            return Colors.white; // Default text color
                          },
                        ),
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.symmetric(
                              vertical:
                                  15), // Adjust padding, making the button taller
                        ),
                      ),
                      child: const Text('Open Post'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

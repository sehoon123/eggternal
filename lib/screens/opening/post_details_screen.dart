// post_details_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/handler/location_handler.dart';
import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/opening/ar_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share/share.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  @override
  PostDetailsScreenState createState() => PostDetailsScreenState();
}

class PostDetailsScreenState extends State<PostDetailsScreen> {
  late LocationHandler _locationHandler;

  @override
  void initState() {
    super.initState();
    _locationHandler = LocationHandler();
    _locationHandler.startLocationUpdates();
  }


  @override
  void dispose() {
    _locationHandler.stopLocationUpdates();
    super.dispose();
  }

  bool _isReadyToOpen(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now());
    return difference.inDays < 0 ||
        (difference.inDays == 0 && difference.inHours <= 0);
  }

  void updatePostOpenedStatus(String postKey) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      // Handle the case where there is no current user
      return;
    }

    // Reference to the Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Reference to the current user's document
    DocumentReference userDoc =
        firestore.collection('users').doc(currentUserId);

    // Get the user's document snapshot to access the posts
    DocumentSnapshot userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      Map<String, dynamic>? userPosts =
          (userSnapshot.data() as Map<String, dynamic>?)?['posts'];

      if (userPosts != null && userPosts.containsKey(postKey)) {
        // If the regular post exists, update its isOpened field
        debugPrint('Updating post $postKey to be opened.');
        await userDoc.update({
          'posts.$postKey.isOpened': true,
        });
      } else if (userPosts != null &&
          userPosts.containsKey('shared_$postKey')) {
        // If the shared post exists, update its isOpened field
        debugPrint('Updating shared post $postKey to be opened.');
        await userDoc.update({
          'posts.shared_$postKey.isOpened': true,
        });
      } else {
        // Handle the case where neither document exists
        debugPrint(
            "Neither regular nor shared post exists for key: $postKey under user: $currentUserId");
      }
    } else {
      // Handle the case where the user document does not exist
      debugPrint("User document does not exist for user: $currentUserId");
    }
  }

  Future<String> createDynamicLink(Post post) async {
    Map<String, dynamic> postMap = post.toJson();
    postMap['location'] = {
      'geopoint': {
        'latitude': post.location.latitude,
        'longitude': post.location.longitude,
      },
    };
    debugPrint(
        'lat, long: ${post.location.latitude}, ${post.location.longitude}');
    // Create BranchLinkProperties with the desired properties
    BranchLinkProperties linkProperties = BranchLinkProperties(
      channel: 'facebook', // The channel through which the link was shared
      feature: 'sharing', // The feature that the link is associated with
      alias: 'post-${post.key}', // A unique alias for the link
      stage: 'new user', // The stage of the user's lifecycle
      matchDuration:
          43200, // The duration in seconds for which the link should be matched
      tags: ['post', 'share'], // Tags associated with the link
      campaign:
          'post sharing campaign', // The campaign associated with the link
    );

    // Add any additional control parameters if needed
    linkProperties.addControlParam('post', jsonEncode(postMap));

    // Create a BranchUniversalObject for the post
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'content/${post.key}',
      title: 'Check out this post!',
      contentDescription: 'This is a great post you should check out.',
      imageUrl: 'https://example.com/post-image.jpg',
      contentMetadata: BranchContentMetaData()
        ..addCustomMetadata('post', jsonEncode(postMap)),
    );

    // Create the dynamic link
    BranchResponse link = await FlutterBranchSdk.getShortUrl(
      buo: buo,
      linkProperties: linkProperties,
    );

    return link.result;
  }

  @override
  Widget build(BuildContext context) {
    // Set your threshold distance
    double thresholdDistance = 50.0; // in meters

    // Check if the post is ready to open based on time
    bool isReadyToOpen = _isReadyToOpen(widget.post.dueDate);

    return StreamBuilder<LatLng>(
        stream: GlobalLocationData().locationStream,
        builder: (context, snapshot) {
          final userLocation = snapshot.data;
          final lastKnownLocation = GlobalLocationData().lastKnownLocation;
          final locationToUse = userLocation ?? lastKnownLocation;

          double distance = locationToUse != null
              ? GeoFirePoint.distanceBetween(
                  to: Coordinates(
                    widget.post.location.latitude,
                    widget.post.location.longitude,
                  ),
                  from: Coordinates(
                    locationToUse.latitude,
                    locationToUse.longitude,
                  ),
                )
              : double.infinity;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Post Details'),
              actions: [
                IconButton(
                  onPressed: () async {
                    String dynamicLink = await createDynamicLink(widget.post);
                    Share.share('Check out this post: $dynamicLink');
                  },
                  icon: const Icon(Icons.share),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Updating the distance will trigger a rebuild
                      distance = locationToUse != null
                          ? GeoFirePoint.distanceBetween(
                              to: Coordinates(
                                widget.post.location.latitude,
                                widget.post.location.longitude,
                              ),
                              from: Coordinates(
                                locationToUse.latitude,
                                locationToUse.longitude,
                              ),
                            )
                          : double.infinity;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        widget.post.title,
                        style: const TextStyle(fontSize: 30.0),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Display user's location if available
                    if (locationToUse == null) ...[
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
                                position: LatLng(
                                    widget.post.location.latitude,
                                    widget.post.location.longitude),
                                infoWindow: const InfoWindow(
                                  title: 'Post Location',
                                  snippet:
                                      'This is where the post is located.',
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
                        width: double.infinity,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (distance * 1000 <= thresholdDistance &&
                                  isReadyToOpen) {
                                updatePostOpenedStatus(widget.post.key);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ARViewPage(post: widget.post),
                                  ),
                                );
                              } else {
                                if (distance * 1000 > thresholdDistance &&
                                    !isReadyToOpen) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You are too far from the location and the post is not ready to open yet.'),
                                    ),
                                  );
                                } else if (distance * 1000 >
                                    thresholdDistance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You are too far from the location.'),
                                    ),
                                  );
                                } else if (!isReadyToOpen) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'The post is not ready to open yet.'),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (distance * 1000 > thresholdDistance ||
                                      !isReadyToOpen) {
                                    return Colors.grey;
                                  }
                                  return Theme.of(context).primaryColor;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (distance * 1000 > thresholdDistance ||
                                      !isReadyToOpen) {
                                    return Colors.black;
                                  }
                                  return Colors.white;
                                },
                              ),
                              padding: MaterialStateProperty.all<
                                  EdgeInsetsGeometry>(
                                const EdgeInsets.symmetric(vertical: 15),
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
        });
  }
}

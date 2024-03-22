import 'dart:convert';

import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/opening/post_details_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsProvider>(context, listen: false).fetchPosts();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // debugPrintSharedPreferences();
    // Removed _scrollController.addListener(_onScroll); as it's not needed for non-lazy loading
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> createDynamicLink(String postId) async {
    // Create BranchLinkProperties with the desired properties
    BranchLinkProperties linkProperties = BranchLinkProperties(
      channel: 'facebook', // The channel through which the link was shared
      feature: 'sharing', // The feature that the link is associated with
      alias: 'post-$postId', // A unique alias for the link
      stage: 'new user', // The stage of the user's lifecycle
      matchDuration:
          43200, // The duration in seconds for which the link should be matched
      tags: ['post', 'share'], // Tags associated with the link
      campaign:
          'post sharing campaign', // The campaign associated with the link
    );

    // Add any additional control parameters if needed
    linkProperties.addControlParam(postId, 'postId');

    // Create a BranchUniversalObject for the post
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'content/$postId',
      title: 'Check out this post!',
      contentDescription: 'This is a great post you should check out.',
      imageUrl: 'https://example.com/post-image.jpg',
      contentMetadata: BranchContentMetaData()
        ..addCustomMetadata('postId', postId),
    );

    // Create the dynamic link
    BranchResponse link = await FlutterBranchSdk.getShortUrl(
      buo: buo,
      linkProperties: linkProperties,
    );

    return link.result;
  }

  void debugPrintSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getKeys().forEach((key) {
      debugPrint('$key: ${prefs.get(key)}');
    });
  }

  Future<String> _getUsername(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString('nickname_$userId');

    if (nickname != null) {
      return nickname;
    } else {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        nickname = userDoc.data()!['nickname'];
        await prefs.setString('nickname_$userId', nickname!);
        return nickname;
      } else {
        return 'Unknown User';
      }
    }
  }

  double _calculateDistance(GeoFirePoint postLocation) {
    final userLocation = GlobalLocationData().currentLocation;
    if (userLocation != null) {
      return postLocation.distance(
        lat: userLocation.latitude,
        lng: userLocation.longitude,
      );
    } else {
      return -1;
    }
  }

  String _calculateTimeLeft(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (dueDate.isBefore(now)) {
      return "Ready to Open";
    } else if (difference.inDays == 0) {
      final hours = difference.inHours;
      return 'about $hours hours left';
    } else {
      return 'about ${difference.inDays} days left';
    }
  }

  Future<Map<String, dynamic>?> _storeAndRetrievePostDetails(
    String postKey,
    GeoFirePoint postLocation,
    String username,
    String title,
    DateTime dueDate,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDetails = prefs.getString('postDetails_$postKey');

    if (storedDetails != null) {
      // Assuming the stored location is a string representation of GeoFirePoint
      // You might need to adjust this based on how you're storing the location
      Map<String, dynamic> details = jsonDecode(storedDetails);
      return details;
    } else {
      Map<String, dynamic> details = {
        'location': '${postLocation.latitude},${postLocation.longitude}',
        'username': username,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
      };
      await prefs.setString('postDetails_$postKey', jsonEncode(details));
      return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<PostsProvider>(context, listen: false).fetchPosts();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (postsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ToggleButtons(
                    isSelected: [
                      postsProvider.isMyPostsSelected,
                      !postsProvider.isMyPostsSelected
                    ],
                    onPressed: (index) {
                      Provider.of<PostsProvider>(context, listen: false)
                          .togglePostsView();
                    },
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Theme.of(context).primaryColor,
                    renderBorder: true,
                    constraints: const BoxConstraints(
                      minWidth: 100,
                      minHeight: 36,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('My Posts'),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Shared Posts'),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: postsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          postsProvider.isMyPostsSelected
                              ? '${postsProvider.postCount} posts'
                              : '${postsProvider.sharedPostCount} shared posts',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: postsProvider.posts.length,
                    itemBuilder: (context, index) {
                      final post = postsProvider.posts[index];
                      final timeLeft = _calculateTimeLeft(post.dueDate);

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _storeAndRetrievePostDetails(
                          post.key,
                          post.location,
                          post.userId,
                          post.title,
                          post.dueDate,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return ListTile(
                              leading: const CircularProgressIndicator(),
                              title: Text(post.title),
                              subtitle: const Text('Loading post details...'),
                            );
                          } else if (snapshot.hasError) {
                            return ListTile(
                              leading: const Icon(Icons.error),
                              title: Text(post.title),
                              subtitle:
                                  const Text('Error loading post details'),
                            );
                          } else {
                            final details = snapshot.data;
                            final postLocation = GeoFirePoint(
                              double.parse(details!['location'].split(',')[0]),
                              double.parse(details['location'].split(',')[1]),
                            );
                            final userLocation =
                                GlobalLocationData().currentLocation;
                            final distance = userLocation != null
                                ? _calculateDistance(postLocation)
                                : -1;

                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: timeLeft == 'Ready to Open'
                                        ? Colors.green[100]
                                        : Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                  ),
                                  child: FutureBuilder<String>(
                                    future: _getUsername(details['username']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return ListTile(
                                          leading: CircleAvatar(
                                            child: Text(
                                                snapshot.data!.substring(0, 1)),
                                          ),
                                          title: Text(details['title']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('User: ${snapshot.data}'),
                                              Text(
                                                  'Distance: ${distance > 1 ? '${distance.toStringAsFixed(2)} km' : '${(distance * 1000).toStringAsFixed(0)} m'}'),
                                              Text('Time Left: $timeLeft'),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.share),
                                            onPressed: () async {
                                              String dynamicLink =
                                                  await createDynamicLink(
                                                      post.key);
                                              Share.share(
                                                  'Check out this post: $dynamicLink');
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PostDetailsScreen(
                                                        post: post),
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return ListTile(
                                          leading:
                                              const CircularProgressIndicator(),
                                          title: Text(details['title']),
                                          subtitle:
                                              const Text('Loading username...'),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

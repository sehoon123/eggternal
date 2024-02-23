import 'package:eggternal/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:eggternal/screens/post_details_screen.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Position? _currentPosition;

  final int _postCount = 0;
  final int _sharedPostCount = 0;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _loadPostCount();
    _determineCurrentPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsProvider>(context, listen: false).fetchPosts();
    });
  }

  void _determineCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('Current position: $position');

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Handle the error, possibly by requesting location permissions
      // or guiding the user to enable location services.
    }
  }

  // Assuming Firebase for user data, modify as needed
  Future<String> _getUsername(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // debugPrint('getUsername success');
    // debugPrint('userDoc: ${userDoc.data()}');
    return userDoc.data()!['nickname'];
  }

  double _calculateDistance(GeoFirePoint postLocation) {
    if (_currentPosition != null) {
      return postLocation.distance(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );
    } else {
      return -1;
    }
  }

  String _calculateTimeLeft(Timestamp dueDate) {
    final difference = dueDate.toDate().difference(DateTime.now());
    return 'about ${difference.inDays} days left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: Consumer<PostsProvider>(
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
                  borderRadius: BorderRadius.circular(8.0),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  renderBorder: true,
                  constraints:
                      const BoxConstraints(minHeight: 36, minWidth: 100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('My Posts'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Shared Posts'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: postsProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        postsProvider.isMyPostsSelected
                            ? '${postsProvider.postCount} images'
                            : '${postsProvider.sharedPostCount} images',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: postsProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = postsProvider.posts[index];
                    final distance = _currentPosition != null
                        ? _calculateDistance(post.location)
                        : -1;
                    final timeLeft = _calculateTimeLeft(post.dueDate);

                    return FutureBuilder<String>(
                        future: _getUsername(post.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return ListTile(
                              leading: const CircularProgressIndicator(),
                              title: Text(post.text),
                              subtitle: const Text('Loading user nickname...'),
                            );
                          } else if (snapshot.hasError) {
                            return ListTile(
                              leading: const Icon(Icons.error),
                              title: Text(post.text),
                              subtitle:
                                  const Text('Error loading user nickname'),
                            );
                          } else {
                            return ListTile(
                              leading: CircleAvatar(
                                  child: Text(snapshot.data!.substring(0, 1))),
                              title: Text(post.text),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'User: ${snapshot.data}'), // Assuming you want to display the user ID for simplicity
                                  Text(
                                      'Distance: ${distance > 1 ? '${distance.toStringAsFixed(2)} km' : '${(distance * 1000).toStringAsFixed(0)} m'}'),
                                  Text('Time Left: $timeLeft'),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailsScreen(
                                      post: post,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/post_details_screen.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Fetch more posts 200 pixels before reaching the bottom
      Provider.of<PostsProvider>(context, listen: false).fetchPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        // Store the fetched nickname in shared_preferences with a unique key
        await prefs.setString('nickname_$userId', nickname!);
        return nickname;
      } else {
        // Handle the case where the user document does not exist
        // You might want to return a default value or show an error message
        return 'Unknown User';
      }
    }
  }

  double _calculateDistance(GeoFirePoint postLocation) {
    final userLocation =
        Provider.of<LocationProvider>(context, listen: false).userLocation;
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

    // Check if the due date is in the past
    if (dueDate.isBefore(now)) {
      // If the due date is today but earlier, show "Ready to Open"
      if (dueDate.day == now.day &&
          dueDate.month == now.month &&
          dueDate.year == now.year) {
        return "Ready to Open";
      } else {
        // If the due date is before today, show how many days ago
        final daysAgo = -difference.inDays; // Make positive for display
        return '$daysAgo days ago';
      }
    } else if (difference.inDays == 0) {
      // When the difference is less than a day, show hours left
      final hours = difference.inHours;
      return 'about $hours hours left';
    } else {
      // For more than one day, show days left
      return 'about ${difference.inDays} days left';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
        ),
        body: Consumer<PostsProvider>(builder: (context, postsProvider, child) {
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
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: postsProvider.posts.length,
                  itemBuilder: (context, index) {
                    // debugPrint("building list item $index");
                    if (index >= postsProvider.posts.length) {
                      return postsProvider.hasMorePosts
                          ? const Center(child: CircularProgressIndicator())
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Center(
                                  child: Text('You have reached the end')),
                            );
                    }
                    final post = postsProvider.posts[index];
                    final timeLeft = _calculateTimeLeft(post.dueDate);

                    return FutureBuilder<String>(
                      future: _getUsername(post.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return ListTile(
                            leading: const CircularProgressIndicator(),
                            title: Text(post.title),
                            subtitle: const Text('Loading user nickname...'),
                          );
                        } else if (snapshot.hasError) {
                          return ListTile(
                            leading: const Icon(Icons.error),
                            title: Text(post.title),
                            subtitle: const Text('Error loading user nickname'),
                          );
                        } else {
                          final userLocation = Provider.of<LocationProvider>(
                                  context,
                                  listen: false)
                              .userLocation;
                          final distance = userLocation != null
                              ? _calculateDistance(post.location)
                              : -1;

                          return ListTile(
                            leading: CircleAvatar(
                                child: Text(snapshot.data!.substring(0, 1))),
                            title: Text(post.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User: ${snapshot.data}'),
                                Text(
                                    'Distance: ${distance > 1 ? '${distance.toStringAsFixed(2)} km' : '${(distance * 1000).toStringAsFixed(0)} m'}'),
                                Text('Time Left: $timeLeft'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () {
                                // Share the post
                                Share.share(
                                  'Check out this post: ${post.title}',
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailsScreen(post: post),
                                ),
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                ),
              )
            ],
          );
        }));
  }
}

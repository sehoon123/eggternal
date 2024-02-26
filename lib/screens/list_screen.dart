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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsProvider>(context, listen: false).fetchPosts();
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
    final difference = dueDate.difference(DateTime.now());
    return difference.inDays < 0
        ? "Ready to Open"
        : 'about ${difference.inDays} days left';
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
              // ... (other widgets)
              Expanded(
                child: ListView.builder(
                  itemCount: postsProvider.posts.length,
                  itemBuilder: (context, index) {
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

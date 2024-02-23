import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:eggternal/screens/post_details_screen.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Position? _currentPosition;

  final List<Post> _posts = [];
  List<double> _postDistances = [];

  bool isMyPostsSelected = true; // Default to show My Posts
  int _postCount = 0;
  int _sharedPostCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostCount();
    _determineCurrentPosition();
    _getPosts();
  }

  void _determineCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distances for all posts
      final List<double> distances = [];
      for (final post in _posts) {
        distances.add(await _calculateDistance(post.location, position));
      }

      setState(() {
        _currentPosition = position;
        _postDistances = distances;
      });
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  Future<double> _calculateDistance(
      GeoFirePoint postLocation, Position userPosition) async {
    return postLocation.distance(
      lat: userPosition.latitude,
      lng: userPosition.longitude,
    );
  }

  void _loadPostCount() async {
    setState(() {
      _isLoading = true;
    });

    final posts =
        isMyPostsSelected ? await _getPosts() : await _getSharedPosts();
    final postCount = posts.length;

    setState(() {
      _isLoading = false;
      _postCount = postCount;
      _sharedPostCount = postCount;
    });
  }

  Future<List<Post>> _getPosts() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: currentUser!.uid)
        .get();

    return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  Future<List<Post>> _getSharedPosts() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('sharedUser', isEqualTo: currentUser!.uid)
        .get();

    return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  Future<Map<String, String>> _getUsernames(List<String> userIds) async {
    final Map<String, String> usernames = {};

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    for (final doc in querySnapshot.docs) {
      usernames[doc.id] = doc.data()['nickname'];
    }

    return usernames;
  }

  // Assuming Firebase for user data, modify as needed
  Future<String> _getUsername(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // debugPrint('getUsername success');
    // debugPrint('userDoc: ${userDoc.data()}');
    return userDoc.data()!['nickname'];
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ToggleButtons(
              isSelected: [isMyPostsSelected, !isMyPostsSelected],
              onPressed: (index) {
                setState(() {
                  isMyPostsSelected = index == 0;
                  debugPrint(isMyPostsSelected.toString());
                  _loadPostCount();
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: Colors.white,
              fillColor: Theme.of(context).primaryColor,
              renderBorder: true,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    isMyPostsSelected
                        ? '$_postCount images'
                        : '$_sharedPostCount images',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where(
                    isMyPostsSelected ? 'userId' : 'sharedUser',
                    isEqualTo: currentUser!.uid,
                  )
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  List<Post> posts = snapshot.data!.docs
                      .map((doc) => Post.fromFirestore(doc))
                      .toList();
                  for (var post in posts) {
                    debugPrint('Post: ${post.text}');
                  }
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder(
                          future: Future.wait([
                            _getUsername(posts[index].userId),
                            _calculateDistance(
                                posts[index].location, _currentPosition!),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // debugPrint('waiting for future to complete');
                              return const Center(
                                // child: CircularProgressIndicator());
                                child: LinearProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Text('Error loading data'),
                              );
                            }

                            final username = snapshot.data![0] as String;
                            final distance = snapshot.data![1] as double;
                            final timeLeft =
                                _calculateTimeLeft(posts[index].dueDate);

                            return ListTile(
                              leading: CircleAvatar(
                                  child: Text(username.substring(0, 1))),
                              title: Text(posts[index].text),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('User: $username'),
                                  Text(
                                      'Distance: ${distance.toStringAsFixed(2)} meters'),
                                  Text('Time Left: $timeLeft'),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailsScreen(
                                      post: posts[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          });
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
  bool isMyPostsSelected = true; // Default to show My Posts

  int _postCount = 0;
  int _sharedPostCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostCount();
  }

  void _loadPostCount() async {
    setState(() {
      _isLoading = true;
    });

    final count =
        isMyPostsSelected ? await _getPostCount() : await _getSharedPostCount();

    setState(() {
      _isLoading = false;
      _postCount = count;
      _sharedPostCount = count;
    });
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  List<Post> posts = snapshot.data!.docs
                      .map((doc) => Post.fromFirestore(doc))
                      .toList();
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder(
                          future: Future.wait([
                            _getUsername(posts[index].userId),
                            _calculateDistance(posts[index].location),
                          ]),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
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

  Future<int> _getPostCount() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where(
          isMyPostsSelected ? 'userId' : 'sharedUser',
          isEqualTo: currentUser!.uid,
        )
        .get();

    return querySnapshot.size;
  }

  Future<int> _getSharedPostCount() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where(
          'sharedUser',
          isEqualTo: currentUser!.uid,
          // arrayContains: currentUser!.uid,
        ) // Target shared posts
        .get();

    // print currentUser!.uid
    debugPrint(currentUser!.uid);

    return querySnapshot.size;
  }

  // Assuming Firebase for user data, modify as needed
  Future<String> _getUsername(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    debugPrint('getUsername success');
    debugPrint('userDoc: ${userDoc.data()}');
    return userDoc
        .data()!['nickname']; // Replace 'username' with the correct field
  }

  Future<double> _calculateDistance(GeoFirePoint postLocation) async {
    final myLocation = await Geolocator.getCurrentPosition();
    debugPrint('calculateDistance success');
    return postLocation.distance(
        lat: myLocation.latitude, lng: myLocation.longitude);
  }

  String _calculateTimeLeft(Timestamp dueDate) {
    // ... Your logic to determine the time left
    // Example:
    final difference = dueDate.toDate().difference(DateTime.now());
    return 'about ${difference.inDays} days left';
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/models/post.dart';
import 'package:eggternal/screens/post_details_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool isMyPostsSelected = true; // Default to show My Posts

  int _postCount = 0;
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
                    '$_postCount images',
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
                    isMyPostsSelected ? 'userId' : 'sharedUserId',
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
                      return ListTile(
                        title: Text(posts[index].text),
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
          isMyPostsSelected ? 'userId' : 'sharedUserId',
          isEqualTo: currentUser!.uid,
        )
        .get();

    return querySnapshot.size;
  }

  Future<int> _getSharedPostCount() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('sharedUserId',
            isEqualTo: currentUser!.uid) // Target shared posts
        .get();

    return querySnapshot.size;
  }
}

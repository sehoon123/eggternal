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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .snapshots(), // Adjust the collection name if needed
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
                        text: posts[index].text,
                        imageUrls: posts[index].imageUrls,
                        location: posts[index].location,
                      ),
                    ),
                  );
                });
              },
            );
          }
        },
      ),
    );
  }
}

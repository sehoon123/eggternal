import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  Future<void> updateDB() async {
    try {
      // Get all the posts from the 'posts' collection
      final querySnapshot = await FirebaseFirestore.instance.collection('posts').get();

      // Iterate over each post document
      for (final doc in querySnapshot.docs) {
        final postData = doc.data();
        final post = Post.fromJson(postData);

        // Create a map representing the post data
        Map<String, dynamic> postMap = post.toJson();

        // Get a reference to the user document
        DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(post.userId);

        // Update the user document by adding the post data to the 'posts' map field
        await userDoc.update({
          'posts.${post.key}': postMap,
        });
      }

      debugPrint('Database updated successfully');
    } catch (e) {
      debugPrint('Error updating database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Payment'),
      // ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ElevatedButton(
              //   onPressed: () async {
              //     await updateDB();
              //   },
              //   child: const Text('update db'),
              // ),
              ElevatedButton(
                onPressed: () async {
                  debugPrint('Go to Google');
                  final url = Uri.parse('https://www.google.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: const Text('Go to Google'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse('https://www.youtube.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: const Text('Go to YouTube'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

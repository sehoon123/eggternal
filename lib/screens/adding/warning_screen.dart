import 'dart:convert';
import 'dart:io';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/adding/post_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class WarningScreen extends StatefulWidget {
  final Post post;

  const WarningScreen({
    super.key,
    required this.post,
  });

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  Future<void>? _uploadPostFuture;

  Future<String> _uploadFile(File file) async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    // Create a reference to the file location in Firebase Storage
    Reference ref = FirebaseStorage.instance
        .ref('user_data/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}');

    // Upload the file to Firebase Storage
    UploadTask uploadTask = ref.putFile(file);

    // Wait for the upload to complete
    await uploadTask;

    // Get the download URL of the uploaded file
    String downloadURL = await ref.getDownloadURL();

    return downloadURL;
  }

  Future<void> _uploadPost() async {
    var uuid = const Uuid();
    String key = uuid.v4();

    // Upload images to Firebase Storage and get their download URLs
    Map<String, String> imagePathToUrlMap = {};
    for (String imagePath in widget.post.imageUrls) {
      File imageFile = File(imagePath);
      // Upload the image to Firebase Storage
      String imageUrl = await _uploadFile(imageFile);
      imagePathToUrlMap[imagePath] =
          imageUrl; // Map the local path to the Firebase URL
    }

    // Replace the local image paths in the contentDelta with the Firebase Storage URLs
    List<dynamic> contentDeltaList = jsonDecode(widget.post.contentDelta);
    for (var item in contentDeltaList) {
      if (item is Map && item.containsKey('insert') && item['insert'] is Map) {
        Map<String, dynamic> insertMap = item['insert'] as Map<String, dynamic>;
        if (insertMap.containsKey('image') &&
            imagePathToUrlMap.containsKey(insertMap['image'])) {
          insertMap['image'] = imagePathToUrlMap[insertMap[
              'image']]!; // Replace the local path with the Firebase URL
        }
      }
    }
    String updatedContentDelta = jsonEncode(contentDeltaList);

    // Add the post to Firestore with the updated contentDelta
    await FirebaseFirestore.instance.collection('posts').doc(key).set({
      'key': key,
      'title': widget.post.title,
      'contentDelta': updatedContentDelta, // Use the updated contentDelta
      'dueDate': widget.post.dueDate,
      'createdAt': widget.post.createdAt,
      'location': GeoPoint(
          widget.post.location.latitude, widget.post.location.longitude),
      'imageUrls':
          imagePathToUrlMap.values.toList(), // Use the list of Firebase URLs
      'userId': widget.post.userId,
      'sharedUser': widget.post.sharedUser,
      // Add any other necessary fields
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await removeAllLocationPrefs(); // Remove all location prefs
    // await prefs.setString('location_$key',
    //     '${widget.post.location.latitude},${widget.post.location.longitude}');
  }

  Future<void> removeAllLocationPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Get all keys
    Set<String> keys = prefs.getKeys();
    // Iterate over the keys
    for (String key in keys) {
      // Check if the key starts with 'location_'
      if (key.startsWith('location_')) {
        // Remove the key
        await prefs.remove(key);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warning'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You can\'t modify this post after posting.'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _uploadPostFuture = _uploadPost();
                      });
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
            ),
            if (_uploadPostFuture != null)
              FutureBuilder(
                future: _uploadPostFuture,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    // Navigate to the PostSuccessScreen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PostSuccessScreen(
                              imageAssetPaths: [
                                'assets/images/logo.png'
                              ]), // Replace with actual image paths
                        ),
                      );
                    });
                    return Container(); // Return an empty container when not uploading
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:eggciting/screens/post_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class WarningScreen extends StatelessWidget {
  final String title;
  final String content;
  final DateTime dueDate;
  final List<File> images; // Assuming you're passing a list of File objects
  final LatLng? selectedLocation; // Add this line

  const WarningScreen({
    super.key,
    required this.title,
    required this.content,
    required this.dueDate,
    required this.images,
    this.selectedLocation, // Update this line
  });

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
    // Upload images to Firebase Storage and get their download URLs
    List<String> imageUrls = [];
    for (File image in images) {
      String imageUrl = await _uploadFile(image);
      imageUrls.add(imageUrl);
    }

    // Add the post to Firestore
    await FirebaseFirestore.instance.collection('posts').add({
      'title': title,
      'content': content,
      'dueDate': dueDate,
      'createdAt': DateTime.now(),
      'location': GeoPoint(selectedLocation!.latitude,
          selectedLocation!.longitude), // Add this line
      'imageUrls': imageUrls,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'sharedUser': [], // Add this line
      // Add any other necessary fields
      // Optionally, you can add the selected location here if you want to store it
      // 'location': selectedLocation?.toJson(), // Assuming LatLng has a toJson method
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warning'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You can\'t modify this post after posting.'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Upload the post
                await _uploadPost();

                // Navigate to the PostSuccessScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostSuccessScreen(
                        imageAssetPaths: [
                          'assets/images/logo.png'
                        ]), // Replace with actual image paths
                  ),
                );
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

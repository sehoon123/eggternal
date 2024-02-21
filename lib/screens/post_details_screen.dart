import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  final String text;
  final List<String> imageUrls;
  final GeoPoint location; // Assuming you have the location

  const PostDetailsScreen({
    super.key,
    required this.text,
    required this.imageUrls,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 16.0),
            Expanded(
              child: imageUrls.isNotEmpty
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Adjust as needed
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Image.network(imageUrls[index]),
                        );
                      },
                    )
                  : const Center(child: Text('No Images')),
            ),

            // Add display of location information if desired
          ],
        ),
      ),
    );
  }
}

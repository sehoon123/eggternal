import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String text;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final String userId;
  final GeoPoint location; // Assuming you're using GeoPoint for geolocation

  Post({
    required this.text, 
    required this.imageUrls, 
    required this.createdAt, 
    required this.userId,
    required this.location,
  });

  // Add a factory method to create a Post from a Firestore DocumentSnapshot 
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      text: data['text'],
      imageUrls: List<String>.from(data['imageUrls']),
      createdAt: data['createdAt'],
      userId: data['userId'],
      location: data['location'],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class Post {
  final String text;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final String userId;
  final GeoFirePoint location;
  final Timestamp dueDate;
  final String sharedUser;

  Post({
    required this.text,
    required this.imageUrls,
    required this.createdAt,
    required this.userId,
    required this.location,
    required this.dueDate,
    required this.sharedUser,
  });

  // Add a factory method to create a Post from a Firestore DocumentSnapshot
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      text: data['text'],
      imageUrls: List<String>.from(data['imageUrls']),
      createdAt: data['createdAt'],
      userId: data['userId'],
      location:
          GeoFirePoint(data['location'].latitude, data['location'].longitude),
      dueDate: data['dueDate'],
      sharedUser: data['sharedUser'],
    );
  }
}

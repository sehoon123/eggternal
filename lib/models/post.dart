import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class Post {
  final String title;
  final String content;
  final DateTime dueDate;
  final DateTime createdAt;
  final String userId;
  final GeoFirePoint location;
  final List<String> imageUrls;
  final List<String> sharedUser;

  Post({
    required this.title,
    required this.content,
    required this.dueDate,
    required this.createdAt,
    required this.userId,
    required this.location,
    required this.imageUrls,
    required this.sharedUser,
  });

  // Add a factory method to create a Post from a Firestore DocumentSnapshot
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      title: data['title'],
      content: data['content'],
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'],
      location: GeoFirePoint(data['location'].latitude, data['location'].longitude),
      imageUrls: List<String>.from(data['imageUrls']),
      sharedUser: List<String>.from(data['sharedUser']),
    );
  }
}

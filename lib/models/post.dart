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

    String title = data['title'] ?? 'No Title';
    String content = data['content'] ?? 'No Content';
    DateTime dueDate = data['dueDate'] != null
        ? (data['dueDate'] as Timestamp).toDate()
        : DateTime.now();
    DateTime createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    String userId = data['userId'] ?? 'No User ID';
    GeoFirePoint location = data['location'] != null
        ? GeoFirePoint(data['location'].latitude, data['location'].longitude)
        : GeoFirePoint(0, 0);
    List<String> imageUrls =
        data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [];
    List<String> sharedUser =
        data['sharedUser'] != null ? List<String>.from(data['sharedUser']) : [];

    return Post(
      title: title,
      content: content,
      dueDate: dueDate,
      createdAt: createdAt,
      userId: userId,
      location: location,
      imageUrls: imageUrls,
      sharedUser: sharedUser,
    );
  }
}

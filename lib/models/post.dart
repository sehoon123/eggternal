import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class Post {
  final String key;
  final String title;
  final String contentDelta; // Store the rich text content as a JSON string
  final DateTime dueDate;
  final DateTime createdAt;
  final String userId;
  final GeoFirePoint location;
  final List<String> imageUrls;
  final List<String> sharedUser;

  Post({
    required this.key,
    required this.title,
    required this.contentDelta, // Use contentDelta instead of content
    required this.dueDate,
    required this.createdAt,
    required this.userId,
    required this.location,
    required this.imageUrls,
    required this.sharedUser,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    String key = json['key'] ?? 'No Key';
    String title = json['title'] ?? 'No Title';
    String contentDelta =
        json['contentDelta'] ?? '{}'; // Default to an empty Delta
    // Correctly handle Timestamp objects for dueDate and createdAt
    DateTime dueDate = json['dueDate'] != null
        ? (json['dueDate'] as Timestamp)
            .toDate()
            .toLocal() // Convert Timestamp to DateTime and then to local time
        : DateTime.now();
    DateTime createdAt = json['createdAt'] != null
        ? (json['createdAt'] as Timestamp)
            .toDate()
            .toLocal() // Convert Timestamp to DateTime and then to local time
        : DateTime.now();
    String userId = json['userId'] ?? 'No User ID';
    GeoFirePoint location = json['location'] != null
        ? GeoFirePoint(json['location'].latitude, json['location'].longitude)
        : GeoFirePoint(0, 0);
    List<String> imageUrls =
        json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [];
    List<String> sharedUser =
        json['sharedUser'] != null ? List<String>.from(json['sharedUser']) : [];

    return Post(
      key: key,
      title: title,
      contentDelta: contentDelta,
      dueDate: dueDate,
      createdAt: createdAt,
      userId: userId,
      location: location,
      imageUrls: imageUrls,
      sharedUser: sharedUser,
    );
  }

  // Method to convert a Post object to a Map (JSON data)
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'contentDelta': contentDelta, // Use contentDelta
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'imageUrls': imageUrls,
      'sharedUser': sharedUser,
    };
  }
}

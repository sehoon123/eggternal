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
    required this.contentDelta,
    required this.dueDate,
    required this.createdAt,
    required this.userId,
    required this.location,
    required this.imageUrls,
    required this.sharedUser,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Assuming all required fields are present. Add error handling as needed.
    return Post(
      key: json['key'] ?? 'No Key',
      title: json['title'] ?? 'No Title',
      contentDelta: json['contentDelta'] ?? '{}',
      dueDate: _convertToDateTime(json['dueDate']),
      createdAt: _convertToDateTime(json['createdAt']),
      userId: json['userId'] ?? 'No User ID',
      location: _convertToGeoFirePoint(json['location']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      sharedUser: List<String>.from(json['sharedUser'] ?? []),
    );
  }

  factory Post.fromSharedJson(Map<String, dynamic> json) {
    // Convert the location from a map to a GeoFirePoint
    GeoFirePoint location = GeoFirePoint(
      json['location']['geopoint']['latitude'],
      json['location']['geopoint']['longitude'],
    );

    // Create a new Post object with the converted location
    return Post(
      key: json['key'] ?? 'No Key',
      title: json['title'] ?? 'No Title',
      contentDelta: json['contentDelta'] ?? '{}',
      dueDate: _convertToDateTime(json['dueDate']),
      createdAt: _convertToDateTime(json['createdAt']),
      userId: json['userId'] ?? 'No User ID',
      location: location,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      sharedUser: List<String>.from(json['sharedUser'] ?? []),
    );
  }
    // Assuming all required fields are present. Add error handling as needed.

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'contentDelta': contentDelta,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'location': location.data,
      'imageUrls': imageUrls,
      'sharedUser': sharedUser,
    };
  }

  static DateTime _convertToDateTime(dynamic field) {
    if (field is Timestamp) {
      return field.toDate().toLocal();
    } else if (field is String) {
      return DateTime.parse(field);
    } else {
      return DateTime.now(); // Default value or throw an error
    }
  }

  static GeoFirePoint _convertToGeoFirePoint(dynamic field) {
    if (field is GeoPoint) {
      // Directly access latitude and longitude properties of GeoPoint
      return GeoFirePoint(field.latitude, field.longitude);
    } else {
      return GeoFirePoint(0, 0); // Default value or throw an error
    }
  }
}

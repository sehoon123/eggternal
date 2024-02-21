import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> addUser(Map<String, dynamic> userData) {
    return _usersCollection.add(userData);
  }

  Stream<QuerySnapshot> get usersStream {
    return _usersCollection.snapshots();
  }

  Future<DocumentSnapshot> getUser(String id) {
    return _usersCollection.doc(id).get();
  }
}
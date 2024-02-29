import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart'; // Ensure this path is correct

class PostsProvider with ChangeNotifier {
  User? _currentUser;
  final List<Post> _posts = [];
  DocumentSnapshot? _lastDocument; // To keep track of the last document fetched
  bool _isMyPostsSelected = true; // Default to show My Posts
  bool _isLoading = false;
  bool _hasMorePosts =
      true; // To check if more posts are available for fetching
  int _postCount = 0;
  final int _sharedPostCount = 0;

  User? get currentUser => _currentUser;
  List<Post> get posts => _posts;
  bool get isMyPostsSelected => _isMyPostsSelected;
  bool get isLoading => _isLoading;
  bool get hasMorePosts => _hasMorePosts;
  int get postCount => _postCount;
  int get sharedPostCount => _sharedPostCount;

  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setMyPostsSelected(bool value) {
    _isMyPostsSelected = value;
    debugPrint('My Posts selected: $value');
    notifyListeners();
  }

  Future<void> fetchPosts({bool isInitialFetch = false}) async {
    if (isInitialFetch) {
      _posts.clear();
      _lastDocument = null;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts || _isLoading) return;

    setIsLoading(true);
    debugPrint('Fetching posts...');

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where(
            _isMyPostsSelected ? 'userId' : 'sharedUser',
            isEqualTo: _currentUser!.uid,
          )
          .orderBy('dueDate',
              descending: true) // Assuming you have a timestamp field
          .limit(10); // Adjust the limit as needed

      debugPrint('Last document: $_lastDocument');

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _posts.addAll(
            querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
      } else {
        _hasMorePosts = false;
      }

      _postCount = _posts.length;
      // Update sharedPostCount logic if needed
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      setIsLoading(false);
    }
  }

  void togglePostsView() {
    _isMyPostsSelected = !_isMyPostsSelected;
    fetchPosts(isInitialFetch: true);
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> get postsStream {
    // Adjust the query based on whether "My Posts" or "Shared Posts" is selected
    String field = _isMyPostsSelected ? 'userId' : 'sharedUser';
    return FirebaseFirestore.instance
        .collection('posts')
        .where(field, isEqualTo: _currentUser?.uid)
        .orderBy('dueDate',
            descending: true) // Assuming you have a timestamp field
        .snapshots();
  }
}

import 'package:eggciting/models/global_location_data.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart';

class PostsProvider with ChangeNotifier {
  User? _currentUser;
  final List<Post> _posts = [];
  DocumentSnapshot? _lastDocument; // To keep track of the last document fetched
  bool _isMyPostsSelected = true; // Default to show My Posts
  bool _isLoading = false;
  bool _hasMorePosts =
      true; // To check if more posts are available for fetching
  int _postCount = 0;
  int _sharedPostCount = 0;

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
      if (!_isMyPostsSelected) {
        _sharedPostCount =
            0; // Reset sharedPostCount on initial fetch of shared posts
      }
    }

    if (!_hasMorePosts || _isLoading) return;

    setIsLoading(true);

    try {
      Query query;
      if (_isMyPostsSelected) {
        query = FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: _currentUser?.uid);
      } else {
        query = FirebaseFirestore.instance
            .collection('posts')
            .where('sharedUser', arrayContains: _currentUser?.uid);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot =
          await query.limit(10).get(); // Consider adding a limit

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        List<Post> fetchedPosts = querySnapshot.docs
            .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        if (!_isMyPostsSelected) {
          // Update sharedPostCount only when fetching shared posts
          _sharedPostCount += fetchedPosts.length;
        }

        _posts.addAll(fetchedPosts);
      } else {
        _hasMorePosts = false;
      }

      _postCount = _posts.length;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      _hasMorePosts = false;
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

  Stream<List<Post>> get postsStream {
    // Adjust the query based on whether "My Posts" or "Shared Posts" is selected
    Query query;
    if (_isMyPostsSelected) {
      debugPrint('Fetching My Posts for ${_currentUser?.uid}');
      // For "My Posts", filter by 'userId'
      query = FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _currentUser?.uid);
    } else {
      // For "Shared Posts", filter by 'sharedUser' containing the current user's UID
      debugPrint('Fetching Shared Posts for ${_currentUser?.uid}');
      query = FirebaseFirestore.instance
          .collection('posts')
          .where('sharedUser', arrayContains: _currentUser?.uid);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Assuming Post.fromJson can handle the conversion correctly
        return Post.fromJson(data);
      }).toList();
    });
  }
}

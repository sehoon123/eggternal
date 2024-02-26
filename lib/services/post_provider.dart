import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart'; // Ensure this path is correct

class PostsProvider with ChangeNotifier {
  User? _currentUser;
  List<Post> _posts = [];
  bool _isMyPostsSelected = true; // Default to show My Posts
  bool _isLoading = false;
  int _postCount = 0;
  int _sharedPostCount = 0;

  User? get currentUser => _currentUser;
  List<Post> get posts => _posts;
  bool get isMyPostsSelected => _isMyPostsSelected;
  bool get isLoading => _isLoading;
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

  Future<void> fetchPosts() async {
    setIsLoading(true);
    debugPrint('Fetching posts...');
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where(
            isMyPostsSelected ? 'userId' : 'sharedUser',
            isEqualTo: _currentUser!.uid,
          )
          .get();

      _posts =
          querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      _postCount = _posts.length;
      _sharedPostCount = _posts
          .length; // Assuming shared posts count is the same for simplicity
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      setIsLoading(false);
    }
  }

  void togglePostsView() {
    _isMyPostsSelected = !_isMyPostsSelected;
    fetchPosts();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> get postsStream {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: currentUser?.uid)
        .snapshots();
  }
}

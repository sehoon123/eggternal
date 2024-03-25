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
      // Assuming _currentUser is not null and has a valid uid
      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();

      if (userDocSnapshot.exists) {
        Map<String, dynamic> userData =
            userDocSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> userPosts = userData['posts'] ?? {};

        // Filter posts based on _isMyPostsSelected
        Iterable<MapEntry<String, dynamic>> filteredEntries;
        if (_isMyPostsSelected) {
          // For "My Posts", include all posts not starting with "shared_"
          filteredEntries = userPosts.entries
              .where((entry) => !entry.key.startsWith('shared_'));
        } else {
          // For "Shared Posts", only include posts starting with "shared_"
          filteredEntries = userPosts.entries
              .where((entry) => entry.key.startsWith('shared_'));
        }

        List<Post> fetchedPosts = filteredEntries.map((entry) {
          // Assuming each entry.value is a Map<String, dynamic> that represents a post
          return Post.fromJson(entry.value);
        }).toList();

        _posts.addAll(fetchedPosts);

        if (_isMyPostsSelected) {
          _postCount = _posts.length;
        } else {
          _sharedPostCount = _posts.length;
        }

        // Since we're fetching all posts at once from the user document, we might want to set _hasMorePosts to false
        _hasMorePosts = false;
      } else {
        debugPrint('User document does not exist');
        _hasMorePosts = false;
      }
    } catch (e) {
      debugPrint('Error fetching posts from user document: $e');
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
    // Ensure we have a current user
    if (_currentUser?.uid == null) {
      debugPrint('No current user set');
      return Stream.value([]); // Return an empty stream if no user is set
    }

    // Stream the user document
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        debugPrint('User document does not exist');
        return []; // Return an empty list if the user document doesn't exist
      }

      Map<String, dynamic> userData = snapshot.data()!;
      Map<String, dynamic> userPosts = userData['posts'] ?? {};

      // Filter posts based on _isMyPostsSelected
      Iterable<MapEntry<String, dynamic>> filteredEntries;
      if (_isMyPostsSelected) {
        // For "My Posts", include all posts not starting with "shared_"
        filteredEntries = userPosts.entries
            .where((entry) => !entry.key.startsWith('shared_'));
      } else {
        // For "Shared Posts", only include posts starting with "shared_"
        filteredEntries =
            userPosts.entries.where((entry) => entry.key.startsWith('shared_'));
      }

      // Convert the filtered posts map to a list of Post objects
      List<Post> posts = filteredEntries.map((entry) {
        // Assuming each entry.value is a Map<String, dynamic> that represents a post
        return Post.fromJson(Map<String, dynamic>.from(entry.value));
      }).toList();

      return posts;
    });
  }
}

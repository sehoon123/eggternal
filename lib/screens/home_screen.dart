import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/adding/add_page_screen.dart';
import 'package:eggciting/screens/adding/add_screen_deprecated.dart';
import 'package:eggciting/screens/ar_test.dart';
import 'package:eggciting/screens/list_screen.dart';
import 'package:eggciting/screens/map_screen.dart';
import 'package:eggciting/screens/payment_screen.dart';
import 'package:eggciting/screens/settings_screen.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    Provider.of<LocationProvider>(context, listen: false)
        .startTrackingLocation();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      refreshListScreenData();
    }
  }

  void refreshListScreenData() {
    Provider.of<PostsProvider>(context, listen: false)
        .fetchPosts(isInitialFetch: true);
  }

  Future<void> _loadUserNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = FirebaseAuth.instance.currentUser!.uid;
    String? nickname = prefs.getString('nickname_$userId');

    if (nickname == null) {
      // If the nickname is not in shared_preferences, fetch it from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (doc.exists) {
        nickname = doc.data()?['nickname'] ?? '';
        // Store the fetched nickname in shared_preferences
        await prefs.setString('nickname_$userId', nickname!);
      }
    }

    // You can now use the nickname variable as needed
    // For example, you might want to update the UI or pass the nickname to another widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const MapScreen(),
          const ListScreen(),
          const AddPageScreen(),
          PaymentScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        unselectedItemColor: Colors.grey,
        unselectedIconTheme: const IconThemeData(
          color: Colors.grey,
        ),
        unselectedLabelStyle: const TextStyle(
          color: Colors.grey,
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.deepPurple,
            icon: Icon(Icons.create),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

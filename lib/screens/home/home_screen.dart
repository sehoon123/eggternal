import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/handler/location_handler.dart';
import 'package:eggciting/screens/adding/map_selection_screen.dart';
import 'package:eggciting/screens/home/list_screen.dart';
import 'package:eggciting/screens/home/map_screen.dart';
import 'package:eggciting/screens/home/payment_screen.dart';
import 'package:eggciting/screens/home/settings_screen.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.firestore, this.initialIndex = 0});
  final FirebaseFirestore firestore;
  final int initialIndex;

  static _HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationHandler _locationHandler = LocationHandler();
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _selectedIndex = widget.initialIndex;
    _pageController.addListener(() {
      int currentIndex = _pageController.page!.round();
      if (currentIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = currentIndex;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadUserNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = FirebaseAuth.instance.currentUser!.uid;
    String? nickname = prefs.getString('nickname_$userId');

    debugPrint('userId: $userId');
    await prefs.setString('userId', userId);
    debugPrint('nickname: $nickname');

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
    return WillPopScope(
      onWillPop: () async {
        if (_pageController.page!.round() == 0) {
          return true;
        } else {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            children: <Widget>[
              const MapScreen(),
              const ListScreen(),
              const MapSelectionScreen(),
              const PaymentScreen(),
              SettingsScreen(locationHandler: _locationHandler),
            ],
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
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
              icon: Icon(Icons.credit_card_outlined),
              label: 'Pay',
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
      ),
    );
  }
}

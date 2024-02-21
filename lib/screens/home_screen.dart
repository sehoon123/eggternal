import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(37.521563, 126.677433); // 초기값 설정

  @override
  void initState() {
    super.initState();
    _initCenter();
  }

  void _initCenter() async {
    Position position = await _getCurrentLocation();
    setState(() {
      _center = LatLng(position.latitude, position.longitude); // 사용자의 위치로 초기화
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _center,
          zoom: 12,
        ),
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF67280),
        ).copyWith(
          primary: const Color(0xFFF67280),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Test'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: GoogleMap(
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 12,
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
              icon: Icon(Icons.create),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: Colors.amber[800],
          onTap: (index) {
            // Handle navigation
            debugPrint('Tapped item: $index');
            if (index == 1) {
              Navigator.pushNamed(context, '/list');
            }
            if (index == 2) {
              Navigator.pushNamed(context, '/add');
            }
          },
        ),
      ),
    );
  }
}

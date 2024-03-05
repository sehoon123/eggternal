import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
<<<<<<< HEAD
import 'package:eggternal/screens/post_details_screen.dart';
=======
import 'package:eggciting/screens/post_details_screen.dart';
>>>>>>> deb
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
<<<<<<< HEAD
  late GoogleMapController _mapController;
  LatLng? _initialPosition;
  LatLng? userLocation;
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCenter();
  }

  // Function to Initialize the Map with User Location
  void _initializeCenter() async {
    final LocationService locationService = LocationService();
    LatLng? center = await locationService.getCurrentLatLng();

    debugPrint('Center: $center');

      setState(() {
        _initialPosition = center;
      });

    if (center != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 14.0, // Adjust the zoom level as needed
          ),
        ),
      );
    }
  }

  // Function when Map is Created
=======
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsPlaces _places =
      GoogleMapsPlaces(apiKey: dotenv.env['androidGeoApiKey']!);
  List<Prediction> _predictions = [];

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final userLocation =
        Provider.of<LocationProvider>(context, listen: false).userLocation;
    if (userLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 16)));
    }
  }

  void _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }
    final response = await _places.autocomplete(query);
    setState(() {
      _predictions = response.predictions;
    });
  }

  void _moveToSearchedPlace(String placeId) async {
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16),
      ),
    );
  }

>>>>>>> deb
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
<<<<<<< HEAD
      body: StreamBuilder<QuerySnapshot>(
        stream: Provider.of<PostsProvider>(context).postsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                  target: _initialPosition ?? const LatLng(0, 0), zoom: 12),
              markers: snapshot.data!.docs.map((doc) {
                final post = Post.fromFirestore(doc);
                Coordinates postLocation = Coordinates(
                  post.location.latitude,
                  post.location.longitude,
                );

                double distance = userLocation != null
                    ? GeoFirePoint.distanceBetween(
                        to: postLocation,
                        from: Coordinates(
                          userLocation!.latitude,
                          userLocation!.longitude,
                        ),
                      )
                    : double.infinity;

                return Marker(
                  markerId: MarkerId(doc.id),
                  position:
                      LatLng(post.location.latitude, post.location.longitude),
                  infoWindow: InfoWindow(
                    title: post.text,
                    snippet: 'Distance: ${distance.toStringAsFixed(2)}km',
=======
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: Provider.of<PostsProvider>(context).postsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final userLocation =
                    Provider.of<LocationProvider>(context, listen: false)
                        .userLocation;
                return GoogleMap(
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: userLocation ?? const LatLng(0, 0),
                    zoom: 12,
>>>>>>> deb
                  ),
                  onTap: (LatLng position) {
                    FocusScope.of(context).unfocus();
                  },
                  markers: snapshot.data!.docs.map((doc) {
                    final post = Post.fromFirestore(doc);
                    return Marker(
                      markerId: MarkerId(doc.id),
                      position: LatLng(
                          post.location.latitude, post.location.longitude),
                      infoWindow: InfoWindow(title: post.title),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailsScreen(post: post),
                          ),
                        );
                      },
                    );
                  }).toSet(),
                );
              }
            },
          ),
          Positioned(
            top: 10,
            right: 15,
            left: 15,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _searchPlace,
                  decoration: InputDecoration(
                    hintText: 'Search for a place...',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.search),
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_predictions[index].description ??
                              'No description'),
                          onTap: () {
                            _moveToSearchedPlace(_predictions[index].placeId!);
                            _searchController.clear();
                            setState(() {
                              _predictions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

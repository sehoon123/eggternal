import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eggciting/screens/opening/post_details_screen.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsPlaces _places =
      GoogleMapsPlaces(apiKey: dotenv.env['androidGeoApiKey']!);
  List<Prediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final userLocation = GlobalLocationData().currentLocation;
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

  Future<void> _moveToCurrentUserLocation() async {
    bool serviceEnabled;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // When we reach here, permissions are granted and we can continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<List<Post>>(
              stream: Provider.of<PostsProvider>(context).postsStream,
              builder: (context, snapshot) {
                // debugPrint('snapshot: $snapshot');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final userLocation = GlobalLocationData().currentLocation;
                  return GoogleMap(
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: userLocation ?? const LatLng(0, 0),
                      zoom: 12,
                    ),
                    onTap: (LatLng position) {
                      FocusScope.of(context).unfocus();
                    },
                    markers: snapshot.data!.map((post) {
                      return Marker(
                        markerId: MarkerId(post
                            .key), // Assuming the Post class has an 'id' field
                        position: LatLng(
                            post.location.latitude, post.location.longitude),
                        infoWindow: InfoWindow(title: post.title),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailsScreen(post: post),
                            ),
                          );
                        },
                      );
                    }).toSet(),
                  );
                } else {
                  return const Center(child: Text('No data available'));
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
                              _moveToSearchedPlace(
                                  _predictions[index].placeId!);
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
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: _moveToCurrentUserLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

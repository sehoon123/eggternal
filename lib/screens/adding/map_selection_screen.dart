import 'package:eggciting/screens/adding/new_adding_page.dart';
import 'package:eggciting/screens/adding/write_content_screen.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  late LocationProvider _locationProvider;
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsPlaces _places =
      GoogleMapsPlaces(apiKey: dotenv.env['androidGeoApiKey']!);
  List<Prediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    _locationProvider = Provider.of<LocationProvider>(context, listen: false);
    _locationProvider.startTrackingLocation();
  }

  @override
  void dispose() {
    _locationProvider.stopTrackingLocation();
    super.dispose();
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

    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 20),
      ),
    );
    setState(() {
      _selectedPosition = LatLng(lat, lng);
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selectedLocation'),
        position: LatLng(lat, lng),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = _locationProvider.userLocation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _controller = controller;
              if (userLocation != null) {
                _controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: userLocation,
                      zoom: 20,
                    ),
                  ),
                );
              }
            },
            onTap: (position) {
              setState(() {
                _selectedPosition = position;
                _markers.clear();
                _markers.add(Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: position,
                ));
              });
              FocusScope.of(context).unfocus();
            },
            markers: _markers,
            initialCameraPosition: userLocation != null
                ? CameraPosition(
                    target: userLocation,
                    zoom: 20,
                  )
                : const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 20,
                  ),
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
                            _searchController.text =
                                _predictions[index].description ?? '';
                            _moveToSearchedPlace(_predictions[index].placeId!);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewAddingPage(
                selectedLocation: _selectedPosition!,
              ),
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
}

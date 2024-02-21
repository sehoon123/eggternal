import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:eggternal/screens/map_selection_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<dynamic> _images = []; // Can hold either File or String (URLs)
  User? user = FirebaseAuth.instance.currentUser;
  bool _isImageSelectionInProgress = false;
  Position? _currentPosition;
  String? _locationAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check location service & permission
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle the case where the location service is disabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle case when a user permanently denies permission
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = position;
    _updateLocationAddress(); // Get address details
  }

  void _updateLocationAddress() async {
    if (_currentPosition != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        Placemark placemark =
            placemarks.first; // Assuming you need the first result
        String address =
            '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';

        setState(() {
          _locationAddress = address;
        });
      } catch (e) {
        debugPrint('Error getting address: $e');
        // Handle error gracefully (e.g., show a message)
      }
    }
  }

  Future<void> _postContent() async {
    String text = _textEditingController.text;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Offload to a background task
      await Future.wait([
        for (int i = 0; i < _images.length; i++)
          if (_images[i] is File) _uploadFile(_images[i]),
        _updateFirestore(text),
      ]);

      // Show success (on the main thread)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content added successfully')),
      );
    } catch (e) {
      debugPrint('Error adding post: $e');
      // Handle error (still on the main thread)
    } finally {
      Navigator.pop(context); // Close dialog
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

// Helper functions for background tasks
  Future<String> _uploadFile(File file) async {
    final storageRef = FirebaseStorage.instance.ref().child(
        'user_data/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(file);
    final url = await FirebaseStorage
        .instance // Access the ref property of the uploadTask object
        .ref(uploadTask.snapshot.ref.fullPath)
        .getDownloadURL();
    return url;
  }

  Future<void> _updateFirestore(String text) async {
    // Rebuild _images with URLs if needed
    await widget.firestore.collection('posts').add({
      'text': text,
      'imageUrls': _images,
      'createdAt': Timestamp.now(),
      'userId': user!.uid,
      'location':
          GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
    });

    // Clear data
    _textEditingController.clear();
    _images.clear();
    setState(() {});
  }

  void _openMapSelection() async {
    final selectedPosition = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapSelectionScreen(),
      ),
    );

    if (selectedPosition != null) {
      setState(() {
        _currentPosition = Position(
          latitude: selectedPosition.latitude,
          longitude: selectedPosition.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _updateLocationAddress();
      });
    }
  }

  void _selectImage() async {
    if (_isImageSelectionInProgress) {
      return;
    }

    setState(() {
      _isImageSelectionInProgress = true;
    });

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      _isImageSelectionInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Content'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                hintText: 'Enter text',
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _images.isEmpty
                  ? const Center(child: Text('No Images Selected'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        if (_images[index] is File) {
                          return Image.file(_images[index] as File);
                        } else {
                          return Image.network(_images[index] as String);
                        }
                      },
                    ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _selectImage,
              child: const Text('Select Images'),
            ),
            const SizedBox(height: 16.0),
            Text(_locationAddress ?? 'Location not available'),
            ElevatedButton(
              onPressed: _openMapSelection,
              child: const Text('Select Location on Map'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _postContent,
              child: const Text('Post Content'),
            ),
          ],
        ),
      ),
    );
  }
}

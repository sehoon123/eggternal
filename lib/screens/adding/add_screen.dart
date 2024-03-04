import 'dart:io';
import 'package:eggciting/services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:eggciting/screens/adding/map_selection_screen.dart';
import 'package:intl/intl.dart';

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
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    final LocationService locationService = LocationService();

    if (!await locationService.isLocationServiceEnabled()) {
      return;
    }

    try {
      Position position = await locationService.getCurrentLocation();
      _currentPosition = position;
      _updateLocationAddress(); // Get address details
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
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

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _updateFirestore(text);

      // Show success (on the main thread)
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Content added successfully')),
      // );
    } catch (e) {
      debugPrint('Error adding post: $e');
      // Handle error (still on the main thread)
    } finally {
      Navigator.pop(context); // Close dialog
      // move to  PostSuccessScreen

      Navigator.of(context).pushReplacementNamed('/postSuccess');
    }
  }

// Helper functions for background tasks
  Future<String> _uploadFile(dynamic file) async {
    if (file is File) {
      final storageRef = FirebaseStorage.instance.ref().child(
          'user_data/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } else if (file is String) {
      // If the file is already a URL, no need to upload
      return file;
    } else {
      throw ArgumentError('Invalid file type: $file');
    }
  }

  Future<void> _updateFirestore(String text) async {
    // Modify _images with URLs
    for (int i = 0; i < _images.length; i++) {
      if (_images[i] is File) {
        _images[i] = await _uploadFile(_images[i]); // Replace File with URL
      }
    }

    // Rebuild _images with URLs if needed
    await widget.firestore.collection('posts').add({
      'text': text,
      'imageUrls': _images,
      'createdAt': Timestamp.now(),
      'userId': user!.uid,
      'location':
          GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      'dueDate': _dueDate,
      'sharedUser': '', // Add shared user if needed
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

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Content'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                ),
              ),
              const SizedBox(height: 16.0),
              _images.isEmpty
                  ? const Center(child: Text('No Images Selected'))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            if (image is File)
                              Image.file(
                                image,
                                fit: BoxFit.cover,
                              )
                            else
                              Image.network(
                                image,
                                fit: BoxFit.cover,
                              ),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.remove_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
              Text(_dueDate != null
                  ? 'Due Date: ${DateFormat.yMMMd().format(_dueDate!)}'
                  : 'No Due Date Selected'),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dueDate = pickedDate;
                    });
                  }
                },
                child: const Text('Select Due Date'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _postContent,
                child: const Text('Post Content'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:eggciting/screens/adding/select_due_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:image_picker/image_picker.dart'; // Import ImagePicker

class SelectImageScreen extends StatefulWidget {
  final String title;
  final String content;
  final List<File> images; // Assuming you're passing a list of File objects
  final LatLng? selectedLocation; // Add this line

  const SelectImageScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.images,
    this.selectedLocation, // Update this line
  }) : super(key: key);

  @override
  _SelectImageScreenState createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = []; // Create a new list of images

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.images); // Add the images from the widget to the list
  }

  Future<void> _selectImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
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
        title: const Text('Select Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _images.isNotEmpty
                  ? GridView.builder(
                      itemCount: _images.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
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
                    )
                  : const Text('No images selected.'),
            ),
          ),
          ElevatedButton(
            onPressed: _selectImages,
            child: const Text('Select Images'),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectDueDateScreen(
                    title: widget.title,
                    content: widget.content,
                    images: _images,
                    selectedLocation: widget.selectedLocation,
                  ),
                ),
              );
            },
            child: const Text('Next'),
          ),
          const SizedBox(height: 16.0), // Add some spacing at the bottom for better UI
        ],
      ),
    );
  }
}

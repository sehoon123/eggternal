import 'dart:io';
import 'package:eggciting/screens/select_due_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:image_picker/image_picker.dart'; // Import ImagePicker

class SelectImageScreen extends StatefulWidget {
  final String title;
  final String content;
  final List<File> images; // Assuming you're passing a list of File objects
  final LatLng? selectedLocation; // Add this line

  const SelectImageScreen({
    super.key,
    required this.title,
    required this.content,
    required this.images,
    this.selectedLocation, // Update this line
  });

  @override
  _SelectImageScreenState createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    setState(() {
      widget.images.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
  }

  void _removeImage(int index) {
    setState(() {
      widget.images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the selected images using GridView.builder
            if (widget.images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final image = widget.images[index];
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
              ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _selectImages, // Call the _selectImages method
              child: const Text('Select Images'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the next screen with the title, content, and selected images
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectDueDateScreen(
                      title: widget.title,
                      content: widget.content,
                      images:
                          widget.images, // Pass the images to the next screen
                      selectedLocation:
                          widget.selectedLocation, // Pass the selected location
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

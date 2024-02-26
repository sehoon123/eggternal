import 'package:eggciting/screens/select_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class WriteContentScreen extends StatefulWidget {
  final LatLng? selectedLocation; // Add this line

  const WriteContentScreen(
      {super.key, this.selectedLocation}); // Update this line

  @override
  _WriteContentScreenState createState() => _WriteContentScreenState();
}

class _WriteContentScreenState extends State<WriteContentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Content'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter your title here',
              ),
            ),
            const SizedBox(height: 100.0),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Enter your content here',
              ),
              maxLines: null, // Allows for multi-line input
            ),
            const SizedBox(height: 16.0),
            // add spaces to make the button stick to the bottom
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Save the title and content and navigate to the next screen
                final title = _titleController.text;
                final content = _contentController.text;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectImageScreen(
                      title: title,
                      content: content,
                      images: const [], // Pass an empty list of images
                      selectedLocation:
                          widget.selectedLocation, // Pass the selected location
                    ),
                  ),
                );
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

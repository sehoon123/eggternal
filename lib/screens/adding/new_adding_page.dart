import 'dart:convert';

import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/adding/map_selection_screen.dart';
import 'package:eggciting/screens/adding/select_due_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/embeds/image/editor/image_embed.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart'; // Add this import for File

class NewAddingPage extends StatefulWidget {
  final LatLng? selectedLocation;

  const NewAddingPage({super.key, this.selectedLocation});

  @override
  _NewAddingPageState createState() => _NewAddingPageState();
}

class _NewAddingPageState extends State<NewAddingPage> {
  final QuillController _controller = QuillController.basic();
  final Map<String, File> _imagePaths = {};

  Future<String> _getUserIdFromSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Adding Page'),
      ),
      body: Column(
        children: [
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _controller,
              showSubscript: false,
              showSuperscript: false,
              showInlineCode: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showIndent: false,
              showListBullets: false,
              showListNumbers: false,
              showCodeBlock: false,
              showListCheck: false,
              showSearchButton: false,
              sharedConfigurations: const QuillSharedConfigurations(
                locale: Locale('en'), // Set English locale
              ),
              customButtons: [
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
          Expanded(
            child: QuillEditor.basic(
              configurations: QuillEditorConfigurations(
                controller: _controller,
                readOnly: false, // true for view only mode
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
          const SizedBox(
            height: 80,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Collect the rich text content and convert it to a JSON string
          final String contentDelta =
              jsonEncode(_controller.document.toDelta().toList());

          // Collect the images
          // Assuming you have a method to get the image paths or URLs
          final List<File> images = _getImagePathsOrURLs();

          final List<String> imagePaths =
              images.map((file) => file.path).toList();

          // Extract the first line of text from the contentDelta
          final List<dynamic> contentDeltaList = jsonDecode(contentDelta);
          String title =
              'No Title'; // Default title in case the content is empty
          for (var item in contentDeltaList) {
            if (item is Map && item.containsKey('insert')) {
              String insertText = item['insert'];
              if (insertText.contains('\n')) {
                title = insertText.split('\n')[0]; // Get the first line of text
                break;
              } else {
                title =
                    insertText; // If there's no line break, use the entire text as the title
                break;
              }
            }
          }

          // Create a Post object with the collected data
          final Post post = Post(
            title: title, // You might want to collect this from the user
            contentDelta: contentDelta,
            dueDate: DateTime.now(), // Adjust as needed
            createdAt: DateTime.now(), // Adjust as needed
            userId: await _getUserIdFromSharedPrefs(), // Adjust as needed
            location: GeoFirePoint(
              widget.selectedLocation!.latitude,
              widget.selectedLocation!.longitude,
            ),
            imageUrls: imagePaths,
            sharedUser: [], // Adjust as needed
          );

          // Navigate to the MapSelectionScreen, passing the Post object along
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectDueDateScreen(post: post),
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  List<File> _getImagePathsOrURLs() {
    return _imagePaths.values.toList();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final File imageFile = File(pickedImage.path); // Convert XFile to File
      // Calculate the current cursor position
      final int cursorPosition = _controller.selection.baseOffset;
      // Create a Delta with an insert operation for the image
      final Delta delta = Delta()
        ..retain(cursorPosition)
        ..insert('\n') // Insert a line break before the image
        ..insert({'image': imageFile.path}) // Use the file path as the key
        ..insert('\n'); // Insert a line break after the image

      // Compose the Delta to insert the image at the cursor position
      _controller.compose(
        delta,
        _controller.selection,
        ChangeSource.local,
      );

      _controller.updateSelection(
        TextSelection.collapsed(
          offset: _controller.selection.baseOffset + 3,
        ),
        ChangeSource.local,
      );

      // Store the File object in the map
      _imagePaths[imageFile.path] = imageFile;
    }
  }
}

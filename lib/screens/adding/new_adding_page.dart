import 'dart:async';
import 'dart:convert';

import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/adding/map_selection_screen.dart';
import 'package:eggciting/screens/adding/select_due_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/embeds/image/editor/image_embed.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> _getUserIdFromSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint('userId from newadding: ${prefs.getString('userId')}');
    return prefs.getString('userId') ?? '';
  }

  List<File> _getImagePathsOrURLs() {
    return _imagePaths.values.toList();
  }

  Future<void> _pickImage() async {
    await Permission.photos.request();
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedImages = await picker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();

      for (XFile pickedImage in pickedImages) {
        final File imageFile = File(pickedImage.path); // Convert XFile to File
        // Calculate the current cursor position
        int cursorPosition = _controller.selection.baseOffset;
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
            offset: cursorPosition,
          ),
          ChangeSource.local,
        );

        // Store the File object in the map
        _imagePaths[imageFile.path] = imageFile;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double? lastPointerY;

    return SafeArea(
      child: Scaffold(
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
              child: Listener(
                onPointerMove: (event) {
                  if (lastPointerY != null) {
                    if (event.position.dy > lastPointerY!) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  }
                  lastPointerY = event.position.dy;
                },
                child: Scrollable(
                    controller: ScrollController(),
                    viewportBuilder: (context, viewportOffset) {
                      return QuillEditor.basic(
                        configurations: QuillEditorConfigurations(
                          placeholder: 'First line will be the title',
                          controller: _controller,
                          scrollBottomInset: 10,
                          showCursor: true,
                          padding: const EdgeInsets.only(bottom: 50),
                          readOnly: false, // true for view only mode
                          sharedConfigurations: const QuillSharedConfigurations(
                            locale: Locale('en'),
                          ),
                          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                        ),
                      );
                    }),
              ),
            ),
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
                  title =
                      insertText.split('\n')[0]; // Get the first line of text
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
              key: '', // You might want to generate a key for the post
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/embeds/image/editor/image_embed.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'dart:io'; // Add this import for File

class NewAddingPage extends StatefulWidget {
  final LatLng? selectedLocation;

  const NewAddingPage({super.key, this.selectedLocation});

  @override
  _NewAddingPageState createState() => _NewAddingPageState();
}

class _NewAddingPageState extends State<NewAddingPage> {
  final QuillController _controller = QuillController.basic();

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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle the submission of the content and images
          // You can access the content with _controller.document.toDelta().toList()
          // For images, you'll need to handle them separately, possibly by uploading them to a server
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final String imagePath = pickedImage.path;
      // Calculate the current cursor position
      final int cursorPosition = _controller.selection.baseOffset;
      // Create a Delta with an insert operation for the image
      final Delta delta = Delta()
        ..retain(cursorPosition)
        ..insert('\n') // Insert a line break before the image
        ..insert({'image': imagePath})
        ..insert('\n'); // Insert a line break after the image
      // Compose the Delta to insert the image at the cursor position
      _controller.compose(
          delta,
          TextSelection.collapsed(
              offset: cursorPosition + 3), // Adjust the cursor position
          ChangeSource.local);
    }
  }
}

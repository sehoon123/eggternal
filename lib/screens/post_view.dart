import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:eggciting/models/post.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class DisplayPostScreen extends StatefulWidget {
 final Post post;

 const DisplayPostScreen({Key? key, required this.post}) : super(key: key);

 @override
 State<DisplayPostScreen> createState() => _DisplayPostScreenState();
}

class _DisplayPostScreenState extends State<DisplayPostScreen> {
 fq.QuillController _controller = fq.QuillController.basic();
 double _imageCardHeight = 0; // Initially set to 0 to avoid rendering issues

 @override
 void initState() {
    super.initState();
    _loadContent();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        _imageCardHeight = MediaQuery.of(context).size.height * 0.8; // Set initial height after build
      });
    });
 }

 Future<void> _loadContent() async {
    final contentDelta = widget.post.contentDelta;
    final doc = fq.Document.fromJson(jsonDecode(contentDelta));
    debugPrint('Loaded content: $doc');
    setState(() {
      _controller = fq.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
 }

 @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title, style: const TextStyle(fontSize: 30)),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _imageCardHeight -= details.delta.dy; // Adjust the height based on the swipe
            _imageCardHeight = _imageCardHeight.clamp(100.0, MediaQuery.of(context).size.height * 0.8); // Ensure the height stays within bounds
          });
        },
        child: Stack(
          children: [
            AnimatedContainer(
              height: _imageCardHeight,
              duration: const Duration(milliseconds: 300),
              child: widget.post.imageUrls.isNotEmpty
                 ? Image.network(
                      widget.post.imageUrls.first, // Assuming the first image is the main one
                      fit: BoxFit.cover,
                    )
                 : Container(), // Empty container if no images
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                 SizedBox(height: _imageCardHeight), // Space for the image card
                 fq.QuillEditor.basic(
                    configurations: fq.QuillEditorConfigurations(
                      controller: _controller,
                      readOnly: true,
                      showCursor: false,
                      autoFocus: false,
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                 ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
 }
}
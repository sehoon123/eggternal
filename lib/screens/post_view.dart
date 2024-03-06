import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:eggciting/models/post.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class DisplayPostScreen extends StatefulWidget {
  final Post post;

  const DisplayPostScreen({super.key, required this.post});

  @override
  State<DisplayPostScreen> createState() => _DisplayPostScreenState();
}

class _DisplayPostScreenState extends State<DisplayPostScreen> {
  fq.QuillController _controller = fq.QuillController.basic();
  ScrollController _scrollController = ScrollController();
  double _imageCardHeight = 0; 
  double _imageOpacity = 1.0; 

  @override
  void initState() {
    super.initState();
    _loadContent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _imageCardHeight = MediaQuery.of(context).size.height * 0.8; 
      });
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      double scrollOffset = _scrollController.offset;
      _imageCardHeight = MediaQuery.of(context).size.height * 0.8 - (scrollOffset * 0.2); 
      _imageCardHeight = _imageCardHeight.clamp(100.0, MediaQuery.of(context).size.height * 0.8);

      _imageOpacity = (1 - (scrollOffset / 300)).clamp(0.0, 1.0); 
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
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _imageCardHeight -= details.delta.dy; 
            _imageCardHeight = _imageCardHeight.clamp(100.0, MediaQuery.of(context).size.height * 0.8); 
          });
        },
        child: CustomScrollView(
          controller: _scrollController, // Attach controller for scrolling
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.8,
              flexibleSpace: FlexibleSpaceBar(
                background: widget.post.imageUrls.isNotEmpty
                    ? Image.network(
                        widget.post.imageUrls.first,
                        fit: BoxFit.cover,
                      )
                    : Container(), 
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                // SizedBox(height: _imageCardHeight), 
                Container(
                  color: Colors.white,
                  child: fq.QuillEditor.basic(
                    configurations: fq.QuillEditorConfigurations(
                      controller: _controller,
                      readOnly: true,
                      showCursor: false,
                      autoFocus: false,
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

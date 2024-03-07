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
  final ScrollController _scrollController = ScrollController();
  double _titleOpacity = 1.0;
  double _expandedHeight = 0.0;
  bool _imageLoaded = false;
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _scrollController.addListener(_onScroll);
    _loadImage(); // Load the image
  }

  void _onScroll() {
    setState(() {
      double scrollOffset = _scrollController.offset;
      _titleOpacity = (1 - (scrollOffset / 100)).clamp(0.0, 1.0);
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

  void _loadImage() {
    setState(() {
      _isloading = true;
    });
    Image image = Image.network(widget.post.imageUrls.first);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        if (!_imageLoaded) {
          double aspectRatio = info.image.width / info.image.height;
          double deviceWidth = MediaQuery.of(context).size.width;
          double calculatedHeight = deviceWidth / aspectRatio;
          debugPrint('image height: ${info.image.height}');
          debugPrint('image width: ${info.image.width}');
          debugPrint('calculated height: $calculatedHeight');
          setState(() {
            _expandedHeight = calculatedHeight;
            _imageLoaded = true;
            _isloading = false;
          });
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isloading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        // Use a Stack for layering
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: _expandedHeight,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      widget.post.imageUrls.isNotEmpty
                          ? _imageLoaded // Check the flag
                              ? Image.network(
                                  widget.post.imageUrls.first,
                                  fit: BoxFit.fitWidth,
                                )
                              : Container() // No need for the circular indicator here
                          : Container(),
                      Positioned(
                        bottom: 70.0,
                        left: 20.0,
                        child: Opacity(
                          opacity: _titleOpacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.title,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                widget.post.location.toString(),
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
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
        ],
      ),
    );
  }
}

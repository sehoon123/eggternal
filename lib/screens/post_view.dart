import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  bool _showPhotoCard = true;
  double _photoCardBackgroundOpacity = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
      _loadImage(); // Load the imagd
    });
    _scrollController.addListener(_onScroll);
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

    int loadedImages = 0;
    double firstImageHeight = 0.0; // To store the height of the first image

    for (String imageUrl in widget.post.imageUrls) {
      Image image = Image.network(imageUrl);
      image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          if (loadedImages == 0) {
            // This is the first image, calculate its height
            double aspectRatio = info.image.width / info.image.height;
            double deviceWidth = MediaQuery.of(context).size.width;
            firstImageHeight = deviceWidth / aspectRatio;
          }

          loadedImages++;
          if (loadedImages == widget.post.imageUrls.length) {
            // All images have been loaded
            setState(() {
              _expandedHeight =
                  firstImageHeight; // Use the height of the first image
              _imageLoaded = true;
              _isloading = false;
              _showPhotoCard = true;
            });
          }
        }),
      );
    }

    if (widget.post.imageUrls.isEmpty) {
      // Handle case where there are no images
      setState(() {
        _imageLoaded = true;
        _isloading = false;
      });
    }
  }

  Widget _buildPhotoCard() {
    // Initial height of the photo card
    double photoCardHeight =
        MediaQuery.of(context).size.height; // Full screen height

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Your existing opacity calculation logic
      },
      child: Stack(
        children: [
          // Background with animated opacity
          AnimatedOpacity(
            opacity:
                _photoCardBackgroundOpacity, // Control this value to animate opacity
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black.withOpacity(0.8), // Start with 0.8 opacity
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(),
          ),
          // Dismissible photo card
          Dismissible(
            key: UniqueKey(), // Each Dismissible needs a unique key
            direction: DismissDirection.up, // Allow swiping up
            onDismissed: (direction) {
              // This callback is called when the card is dismissed
              setState(() {
                _showPhotoCard = false; // Hide the photo card
                _photoCardBackgroundOpacity =
                    0.0; // Make the background fully transparent
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: photoCardHeight, // Use the animated height
              color: Colors.transparent,
              padding:
                  const EdgeInsets.all(20), // Add padding around the PhotoCard
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.9, // Photo card width
                  height: MediaQuery.of(context).size.height *
                      0.9, // Photo card height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: widget.post.imageUrls.isNotEmpty
                      ? Image.network(
                          widget.post.imageUrls.first,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
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
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Container(
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
                    );
                  },
                ),
              ),
            ],
          ),
          if (_showPhotoCard) _buildPhotoCard(),
        ],
      ),
    );
  }
}

import 'package:eggciting/screens/home/map_screen.dart';
import 'package:flutter/material.dart';

class PostSuccessScreen extends StatelessWidget {
  final List<String> imageAssetPaths;

  const PostSuccessScreen({super.key, required this.imageAssetPaths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Centered image
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.9, //   80% of screen width
                height: MediaQuery.of(context).size.height *
                    0.5, //   60% of screen height
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageAssetPaths
                        .first), // Assuming you want the first image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Continue button
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

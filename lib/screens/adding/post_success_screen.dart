import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/home/home_screen.dart';
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
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageAssetPaths.first),
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(),
                    ),
                    (route) => false,
                  );
                  HomeScreen.of(context)?.updateSelectedIndex(0);
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

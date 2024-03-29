import 'package:eggciting/services/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:eggciting/services/auth_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  late DateTime start;

  Future<void> loadHomeScreen() async {
    try {
      start = DateTime.now();
      await Future.delayed(const Duration(seconds: 1));

      // Check if the user is logged in
      var user = await AuthService().currentUser();
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // If the user is logged in, navigate to the HomeScreen
        if (mounted) {
          Provider.of<PostsProvider>(context, listen: false).setCurrentUser(user);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      debugPrint('Error in loadHomeScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    start = DateTime.now();
    return FutureBuilder(
      future: loadHomeScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.primary,
            body: Center(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: (snapshot.connectionState == ConnectionState.waiting &&
                        DateTime.now().difference(start).inSeconds < 1)
                    ? Image.asset('assets/images/logo.png')
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        } else {
          // If something goes wrong
          return Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

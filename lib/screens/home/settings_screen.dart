import 'dart:io';
import 'package:eggciting/handler/location_handler.dart';
import 'package:eggciting/screens/signin/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final LocationHandler locationHandler;
  const SettingsScreen({super.key, required this.locationHandler});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  File? _localImageFile;
  bool _useBackgroundNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (user != null) {
      String? nickname = prefs.getString('nickname_${user!.uid}');
      String? profileImageUrl = prefs.getString('profileImageUrl_${user!.uid}');

      if (nickname != null && profileImageUrl != null) {
        setState(() {
          _nameController.text = nickname;
          _profileImageUrl = profileImageUrl;
        });
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _nameController.text = doc.data()?['nickname'] ?? '';
            _profileImageUrl = doc.data()?['profileImageUrl'] ?? '';
          });
          // Store the fetched values in shared_preferences
          await prefs.setString('nickname_${user!.uid}', _nameController.text);
          await prefs.setString(
              'profileImageUrl_${user!.uid}', _profileImageUrl!);
        }
      }
      _useBackgroundNotifications =
          prefs.getBool('useBackgroundNotifications') ?? false;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _localImageFile = File(pickedFile.path);
      await _uploadImage(); // Upload the image after picking
    }
  }

  Future<void> _uploadImage() async {
    if (_localImageFile == null) return;

    final ref = FirebaseStorage.instance
        .ref('user_images/${user!.uid}/${user!.uid}.jpg');
    await ref.putFile(_localImageFile!);
    final imageUrl = await ref.getDownloadURL();

    setState(() {
      _profileImageUrl = imageUrl; // Update with the new image URL
    });

    // Optionally, update the user's profile in Firestore with the new image URL
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'profileImageUrl': imageUrl,
    });

    // Store the new image URL in shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImageUrl_${user!.uid}', imageUrl);
  }

  Future<void> _updateProfile() async {
    final nicknameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: _nameController.text.trim())
        .get();

    if (nicknameQuery.docs.isNotEmpty &&
        nicknameQuery.docs.first.id != user!.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Nickname is already taken. Please choose another one.')));
      }
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'nickname': _nameController.text.trim(),
    });

    // Store the new nickname in shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname_${user!.uid}', _nameController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')));
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Clear shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Navigate to the login screen
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // User is not logged in, navigate to the login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });
      return Container(); // Return an empty container while navigating
    } else {
      // User is logged in, show the settings screen
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 140,
                  backgroundColor: Colors.grey,
                  backgroundImage: _profileImageUrl != null &&
                          Uri.parse(_profileImageUrl!).host.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage(
                              'assets/images/default_profile_image.png')
                          as ImageProvider,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Change Profile Image'),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Profile Name'),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16.0), // Add gap between TextField and the button
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Update Profile'),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Use Background Notifications'),
                  value: _useBackgroundNotifications,
                  onChanged: (bool value) async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    debugPrint('useBackgroundNotifications: $value');
                    await prefs.setBool('useBackgroundNotifications', value);
                    setState(() {
                      _useBackgroundNotifications = value;
                    });

                    widget.locationHandler
                        .updateUseBackgroundNotifications(value);

                  },
                ),
                const Spacer(), // This will push the logout button to the bottom
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

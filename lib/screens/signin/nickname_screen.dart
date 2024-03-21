import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _setNickname() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('No user signed in');
          return;
        }

        // Check if the nickname already exists
        final nicknameSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('nickname', isEqualTo: _nicknameController.text)
            .get();

        if (nicknameSnapshot.docs.isNotEmpty) {
          // The nickname already exists, show an error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'This nickname is already taken. Please choose another one.')),
            );
          }
        } else {
          // The nickname does not exist, update the user document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'nickname': _nicknameController.text});

          // Navigate to the next screen (e.g., home screen)
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        // Handle update error - maybe show the user an error message
        debugPrint('Error updating nickname: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Nickname'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your nickname',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a nickname';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _setNickname,
                  child: const Text('Save Nickname'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

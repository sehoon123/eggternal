import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  void _showDisagreePopup(BuildContext context) {
    Alert(
      context: context,
      title: "Notice", // Update title as needed
      desc: "Must agree to terms to use this app.", // Update message
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context), // Close the popup
          color: Colors.green,
          child: const Text("OK"), // Example button color
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용 약관 동의'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '여기에 이용 약관 내용을 넣으세요.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              ElevatedButton(
                child: const Text('동의'),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    // User is signed in
                    final userId = user.uid; // Access the user's ID

                    // Update Firestore with Agreement
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'agreement': true,
                    });

                    debugPrint('User $userId has agreed to the terms of service');

                    // Navigate to main screen (Uncomment this line)
                    Navigator.pushReplacementNamed(context, '/nickname');
                  } else {
                    // User is not signed in - Handle this case
                    debugPrint('User is not signed in');
                  }
                  // 사용자가 동의 버튼을 누르면 메인 화면으로 이동합니다.
                  // Navigator.pushReplacementNamed(context, '/main');
                },
              ),
              const SizedBox(width: 150),
              ElevatedButton(
                child: const Text('비동의'),
                onPressed: () async {
                  // Navigate to main screen (Uncomment this line)
                  // Navigator.pushReplacementNamed(context, '/home');
                  // _showDisagreePopup(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('이용 약관에 동의해야 이용할 수 있습니다. 동의해주세요.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

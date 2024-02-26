import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                debugPrint('Go to Google');
                final url = Uri.parse('https://www.google.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: const Text('Go to Google'),
            ),
            const SizedBox(height:   16.0),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('https://www.youtube.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: const Text('Go to YouTube'),
            ),
          ],
        ),
      ),
    );
  }
}

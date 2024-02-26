import 'package:flutter/material.dart';

class PostSuccessScreen extends StatelessWidget {
  final String text;
  final List<String> imageUrls;

  const PostSuccessScreen({Key? key, required this.text, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Success'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(text, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height:  16.0),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:  3,
                  crossAxisSpacing:  8.0,
                  mainAxisSpacing:  8.0,
                ),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

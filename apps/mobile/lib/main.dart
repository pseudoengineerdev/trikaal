import 'package:flutter/material.dart';

void main() {
  runApp(const TrikaalApp());
}

class TrikaalApp extends StatelessWidget {
  const TrikaalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trikaal',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Trikaal mobile app scaffold is ready for API integration.'),
        ),
      ),
    );
  }
}

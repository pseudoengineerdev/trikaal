import 'package:flutter/material.dart';

import 'features/charts/presentation/birth_input_page.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const BirthInputPage(),
    );
  }
}

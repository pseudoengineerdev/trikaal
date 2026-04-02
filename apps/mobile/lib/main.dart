import 'package:flutter/material.dart';

import 'app/home_shell_page.dart';
import 'app/theme/trikaal_theme.dart';

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
      theme: TrikaalTheme.light(),
      home: const HomeShellPage(),
    );
  }
}

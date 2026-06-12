import 'package:flutter/material.dart';

import 'app/navigation/app_routes.dart';
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
      themeMode: ThemeMode.dark,
      theme: TrikaalTheme.dark(),
      darkTheme: TrikaalTheme.dark(),
      // home is intentionally absent: deep-linked cold starts need
      // onGenerateInitialRoutes, which is mutually exclusive with home.
      onGenerateRoute: onGenerateAppRoute,
      onGenerateInitialRoutes: generateAppInitialRoutes,
    );
  }
}

import 'package:flutter/material.dart';

import '../features/charts/presentation/birth_input_page.dart';
import '../features/dasha/presentation/dasha_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    BirthInputPage(),
    DashaPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.timelapse),
            label: 'Dasha',
          ),
        ],
      ),
    );
  }
}

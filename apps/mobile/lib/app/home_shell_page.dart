import 'package:flutter/material.dart';

import 'state/birth_input_state.dart';
import '../features/charts/presentation/birth_input_page.dart';
import '../features/dasha/presentation/dasha_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;
  final BirthInputState _birthInputState = BirthInputState();

  @override
  void dispose() {
    _birthInputState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      BirthInputPage(
        birthInputState: _birthInputState,
        onOpenDashaTab: _openDashaTab,
      ),
      DashaPage(birthInputState: _birthInputState),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
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

  void _openDashaTab() {
    setState(() {
      _selectedIndex = 1;
    });
  }
}

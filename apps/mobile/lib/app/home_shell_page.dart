import 'package:flutter/material.dart';

import 'state/astrology_terms_state.dart';
import 'state/birth_input_state.dart';
import 'state/terminology_mode_state.dart';
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
  final TerminologyModeState _terminologyModeState = TerminologyModeState();
  final AstrologyTermsState _astrologyTermsState = AstrologyTermsState();

  @override
  void initState() {
    super.initState();
    _astrologyTermsState.load();
    _birthInputState.loadSavedProfiles();
  }

  @override
  void dispose() {
    _birthInputState.dispose();
    _terminologyModeState.dispose();
    _astrologyTermsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      BirthInputPage(
        birthInputState: _birthInputState,
        terminologyModeState: _terminologyModeState,
        astrologyTermsState: _astrologyTermsState,
      ),
      DashaPage(
        birthInputState: _birthInputState,
        terminologyModeState: _terminologyModeState,
        astrologyTermsState: _astrologyTermsState,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Charts',
              ),
              NavigationDestination(
                icon: Icon(Icons.nightlight_round_outlined),
                selectedIcon: Icon(Icons.nightlight_round),
                label: 'Dasha',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'state/birth_input_state.dart';
import '../features/home/presentation/home_overview_page.dart';
import '../features/onboarding/presentation/onboarding_flow_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final BirthInputState _birthInputState = BirthInputState();

  @override
  void initState() {
    super.initState();
    _birthInputState.loadSavedProfiles();
  }

  @override
  void dispose() {
    _birthInputState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _birthInputState,
      builder: (BuildContext context, Widget? child) {
        if (!_birthInputState.onboardingCompleted ||
            !_birthInputState.hasComputedChart ||
            _birthInputState.computedReport == null) {
          return OnboardingFlowPage(
            birthInputState: _birthInputState,
            onCompleted: () {
              setState(() {});
            },
          );
        }

        return HomeOverviewPage(
          birthInputState: _birthInputState,
        );
      },
    );
  }
}

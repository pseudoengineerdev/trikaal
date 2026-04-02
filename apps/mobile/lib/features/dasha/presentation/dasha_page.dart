import 'package:flutter/material.dart';

import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/neo_surface.dart';
import '../../shared/widgets/terminology_toggle.dart';
import 'widgets/dasha_state_widgets.dart';

class DashaPage extends StatelessWidget {
  const DashaPage({
    required this.birthInputState,
    required this.terminologyModeState,
    required this.astrologyTermsState,
    super.key,
  });

  final BirthInputState birthInputState;
  final TerminologyModeState terminologyModeState;
  final AstrologyTermsState astrologyTermsState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dasha')),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          birthInputState,
          terminologyModeState,
          astrologyTermsState,
        ]),
        builder: (BuildContext context, Widget? child) {
          return AstroPageBackground(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: NeoSurface(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Vimshottari Timeline & Active Periods',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TerminologyToggle(
                        mode: terminologyModeState.mode,
                        onChanged: terminologyModeState.setMode,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBodyContent(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent() {
    final dashaSummary = birthInputState.computedDasha;
    if (!birthInputState.hasComputedChart || dashaSummary == null) {
      return DashaEmptyState(
        dateOfBirth: birthInputState.dateOfBirth,
        timeOfBirth: birthInputState.timeOfBirth,
        placeOfBirth: birthInputState.placeOfBirth,
      );
    }
    return DashaSummaryCard(
      summary: dashaSummary,
      dateOfBirth: birthInputState.dateOfBirth,
      timeOfBirth: birthInputState.timeOfBirth,
      placeOfBirth: birthInputState.placeOfBirth,
      mode: terminologyModeState.mode,
      termsState: astrologyTermsState,
    );
  }
}

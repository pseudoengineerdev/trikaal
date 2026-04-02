import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/presentation/widgets/chart_result_card.dart';
import '../../shared/widgets/terminology_toggle.dart';

class BirthChartDetailPage extends StatefulWidget {
  const BirthChartDetailPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<BirthChartDetailPage> createState() => _BirthChartDetailPageState();
}

class _BirthChartDetailPageState extends State<BirthChartDetailPage> {
  late final TerminologyModeState _terminologyModeState;
  late final AstrologyTermsState _astrologyTermsState;

  @override
  void initState() {
    super.initState();
    _terminologyModeState = TerminologyModeState();
    _astrologyTermsState = AstrologyTermsState();
    _astrologyTermsState.load();
  }

  @override
  void dispose() {
    _terminologyModeState.dispose();
    _astrologyTermsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.birthInputState.computedReport;

    return UniversalDockScaffold(
      appBar: AppBar(title: const Text('Birth Chart')),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _terminologyModeState,
          _astrologyTermsState,
          widget.birthInputState,
        ]),
        builder: (BuildContext context, Widget? child) {
          return AstroPageBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Expanded(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Detailed Kundli, Rashi (D1), Navamsa (D9), Graha Table',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TerminologyToggle(
                          mode: _terminologyModeState.mode,
                          onChanged: _terminologyModeState.setMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (report == null)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No chart computed yet. Compute chart first from onboarding/home flow.',
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: ChartResultCard(
                            result: report,
                            mode: _terminologyModeState.mode,
                            termsState: _astrologyTermsState,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.charts,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.popOne,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_kaal_sarpa_models.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import 'state/kaal_sarpa_controller.dart';

const Map<String, String> _planetLabel = <String, String>{
  'sun': 'Sun',
  'moon': 'Moon',
  'mangal': 'Mars',
  'budha': 'Mercury',
  'guru': 'Jupiter',
  'shukra': 'Venus',
  'shani': 'Saturn',
};

const Map<String, String> _planetGlyph = <String, String>{
  'sun': '☉',
  'moon': '☽',
  'mangal': '♂',
  'budha': '☿',
  'guru': '♃',
  'shukra': '♀',
  'shani': '♄',
};

class KaalSarpaPage extends StatefulWidget {
  const KaalSarpaPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<KaalSarpaPage> createState() => _KaalSarpaPageState();
}

class _KaalSarpaPageState extends State<KaalSarpaPage> {
  late final KaalSarpaController _controller;
  bool _autoComputeAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = KaalSarpaController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoComputeAttempted || !_canCompute) {
        return;
      }
      _autoComputeAttempted = true;
      _compute();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canCompute {
    return widget.birthInputState.dateOfBirth.trim().isNotEmpty &&
        widget.birthInputState.timeOfBirth.trim().isNotEmpty &&
        widget.birthInputState.placeOfBirth.trim().isNotEmpty;
  }

  Future<void> _compute() {
    return _controller.compute(
      request: ComputeKaalSarpaRequest(
        dateOfBirth: widget.birthInputState.dateOfBirth.trim(),
        timeOfBirth: widget.birthInputState.timeOfBirth.trim(),
        placeOfBirth: widget.birthInputState.placeOfBirth.trim(),
        customPlace: widget.birthInputState.customPlace,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onCurrentLocationTap: () => showCurrentLocationPickerSheet(
          context: context,
          birthInputState: widget.birthInputState,
        ),
        currentLocationLabel: widget.birthInputState.placeForCurrentObservations,
        onCalendarTap: () => openHinduCalendar(context, widget.birthInputState),
        onPremiumTap: () => _handleDockTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                children: <Widget>[
                  Text(
                    'Kaal Sarpa Dosh',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Computed from your D1 chart using the Rahu-Ketu enclosure rule on seven classical planets.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _profileSummary(context),
                  if (_controller.loading &&
                      _controller.result == null) ...<Widget>[
                    const SizedBox(height: 14),
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (_controller.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    ErrorCard(
                      message: _controller.error!,
                      onRetry: _canCompute ? _compute : null,
                    ),
                  ],
                  if (_controller.result != null) ...<Widget>[
                    const SizedBox(height: 14),
                    _resultBody(context, _controller.result!),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: TrikaalSurface.decoration(
        colorScheme: Theme.of(context).colorScheme,
        radius: 14,
      ),
      child: Text(
        '${widget.birthInputState.firstName.trim().isEmpty ? 'Profile' : widget.birthInputState.firstName.trim()}\n'
        '${widget.birthInputState.dateOfBirth} • ${widget.birthInputState.timeOfBirth}\n'
        '${widget.birthInputState.placeOfBirth}',
        style: const TextStyle(
          color: Color(0xFFD8C8F5),
          height: 1.25,
        ),
      ),
    );
  }

  Widget _resultBody(
    BuildContext context,
    ComputeKaalSarpaResponse response,
  ) {
    final result = response.kaalSarpa;
    final isRahuToKetu =
        result.axis.rahuToKetuEnclosure && !result.axis.ketuToRahuEnclosure;
    final verdictLine = result.isKaalSarpa
        ? 'Your kundali has kaal sarpa dosh.'
        : 'Your kundali has no kaal sarpa dosh.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Planet Enclosure',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFFE7B3),
              ),
        ),
        const SizedBox(height: 6),
        _planetTable(context, result, isRahuToKetu),
        if (result.outsidePlanets.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Outside planets: ${result.outsidePlanets.map(_planetName).join(', ')}',
            style: const TextStyle(
              color: Color(0xFFFFD27D),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          verdictLine,
          style: const TextStyle(
            color: Color(0xFFD8C8F5),
            height: 1.25,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _planetTable(
    BuildContext context,
    KaalSarpaResult result,
    bool isRahuToKetu,
  ) {
    final dividerColor = const Color(0xFF9D4EDD).withValues(alpha: 0.28);
    final planets = result.classicalPlanets;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: TrikaalSurface.decoration(
          colorScheme: Theme.of(context).colorScheme,
          radius: 18,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(0.9),
            },
            children: <TableRow>[
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                children: const <Widget>[
                  _KaalSarpaCell(
                    text: 'Planet',
                    isHeader: true,
                  ),
                  _KaalSarpaCell(
                    text: 'Degree',
                    isHeader: true,
                    textAlign: TextAlign.center,
                  ),
                  _KaalSarpaCell(
                    text: 'Inside',
                    isHeader: true,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              ...List<TableRow>.generate(planets.length, (int index) {
                final key = planets[index];
                final evidence = result.planetEvidence[key];
                final inside = isRahuToKetu
                    ? (evidence?.withinRahuToKetuArc ?? false)
                    : (evidence?.withinKetuToRahuArc ?? false);
                return TableRow(
                  decoration: index == planets.length - 1
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: dividerColor),
                          ),
                        ),
                  children: <Widget>[
                    _KaalSarpaCell(
                      text: '${_planetGlyph[key] ?? '•'} ${_planetName(key)}',
                    ),
                    _KaalSarpaCell(
                      text:
                          '${(evidence?.siderealDegree ?? 0).toStringAsFixed(2)}°',
                      textAlign: TextAlign.center,
                    ),
                    _KaalSarpaCell(
                      text: inside ? '✓' : '✗',
                      textAlign: TextAlign.center,
                      color: inside
                          ? const Color(0xFF6DFFB3)
                          : const Color(0xFFFFD27D),
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _planetName(String key) {
    return _planetLabel[key] ?? key;
  }

  void _handleDockTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.charts,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.stay,
    );
  }
}

class _KaalSarpaCell extends StatelessWidget {
  const _KaalSarpaCell({
    required this.text,
    this.isHeader = false,
    this.textAlign = TextAlign.start,
    this.color,
    this.fontWeight,
  });

  final String text;
  final bool isHeader;
  final TextAlign textAlign;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          color: color ?? (isHeader ? Colors.white : const Color(0xFFE8DBFF)),
          fontSize: isHeader ? 14 : 13,
          fontWeight:
              fontWeight ?? (isHeader ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}

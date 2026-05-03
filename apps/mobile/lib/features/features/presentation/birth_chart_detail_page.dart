import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/chart_api_client.dart';
import '../../charts/data/models/compute_chart_models.dart';
import '../../charts/data/models/compute_report_models.dart';
import '../domain/vedic_dominants.dart';
import '../domain/report_refresh_policy.dart';
import '../../home/presentation/astrology/rashi_insights.dart';
import '../../shared/astrology/term_localizer.dart';
import '../../shared/widgets/terminology_toggle.dart';
import '../../subscription/presentation/subscription_page.dart';

enum _BirthChartMainTab {
  chart(label: 'Chart'),
  tables(label: 'Table'),
  dominants(label: 'Dominants');

  const _BirthChartMainTab({required this.label});
  final String label;
}

enum _ChartSubTab {
  planets(label: 'Planets'),
  houses(label: 'Houses');

  const _ChartSubTab({required this.label});
  final String label;
}

const List<String> _planetOrder = <String>[
  'lagna',
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
];

const List<String> _wheelPlanetOrder = <String>[
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
];

final List<String> _tableChartCodes = List<String>.unmodifiable(
  <String>[
    'BC',
    ...List<String>.generate(60, (int index) => 'D${index + 1}'),
  ],
);

const Map<String, String> _grahaGlyph = <String, String>{
  'sun': '☉',
  'moon': '☽',
  'mangal': '♂',
  'budha': '☿',
  'guru': '♃',
  'shukra': '♀',
  'shani': '♄',
  'rahu': '☊',
  'ketu': '☋',
  'lagna': '↑',
};

const Map<String, Color> _planetDotColor = <String, Color>{
  'sun': Color(0xFFFF8A3C),
  'moon': Color(0xFFCED4FF),
  'mangal': Color(0xFFE57373),
  'budha': Color(0xFF9CCC65),
  'guru': Color(0xFFFFD54F),
  'shukra': Color(0xFFF48FB1),
  'shani': Color(0xFF90A4AE),
  'rahu': Color(0xFFBA68C8),
  'ketu': Color(0xFF4DD0E1),
};

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
  late final ChartApiClient _chartApiClient;
  _BirthChartMainTab _mainTab = _BirthChartMainTab.chart;
  _ChartSubTab _chartSubTab = _ChartSubTab.planets;
  String _selectedTableChartCode = 'D1';
  bool _autoRefreshingReport = false;
  bool _autoRefreshAttempted = false;

  @override
  void initState() {
    super.initState();
    _terminologyModeState = TerminologyModeState();
    _astrologyTermsState = AstrologyTermsState();
    _chartApiClient = ChartApiClient();
    _astrologyTermsState.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRefreshReportForToday();
    });
  }

  @override
  void dispose() {
    _chartApiClient.dispose();
    _terminologyModeState.dispose();
    _astrologyTermsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.birthInputState.computedReport;

    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onPremiumTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return SubscriptionPage(
                  birthInputState: widget.birthInputState,
                );
              },
            ),
          );
        },
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content:
                        Text('Additional birth-chart actions are coming next.'),
                  ),
                );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
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
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      children: <Widget>[
                        _PillTabs<_BirthChartMainTab>(
                          options: _BirthChartMainTab.values,
                          selected: _mainTab,
                          labelFor: (_BirthChartMainTab option) => option.label,
                          onSelected: (_BirthChartMainTab value) {
                            setState(() => _mainTab = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TerminologyToggle(
                            mode: _terminologyModeState.mode,
                            onChanged: _terminologyModeState.setMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_autoRefreshingReport)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: report == null
                        ? _buildNoChartState()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _buildMainTabBody(report),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoChartState() {
    return ListView(
      key: const ValueKey<String>('no_chart'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'No chart computed yet. Compute chart first from onboarding/home flow.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabBody(ComputeReportResponse report) {
    switch (_mainTab) {
      case _BirthChartMainTab.chart:
        return _buildChartTab(report);
      case _BirthChartMainTab.tables:
        return _buildTablesTab(report);
      case _BirthChartMainTab.dominants:
        return _buildDominantsTab(report);
    }
  }

  Widget _buildChartTab(ComputeReportResponse report) {
    final displayName = widget.birthInputState.firstName.trim().isEmpty
        ? 'You'
        : widget.birthInputState.firstName.trim();
    final snapshot = report.snapshot;
    final planetEntries = _planetEntries(snapshot.grahaTable);

    return ListView(
      key: const ValueKey<String>('chart_tab'),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
      children: <Widget>[
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.birthInputState.dateOfBirth} • ${widget.birthInputState.timeOfBirth}',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.birthInputState.placeOfBirth,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _VedicWheelPainter(
                  lagnaSiderealDeg: snapshot.grahaTable.lagna.siderealDeg,
                  planets: _wheelPlanetOrder
                      .map(snapshot.grahaTable.entryByKey)
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PillTabs<_ChartSubTab>(
          options: _ChartSubTab.values,
          selected: _chartSubTab,
          labelFor: (_ChartSubTab option) => option.label,
          onSelected: (_ChartSubTab value) {
            setState(() => _chartSubTab = value);
          },
        ),
        const SizedBox(height: 10),
        if (_chartSubTab == _ChartSubTab.planets)
          ...planetEntries.map((entry) => _buildPlanetCard(entry)),
        if (_chartSubTab == _ChartSubTab.houses)
          ...snapshot.varga.d1.sortedHouses.map(
              (entry) => _buildHouseCard(entry.key, entry.value, snapshot)),
      ],
    );
  }

  Widget _buildPlanetCard(ReportGrahaEntry entry) {
    final mode = _terminologyModeState.mode;
    final graha = localizeGraha(
      entry.key,
      mode,
      termsState: _astrologyTermsState,
    );
    final rashi = localizeRashi(
      entry.rashi,
      mode,
      termsState: _astrologyTermsState,
    );
    final nakshatra = localizeNakshatra(
      entry.nakshatra,
      mode,
      termsState: _astrologyTermsState,
    );
    final symbol = _rashiSymbol(entry.rashi);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_grahaGlyph[entry.key] ?? '•'} $graha  in $rashi $symbol',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'House: ${entry.house}, Degree: ${_formatDegree(entry.siderealDeg)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nakshatra: $nakshatra (Pada ${entry.pada})',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _StatusChip(
                    label: entry.retrograde ? 'Retrograde' : 'Direct',
                    emphasized: entry.retrograde,
                  ),
                  _StatusChip(
                    label: entry.combust ? 'Combust' : 'Not Combust',
                    emphasized: entry.combust,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHouseCard(
    int houseIndex,
    ReportHouse house,
    ReportSnapshot snapshot,
  ) {
    final mode = _terminologyModeState.mode;
    final rashi = localizeRashi(
      house.rashi,
      mode,
      termsState: _astrologyTermsState,
    );
    final symbol = _rashiSymbol(house.rashi);
    final occupants = house.occupants.map((occupant) {
      final name = localizeGraha(
        occupant,
        mode,
        termsState: _astrologyTermsState,
      );
      return '${_grahaGlyph[occupant] ?? '•'} $name';
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_ordinal(houseIndex)} House in $rashi $symbol',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'House System: Whole Sign',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                occupants.isEmpty
                    ? 'Occupants: none'
                    : 'Occupants: ${occupants.join(', ')}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablesTab(ComputeReportResponse report) {
    final chartCode = _selectedTableChartCode;
    final divisionCode = _divisionCodeForTableChart(chartCode);
    final selectedDivision = report.snapshot.varga.divisionByCode(divisionCode);
    final isSupported = selectedDivision != null;
    final tableRows = _tableRowsForChart(
      table: report.snapshot.grahaTable,
      chartCode: chartCode,
      division: selectedDivision,
    );
    final mode = _terminologyModeState.mode;

    return ListView(
      key: const ValueKey<String>('tables_tab'),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                'Graha Table',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              key: const ValueKey<String>('table-chart-selector'),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: chartCode,
                  isDense: true,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _tableChartCodes
                      .map(
                        (String code) => DropdownMenuItem<String>(
                          value: code,
                          key: ValueKey<String>('table-chart-option-$code'),
                          child: Text(_tableChartLabel(code)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (String? value) {
                    if (value == null || value == chartCode) {
                      return;
                    }
                    setState(() {
                      _selectedTableChartCode = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!isSupported)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Chart $chartCode is intentionally locked until Drik parity fixtures are captured and verified for this division. '
                'This usually means the requested division is missing from the engine payload.',
                key: const ValueKey<String>('table-chart-locked-message'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (isSupported)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.42),
                ),
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: 0.22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 14,
                    headingRowHeight: 42,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 42,
                    dividerThickness: 0.7,
                    headingTextStyle: Theme.of(context).textTheme.titleSmall,
                    dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Planet')),
                      DataColumn(label: Text('Sign')),
                      DataColumn(label: Text('Degree')),
                      DataColumn(label: Text('House')),
                      DataColumn(label: Text('Motion')),
                    ],
                    rows: tableRows.map((entry) {
                      final graha = localizeGraha(
                        entry.key,
                        mode,
                        termsState: _astrologyTermsState,
                      );
                      final rashi = localizeRashi(
                        entry.rashi,
                        mode,
                        termsState: _astrologyTermsState,
                      );
                      return DataRow(
                        cells: <DataCell>[
                          DataCell(
                            Text(
                              '${_grahaGlyph[entry.key] ?? ''} $graha',
                              key: ValueKey<String>(
                                'table-$chartCode-graha-${entry.key}',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '$rashi ${_rashiSymbol(entry.rashi)}',
                              key: ValueKey<String>(
                                'table-$chartCode-rashi-${entry.key}',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              entry.degreeInDivisionDeg == null
                                  ? '—'
                                  : _formatDegree(entry.degreeInDivisionDeg!),
                              key: ValueKey<String>(
                                'table-$chartCode-degree-${entry.key}',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              entry.house.toString(),
                              key: ValueKey<String>(
                                'table-$chartCode-house-${entry.key}',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              entry.retrograde ? 'Retrograde' : 'Direct',
                              key: ValueKey<String>(
                                'table-$chartCode-motion-${entry.key}',
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDominantsTab(ComputeReportResponse report) {
    final mode = _terminologyModeState.mode;
    final dominance = computeVedicDominanceSnapshot(
      grahaTable: report.snapshot.grahaTable,
      dasha: report.dasha,
    );
    final strongestGraha = dominance.strongestGraha;
    final strongestElement = dominance.strongestElement;
    final strongestGrahaName = localizeGraha(
      strongestGraha.grahaKey,
      mode,
      termsState: _astrologyTermsState,
    );
    final strongestElementPercent = strongestElement.percent.toStringAsFixed(1);
    final mahaDashaDisplay = dominance.mahaDashaLordKey == null
        ? report.dasha.currentMahaDasha
        : localizeGraha(
            dominance.mahaDashaLordKey!,
            mode,
            termsState: _astrologyTermsState,
          );
    final antarDashaDisplay = dominance.antarDashaLordKey == null
        ? report.dasha.currentAntarDasha
        : localizeGraha(
            dominance.antarDashaLordKey!,
            mode,
            termsState: _astrologyTermsState,
          );
    final lastUpdated = formatReportAsOfForDisplay(report.dasha.asOfIso);
    final activeWindowDisplay = formatActiveWindowForDisplay(
      report.dasha.activeFrom,
      report.dasha.activeUntil,
    );

    return ListView(
      key: const ValueKey<String>('dominants_tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Vedic Signature Snapshot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: $lastUpdated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                _SnapshotMetricRow(
                  label: 'Strongest Graha',
                  value:
                      '$strongestGrahaName (${strongestGraha.totalPoints} pts · ${strongestGraha.dominantPercent.toStringAsFixed(1)}%)',
                ),
                const SizedBox(height: 8),
                _SnapshotMetricRow(
                  label: 'Dominant Element',
                  value:
                      '${strongestElement.element} ($strongestElementPercent%)',
                ),
                const SizedBox(height: 8),
                _SnapshotMetricRow(
                  label: 'Maha Dasha',
                  value: mahaDashaDisplay,
                ),
                const SizedBox(height: 6),
                _SnapshotMetricRow(
                  label: 'Antar Dasha',
                  value: antarDashaDisplay,
                ),
                const SizedBox(height: 6),
                _SnapshotMetricRow(
                  label: 'Active Window',
                  value: activeWindowDisplay,
                  valueStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Dominant Graha (Vedic)',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'How scoring works',
                      onPressed: () => _showDominanceScoringInfo(context),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List<Widget>.generate(dominance.grahaScores.length, (index) {
                  final row = dominance.grahaScores[index];
                  final grahaName = localizeGraha(
                    row.grahaKey,
                    mode,
                    termsState: _astrologyTermsState,
                  );
                  final rashiName = localizeRashi(
                    row.rashi,
                    mode,
                    termsState: _astrologyTermsState,
                  );
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == dominance.grahaScores.length - 1 ? 0 : 8,
                    ),
                    child: _DominantGrahaRow(
                      rank: index + 1,
                      grahaName: grahaName,
                      grahaKey: row.grahaKey,
                      rashiName: rashiName,
                      rashiSymbol: _rashiSymbol(row.rashi),
                      house: row.house,
                      points: row.totalPoints,
                      percent: row.dominantPercent,
                      dignityTag: row.dignityTag,
                      mahaActive: row.mahaDashaActive,
                      antarActive: row.antarDashaActive,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Element Balance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'About element balance',
                      onPressed: () => _showElementBalanceInfo(context),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Weighted influence rank across graha, dignity, house strength, and dasha activation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                ...dominance.elementScores.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ElementMeterRow(
                      label: entry.element,
                      points: entry.points,
                      placements: entry.placements,
                      percent: entry.percent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scoring uses Vedic house placement, house lordship from Lagna, D1/D9 dignity, motion/combust state, and active dasha weighting.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<ReportGrahaEntry> _planetEntries(ReportGrahaTable table) {
    return _planetOrder.map(table.entryByKey).toList(growable: false);
  }

  String _divisionCodeForTableChart(String chartCode) {
    if (chartCode == 'BC') {
      return 'd1';
    }
    return chartCode.toLowerCase();
  }

  String _tableChartLabel(String chartCode) {
    return chartCode == 'BC' ? 'BC' : chartCode;
  }

  List<_TableGrahaRow> _tableRowsForChart({
    required ReportGrahaTable table,
    required String chartCode,
    required ReportDivision? division,
  }) {
    final entries = _planetEntries(table);
    switch (chartCode) {
      case 'BC':
        return entries
            .map(
              (entry) => _TableGrahaRow(
                key: entry.key,
                rashi: entry.rashi,
                house: entry.house,
                degreeInDivisionDeg: entry.siderealDeg,
                retrograde: entry.retrograde,
              ),
            )
            .toList(growable: false);
      case 'D1':
      default:
        if (division == null) {
          return const <_TableGrahaRow>[];
        }
        return entries.map(
          (entry) {
            final placement = division.grahaPositions[entry.key];
            return _TableGrahaRow(
              key: entry.key,
              rashi: placement?.rashi ?? entry.rashi,
              house: placement?.house ?? entry.house,
              degreeInDivisionDeg: placement?.degreeInSignDeg,
              retrograde: entry.retrograde,
            );
          },
        ).toList(growable: false);
    }
  }

  String _rashiSymbol(String rashiCode) {
    return rashiInsightFor(rashiCode).symbol;
  }

  String _formatDegree(double siderealDeg) {
    final normalized = ((siderealDeg % 30) + 30) % 30;
    final totalSeconds = (normalized * 3600).round().clamp(0, 107999);
    final degrees = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
  }

  String _ordinal(int value) {
    if (value >= 11 && value <= 13) {
      return '${value}th';
    }
    switch (value % 10) {
      case 1:
        return '${value}st';
      case 2:
        return '${value}nd';
      case 3:
        return '${value}rd';
      default:
        return '${value}th';
    }
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

  Future<void> _maybeRefreshReportForToday() async {
    if (_autoRefreshAttempted) {
      return;
    }
    _autoRefreshAttempted = true;

    final report = widget.birthInputState.computedReport;
    if (report == null) {
      return;
    }
    if (widget.birthInputState.dateOfBirth.trim().isEmpty ||
        widget.birthInputState.timeOfBirth.trim().isEmpty ||
        widget.birthInputState.placeOfBirth.trim().isEmpty) {
      return;
    }
    if (!_isReportStale(report)) {
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _autoRefreshingReport = true;
    });

    try {
      final refreshed = await _chartApiClient.computeReport(
        ComputeChartRequest(
          dateOfBirth: widget.birthInputState.dateOfBirth,
          timeOfBirth: widget.birthInputState.timeOfBirth,
          placeOfBirth: widget.birthInputState.placeOfBirth,
          customPlace: widget.birthInputState.customPlace,
        ),
      );
      if (!mounted) {
        return;
      }
      widget.birthInputState.markReportComputed(refreshed);
    } catch (_) {
      // Keep existing report data if background refresh fails.
    } finally {
      if (mounted) {
        setState(() {
          _autoRefreshingReport = false;
        });
      }
    }
  }

  bool _isReportStale(ComputeReportResponse report) {
    return shouldAutoRefreshReportForDay(
      report.dasha.asOfIso,
      now: DateTime.now(),
    );
  }

  void _showDominanceScoringInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'How Dominant Score Works',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Each graha gets points from:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                '• House placement strength (Kendra/Trikona/Upachaya/Dusthana)',
              ),
              const Text(
                '• House lordship strength from your Lagna (1/5/9, 4/7/10, etc.)',
              ),
              const Text(
                '• Dignity in D1 and D9 (Exalted/Mooltrikona/Own/Friendly/Neutral/Inimical/Debilitated)',
              ),
              const Text('• Motion and condition (Retrograde, Combust)'),
              const Text('• Current Dasha activation (Maha/Antar)'),
              const SizedBox(height: 10),
              Text(
                'Percent is each graha’s share of total weighted points. Element bars use weighted graha totals (not flat counts), so they update as chart + dasha context changes.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showElementBalanceInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Element Balance (Vedic)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'What this is:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A quick distribution of Fire, Earth, Air, and Water in your chart profile.',
              ),
              const SizedBox(height: 8),
              Text(
                'Why it is important:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'It summarizes temperament tendencies: drive (Fire), stability (Earth), communication/intellect (Air), and emotional depth (Water).',
              ),
              const SizedBox(height: 8),
              Text(
                'How we calculate it:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Each graha is mapped to its rashi element. Then we sum weighted dominance points by element, with Lagna/Moon/Sun given slightly higher influence. Percentages come from those weighted totals.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PillTabs<T> extends StatelessWidget {
  const _PillTabs({
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      labelFor(option),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.emphasized,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: emphasized
            ? colorScheme.primaryContainer.withValues(alpha: 0.65)
            : colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _DominantGrahaRow extends StatelessWidget {
  const _DominantGrahaRow({
    required this.rank,
    required this.grahaName,
    required this.grahaKey,
    required this.rashiName,
    required this.rashiSymbol,
    required this.house,
    required this.points,
    required this.percent,
    required this.dignityTag,
    required this.mahaActive,
    required this.antarActive,
  });

  final int rank;
  final String grahaName;
  final String grahaKey;
  final String rashiName;
  final String rashiSymbol;
  final int house;
  final int points;
  final double percent;
  final String dignityTag;
  final bool mahaActive;
  final bool antarActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDashaBadge = mahaActive || antarActive;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.85)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_grahaGlyph[grahaKey] ?? '•'} $grahaName',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$points pts',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$rashiName $rashiSymbol • House $house',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _smallTag(context, dignityTag),
              if (mahaActive) _smallTag(context, 'Maha Dasha'),
              if (antarActive) _smallTag(context, 'Antar Dasha'),
              if (!hasDashaBadge) _smallTag(context, 'No active Dasha'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _SnapshotMetricRow extends StatelessWidget {
  const _SnapshotMetricRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final resolvedValueStyle =
        valueStyle ?? Theme.of(context).textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 122,
          child: Text(
            label,
            style: labelStyle,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: resolvedValueStyle,
          ),
        ),
      ],
    );
  }
}

class _ElementMeterRow extends StatelessWidget {
  const _ElementMeterRow({
    required this.label,
    required this.points,
    required this.placements,
    required this.percent,
  });

  final String label;
  final double points;
  final int placements;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final barColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.9);
    final baseColor =
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          '${points.toStringAsFixed(1)} pts • $placements placement${placements == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 7,
            backgroundColor: baseColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _TableGrahaRow {
  const _TableGrahaRow({
    required this.key,
    required this.rashi,
    required this.house,
    required this.degreeInDivisionDeg,
    required this.retrograde,
  });

  final String key;
  final String rashi;
  final int house;
  final double? degreeInDivisionDeg;
  final bool retrograde;
}

class _VedicWheelPainter extends CustomPainter {
  const _VedicWheelPainter({
    required this.lagnaSiderealDeg,
    required this.planets,
  });

  final double lagnaSiderealDeg;
  final List<ReportGrahaEntry> planets;
  static const List<Color> _zodiacRingColors = <Color>[
    Color(0xFF7B2CBF),
    Color(0xFF5A189A),
    Color(0xFF3C096C),
    Color(0xFF4E148C),
    Color(0xFF6A2FB5),
    Color(0xFF53208D),
    Color(0xFF7B2CBF),
    Color(0xFF5A189A),
    Color(0xFF3C096C),
    Color(0xFF4E148C),
    Color(0xFF6A2FB5),
    Color(0xFF53208D),
  ];
  static const List<Color> _zodiacGlyphColors = <Color>[
    Color(0xFFFF8A3C),
    Color(0xFFFFC84A),
    Color(0xFFE0AAFF),
    Color(0xFF7DB7FF),
    Color(0xFFF8D775),
    Color(0xFF9CCC65),
    Color(0xFFE0AAFF),
    Color(0xFF4DD0E1),
    Color(0xFFFFCC80),
    Color(0xFFB0BEC5),
    Color(0xFF80CBC4),
    Color(0xFFFF9CCC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    final ringOuterRadius = maxRadius * 0.94;
    final ringInnerRadius = maxRadius * 0.74;
    final glyphOrbitRadius = maxRadius * 0.81;
    final planetOrbitRadius = maxRadius * 0.55;
    final coreRadius = maxRadius * 0.67;
    const segmentCount = 12;
    final segmentSweep = (math.pi * 2) / segmentCount;
    final segmentGap = segmentSweep * 0.05;

    final wheelBackdropPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF2A0B4B).withValues(alpha: 0.85),
          const Color(0xFF180437).withValues(alpha: 0.95),
          const Color(0xFF0F022A).withValues(alpha: 1),
        ],
        stops: const <double>[0, 0.62, 1],
      ).createShader(
        Rect.fromCircle(center: center, radius: ringOuterRadius),
      );
    canvas.drawCircle(center, ringOuterRadius, wheelBackdropPaint);

    final ringOuterRect =
        Rect.fromCircle(center: center, radius: ringOuterRadius);
    final ringInnerRect =
        Rect.fromCircle(center: center, radius: ringInnerRadius);
    for (var i = 0; i < segmentCount; i += 1) {
      final start = _degToRad(i * 30) + (segmentGap / 2);
      final sweep = segmentSweep - segmentGap;
      final segmentPath = Path()
        ..arcTo(ringOuterRect, start, sweep, false)
        ..arcTo(ringInnerRect, start + sweep, -sweep, false)
        ..close();
      canvas.drawPath(
        segmentPath,
        Paint()..color = _zodiacRingColors[i].withValues(alpha: 0.92),
      );
    }

    final ringStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFD9C4FF).withValues(alpha: 0.35);
    canvas.drawCircle(center, ringOuterRadius, ringStrokePaint);
    canvas.drawCircle(center, ringInnerRadius, ringStrokePaint);

    final coreGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF3E1172).withValues(alpha: 0.45),
          const Color(0xFF180437).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, coreGlowPaint);

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawCircle(center, coreRadius, framePaint);
    canvas.drawCircle(center, maxRadius * 0.49, framePaint);

    final houseLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.2);
    final houseLineStartRadius = maxRadius * 0.49;
    for (var i = 0; i < segmentCount; i += 1) {
      final houseDeg = (lagnaSiderealDeg + (i * 30)) % 360;
      final angle = _degToRad(houseDeg);
      final start = Offset(
        center.dx + (math.cos(angle) * houseLineStartRadius),
        center.dy + (math.sin(angle) * houseLineStartRadius),
      );
      final end = Offset(
        center.dx + (math.cos(angle) * coreRadius),
        center.dy + (math.sin(angle) * coreRadius),
      );
      canvas.drawLine(start, end, houseLinePaint);
    }

    for (var i = 0; i < segmentCount; i += 1) {
      final mid = _degToRad((i * 30) + 15);
      final chipCenter = Offset(
        center.dx + (math.cos(mid) * glyphOrbitRadius),
        center.dy + (math.sin(mid) * glyphOrbitRadius),
      );
      final chipRadius = maxRadius * 0.035;
      final chipColor = _zodiacGlyphColors[i];
      canvas.drawCircle(
        chipCenter,
        chipRadius,
        Paint()..color = const Color(0xFF190433).withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        chipCenter,
        chipRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = chipColor.withValues(alpha: 0.95),
      );
      _drawText(
        canvas,
        _zodiacSymbols[i],
        chipCenter,
        fontSize: maxRadius * 0.052,
        color: chipColor,
      );
    }

    final sortedPlanets = <ReportGrahaEntry>[...planets]
      ..sort((a, b) => a.siderealDeg.compareTo(b.siderealDeg));
    final planetLayouts = <({ReportGrahaEntry planet, Offset position})>[];
    var clusterIndex = 0;
    double? previousDegree;
    for (final planet in sortedPlanets) {
      if (previousDegree != null &&
          _angularSeparation(previousDegree, planet.siderealDeg) < 9.5) {
        clusterIndex += 1;
      } else {
        clusterIndex = 0;
      }
      final lane = _laneForCluster(clusterIndex);
      final orbit = planetOrbitRadius + (lane * maxRadius * 0.03);
      final angle = _degToRad(planet.siderealDeg);
      final point = Offset(
        center.dx + (math.cos(angle) * orbit),
        center.dy + (math.sin(angle) * orbit),
      );
      planetLayouts.add((planet: planet, position: point));
      previousDegree = planet.siderealDeg;
    }

    final webPrimaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF70D6FF).withValues(alpha: 0.42);
    final webSecondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFF8FCF).withValues(alpha: 0.36);
    for (var i = 0; i < planetLayouts.length; i += 1) {
      if (planetLayouts.length < 4) {
        break;
      }
      final p1 = planetLayouts[i].position;
      if (i.isEven) {
        final p2 = planetLayouts[(i + 3) % planetLayouts.length].position;
        canvas.drawLine(p1, p2, webPrimaryPaint);
      }
      if (i % 3 == 0) {
        final p3 = planetLayouts[(i + 4) % planetLayouts.length].position;
        canvas.drawLine(p1, p3, webSecondaryPaint);
      }
    }

    for (final entry in planetLayouts) {
      final planet = entry.planet;
      final point = entry.position;
      final color = _planetDotColor[planet.key] ?? const Color(0xFFE0AAFF);
      canvas.drawCircle(
        point,
        maxRadius * 0.04,
        Paint()..color = color.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        point,
        maxRadius * 0.028,
        Paint()..color = const Color(0xFF14032E),
      );
      canvas.drawCircle(
        point,
        maxRadius * 0.028,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.95),
      );
      _drawText(
        canvas,
        _grahaGlyph[planet.key] ?? '•',
        point,
        fontSize: maxRadius * 0.05,
        color: color,
      );
    }

    _drawAngleLabel(
      canvas: canvas,
      center: center,
      radius: ringOuterRadius * 1.035,
      degree: lagnaSiderealDeg,
      label: 'As',
      fontSize: maxRadius * 0.055,
    );
    _drawAngleLabel(
      canvas: canvas,
      center: center,
      radius: ringOuterRadius * 1.035,
      degree: (lagnaSiderealDeg + 180) % 360,
      label: 'Ds',
      fontSize: maxRadius * 0.042,
    );
    _drawAngleLabel(
      canvas: canvas,
      center: center,
      radius: ringOuterRadius * 1.035,
      degree: (lagnaSiderealDeg + 270) % 360,
      label: 'Mc',
      fontSize: maxRadius * 0.04,
    );
    _drawAngleLabel(
      canvas: canvas,
      center: center,
      radius: ringOuterRadius * 1.035,
      degree: (lagnaSiderealDeg + 90) % 360,
      label: 'Ic',
      fontSize: maxRadius * 0.04,
    );

    canvas.drawCircle(
      center,
      maxRadius * 0.01,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _VedicWheelPainter oldDelegate) {
    if (oldDelegate.lagnaSiderealDeg != lagnaSiderealDeg) {
      return true;
    }
    if (oldDelegate.planets.length != planets.length) {
      return true;
    }
    for (var i = 0; i < planets.length; i += 1) {
      if (oldDelegate.planets[i].siderealDeg != planets[i].siderealDeg ||
          oldDelegate.planets[i].key != planets[i].key) {
        return true;
      }
    }
    return false;
  }

  double _degToRad(double degree) => ((degree - 90) * math.pi) / 180;
  double _angularSeparation(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  int _laneForCluster(int clusterIndex) {
    const lanes = <int>[0, -1, 1, -2, 2, -3, 3];
    return lanes[clusterIndex % lanes.length];
  }

  void _drawAngleLabel({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double degree,
    required String label,
    required double fontSize,
  }) {
    final angle = _degToRad(degree);
    final point = Offset(
      center.dx + (math.cos(angle) * radius),
      center.dy + (math.sin(angle) * radius),
    );
    _drawText(
      canvas,
      label,
      point,
      fontSize: fontSize,
      color: Colors.white.withValues(alpha: 0.8),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        center.dx - (painter.width / 2),
        center.dy - (painter.height / 2),
      ),
    );
  }
}

const List<String> _zodiacSymbols = <String>[
  '♈',
  '♉',
  '♊',
  '♋',
  '♌',
  '♍',
  '♎',
  '♏',
  '♐',
  '♑',
  '♒',
  '♓',
];

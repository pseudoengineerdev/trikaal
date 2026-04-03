import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_report_models.dart';
import '../../home/presentation/astrology/rashi_insights.dart';
import '../../shared/astrology/term_localizer.dart';
import '../../shared/widgets/terminology_toggle.dart';

enum _BirthChartMainTab {
  chart(label: 'Chart'),
  tables(label: 'Tables'),
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
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
  'lagna',
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
  _BirthChartMainTab _mainTab = _BirthChartMainTab.chart;
  _ChartSubTab _chartSubTab = _ChartSubTab.planets;

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
      appBar: AppBar(
        title: const Text('Birth Chart'),
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
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _PillTabs<_BirthChartMainTab>(
                            options: _BirthChartMainTab.values,
                            selected: _mainTab,
                            labelFor: (_BirthChartMainTab option) =>
                                option.label,
                            onSelected: (_BirthChartMainTab value) {
                              setState(() => _mainTab = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        TerminologyToggle(
                          mode: _terminologyModeState.mode,
                          onChanged: _terminologyModeState.setMode,
                        ),
                      ],
                    ),
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
    final cusp = _formatDegree(
      (snapshot.grahaTable.lagna.siderealDeg + ((houseIndex - 1) * 30)) % 360,
    );
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
                'Degree: $cusp',
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
    final snapshot = report.snapshot;
    final planetEntries = _planetEntries(snapshot.grahaTable);
    final mode = _terminologyModeState.mode;

    return ListView(
      key: const ValueKey<String>('tables_tab'),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
      children: <Widget>[
        Text(
          'Planets',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: Theme.of(context).textTheme.titleSmall,
                dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Planet')),
                  DataColumn(label: Text('Sign')),
                  DataColumn(label: Text('Degree')),
                  DataColumn(label: Text('House')),
                  DataColumn(label: Text('Motion')),
                ],
                rows: planetEntries.map((entry) {
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
                      DataCell(Text('${_grahaGlyph[entry.key] ?? ''} $graha')),
                      DataCell(Text('$rashi ${_rashiSymbol(entry.rashi)}')),
                      DataCell(Text(_formatDegree(entry.siderealDeg))),
                      DataCell(Text(entry.house.toString())),
                      DataCell(
                          Text(entry.retrograde ? 'Retrograde' : 'Direct')),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Houses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: Theme.of(context).textTheme.titleSmall,
                dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                columns: const <DataColumn>[
                  DataColumn(label: Text('House')),
                  DataColumn(label: Text('Sign')),
                  DataColumn(label: Text('Degree')),
                  DataColumn(label: Text('Occupants')),
                ],
                rows: snapshot.varga.d1.sortedHouses.map((houseEntry) {
                  final index = houseEntry.key;
                  final house = houseEntry.value;
                  final rashi = localizeRashi(
                    house.rashi,
                    mode,
                    termsState: _astrologyTermsState,
                  );
                  final degree = _formatDegree(
                    (snapshot.grahaTable.lagna.siderealDeg +
                            ((index - 1) * 30)) %
                        360,
                  );
                  final occupants = house.occupants.isEmpty
                      ? '—'
                      : house.occupants
                          .map(
                            (key) => localizeGraha(
                              key,
                              mode,
                              termsState: _astrologyTermsState,
                            ),
                          )
                          .join(', ');
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(index.toString())),
                      DataCell(Text('$rashi ${_rashiSymbol(house.rashi)}')),
                      DataCell(Text(degree)),
                      DataCell(SizedBox(width: 220, child: Text(occupants))),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDominantsTab(ComputeReportResponse report) {
    final navagraha = _wheelPlanetOrder
        .map(report.snapshot.grahaTable.entryByKey)
        .toList(growable: false);
    final elementCounts = _elementCounts(navagraha);

    return ListView(
      key: const ValueKey<String>('dominants_tab'),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Current Dasha Influence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Maha Dasha: ${report.dasha.currentMahaDasha}'),
                Text('Antar Dasha: ${report.dasha.currentAntarDasha}'),
                Text(
                  'Active Window: ${report.dasha.activeFrom} to ${report.dasha.activeUntil}',
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
                Text(
                  'Element Balance (Navagraha)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...elementCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Detailed Vedic dominance scoring (Graha influence matrix) will be added next.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<ReportGrahaEntry> _planetEntries(ReportGrahaTable table) {
    return _planetOrder.map(table.entryByKey).toList(growable: false);
  }

  Map<String, int> _elementCounts(List<ReportGrahaEntry> entries) {
    final counts = <String, int>{
      'Fire': 0,
      'Earth': 0,
      'Air': 0,
      'Water': 0,
    };
    for (final entry in entries) {
      final rashi = rashiInsightFor(entry.rashi);
      final element = rashi.element;
      counts[element] = (counts[element] ?? 0) + 1;
    }
    return counts;
  }

  String _rashiSymbol(String rashiCode) {
    return rashiInsightFor(rashiCode).symbol;
  }

  String _formatDegree(double siderealDeg) {
    final normalized = ((siderealDeg % 30) + 30) % 30;
    final degrees = normalized.floor();
    final minuteFloat = (normalized - degrees) * 60;
    final minutes = minuteFloat.floor();
    final seconds = ((minuteFloat - minutes) * 60).round();
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

class _VedicWheelPainter extends CustomPainter {
  const _VedicWheelPainter({
    required this.lagnaSiderealDeg,
    required this.planets,
  });

  final double lagnaSiderealDeg;
  final List<ReportGrahaEntry> planets;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final outerRect = Rect.fromCircle(center: center, radius: radius * 0.93);

    final ringColors = <Color>[
      const Color(0xFF3C096C),
      const Color(0xFF5A189A),
      const Color(0xFF240046),
      const Color(0xFF7B2CBF),
    ];
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.19;
    final ringSweep = (math.pi * 2) / 12;
    for (var i = 0; i < 12; i += 1) {
      ringPaint.color =
          ringColors[i % ringColors.length].withValues(alpha: 0.88);
      canvas.drawArc(
        outerRect,
        _degToRad(i * 30),
        ringSweep,
        false,
        ringPaint,
      );
    }

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.32);
    canvas.drawCircle(center, radius * 0.84, framePaint);
    canvas.drawCircle(center, radius * 0.62, framePaint);
    canvas.drawCircle(center, radius * 0.30, framePaint);

    final housePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.26);
    for (var i = 0; i < 12; i += 1) {
      final houseDeg = (lagnaSiderealDeg + (i * 30)) % 360;
      final angle = _degToRad(houseDeg);
      final end = Offset(
        center.dx + math.cos(angle) * radius * 0.84,
        center.dy + math.sin(angle) * radius * 0.84,
      );
      canvas.drawLine(center, end, housePaint);
    }

    for (var i = 0; i < 12; i += 1) {
      final mid = _degToRad((i * 30) + 15);
      final labelPoint = Offset(
        center.dx + math.cos(mid) * radius * 0.78,
        center.dy + math.sin(mid) * radius * 0.78,
      );
      _drawText(
        canvas,
        _zodiacSymbols[i],
        labelPoint,
        fontSize: radius * 0.085,
        color: Colors.white.withValues(alpha: 0.86),
      );
    }

    for (final planet in planets) {
      final angle = _degToRad(planet.siderealDeg);
      final point = Offset(
        center.dx + math.cos(angle) * radius * 0.52,
        center.dy + math.sin(angle) * radius * 0.52,
      );
      final color = _planetDotColor[planet.key] ?? const Color(0xFFE0AAFF);
      canvas.drawCircle(point, radius * 0.020, Paint()..color = color);
      _drawText(
        canvas,
        _grahaGlyph[planet.key] ?? '•',
        Offset(point.dx, point.dy - (radius * 0.040)),
        fontSize: radius * 0.06,
        color: color,
      );
    }

    _drawText(
      canvas,
      'As',
      Offset(
        center.dx + math.cos(_degToRad(lagnaSiderealDeg)) * radius * 0.95,
        center.dy + math.sin(_degToRad(lagnaSiderealDeg)) * radius * 0.95,
      ),
      fontSize: radius * 0.06,
      color: Colors.white.withValues(alpha: 0.8),
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

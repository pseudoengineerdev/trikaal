import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../charts/data/models/compute_report_models.dart';
import '../../home/presentation/astrology/rashi_insights.dart';

const List<String> _profileGrahaOrder = <String>[
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

const Map<String, String> _grahaLabel = <String, String>{
  'lagna': 'ASCENDANT',
  'sun': 'SUN',
  'moon': 'MOON',
  'mangal': 'MARS',
  'budha': 'MERCURY',
  'guru': 'JUPITER',
  'shukra': 'VENUS',
  'shani': 'SATURN',
  'rahu': 'RAHU',
  'ketu': 'KETU',
};

const Map<String, String> _grahaGlyph = <String, String>{
  'lagna': '↑',
  'sun': '☉',
  'moon': '☽',
  'mangal': '♂',
  'budha': '☿',
  'guru': '♃',
  'shukra': '♀',
  'shani': '♄',
  'rahu': '☊',
  'ketu': '☋',
};

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  Widget build(BuildContext context) {
    final report = birthInputState.computedReport;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const AstroPageBackground(
          child: Center(
            child: Text('Profile is available after chart computation.'),
          ),
        ),
      );
    }

    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'You'
        : birthInputState.firstName.trim();
    final handle =
        '@${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    final sun = rashiInsightFor(report.snapshot.vedic.sun.rashi);
    final moon = rashiInsightFor(report.snapshot.vedic.moon.rashi);
    final rising = rashiInsightFor(report.snapshot.vedic.lagna.rashi);
    final chartRows = _buildChartRows(report.snapshot.grahaTable);

    final tableBorderColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.65);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AstroPageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.person_rounded, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            handle,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '☉ ${sun.name}  ☽ ${moon.name}  ↑ ${rising.name}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _ProfileTabBar(
                activeIndex: 0,
                tabs: const <String>['Chart', 'Saved', 'Settings'],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: tableBorderColor),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: Text(
                              'S\nI\nG\nN\nS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Table(
                            columnWidths: const <int, TableColumnWidth>{
                              0: FlexColumnWidth(1.15),
                              1: FlexColumnWidth(1.22),
                              2: FlexColumnWidth(0.45),
                            },
                            border: TableBorder(
                              horizontalInside:
                                  BorderSide(color: tableBorderColor),
                              verticalInside:
                                  BorderSide(color: tableBorderColor),
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: chartRows.map((row) {
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: row.house.isEven
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.transparent,
                                ),
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      row.showRashi
                                          ? _rashiName(row.rashiCode)
                                          : '',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      '${_grahaGlyph[row.grahaKey] ?? '•'} ${_grahaLabel[row.grahaKey] ?? row.grahaKey.toUpperCase()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      '${row.house}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(growable: false),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: Text(
                              'H\nO\nU\nS\nE\nS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ProfileChartRow> _buildChartRows(ReportGrahaTable table) {
    final entries = _profileGrahaOrder
        .map((String key) => table.entryByKey(key))
        .toList(growable: false)
      ..sort((a, b) {
        final byHouse = a.house.compareTo(b.house);
        if (byHouse != 0) {
          return byHouse;
        }
        final aOrder = _profileGrahaOrder.indexOf(a.key);
        final bOrder = _profileGrahaOrder.indexOf(b.key);
        return aOrder.compareTo(bOrder);
      });

    String? previousRashi;
    final rows = <_ProfileChartRow>[];
    for (final entry in entries) {
      final showRashi = previousRashi != entry.rashi;
      rows.add(
        _ProfileChartRow(
          rashiCode: entry.rashi,
          grahaKey: entry.key,
          house: entry.house,
          showRashi: showRashi,
        ),
      );
      previousRashi = entry.rashi;
    }
    return rows;
  }

  String _rashiName(String rawCode) {
    return rashiInsightFor(rawCode).name;
  }
}

class _ProfileChartRow {
  const _ProfileChartRow({
    required this.rashiCode,
    required this.grahaKey,
    required this.house,
    required this.showRashi,
  });

  final String rashiCode;
  final String grahaKey;
  final int house;
  final bool showRashi;
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.tabs,
    required this.activeIndex,
  });

  final List<String> tabs;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.onSurface;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: List<Widget>.generate(tabs.length, (index) {
          final isActive = index == activeIndex;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '${isActive ? '• ' : ''}${tabs[index]}',
                    style: TextStyle(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  height: 2,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

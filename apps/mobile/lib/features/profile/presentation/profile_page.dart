import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
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
      return UniversalDockScaffold(
        activeItem: AppDockItem.profile,
        onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
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
    ).colorScheme.outlineVariant.withValues(alpha: 0.42);

    return UniversalDockScaffold(
      activeItem: AppDockItem.profile,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
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
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
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
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: IntrinsicHeight(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: tableBorderColor),
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.black.withValues(alpha: 0.22),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SizedBox(
                                width: 28,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(left: 4, top: 8),
                                    child: Text(
                                      'S\nI\nG\nN\nS',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 11.2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        letterSpacing: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Table(
                                    columnWidths: const <int, TableColumnWidth>{
                                      0: FlexColumnWidth(1.05),
                                      1: FlexColumnWidth(1.34),
                                      2: FlexColumnWidth(0.34),
                                    },
                                    border: TableBorder(
                                      verticalInside: BorderSide(
                                          color: tableBorderColor, width: 0.8),
                                    ),
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: chartRows.map((row) {
                                      final signBottomBorder =
                                          row.isLastRow || !row.isRashiGroupEnd
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: tableBorderColor,
                                                  width: 0.8,
                                                );
                                      final houseBottomBorder =
                                          row.isLastRow || !row.isHouseGroupEnd
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: tableBorderColor,
                                                  width: 0.8,
                                                );
                                      return TableRow(
                                        children: <Widget>[
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: signBottomBorder,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                row.showRashi
                                                    ? _rashiName(row.rashiCode)
                                                    : '',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            color: const Color(0xFF10002B),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                '${_grahaGlyph[row.grahaKey] ?? '•'} ${_grahaLabel[row.grahaKey] ?? row.grahaKey.toUpperCase()}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontSize: 11.9,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: houseBottomBorder,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                row.showHouse
                                                    ? '${row.house}'
                                                    : '',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontSize: 13.3,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(growable: false),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 4, bottom: 8),
                                    child: Text(
                                      'H\nO\nU\nS\nE\nS',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11.2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        letterSpacing: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    switch (item) {
      case AppDockItem.home:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      case AppDockItem.profile:
        return;
      case AppDockItem.charts:
      case AppDockItem.dasha:
      case AppDockItem.menu:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('This tab will be finalized next.')),
          );
        return;
    }
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
    int? previousHouse;
    final rows = <_ProfileChartRow>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final nextEntry = index + 1 < entries.length ? entries[index + 1] : null;
      final showRashi = previousRashi != entry.rashi;
      final showHouse = previousHouse != entry.house;
      rows.add(
        _ProfileChartRow(
          rashiCode: entry.rashi,
          grahaKey: entry.key,
          house: entry.house,
          showRashi: showRashi,
          showHouse: showHouse,
          isRashiGroupEnd: nextEntry == null || nextEntry.rashi != entry.rashi,
          isHouseGroupEnd: nextEntry == null || nextEntry.house != entry.house,
          isLastRow: nextEntry == null,
        ),
      );
      previousRashi = entry.rashi;
      previousHouse = entry.house;
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
    required this.showHouse,
    required this.isRashiGroupEnd,
    required this.isHouseGroupEnd,
    required this.isLastRow,
  });

  final String rashiCode;
  final String grahaKey;
  final int house;
  final bool showRashi;
  final bool showHouse;
  final bool isRashiGroupEnd;
  final bool isHouseGroupEnd;
  final bool isLastRow;
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
                    tabs[index],
                    style: TextStyle(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  height: 1.8,
                  color: isActive
                      ? Theme.of(context).colorScheme.onSurface
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

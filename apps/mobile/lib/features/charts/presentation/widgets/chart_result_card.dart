import 'package:flutter/material.dart';

import '../../../../app/state/astrology_terms_state.dart';
import '../../../../app/state/terminology_mode_state.dart';
import '../../data/models/compute_chart_models.dart';
import '../../../shared/astrology/term_localizer.dart';

class ChartResultCard extends StatelessWidget {
  const ChartResultCard({
    required this.result,
    required this.mode,
    required this.termsState,
    super.key,
  });

  final ComputeChartResponse result;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final meta = _asMap(result.snapshot['meta']);
    final varga = _asMap(result.snapshot['varga']);
    final d1 = _asMap(varga['d1']);
    final d9 = _asMap(varga['d9']);
    final grahaTable = _asMap(result.snapshot['graha_table']);

    return Column(
      children: <Widget>[
        _SectionCard(
          title: 'Chart Summary',
          children: <Widget>[
            _KeyValueRow(
              label: 'Resolved Place',
              value: result.resolvedPlace.placeLabel,
            ),
            _KeyValueRow(
              label: 'Timezone',
              value: result.resolvedPlace.timezone,
            ),
            _KeyValueRow(
              label: 'Status',
              value: '${meta['status'] ?? '-'}',
            ),
            _KeyValueRow(
              label: 'Lagna (D1)',
              value: localizeRashi(
                '${d1['lagna_rashi'] ?? '-'}',
                mode,
                termsState: termsState,
              ),
            ),
            _KeyValueRow(
              label: 'Lagna (D9)',
              value: localizeRashi(
                '${d9['lagna_rashi'] ?? '-'}',
                mode,
                termsState: termsState,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Rashi Chart (D1)',
          children: <Widget>[
            _DivisionalChartGrid(
              chart: d1,
              mode: mode,
              termsState: termsState,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Navamsa Chart (D9)',
          children: <Widget>[
            _DivisionalChartGrid(
              chart: d9,
              mode: mode,
              termsState: termsState,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Graha Table',
          children: <Widget>[
            _GrahaTable(
              grahaTable: grahaTable,
              mode: mode,
              termsState: termsState,
            ),
          ],
        ),
      ],
    );
  }
}

class _DivisionalChartGrid extends StatelessWidget {
  const _DivisionalChartGrid({
    required this.chart,
    required this.mode,
    required this.termsState,
  });

  final Map<String, dynamic> chart;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final houses = _parseHouses(chart['houses']);
    if (houses.isEmpty) {
      return const Text('Detailed chart data not available yet.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: houses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) {
        final house = houses[index];
        final occupants = house.occupants
            .map(
              (String graha) => localizeGraha(
                graha,
                mode,
                termsState: termsState,
              ),
            )
            .toList(growable: false);

        return DecoratedBox(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'H${house.house}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  localizeRashi(house.rashi, mode, termsState: termsState),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    occupants.isEmpty ? '—' : occupants.join(', '),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GrahaTable extends StatelessWidget {
  const _GrahaTable({
    required this.grahaTable,
    required this.mode,
    required this.termsState,
  });

  final Map<String, dynamic> grahaTable;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  static const List<String> _rowOrder = <String>[
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

  @override
  Widget build(BuildContext context) {
    final rows = _rowOrder
        .where((String key) => grahaTable[key] is Map)
        .map((String key) => _asMap(grahaTable[key]))
        .toList(growable: false);

    if (rows.isEmpty) {
      return const Text('Graha table data not available yet.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 34,
        dataRowMaxHeight: 42,
        columns: const <DataColumn>[
          DataColumn(label: Text('Graha')),
          DataColumn(label: Text('Deg')),
          DataColumn(label: Text('D1')),
          DataColumn(label: Text('Nakshatra')),
          DataColumn(label: Text('Pada')),
          DataColumn(label: Text('House')),
          DataColumn(label: Text('D9')),
          DataColumn(label: Text('D9 H')),
          DataColumn(label: Text('Retro')),
          DataColumn(label: Text('Comb')),
        ],
        rows: rows.map((Map<String, dynamic> row) {
          final key = '${row['key'] ?? ''}';
          final degree = _num(row['sidereal_deg']);
          final rashi = '${row['rashi'] ?? '-'}';
          final nakshatra = '${row['nakshatra'] ?? '-'}';
          final pada = '${row['pada'] ?? '-'}';
          final house = '${row['house'] ?? '-'}';
          final d9Rashi = '${row['d9_rashi'] ?? '-'}';
          final d9House = '${row['d9_house'] ?? '-'}';
          final retrograde = (row['retrograde'] as bool?) ?? false;
          final combust = (row['combust'] as bool?) ?? false;

          return DataRow(
            cells: <DataCell>[
              DataCell(Text(localizeGraha(key, mode, termsState: termsState))),
              DataCell(Text(degree == null ? '-' : degree.toStringAsFixed(2))),
              DataCell(
                  Text(localizeRashi(rashi, mode, termsState: termsState))),
              DataCell(Text(
                  localizeNakshatra(nakshatra, mode, termsState: termsState))),
              DataCell(Text(pada)),
              DataCell(Text(house)),
              DataCell(
                  Text(localizeRashi(d9Rashi, mode, termsState: termsState))),
              DataCell(Text(d9House)),
              DataCell(Text(retrograde ? 'Yes' : 'No')),
              DataCell(Text(combust ? 'Yes' : 'No')),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _HouseCellData {
  const _HouseCellData({
    required this.house,
    required this.rashi,
    required this.occupants,
  });

  final int house;
  final String rashi;
  final List<String> occupants;
}

List<_HouseCellData> _parseHouses(Object? raw) {
  final map = _asMap(raw);
  final houses = <_HouseCellData>[];
  for (final MapEntry<String, dynamic> entry in map.entries) {
    final houseIndex = int.tryParse(entry.key);
    if (houseIndex == null) {
      continue;
    }
    final value = _asMap(entry.value);
    final occupants = _asList(value['occupants']).map((Object? value) {
      return value.toString();
    }).toList(growable: false);
    houses.add(
      _HouseCellData(
        house: houseIndex,
        rashi: '${value['rashi'] ?? '-'}',
        occupants: occupants,
      ),
    );
  }
  houses.sort((left, right) => left.house.compareTo(right.house));
  return houses;
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Object?> _asList(Object? raw) {
  if (raw is List<Object?>) {
    return raw;
  }
  if (raw is List) {
    return raw.cast<Object?>();
  }
  return const <Object?>[];
}

double? _num(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('${raw ?? ''}');
}

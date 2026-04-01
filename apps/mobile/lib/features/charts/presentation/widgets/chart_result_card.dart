import 'package:flutter/material.dart';

import '../../../../app/state/astrology_terms_state.dart';
import '../../../../app/state/terminology_mode_state.dart';
import '../../../shared/astrology/term_localizer.dart';
import '../../data/models/compute_report_models.dart';

class ChartResultCard extends StatelessWidget {
  const ChartResultCard({
    required this.result,
    required this.mode,
    required this.termsState,
    super.key,
  });

  final ComputeReportResponse result;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final snapshot = result.snapshot;
    final d1 = snapshot.varga.d1;
    final d9 = snapshot.varga.d9;

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
              value: snapshot.meta.status,
            ),
            _KeyValueRow(
              label: 'Lagna (D1)',
              value: localizeRashi(
                d1.lagnaRashi,
                mode,
                termsState: termsState,
              ),
            ),
            _KeyValueRow(
              label: 'Lagna (D9)',
              value: localizeRashi(
                d9.lagnaRashi,
                mode,
                termsState: termsState,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Panchanga',
          children: <Widget>[
            _PanchangaSection(
              panchanga: snapshot.panchanga,
              mode: mode,
              termsState: termsState,
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
              grahaTable: snapshot.grahaTable,
              mode: mode,
              termsState: termsState,
            ),
          ],
        ),
      ],
    );
  }
}

class _PanchangaSection extends StatelessWidget {
  const _PanchangaSection({
    required this.panchanga,
    required this.mode,
    required this.termsState,
  });

  final ReportPanchanga panchanga;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _KeyValueRow(
          label: 'Tithi',
          value: _pickPanchangaName(
            vedic: panchanga.tithi.nameVedic,
            english: panchanga.tithi.nameEnglish,
            mode: mode,
          ),
        ),
        _KeyValueRow(
          label: 'Vara',
          value: _pickPanchangaName(
            vedic: panchanga.vara.nameVedic,
            english: panchanga.vara.nameEnglish,
            mode: mode,
          ),
        ),
        _KeyValueRow(
          label: 'Nakshatra',
          value: localizeNakshatra(
            panchanga.nakshatra.nameVedic,
            mode,
            termsState: termsState,
          ),
        ),
        _KeyValueRow(
          label: 'Yoga',
          value: _pickPanchangaName(
            vedic: panchanga.yoga.nameVedic,
            english: panchanga.yoga.nameEnglish,
            mode: mode,
          ),
        ),
        _KeyValueRow(
          label: 'Karana',
          value: _pickPanchangaName(
            vedic: panchanga.karana.nameVedic,
            english: panchanga.karana.nameEnglish,
            mode: mode,
          ),
        ),
        _KeyValueRow(
          label: 'Sunrise',
          value: panchanga.sunrise.localTime,
        ),
        _KeyValueRow(
          label: 'Sunset',
          value: panchanga.sunset.localTime,
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

  final ReportDivision chart;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final houses = chart.sortedHouses;
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
        final houseEntry = houses[index];
        final house = houseEntry.value;
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
                  'H${houseEntry.key}',
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

  final ReportGrahaTable grahaTable;
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
        .map((String key) => grahaTable.entryByKey(key))
        .toList(growable: false);

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
        rows: rows.map((ReportGrahaEntry row) {
          return DataRow(
            cells: <DataCell>[
              DataCell(
                Text(localizeGraha(row.key, mode, termsState: termsState)),
              ),
              DataCell(Text(row.siderealDeg.toStringAsFixed(2))),
              DataCell(
                Text(localizeRashi(row.rashi, mode, termsState: termsState)),
              ),
              DataCell(
                Text(
                  localizeNakshatra(
                    row.nakshatra,
                    mode,
                    termsState: termsState,
                  ),
                ),
              ),
              DataCell(Text(row.pada.toString())),
              DataCell(Text(row.house.toString())),
              DataCell(
                Text(localizeRashi(row.d9Rashi, mode, termsState: termsState)),
              ),
              DataCell(Text(row.d9House.toString())),
              DataCell(Text(row.retrograde ? 'Yes' : 'No')),
              DataCell(Text(row.combust ? 'Yes' : 'No')),
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

String _pickPanchangaName({
  required String vedic,
  required String english,
  required TerminologyMode mode,
}) {
  if (mode == TerminologyMode.vedic) {
    final trimmed = vedic.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  } else {
    final trimmed = english.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  final fallback = vedic.trim().isNotEmpty ? vedic.trim() : english.trim();
  return fallback.isEmpty ? '-' : fallback;
}

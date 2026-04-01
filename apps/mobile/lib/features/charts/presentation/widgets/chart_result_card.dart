import 'package:flutter/material.dart';

import '../../../../app/state/astrology_terms_state.dart';
import '../../../../app/state/terminology_mode_state.dart';
import '../../../dasha/data/models/dasha_models.dart';
import '../../../shared/astrology/term_localizer.dart';
import '../../data/models/compute_report_models.dart';
import '../astrology/kundli_dignity.dart';

const List<String> _kundliGrahaRowOrder = <String>[
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
  'spashth_rahu',
  'spashth_ketu',
  'lagna',
];

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
    final grahaRows = _kundliGrahaRowOrder
        .map((String key) => snapshot.grahaTable.entryByKey(key))
        .toList(growable: false);

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
          title: 'Interpretations (Explainable)',
          children: <Widget>[
            _InterpretationsSection(
              cards: result.interpretations.cards,
              mode: mode,
              dasha: result.dasha,
              termsState: termsState,
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
          title: 'Detailed Kundli',
          children: <Widget>[
            _KundliHighlights(
              rows: grahaRows,
              mode: mode,
              termsState: termsState,
            ),
            const SizedBox(height: 10),
            _HousePlacementsTable(
              rows: grahaRows,
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
              rows: grahaRows,
              mode: mode,
              termsState: termsState,
            ),
          ],
        ),
      ],
    );
  }
}

class _InterpretationsSection extends StatelessWidget {
  const _InterpretationsSection({
    required this.cards,
    required this.mode,
    required this.dasha,
    required this.termsState,
  });

  final List<ReportInterpretationCard> cards;
  final TerminologyMode mode;
  final DashaSummary dasha;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Text(
        'No interpretations available yet for this chart.',
      );
    }
    return Column(
      children: cards
          .map(
            (ReportInterpretationCard card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InterpretationCardTile(
                card: card,
                mode: mode,
                dasha: dasha,
                termsState: termsState,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InterpretationCardTile extends StatelessWidget {
  const _InterpretationCardTile({
    required this.card,
    required this.mode,
    required this.dasha,
    required this.termsState,
  });

  final ReportInterpretationCard card;
  final TerminologyMode mode;
  final DashaSummary dasha;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final scorePercent = (card.strengthScore * 100).round().clamp(0, 100);
    final confidenceLabel = switch (card.confidence) {
      'high' => 'High confidence',
      'medium' => 'Medium confidence',
      _ => 'Emerging signal',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('interpretation-card-${card.cardId}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showInterpretationDetailDrawer(
            context: context,
            card: card,
            mode: mode,
            dasha: dasha,
            termsState: termsState,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _CategoryChip(category: card.category),
                    _ConfidenceChip(
                      confidence: card.confidence,
                      label: '$confidenceLabel ($scorePercent%)',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _localizedTextForMode(card.title, mode),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(_localizedTextForMode(card.summary, mode)),
                const SizedBox(height: 8),
                Text(
                  'Why this appears',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...card.evidence.map(
                  (ReportLocalizedText line) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• ${_localizedTextForMode(line, mode)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What it may indicate',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_localizedTextForMode(card.impact, mode)),
                const SizedBox(height: 8),
                Text(
                  'Tap for practical guidance',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showInterpretationDetailDrawer({
  required BuildContext context,
  required ReportInterpretationCard card,
  required TerminologyMode mode,
  required DashaSummary dasha,
  required AstrologyTermsState termsState,
}) {
  final guidance = _guidanceForInterpretation(
    card: card,
    dasha: dasha,
    mode: mode,
    termsState: termsState,
  );
  final mahaLabel = _localizeDashaLord(
    dasha.currentMahaDasha,
    mode,
    termsState: termsState,
  );
  final antarLabel = _localizeDashaLord(
    dasha.currentAntarDasha,
    mode,
    termsState: termsState,
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController scrollController) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _localizedTextForMode(card.title, mode),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Practical Interpretation Guide',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _CategoryChip(category: card.category),
                      _ConfidenceChip(
                        confidence: card.confidence,
                        label:
                            '${card.confidence.toUpperCase()} (${(card.strengthScore * 100).round()}%)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _localizedTextForMode(card.summary, mode),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Current Dasha Lens',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _KeyValueRow(
                            label: 'System',
                            value: dasha.system,
                          ),
                          _KeyValueRow(
                            label: 'Maha Dasha',
                            value: mahaLabel,
                          ),
                          _KeyValueRow(
                            label: 'Antar Dasha',
                            value: antarLabel,
                          ),
                          _KeyValueRow(
                            label: 'Active Window',
                            value:
                                '${_shortDate(dasha.activeFrom)} → ${_shortDate(dasha.activeUntil)}',
                          ),
                          _KeyValueRow(
                            label: 'Maha Window',
                            value:
                                '${_shortDate(dasha.currentMahaStart)} → ${_shortDate(dasha.currentMahaEnd)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'What to do now',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...guidance.doItems.map(
                            (ReportLocalizedText line) => _GuidanceBullet(
                              text: _localizedTextForMode(line, mode),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'What to watch',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...guidance.watchItems.map(
                            (ReportLocalizedText line) => _GuidanceBullet(
                              text: _localizedTextForMode(line, mode),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Timing checkpoint',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              _localizedTextForMode(guidance.checkpoint, mode)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _GuidanceBullet extends StatelessWidget {
  const _GuidanceBullet({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('• '),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterpretationGuidance {
  const _InterpretationGuidance({
    required this.doItems,
    required this.watchItems,
    required this.checkpoint,
  });

  final List<ReportLocalizedText> doItems;
  final List<ReportLocalizedText> watchItems;
  final ReportLocalizedText checkpoint;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = switch (category) {
      'aspects' => 'Aspects / Drishti',
      'yoga' => 'Yoga',
      'house_lord' => 'House Lord Logic',
      _ => category,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({
    required this.confidence,
    required this.label,
  });

  final String confidence;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (confidence) {
      'high' => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      'medium' => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      _ => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

class _KundliHighlights extends StatelessWidget {
  const _KundliHighlights({
    required this.rows,
    required this.mode,
    required this.termsState,
  });

  final List<ReportGrahaEntry> rows;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    final retro = _joinGrahaNames(
      rows.where((row) => row.retrograde),
      mode: mode,
      termsState: termsState,
    );
    final combust = _joinGrahaNames(
      rows.where((row) => row.combust),
      mode: mode,
      termsState: termsState,
    );
    final exalted = _joinGrahaNames(
      rows.where(
        (row) =>
            evaluateGrahaDignity(
              grahaKey: row.key,
              rashiKey: row.rashi,
            ).dignity ==
            GrahaDignity.exalted,
      ),
      mode: mode,
      termsState: termsState,
    );
    final debilitated = _joinGrahaNames(
      rows.where(
        (row) =>
            evaluateGrahaDignity(
              grahaKey: row.key,
              rashiKey: row.rashi,
            ).dignity ==
            GrahaDignity.debilitated,
      ),
      mode: mode,
      termsState: termsState,
    );

    return Column(
      children: <Widget>[
        _KeyValueRow(label: 'Retrograde', value: retro),
        _KeyValueRow(label: 'Combust', value: combust),
        _KeyValueRow(label: 'Exalted', value: exalted),
        _KeyValueRow(label: 'Debilitated', value: debilitated),
      ],
    );
  }
}

class _HousePlacementsTable extends StatelessWidget {
  const _HousePlacementsTable({
    required this.rows,
    required this.mode,
    required this.termsState,
  });

  final List<ReportGrahaEntry> rows;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tap any house placement row to open deep details.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 34,
            dataRowMaxHeight: 42,
            columns: const <DataColumn>[
              DataColumn(label: Text('Graha')),
              DataColumn(label: Text('House')),
              DataColumn(label: Text('Rashi')),
              DataColumn(label: Text('Nakshatra')),
              DataColumn(label: Text('Pada')),
              DataColumn(label: Text('Retro')),
            ],
            rows: rows.map((ReportGrahaEntry row) {
              final dignity = evaluateGrahaDignity(
                grahaKey: row.key,
                rashiKey: row.rashi,
              );
              void openDetails() {
                _showGrahaDetailDrawer(
                  context: context,
                  row: row,
                  mode: mode,
                  termsState: termsState,
                  dignity: dignity,
                );
              }

              DataCell cell(Widget child) =>
                  DataCell(child, onTap: openDetails);

              return DataRow(
                cells: <DataCell>[
                  cell(
                    Text(
                      localizeGraha(row.key, mode, termsState: termsState),
                      key: ValueKey<String>('house-row-${row.key}'),
                    ),
                  ),
                  cell(Text(row.house.toString())),
                  cell(
                    Text(
                        localizeRashi(row.rashi, mode, termsState: termsState)),
                  ),
                  cell(
                    Text(
                      localizeNakshatra(
                        row.nakshatra,
                        mode,
                        termsState: termsState,
                      ),
                    ),
                  ),
                  cell(Text(row.pada.toString())),
                  cell(Text(row.retrograde ? 'Yes' : 'No')),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _GrahaTable extends StatelessWidget {
  const _GrahaTable({
    required this.rows,
    required this.mode,
    required this.termsState,
  });

  final List<ReportGrahaEntry> rows;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tap any graha row to open deep details.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 34,
            dataRowMaxHeight: 42,
            columns: const <DataColumn>[
              DataColumn(label: Text('Graha')),
              DataColumn(label: Text('Deg')),
              DataColumn(label: Text('Speed')),
              DataColumn(label: Text('D1')),
              DataColumn(label: Text('Nakshatra')),
              DataColumn(label: Text('Pada')),
              DataColumn(label: Text('House')),
              DataColumn(label: Text('D9')),
              DataColumn(label: Text('D9 H')),
              DataColumn(label: Text('Retro')),
              DataColumn(label: Text('Comb')),
              DataColumn(label: Text('Dignity')),
            ],
            rows: rows.map((ReportGrahaEntry row) {
              final dignity = evaluateGrahaDignity(
                grahaKey: row.key,
                rashiKey: row.rashi,
              );
              void openDetails() {
                _showGrahaDetailDrawer(
                  context: context,
                  row: row,
                  mode: mode,
                  termsState: termsState,
                  dignity: dignity,
                );
              }

              DataCell cell(Widget child) =>
                  DataCell(child, onTap: openDetails);

              return DataRow(
                cells: <DataCell>[
                  cell(
                    Text(
                      localizeGraha(row.key, mode, termsState: termsState),
                      key: ValueKey<String>('graha-row-${row.key}'),
                    ),
                  ),
                  cell(Text(row.siderealDeg.toStringAsFixed(2))),
                  cell(Text(row.speedDegPerDay.toStringAsFixed(3))),
                  cell(
                    Text(
                        localizeRashi(row.rashi, mode, termsState: termsState)),
                  ),
                  cell(
                    Text(
                      localizeNakshatra(
                        row.nakshatra,
                        mode,
                        termsState: termsState,
                      ),
                    ),
                  ),
                  cell(Text(row.pada.toString())),
                  cell(Text(row.house.toString())),
                  cell(
                    Text(
                      localizeRashi(row.d9Rashi, mode, termsState: termsState),
                    ),
                  ),
                  cell(Text(row.d9House.toString())),
                  cell(Text(row.retrograde ? 'Yes' : 'No')),
                  cell(Text(row.combust ? 'Yes' : 'No')),
                  cell(
                    _DignityBadge(
                      result: dignity,
                      mode: mode,
                    ),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}

void _showGrahaDetailDrawer({
  required BuildContext context,
  required ReportGrahaEntry row,
  required TerminologyMode mode,
  required AstrologyTermsState termsState,
  required GrahaDignityResult dignity,
}) {
  final motionLabel = row.retrograde ? 'Retrograde' : 'Direct';
  final combustLabel = row.combust ? 'Combust' : 'Not Combust';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.74,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController scrollController) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              localizeGraha(
                                row.key,
                                mode,
                                termsState: termsState,
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Graha Deep View',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _DignityBadge(result: dignity, mode: mode),
                      _DetailFlagPill(label: motionLabel),
                      _DetailFlagPill(label: combustLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: <Widget>[
                          _KeyValueRow(
                            label: 'D1 Rashi',
                            value: localizeRashi(
                              row.rashi,
                              mode,
                              termsState: termsState,
                            ),
                          ),
                          _KeyValueRow(
                            label: 'D1 House',
                            value: 'H${row.house}',
                          ),
                          _KeyValueRow(
                            label: 'D9 Rashi',
                            value: localizeRashi(
                              row.d9Rashi,
                              mode,
                              termsState: termsState,
                            ),
                          ),
                          _KeyValueRow(
                            label: 'D9 House',
                            value: 'H${row.d9House}',
                          ),
                          _KeyValueRow(
                            label: 'Nakshatra',
                            value: localizeNakshatra(
                              row.nakshatra,
                              mode,
                              termsState: termsState,
                            ),
                          ),
                          _KeyValueRow(
                            label: 'Pada',
                            value: row.pada.toString(),
                          ),
                          _KeyValueRow(
                            label: 'Sidereal Deg',
                            value: '${row.siderealDeg.toStringAsFixed(4)}°',
                          ),
                          _KeyValueRow(
                            label: 'Raw Deg',
                            value: '${row.siderealDegRaw.toStringAsFixed(4)}°',
                          ),
                          _KeyValueRow(
                            label: 'Speed',
                            value:
                                '${row.speedDegPerDay.toStringAsFixed(4)}°/day',
                          ),
                          _KeyValueRow(
                            label: 'Retrograde',
                            value: row.retrograde ? 'Yes' : 'No',
                          ),
                          _KeyValueRow(
                            label: 'Combust',
                            value: row.combust ? 'Yes' : 'No',
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _DetailFlagPill extends StatelessWidget {
  const _DetailFlagPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DignityBadge extends StatelessWidget {
  const _DignityBadge({
    required this.result,
    required this.mode,
  });

  final GrahaDignityResult result;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (result.dignity) {
      GrahaDignity.exalted => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      GrahaDignity.debilitated => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      GrahaDignity.ownSign => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      GrahaDignity.neutral => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurface,
        ),
      GrahaDignity.notApplicable => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          result.labelForMode(mode),
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _joinGrahaNames(
  Iterable<ReportGrahaEntry> rows, {
  required TerminologyMode mode,
  required AstrologyTermsState termsState,
}) {
  final names = rows
      .map((row) => localizeGraha(row.key, mode, termsState: termsState))
      .toList(growable: false);
  if (names.isEmpty) {
    return 'None';
  }
  return names.join(', ');
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

String _localizedTextForMode(
  ReportLocalizedText text,
  TerminologyMode mode,
) {
  if (mode == TerminologyMode.vedic) {
    return text.vedic;
  }
  return text.english;
}

_InterpretationGuidance _guidanceForInterpretation({
  required ReportInterpretationCard card,
  required DashaSummary dasha,
  required TerminologyMode mode,
  required AstrologyTermsState termsState,
}) {
  final maha = _localizeDashaLord(
    dasha.currentMahaDasha,
    mode,
    termsState: termsState,
  );
  final antar = _localizeDashaLord(
    dasha.currentAntarDasha,
    mode,
    termsState: termsState,
  );

  switch (card.category) {
    case 'yoga':
      return _InterpretationGuidance(
        doItems: <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Use this period ($maha / $antar) to execute planned decisions instead of overthinking.',
            vedic:
                'Use this period ($maha / $antar) for planned action with clarity and steadiness.',
          ),
          const ReportLocalizedText(
            english:
                'Track one measurable life goal weekly so this yoga becomes visible in real outcomes.',
            vedic:
                'Track one measurable sankalpa weekly so this yoga reflects in lived karma.',
          ),
        ],
        watchItems: const <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Avoid ego-driven shortcuts; yoga strength drops when discipline is ignored.',
            vedic:
                'Avoid ahankara-driven shortcuts; yoga support weakens without niyam.',
          ),
          ReportLocalizedText(
            english:
                'Do not interpret one yoga alone as destiny; always balance with dasha and house context.',
            vedic:
                'Do not read one yoga in isolation; always check dasha and bhava context.',
          ),
        ],
        checkpoint: ReportLocalizedText(
          english:
              'Review progress near ${_shortDate(dasha.activeUntil)} to validate if this yoga is translating into real changes.',
          vedic:
              'Recheck near ${_shortDate(dasha.activeUntil)} and see whether this yoga is expressing through practical results.',
        ),
      );
    case 'house_lord':
      return _InterpretationGuidance(
        doItems: const <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Focus effort on the linked life areas shown in this card and plan concrete weekly actions.',
            vedic:
                'Focus on the linked bhava themes and convert them into practical weekly action.',
          ),
          ReportLocalizedText(
            english:
                'Keep family/career/relationship routines stable; house-lord results improve with consistency.',
            vedic:
                'Maintain stable routines; bhava-lord results improve with steadiness.',
          ),
        ],
        watchItems: const <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Avoid scattering attention across too many priorities at once.',
            vedic:
                'Avoid splitting shakti across too many tracks at the same time.',
          ),
          ReportLocalizedText(
            english:
                'If stress rises, reduce commitments before making major life decisions.',
            vedic:
                'When pressure rises, simplify commitments before big karma choices.',
          ),
        ],
        checkpoint: ReportLocalizedText(
          english:
              'Use $maha / $antar timeline checkpoints every 30 days to monitor whether these linked houses are improving together.',
          vedic:
              'Under $maha / $antar, review every 30 days to check if linked bhava themes are rising together.',
        ),
      );
    default:
      return _InterpretationGuidance(
        doItems: const <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Channel this influence into structured decisions, not emotional reactions.',
            vedic:
                'Channel this drishti into structured karma, not emotional reactivity.',
          ),
          ReportLocalizedText(
            english:
                'Write down one action per affected house and execute it this week.',
            vedic:
                'Assign one practical action to each affected bhava and execute this week.',
          ),
        ],
        watchItems: const <ReportLocalizedText>[
          ReportLocalizedText(
            english:
                'Do not force outcomes immediately; aspects often unfold in stages.',
            vedic:
                'Do not force instant outcomes; drishti effects unfold gradually.',
          ),
          ReportLocalizedText(
            english: 'Watch overreaction in the most activated house areas.',
            vedic: 'Watch overreaction in the most activated bhava themes.',
          ),
        ],
        checkpoint: ReportLocalizedText(
          english:
              'Track behavioral changes until ${_shortDate(dasha.activeUntil)} while $maha / $antar remains active.',
          vedic:
              'Track response patterns until ${_shortDate(dasha.activeUntil)} while $maha / $antar is active.',
        ),
      );
  }
}

String _localizeDashaLord(
  String lord,
  TerminologyMode mode, {
  required AstrologyTermsState termsState,
}) {
  final trimmed = lord.trim();
  if (trimmed.isEmpty) {
    return '-';
  }
  return localizeGraha(trimmed, mode, termsState: termsState);
}

String _shortDate(String isoValue) {
  final trimmed = isoValue.trim();
  if (trimmed.isEmpty) {
    return '-';
  }
  final datePart = trimmed.split('T').first.trim();
  if (datePart.length >= 10) {
    return datePart.substring(0, 10);
  }
  return datePart;
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

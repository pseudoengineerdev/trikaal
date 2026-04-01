import 'package:flutter/material.dart';

import '../../../../app/state/terminology_mode_state.dart';
import '../../data/models/compute_chart_models.dart';
import '../../../shared/astrology/term_localizer.dart';

class ChartResultCard extends StatelessWidget {
  const ChartResultCard({
    required this.result,
    required this.mode,
    super.key,
  });

  final ComputeChartResponse result;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final vedic = _asMap(result.snapshot['vedic']);
    final meta = _asMap(result.snapshot['meta']);
    final bhava = _asMap(result.snapshot['bhava']);

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
            _KeyValueRow(label: 'Status', value: '${meta['status'] ?? '-'}'),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Lagna Overview',
          children: <Widget>[
            _KeyValueRow(
              label: '${localizeGraha('lagna', mode)} Rashi',
              value: localizeRashi('${vedic['lagna_rashi'] ?? '-'}', mode),
            ),
            _KeyValueRow(
              label: '${localizeGraha('lagna', mode)} Nakshatra',
              value: _formatNakshatra(
                '${vedic['lagna_nakshatra'] ?? '-'}',
                '${vedic['lagna_pada'] ?? '-'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Graha Highlights',
          children: <Widget>[
            _KeyValueRow(
              label: localizeGraha('sun', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['sun_rashi'] ?? '-'}',
                nakshatra: '${vedic['sun_nakshatra'] ?? '-'}',
                pada: '${vedic['sun_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('moon', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['moon_rashi'] ?? '-'}',
                nakshatra: '${vedic['moon_nakshatra'] ?? '-'}',
                pada: '${vedic['moon_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('mangal', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['mangal_rashi'] ?? '-'}',
                nakshatra: '${vedic['mangal_nakshatra'] ?? '-'}',
                pada: '${vedic['mangal_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('budha', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['budha_rashi'] ?? '-'}',
                nakshatra: '${vedic['budha_nakshatra'] ?? '-'}',
                pada: '${vedic['budha_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('guru', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['guru_rashi'] ?? '-'}',
                nakshatra: '${vedic['guru_nakshatra'] ?? '-'}',
                pada: '${vedic['guru_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('shukra', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['shukra_rashi'] ?? '-'}',
                nakshatra: '${vedic['shukra_nakshatra'] ?? '-'}',
                pada: '${vedic['shukra_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('shani', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['shani_rashi'] ?? '-'}',
                nakshatra: '${vedic['shani_nakshatra'] ?? '-'}',
                pada: '${vedic['shani_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('rahu', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['rahu_rashi'] ?? '-'}',
                nakshatra: '${vedic['rahu_nakshatra'] ?? '-'}',
                pada: '${vedic['rahu_pada'] ?? '-'}',
              ),
            ),
            _KeyValueRow(
              label: localizeGraha('ketu', mode),
              value: _formatGrahaLine(
                rashi: '${vedic['ketu_rashi'] ?? '-'}',
                nakshatra: '${vedic['ketu_nakshatra'] ?? '-'}',
                pada: '${vedic['ketu_pada'] ?? '-'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Bhava (House Placements)',
          children: <Widget>[
            _KeyValueRow(
              label: '${localizeGraha('sun', mode)} House',
              value: '${bhava['sun_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('moon', mode)} House',
              value: '${bhava['moon_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('mangal', mode)} House',
              value: '${bhava['mangal_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('budha', mode)} House',
              value: '${bhava['budha_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('guru', mode)} House',
              value: '${bhava['guru_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('shukra', mode)} House',
              value: '${bhava['shukra_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('shani', mode)} House',
              value: '${bhava['shani_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('rahu', mode)} House',
              value: '${bhava['rahu_house'] ?? '-'}',
            ),
            _KeyValueRow(
              label: '${localizeGraha('ketu', mode)} House',
              value: '${bhava['ketu_house'] ?? '-'}',
            ),
          ],
        ),
      ],
    );
  }

  String _formatGrahaLine({
    required String rashi,
    required String nakshatra,
    required String pada,
  }) {
    return '${localizeRashi(rashi, mode)} • ${_formatNakshatra(nakshatra, pada)}';
  }

  String _formatNakshatra(String nakshatra, String pada) {
    return '${localizeNakshatra(nakshatra, mode)} ($pada)';
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

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

import 'package:flutter/material.dart';

import '../../data/models/compute_chart_models.dart';

class ChartResultCard extends StatelessWidget {
  const ChartResultCard({required this.result, super.key});

  final ComputeChartResponse result;

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
              label: 'Lagna Rashi',
              value: '${vedic['lagna_rashi'] ?? '-'}',
            ),
            _KeyValueRow(
              label: 'Lagna Nakshatra',
              value:
                  '${vedic['lagna_nakshatra'] ?? '-'} (${vedic['lagna_pada'] ?? '-'})',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Graha Highlights',
          children: <Widget>[
            _KeyValueRow(
              label: 'Surya',
              value:
                  '${vedic['sun_rashi'] ?? '-'} • ${vedic['sun_nakshatra'] ?? '-'} (${vedic['sun_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Chandra',
              value:
                  '${vedic['moon_rashi'] ?? '-'} • ${vedic['moon_nakshatra'] ?? '-'} (${vedic['moon_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Mangal',
              value:
                  '${vedic['mangal_rashi'] ?? '-'} • ${vedic['mangal_nakshatra'] ?? '-'} (${vedic['mangal_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Budha',
              value:
                  '${vedic['budha_rashi'] ?? '-'} • ${vedic['budha_nakshatra'] ?? '-'} (${vedic['budha_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Guru',
              value:
                  '${vedic['guru_rashi'] ?? '-'} • ${vedic['guru_nakshatra'] ?? '-'} (${vedic['guru_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Shukra',
              value:
                  '${vedic['shukra_rashi'] ?? '-'} • ${vedic['shukra_nakshatra'] ?? '-'} (${vedic['shukra_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Shani',
              value:
                  '${vedic['shani_rashi'] ?? '-'} • ${vedic['shani_nakshatra'] ?? '-'} (${vedic['shani_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Rahu',
              value:
                  '${vedic['rahu_rashi'] ?? '-'} • ${vedic['rahu_nakshatra'] ?? '-'} (${vedic['rahu_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Ketu',
              value:
                  '${vedic['ketu_rashi'] ?? '-'} • ${vedic['ketu_nakshatra'] ?? '-'} (${vedic['ketu_pada'] ?? '-'})',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Bhava (House Placements)',
          children: <Widget>[
            _KeyValueRow(
                label: 'Surya House', value: '${bhava['sun_house'] ?? '-'}'),
            _KeyValueRow(
              label: 'Chandra House',
              value: '${bhava['moon_house'] ?? '-'}',
            ),
            _KeyValueRow(
                label: 'Mangal House',
                value: '${bhava['mangal_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Budha House', value: '${bhava['budha_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Guru House', value: '${bhava['guru_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Shukra House',
                value: '${bhava['shukra_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Shani House', value: '${bhava['shani_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Rahu House', value: '${bhava['rahu_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Ketu House', value: '${bhava['ketu_house'] ?? '-'}'),
          ],
        ),
      ],
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

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

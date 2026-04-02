import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_report_models.dart';
import '../../home/presentation/astrology/rashi_insights.dart';
import '../../profile/presentation/profile_page.dart';
import '../../subscription/presentation/subscription_page.dart';

class FeaturesGridPage extends StatelessWidget {
  const FeaturesGridPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  static const List<_FeatureTileData> _featureTiles = <_FeatureTileData>[
    _FeatureTileData(
      code: 'tarot',
      title: 'Tarot Readings',
      icon: Icons.style_rounded,
    ),
    _FeatureTileData(
      code: 'soulmate',
      title: 'Your Soulmate',
      icon: Icons.favorite_outline_rounded,
    ),
    _FeatureTileData(
      code: 'meditation',
      title: 'Meditation',
      icon: Icons.self_improvement_rounded,
    ),
    _FeatureTileData(
      code: 'birth_chart',
      title: 'Birth Chart',
      icon: Icons.donut_large_rounded,
    ),
    _FeatureTileData(
      code: 'dream',
      title: 'Dream Interpretation',
      icon: Icons.bedtime_rounded,
    ),
    _FeatureTileData(
      code: 'astrocartography',
      title: 'Astrocartography',
      icon: Icons.public_rounded,
    ),
    _FeatureTileData(
      code: 'compatibility',
      title: 'Compatibility',
      icon: Icons.volunteer_activism_rounded,
    ),
    _FeatureTileData(
      code: 'rising_sign',
      title: 'Rising Sign',
      icon: Icons.wb_twilight_rounded,
    ),
    _FeatureTileData(
      code: 'celebrity_compatibility',
      title: 'Celebrity Compatibility',
      icon: Icons.people_alt_rounded,
    ),
    _FeatureTileData(
      code: 'fortune_cookie',
      title: 'Fortune Cookie',
      icon: Icons.cookie_rounded,
    ),
    _FeatureTileData(
      code: 'druid',
      title: 'Druid Horoscope',
      icon: Icons.hub_rounded,
    ),
    _FeatureTileData(
      code: 'chinese',
      title: 'Chinese Horoscope',
      icon: Icons.cyclone_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'You'
        : birthInputState.firstName.trim();
    final report = birthInputState.computedReport;

    return UniversalDockScaffold(
      appBar: AppBar(title: const Text('Features')),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const spacing = 12.0;
              final tileWidth = (constraints.maxWidth - 16 - 16 - spacing) / 2;
              const smallCardHeight = 106.0;
              const bigCardHeight = (smallCardHeight * 2) + spacing;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hello, $displayName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore all astrology features in one place.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._buildMosaicSections(
                      context: context,
                      report: report,
                      tileWidth: tileWidth,
                      smallCardHeight: smallCardHeight,
                      bigCardHeight: bigCardHeight,
                      spacing: spacing,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    switch (item) {
      case AppDockItem.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case AppDockItem.profile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return ProfilePage(birthInputState: birthInputState);
            },
          ),
        );
        return;
      case AppDockItem.premium:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return SubscriptionPage(birthInputState: birthInputState);
            },
          ),
        );
        return;
      case AppDockItem.charts:
        return;
      case AppDockItem.menu:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('This tab will be finalized next.')),
          );
        return;
    }
  }

  List<Widget> _buildMosaicSections({
    required BuildContext context,
    required ComputeReportResponse? report,
    required double tileWidth,
    required double smallCardHeight,
    required double bigCardHeight,
    required double spacing,
  }) {
    final sections = <Widget>[];
    for (var start = 0; start < _featureTiles.length; start += 3) {
      final chunk = _featureTiles.skip(start).take(3).toList(growable: false);
      if (chunk.length < 3) {
        sections.add(
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: chunk.map((tile) {
              return SizedBox(
                width: tileWidth,
                child: _FeatureGridCard(
                  data: tile,
                  height: smallCardHeight,
                  chartPreviewLines: _birthChartPreviewForTile(tile, report),
                  onTap: () => _handleFeatureTap(context, tile),
                ),
              );
            }).toList(growable: false),
          ),
        );
        continue;
      }

      final bigOnLeft = (start ~/ 3).isEven;
      final bigTile = chunk[0];
      final topSmallTile = chunk[1];
      final bottomSmallTile = chunk[2];

      final bigCard = SizedBox(
        width: tileWidth,
        child: _FeatureGridCard(
          data: bigTile,
          height: bigCardHeight,
          chartPreviewLines: _birthChartPreviewForTile(bigTile, report),
          onTap: () => _handleFeatureTap(context, bigTile),
        ),
      );
      final stackedSmallCards = SizedBox(
        width: tileWidth,
        child: Column(
          children: <Widget>[
            _FeatureGridCard(
              data: topSmallTile,
              height: smallCardHeight,
              chartPreviewLines:
                  _birthChartPreviewForTile(topSmallTile, report),
              onTap: () => _handleFeatureTap(context, topSmallTile),
            ),
            SizedBox(height: spacing),
            _FeatureGridCard(
              data: bottomSmallTile,
              height: smallCardHeight,
              chartPreviewLines:
                  _birthChartPreviewForTile(bottomSmallTile, report),
              onTap: () => _handleFeatureTap(context, bottomSmallTile),
            ),
          ],
        ),
      );

      sections.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (bigOnLeft) bigCard else stackedSmallCards,
            SizedBox(width: spacing),
            if (bigOnLeft) stackedSmallCards else bigCard,
          ],
        ),
      );
      if (start + 3 < _featureTiles.length) {
        sections.add(SizedBox(height: spacing));
      }
    }
    return sections;
  }

  void _showFeatureToast(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title will be added in the next feature phase.'),
        ),
      );
  }

  void _handleFeatureTap(BuildContext context, _FeatureTileData tile) {
    if (tile.code == 'birth_chart') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ProfilePage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    }
    _showFeatureToast(context, tile.title);
  }

  List<String>? _birthChartPreviewForTile(
    _FeatureTileData tile,
    ComputeReportResponse? report,
  ) {
    if (tile.code != 'birth_chart' || report == null) {
      return null;
    }
    final vedic = report.snapshot.vedic;
    final sun = rashiInsightFor(vedic.sun.rashi);
    final moon = rashiInsightFor(vedic.moon.rashi);
    final rising = rashiInsightFor(vedic.lagna.rashi);
    return <String>[
      '☉ ${sun.name}',
      '☽ ${moon.name}',
      '↑ ${rising.name}',
    ];
  }
}

class _FeatureGridCard extends StatelessWidget {
  const _FeatureGridCard({
    required this.data,
    required this.height,
    required this.chartPreviewLines,
    required this.onTap,
  });

  final _FeatureTileData data;
  final double height;
  final List<String>? chartPreviewLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTall = height > 180;
    final colorScheme = Theme.of(context).colorScheme;
    final isBirthChartCard = chartPreviewLines != null;
    final titleFontSize = isBirthChartCard ? 20.0 : (isTall ? 22.0 : 16.0);
    final titleLineHeight = isTall ? 1.05 : 1.1;
    final titleMaxLines = isBirthChartCard ? 2 : (isTall ? 3 : 2);
    final iconSize = isBirthChartCard ? 30.0 : (isTall ? 34.0 : 24.0);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          color: const Color(0xFF3C096C),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              data.icon,
              size: iconSize,
              color: const Color(0xFFFFE7B3),
            ),
            const SizedBox(height: 6),
            Text(
              data.title,
              maxLines: titleMaxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleFontSize,
                height: titleLineHeight,
                color: const Color(0xFFFFE7B3),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isBirthChartCard) ...<Widget>[
              const SizedBox(height: 8),
              ...(chartPreviewLines ?? const <String>[]).map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Color(0xFFFFE7B3),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ] else ...<Widget>[
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.code,
    required this.title,
    required this.icon,
  });

  final String code;
  final String title;
  final IconData icon;
}

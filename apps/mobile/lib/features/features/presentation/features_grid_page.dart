import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
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
      title: 'Tarot Readings',
      icon: Icons.style_rounded,
    ),
    _FeatureTileData(
      title: 'Your Soulmate',
      icon: Icons.favorite_outline_rounded,
    ),
    _FeatureTileData(
      title: 'Meditation',
      icon: Icons.self_improvement_rounded,
    ),
    _FeatureTileData(
      title: 'Birth Chart',
      icon: Icons.donut_large_rounded,
    ),
    _FeatureTileData(
      title: 'Dream Interpretation',
      icon: Icons.bedtime_rounded,
    ),
    _FeatureTileData(
      title: 'Astrocartography',
      icon: Icons.public_rounded,
    ),
    _FeatureTileData(
      title: 'Compatibility',
      icon: Icons.volunteer_activism_rounded,
    ),
    _FeatureTileData(
      title: 'Rising Sign',
      icon: Icons.wb_twilight_rounded,
    ),
    _FeatureTileData(
      title: 'Celebrity Compatibility',
      icon: Icons.people_alt_rounded,
    ),
    _FeatureTileData(
      title: 'Fortune Cookie',
      icon: Icons.cookie_rounded,
    ),
    _FeatureTileData(
      title: 'Druid Horoscope',
      icon: Icons.hub_rounded,
    ),
    _FeatureTileData(
      title: 'Chinese Horoscope',
      icon: Icons.cyclone_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'You'
        : birthInputState.firstName.trim();

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
                  onTap: () => _showFeatureToast(context, tile.title),
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
          onTap: () => _showFeatureToast(context, bigTile.title),
        ),
      );
      final stackedSmallCards = SizedBox(
        width: tileWidth,
        child: Column(
          children: <Widget>[
            _FeatureGridCard(
              data: topSmallTile,
              height: smallCardHeight,
              onTap: () => _showFeatureToast(context, topSmallTile.title),
            ),
            SizedBox(height: spacing),
            _FeatureGridCard(
              data: bottomSmallTile,
              height: smallCardHeight,
              onTap: () => _showFeatureToast(context, bottomSmallTile.title),
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
}

class _FeatureGridCard extends StatelessWidget {
  const _FeatureGridCard({
    required this.data,
    required this.height,
    required this.onTap,
  });

  final _FeatureTileData data;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTall = height > 180;
    final colorScheme = Theme.of(context).colorScheme;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              data.icon,
              size: isTall ? 34 : 30,
              color: const Color(0xFFFFE7B3),
            ),
            const Spacer(),
            Text(
              data.title,
              style: TextStyle(
                fontSize: isTall ? 22 : 18,
                color: const Color(0xFFFFE7B3),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

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
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Your Soulmate',
      icon: Icons.favorite_outline_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Meditation',
      icon: Icons.self_improvement_rounded,
      isTall: true,
    ),
    _FeatureTileData(
      title: 'Birth Chart',
      icon: Icons.donut_large_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Dream Interpretation',
      icon: Icons.bedtime_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Astrocartography',
      icon: Icons.public_rounded,
      isTall: true,
    ),
    _FeatureTileData(
      title: 'Compatibility',
      icon: Icons.volunteer_activism_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Rising Sign',
      icon: Icons.wb_twilight_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Celebrity Compatibility',
      icon: Icons.people_alt_rounded,
      isTall: true,
    ),
    _FeatureTileData(
      title: 'Fortune Cookie',
      icon: Icons.cookie_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Druid Horoscope',
      icon: Icons.hub_rounded,
      isTall: false,
    ),
    _FeatureTileData(
      title: 'Chinese Horoscope',
      icon: Icons.cyclone_rounded,
      isTall: false,
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
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _featureTiles.map((tile) {
                        return SizedBox(
                          width: tileWidth,
                          child: _FeatureGridCard(
                            data: tile,
                            onTap: () {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${tile.title} will be added in the next feature phase.',
                                    ),
                                  ),
                                );
                            },
                          ),
                        );
                      }).toList(growable: false),
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
}

class _FeatureGridCard extends StatelessWidget {
  const _FeatureGridCard({
    required this.data,
    required this.onTap,
  });

  final _FeatureTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = data.isTall ? 168.0 : 110.0;
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF532A84),
              Color(0xFF4B237A),
            ],
          ),
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
              size: data.isTall ? 34 : 30,
              color: const Color(0xFFFFE7B3),
            ),
            const Spacer(),
            Text(
              data.title,
              style: TextStyle(
                fontSize: data.isTall ? 24 : 18,
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
    required this.isTall,
  });

  final String title;
  final IconData icon;
  final bool isTall;
}

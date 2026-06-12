import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../compatibility/presentation/soulmate_page.dart';
import '../../kaal_sarpa/presentation/kaal_sarpa_page.dart';
import '../../hindu_calendar/presentation/hindu_calendar_page.dart';
import '../../pancha_pakshi/presentation/pancha_pakshi_page.dart';
import 'birth_chart_detail_page.dart';

class FeaturesGridPage extends StatelessWidget {
  const FeaturesGridPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  static const List<_FeatureTileData> _tiles = <_FeatureTileData>[
    _FeatureTileData(
      code: 'birth_chart',
      title: 'Birth Chart',
      description: 'Birth chart module',
      actionLabel: 'Open',
      icon: Icons.donut_large_rounded,
      visualStyle: _FeatureVisualStyle.primary,
    ),
    _FeatureTileData(
      code: 'soulmate',
      title: 'Your Soulmate',
      description: 'Soulmate module',
      actionLabel: 'Open',
      icon: Icons.favorite_outline_rounded,
      visualStyle: _FeatureVisualStyle.supportive,
    ),
    _FeatureTileData(
      code: 'pancha_pakshi',
      title: 'Pancha Pakshi',
      description: 'Pancha Pakshi module',
      actionLabel: 'Open',
      icon: Icons.schedule_rounded,
      visualStyle: _FeatureVisualStyle.supportive,
    ),
    _FeatureTileData(
      code: 'mangal_dosh',
      title: 'Mangal Dosh',
      description: 'Mangal Dosh module',
      actionLabel: 'Open',
      icon: Icons.local_fire_department_rounded,
      badge: 'Partner',
      visualStyle: _FeatureVisualStyle.caution,
    ),
    _FeatureTileData(
      code: 'kaal_sarpa_dosh',
      title: 'Kaal Sarpa Dosh',
      description: 'Kaal Sarpa Dosh module',
      actionLabel: 'Open',
      icon: Icons.brightness_3_rounded,
      visualStyle: _FeatureVisualStyle.caution,
    ),
    _FeatureTileData(
      code: 'hindu_calendar',
      title: 'Hindu Calendar',
      description: 'Hindu lunar calendar module',
      actionLabel: 'Open',
      icon: Icons.calendar_today_rounded,
      visualStyle: _FeatureVisualStyle.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onCurrentLocationTap: () => showCurrentLocationPickerSheet(
          context: context,
          birthInputState: birthInputState,
        ),
        currentLocationLabel: birthInputState.placeForCurrentObservations,
        onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (BuildContext context, int index) {
                final tile = _tiles[index];
                return _FeatureCard(
                  tile: tile,
                  onTap: () => _handleFeatureTap(context, tile),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.charts,
      birthInputState: birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.stay,
    );
  }

  void _handleFeatureTap(BuildContext context, _FeatureTileData tile) {
    if (tile.code == 'birth_chart') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return BirthChartDetailPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    }

    if (tile.code == 'pancha_pakshi') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return PanchaPakshiPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    }

    if (tile.code == 'soulmate') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SoulmatePage(
              birthInputState: birthInputState,
              entryPoint: SoulmateEntryPoint.soulmate,
            );
          },
        ),
      );
      return;
    }

    if (tile.code == 'mangal_dosh') {
      final partner = birthInputState.compatibilityPartnerProfile;
      final partnerReady = partner != null && partner.isComplete;
      if (!partnerReady) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Add partner details in Your Soulmate first. We will reuse them for Mangal Dosh.',
              ),
            ),
          );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return SoulmatePage(
                birthInputState: birthInputState,
                entryPoint: SoulmateEntryPoint.soulmate,
                startWithPartnerForm: true,
              );
            },
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SoulmatePage(
              birthInputState: birthInputState,
              entryPoint: SoulmateEntryPoint.mangalDosh,
            );
          },
        ),
      );
      return;
    }

    if (tile.code == 'kaal_sarpa_dosh') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return KaalSarpaPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    }

    if (tile.code == 'hindu_calendar') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return HinduCalendarPage(birthInputState: birthInputState);
          },
        ),
      );
    }
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.tile,
    required this.onTap,
  });

  final _FeatureTileData tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundAsset = _backgroundAssetForCode(tile.code);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: TrikaalSurface.decoration(
              colorScheme: colorScheme,
              radius: 18,
              fillAlpha: 1,
              image: backgroundAsset == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(backgroundAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      opacity: 0.56,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.10),
                        BlendMode.darken,
                      ),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (backgroundAsset == null) ...<Widget>[
                    Text(
                      _emojiForCode(tile.code),
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    tile.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emojiForCode(String code) {
    switch (code) {
      case 'birth_chart':
        return '🪐';
      case 'soulmate':
        return '💞';
      case 'pancha_pakshi':
        return '🕊️';
      case 'mangal_dosh':
        return '🔥';
      case 'kaal_sarpa_dosh':
        return '🐍';
      case 'hindu_calendar':
        return '📅';
      default:
        return '✨';
    }
  }

  String? _backgroundAssetForCode(String code) {
    switch (code) {
      case 'birth_chart':
        return 'assets/feature_cards/birth_chart_bg.png';
      case 'mangal_dosh':
        return 'assets/feature_cards/mangal_dosh_bg.png';
      case 'kaal_sarpa_dosh':
        return 'assets/feature_cards/kaal_sarpa_dosh_bg.png';
      case 'pancha_pakshi':
        return 'assets/feature_cards/pancha_pakshi_bg.png';
      case 'soulmate':
        return 'assets/feature_cards/soulmate_bg.png';
      case 'hindu_calendar':
        return 'assets/feature_cards/hindu_calendar_bg.png';
      default:
        return null;
    }
  }
}

enum _FeatureVisualStyle {
  primary,
  supportive,
  caution,
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.code,
    required this.title,
    this.description = '',
    this.actionLabel = '',
    this.icon = Icons.auto_awesome_rounded,
    this.badge,
    this.visualStyle = _FeatureVisualStyle.supportive,
  });

  final String code;
  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;
  final String? badge;
  final _FeatureVisualStyle visualStyle;
}

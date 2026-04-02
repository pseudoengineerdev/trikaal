import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../features/presentation/features_grid_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../subscription/presentation/subscription_page.dart';
import 'astrology/rashi_insights.dart';

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  Widget build(BuildContext context) {
    final report = birthInputState.computedReport;
    if (report == null) {
      return UniversalDockScaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Trikaal',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Samarkan',
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        activeItem: AppDockItem.home,
        onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
        body: AstroPageBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.auto_awesome_rounded, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'We need your birth mix to build your personalized home.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final vedic = report.snapshot.vedic;
    final sun = rashiInsightFor(vedic.sun.rashi);
    final moon = rashiInsightFor(vedic.moon.rashi);
    final rising = rashiInsightFor(vedic.lagna.rashi);
    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'Your Profile'
        : birthInputState.firstName.trim();

    return UniversalDockScaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Trikaal',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'Samarkan',
                fontSize: 40,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
      activeItem: AppDockItem.home,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, $displayName',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                _HomeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Your Sign Trio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _SignPill(label: '☉ ${sun.name} ${sun.symbol}'),
                          _SignPill(label: '☽ ${moon.name} ${moon.symbol}'),
                          _SignPill(label: '↑ ${rising.name} ${rising.symbol}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the center profile button for your full "About You" section.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    switch (item) {
      case AppDockItem.home:
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
      case AppDockItem.charts:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return FeaturesGridPage(birthInputState: birthInputState);
            },
          ),
        );
        return;
      case AppDockItem.menu:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('This tab will be finalized next.')),
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
    }
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _SignPill extends StatelessWidget {
  const _SignPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: 0.32,
            ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

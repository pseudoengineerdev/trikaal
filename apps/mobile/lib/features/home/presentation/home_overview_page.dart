import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
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
      return _DockedScaffold(
        appBar: AppBar(title: const Text('Trikaal')),
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

    return _DockedScaffold(
      appBar: AppBar(
        title: const Text('Trikaal'),
      ),
      body: AstroPageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, $displayName',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${birthInputState.dateOfBirth} • ${birthInputState.timeOfBirth} • ${birthInputState.placeOfBirth}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                const SizedBox(height: 14),
                _HomeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'About You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SignTraitTile(
                        title: 'Core Personality',
                        subtitle: 'Sun in ${sun.name} ${sun.symbol}',
                        body: sun.sunTrait,
                        leadingEmoji: '☀️',
                      ),
                      const SizedBox(height: 10),
                      _SignTraitTile(
                        title: 'Emotional Nature',
                        subtitle: 'Moon in ${moon.name} ${moon.symbol}',
                        body: moon.moonTrait,
                        leadingEmoji: '🌙',
                      ),
                      const SizedBox(height: 10),
                      _SignTraitTile(
                        title: 'How Others See You',
                        subtitle: 'Rising in ${rising.name} ${rising.symbol}',
                        body: rising.risingTrait,
                        leadingEmoji: '⬆️',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Charts and Dasha will be moved into a dedicated section next.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _DockedScaffold extends StatelessWidget {
  const _DockedScaffold({
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'profile-docked-fab',
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Profile section coming soon.')),
            );
        },
        tooltip: 'Profile',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.person_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: colorScheme.surface.withValues(alpha: 0.92),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const <Widget>[
              _DockIcon(icon: Icons.auto_awesome_outlined),
              _DockIcon(icon: Icons.grid_view_rounded),
              SizedBox(width: 46),
              _DockIcon(icon: Icons.timeline_rounded),
              _DockIcon(icon: Icons.menu_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('This tab will be finalized next.')),
          );
      },
      icon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Coming soon',
    );
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
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SignTraitTile extends StatelessWidget {
  const _SignTraitTile({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.leadingEmoji,
  });

  final String title;
  final String subtitle;
  final String body;
  final String leadingEmoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          leadingEmoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

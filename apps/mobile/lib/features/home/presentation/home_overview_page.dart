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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
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
                const SizedBox(height: 12),
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
    return Scaffold(
      extendBody: true,
      appBar: appBar,
      body: body,
      bottomNavigationBar: const _CurvedDockBar(),
    );
  }
}

class _CurvedDockBar extends StatelessWidget {
  const _CurvedDockBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: const _CurvedDockClipper(),
                  child: Container(
                    height: 72,
                    color: colorScheme.surface.withValues(alpha: 0.98),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _DockIcon(icon: Icons.auto_awesome_outlined),
                        _DockIcon(icon: Icons.grid_view_rounded),
                        SizedBox(width: 56),
                        _DockIcon(icon: Icons.timeline_rounded),
                        _DockIcon(icon: Icons.menu_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: Material(
                color: colorScheme.primary,
                shape: const CircleBorder(
                  side: BorderSide(
                    color: Color(0x1FFFFFFF),
                    width: 1.2,
                  ),
                ),
                elevation: 8,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Profile section coming soon.'),
                        ),
                      );
                  },
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedDockClipper extends CustomClipper<Path> {
  const _CurvedDockClipper();

  @override
  Path getClip(Size size) {
    const cornerRadius = 32.0;
    const notchRadius = 30.0;
    const notchDepth = 30.0;
    const notchSideInset = 8.0;

    final width = size.width;
    final centerX = width / 2;
    final notchStartX = centerX - notchRadius - notchSideInset;
    final notchEndX = centerX + notchRadius + notchSideInset;

    final path = Path()
      ..moveTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(notchStartX, 0)
      ..cubicTo(
        centerX - notchRadius,
        0,
        centerX - notchRadius + 4,
        notchDepth,
        centerX,
        notchDepth,
      )
      ..cubicTo(
        centerX + notchRadius - 4,
        notchDepth,
        centerX + notchRadius,
        0,
        notchEndX,
        0,
      )
      ..lineTo(width - cornerRadius, 0)
      ..quadraticBezierTo(width, 0, width, cornerRadius)
      ..lineTo(width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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

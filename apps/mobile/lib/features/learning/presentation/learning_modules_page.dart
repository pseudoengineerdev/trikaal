import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../shared/astrology/sign_trio_insights.dart';

class LearningModulesPage extends StatelessWidget {
  const LearningModulesPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  static const List<_LearningModule> _starterModules = <_LearningModule>[
    _LearningModule(
      id: 'app_map',
      badge: 'Start here',
      title: 'How to Use Trikaal',
      summary:
          'Learn what each area of the app does so users never feel buried under features.',
      duration: '4 min',
      level: 'Beginner',
      icon: Icons.dashboard_customize_rounded,
      colors: <Color>[Color(0xFF3B136A), Color(0xFF6B30C9)],
      tags: <String>['Home', 'Reports', 'Guidance'],
      overview:
          'Trikaal works best when people know where to begin. This module introduces the home summary, feature grid, profile, premium insights, and the best order to explore them.',
      whyItMatters:
          'Without orientation, advanced astrology features can feel like too much too fast. This lesson gives users a calm entry point and shows which screen answers which kind of question.',
      keyLessons: <String>[
        'Home is the quick snapshot of who you are and what to pay attention to first.',
        'The feature grid is where users branch into specific readings and deeper tools.',
        'Profile keeps the personal chart summary in one place for easy revisiting.',
        'Premium expands depth, but the basics should feel understandable before anyone upgrades.',
      ],
      inAppConnections: <String>[
        'Home overview welcome card and sign trio snapshot',
        'Features grid for deeper reports',
        'Profile page for the personal chart summary',
        'Premium plans for expanded insights and reports',
      ],
    ),
    _LearningModule(
      id: 'sign_trio',
      badge: 'Core concept',
      title: 'Your Sign Trio',
      summary:
          'Understand why Sun, Moon, and Rising together tell a fuller story than one sign alone.',
      duration: '5 min',
      level: 'Essential',
      icon: Icons.auto_awesome_rounded,
      colors: <Color>[Color(0xFF32104D), Color(0xFF9B4DFF)],
      tags: <String>['Sun', 'Moon', 'Rising'],
      overview:
          'Most people know only their Sun sign, but Trikaal becomes clearer when users read their identity, emotional nature, and outer approach as one combined pattern.',
      whyItMatters:
          'The app already surfaces a sign trio because different features may reflect different parts of a person. This module teaches users how to hold those layers together instead of assuming the app is contradicting itself.',
      keyLessons: <String>[
        'Sun sign points to identity, vitality, and the way someone wants to shine.',
        'Moon sign speaks to emotional needs, instinctive reactions, and inner rhythm.',
        'Rising sign shows how someone approaches life and how others tend to experience them first.',
        'Reading all three together explains why a user may feel deeply unlike generic Sun-sign content online.',
      ],
      inAppConnections: <String>[
        'Home sign trio pills',
        'Profile summary line',
        'Birth chart detail page and future concept explainers',
      ],
    ),
    _LearningModule(
      id: 'birth_chart_basics',
      badge: 'Foundation',
      title: 'Birth Chart Basics',
      summary:
          'Get a simple framework for signs, houses, planets, and how Trikaal turns them into readable insight.',
      duration: '6 min',
      level: 'Beginner',
      icon: Icons.donut_large_rounded,
      colors: <Color>[Color(0xFF231447), Color(0xFF5B3FE7)],
      tags: <String>['Signs', 'Houses', 'Planets'],
      overview:
          'A birth chart is a snapshot of the sky at the moment of birth. Trikaal interprets where the planets were, which signs they occupied, and how houses shape lived experience.',
      whyItMatters:
          'Once users understand this map, every feature in the app feels more grounded. It also prepares them for concepts like ascendant, dominant energies, and house-based interpretations.',
      keyLessons: <String>[
        'Signs describe style and quality of expression.',
        'Planets describe the type of energy or function being expressed.',
        'Houses describe where that energy tends to show up in life.',
        'A useful reading blends all three instead of isolating one symbol.',
      ],
      inAppConnections: <String>[
        'Birth chart detail wheel and tables',
        'Planet and house-based report sections',
        'Profile chart summary',
      ],
    ),
  ];

  static const List<_LearningModule> _deepDiveModules = <_LearningModule>[
    _LearningModule(
      id: 'sun_sign',
      badge: 'Deep dive',
      title: 'Sun Sign',
      summary:
          'See what the Sun really means beyond pop-astrology personality labels.',
      duration: '3 min',
      level: 'Beginner',
      icon: Icons.wb_sunny_outlined,
      colors: <Color>[Color(0xFF4A180E), Color(0xFFCB5E2E)],
      tags: <String>['Identity', 'Vitality', 'Purpose'],
      overview:
          'The Sun represents life force, confidence, creative expression, and the direction a person naturally grows toward.',
      whyItMatters:
          'Users often think the Sun sign is the whole chart. Teaching its real role helps them appreciate the rest of Trikaal instead of flattening everything into one label.',
      keyLessons: <String>[
        'The Sun is about conscious identity and the way someone wants to express their essence.',
        'It often shows pride, purpose, leadership style, and what feels energizing.',
        'A strong Sun reading does not cancel emotional complexity from the Moon or presentation from the Rising sign.',
      ],
      inAppConnections: <String>[
        'Home sign trio and trait summaries',
        'Profile overview and future self-understanding lessons',
      ],
    ),
    _LearningModule(
      id: 'moon_sign',
      badge: 'Deep dive',
      title: 'Moon Sign',
      summary:
          'Explore the inner world: emotions, comfort, memory, and instinctive reactions.',
      duration: '4 min',
      level: 'Essential',
      icon: Icons.dark_mode_rounded,
      colors: <Color>[Color(0xFF1B275A), Color(0xFF536DFF)],
      tags: <String>['Emotions', 'Instinct', 'Inner world'],
      overview:
          'The Moon shows how someone feels, self-soothes, reacts under stress, and experiences intimacy, safety, and belonging.',
      whyItMatters:
          'Many users say they relate to their Moon sign more than their Sun sign. This lesson gives them language for that experience and helps them understand why Trikaal may highlight different traits in different contexts.',
      keyLessons: <String>[
        'The Moon is private and emotional, often showing what is needed to feel safe and nourished.',
        'It explains mood patterns, memory, softness, and what gets felt deeply.',
        'Moon insights can be especially helpful in relationship, lifestyle, and timing features.',
      ],
      inAppConnections: <String>[
        'Sign trio summary and compatibility-style readings',
        'Mood, comfort, and relationship interpretations',
      ],
    ),
    _LearningModule(
      id: 'rising_sign',
      badge: 'Deep dive',
      title: 'Rising Sign',
      summary:
          'Understand the ascendant: first impressions, instinctive approach, and chart structure.',
      duration: '4 min',
      level: 'Essential',
      icon: Icons.north_rounded,
      colors: <Color>[Color(0xFF0E354B), Color(0xFF28A9D9)],
      tags: <String>['Ascendant', 'Approach', 'Outer style'],
      overview:
          'The Rising sign, also called the Ascendant or Lagna, is the sign rising on the eastern horizon at birth. It shapes first impressions and anchors the house structure of the chart.',
      whyItMatters:
          'This is one of the most useful ideas to teach because it helps users understand why the app may describe how they move through life, not just how they feel inside.',
      keyLessons: <String>[
        'Rising sign influences the lens through which someone meets the world.',
        'It often affects presentation, body language, pace, and initial instinct.',
        'Because it sets up the houses, it is structurally important in chart interpretation.',
      ],
      inAppConnections: <String>[
        'Home sign trio pills and profile header',
        'Birth chart detail tables and Lagna references',
      ],
    ),
    _LearningModule(
      id: 'panch_pakshi',
      badge: 'Advanced intro',
      title: 'Panch Pakshi',
      summary:
          'Introduce the five-bird timing system and why it matters for action, rest, and rhythm.',
      duration: '6 min',
      level: 'Advanced',
      icon: Icons.schedule_rounded,
      colors: <Color>[Color(0xFF203B2B), Color(0xFF53A97D)],
      tags: <String>['Timing', 'Rhythm', 'Action windows'],
      overview:
          'Panch Pakshi is a traditional timing system that maps five symbolic birds to changing states of strength and activity. It is often used to identify supportive or weak periods for different kinds of actions.',
      whyItMatters:
          'When users understand that Panch Pakshi is about timing and energetic quality, they can relate it to planning, decision-making, and readiness instead of seeing it as an obscure label.',
      keyLessons: <String>[
        'The system focuses on quality of time, not just personality traits.',
        'Different states indicate when an energy is more active, passive, supported, or constrained.',
        'Users benefit most when Panch Pakshi is framed as a practical rhythm tool rather than a mysterious extra feature.',
      ],
      inAppConnections: <String>[
        'Timing-oriented recommendations and future activity guidance',
        'Learning content that explains when to act, pause, or observe',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final report = birthInputState.computedReport;
    final trio = report == null ? null : SignTrioInsights.fromReport(report);
    final totalModuleCount = _starterModules.length + _deepDiveModules.length;

    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.learning,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LearningHeroCard(
                  totalModuleCount: totalModuleCount,
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  title: 'Start Here',
                  subtitle:
                      'These lessons reduce overwhelm fast and make the rest of the app easier to trust.',
                ),
                const SizedBox(height: 12),
                ..._starterModules.map(
                  (_LearningModule module) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LearningModuleCard(
                      module: module,
                      onTap: () => _showLessonSheet(
                        context,
                        module,
                        trio: trio,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _SectionHeading(
                  title: 'Go Deeper',
                  subtitle:
                      'Concept-by-concept lessons that help users understand what each Trikaal insight is actually saying.',
                ),
                const SizedBox(height: 12),
                ..._deepDiveModules.map(
                  (_LearningModule module) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LearningModuleCard(
                      module: module,
                      onTap: () => _showLessonSheet(
                        context,
                        module,
                        trio: trio,
                      ),
                    ),
                  ),
                ),
              ],
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
      activeItem: AppDockItem.learning,
      birthInputState: birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.pushFeatures,
    );
  }

  void _showLessonSheet(
    BuildContext context,
    _LearningModule module, {
    required SignTrioInsights? trio,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _LearningLessonSheet(
          module: module,
          trio: trio,
        );
      },
    );
  }
}

class _LearningHeroCard extends StatelessWidget {
  const _LearningHeroCard({
    required this.totalModuleCount,
  });

  final int totalModuleCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.24),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF18092F),
            Color(0xFF2A0F4C),
            Color(0xFF3E176C),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    _HeroChip(label: '$totalModuleCount guided lessons'),
                    const _HeroChip(label: 'Built for first-time users'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Learn the why behind your chart.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This space helps you understand what Trikaal is showing, why it matters, and how each insight connects to your life.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Look deeper than surface astrology',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'These lessons are built to pull you into Vedic roots, ancient context, and the deeper logic behind how chart systems were practiced and passed down.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningModuleCard extends StatelessWidget {
  const _LearningModuleCard({
    required this.module,
    required this.onTap,
  });

  final _LearningModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashFactory: InkSparkle.splashFactory,
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.9),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: module.colors,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Icon(module.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _ModulePill(label: module.badge),
                        _ModulePill(label: module.level),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                module.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                module.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: module.tags
                    .map(
                      (String tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                        child: Text(
                          tag,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningLessonSheet extends StatelessWidget {
  const _LearningLessonSheet({
    required this.module,
    required this.trio,
  });

  final _LearningModule module;
  final SignTrioInsights? trio;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF1E093D),
              Color(0xFF130528),
            ],
          ),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.85),
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: module.colors,
                            ),
                          ),
                          child: Icon(module.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _ModulePill(label: module.badge),
                                  _ModulePill(label: module.level),
                                  _ModulePill(label: module.duration),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                module.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(height: 1.05),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                module.summary,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (module.id == 'sign_trio' && trio != null) ...<Widget>[
                      const SizedBox(height: 18),
                      _LessonCallout(
                        title: 'Use the real chart as the teacher',
                        body:
                            'This user\'s trio is ${trio!.sun.name} Sun, ${trio!.moon.name} Moon, and ${trio!.rising.name} Rising. That makes the abstract idea immediately concrete.',
                      ),
                    ],
                    const SizedBox(height: 20),
                    _LessonSection(
                      title: 'What This Means',
                      body: module.overview,
                    ),
                    const SizedBox(height: 16),
                    _LessonSection(
                      title: 'Why It Matters In Trikaal',
                      body: module.whyItMatters,
                    ),
                    const SizedBox(height: 18),
                    _LessonBulletSection(
                      title: 'What Users Should Learn',
                      items: module.keyLessons,
                    ),
                    const SizedBox(height: 18),
                    _LessonBulletSection(
                      title: 'Where It Shows Up In The App',
                      items: module.inAppConnections,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close lesson',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _LessonSection extends StatelessWidget {
  const _LessonSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LessonBulletSection extends StatelessWidget {
  const _LessonBulletSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCallout extends StatelessWidget {
  const _LessonCallout({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF41236B), Color(0xFF241042)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
      ),
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
      ),
    );
  }
}

class _LearningModule {
  const _LearningModule({
    required this.id,
    required this.badge,
    required this.title,
    required this.summary,
    required this.duration,
    required this.level,
    required this.icon,
    required this.colors,
    required this.tags,
    required this.overview,
    required this.whyItMatters,
    required this.keyLessons,
    required this.inAppConnections,
  });

  final String id;
  final String badge;
  final String title;
  final String summary;
  final String duration;
  final String level;
  final IconData icon;
  final List<Color> colors;
  final List<String> tags;
  final String overview;
  final String whyItMatters;
  final List<String> keyLessons;
  final List<String> inAppConnections;
}

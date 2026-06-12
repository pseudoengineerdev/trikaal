import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/state/birth_input_state.dart';
import '../../../../app/theme/trikaal_surface.dart';
import '../../../shared/astrology/sign_trio_insights.dart';
import '../../data/daily_insights_repository.dart';
import '../../domain/daily_insights.dart';

const List<String> _monthNames = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _weekdayNames = <String>[
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
  'Saturday', 'Sunday',
];

/// The home Today tab: date hero with orbit art, reading scope pills,
/// the personalized reading, and the six Vedic level meters.
class TodayView extends StatefulWidget {
  const TodayView({
    required this.birthInputState,
    this.repository = const PlaceholderDailyInsightsRepository(),
    this.now,
    super.key,
  });

  final BirthInputState birthInputState;
  final DailyInsightsRepository repository;

  /// Injectable for tests; defaults to the wall clock.
  final DateTime? now;

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  ReadingScope _scope = ReadingScope.today;
  Map<ReadingScope, DailyReading>? _readings;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final report = widget.birthInputState.computedReport;
    if (report == null) {
      return;
    }
    final trio = SignTrioInsights.fromReport(report);
    final now = widget.now ?? DateTime.now();
    final entries = await Future.wait(
      ReadingScope.values.map((ReadingScope scope) async {
        final anchor = scope == ReadingScope.tomorrow
            ? now.add(const Duration(days: 1))
            : now;
        final reading = await widget.repository.fetchReading(
          scope: scope,
          anchor: anchor,
          trio: trio,
        );
        return MapEntry(scope, reading);
      }),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _readings = Map<ReadingScope, DailyReading>.fromEntries(entries);
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.birthInputState.computedReport;
    if (report == null) {
      return const SizedBox.shrink();
    }
    final now = widget.now ?? DateTime.now();
    final reading = _readings?[_scope];
    final firstName = widget.birthInputState.firstName.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DateHero(now: now, firstName: firstName),
          const SizedBox(height: 18),
          _ScopePills(
            activeScope: _scope,
            onScopeSelected: (ReadingScope scope) {
              if (scope != _scope) {
                setState(() => _scope = scope);
              }
            },
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: reading == null
                ? const Padding(
                    key: ValueKey<String>('loading'),
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    key: ValueKey<ReadingScope>(_scope),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionTitle('Your reading for ${_scope.phrase}'),
                      const SizedBox(height: 10),
                      _ReadingCard(text: reading.text),
                      const SizedBox(height: 22),
                      _SectionTitle(_levelsTitle(_scope)),
                      const SizedBox(height: 10),
                      _MetricGrid(metrics: reading.metrics),
                      const SizedBox(height: 8),
                      const _PreviewFootnote(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _levelsTitle(ReadingScope scope) {
    switch (scope) {
      case ReadingScope.today:
        return "Today's levels";
      case ReadingScope.tomorrow:
        return "Tomorrow's levels";
      case ReadingScope.weekly:
        return "This week's levels";
      case ReadingScope.monthly:
        return "This month's levels";
    }
  }
}

class _DateHero extends StatelessWidget {
  const _DateHero({required this.now, required this.firstName});

  final DateTime now;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (firstName.isNotEmpty) ...<Widget>[
                Text(
                  'Namaste, $firstName',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                '${_monthNames[now.month - 1]} ${now.day}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _weekdayNames[now.weekday - 1],
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const SizedBox(
          width: 118,
          height: 96,
          child: CustomPaint(painter: _OrbitArtPainter()),
        ),
      ],
    );
  }
}

/// Decorative orbit illustration beside the date: two elliptical orbits,
/// a glowing central body, satellites, and scattered stars.
class _OrbitArtPainter extends CustomPainter {
  const _OrbitArtPainter();

  static const Color _mauve = Color(0xFFC77DFF);
  static const Color _paleMauve = Color(0xFFE0AAFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.56, size.height * 0.52);

    void drawOrbit({
      required double radiusX,
      required double radiusY,
      required double angle,
      required Color color,
      double? satelliteAt,
      double satelliteRadius = 3.2,
    }) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: radiusX * 2,
        height: radiusY * 2,
      );
      canvas.drawOval(rect, orbitPaint);

      if (satelliteAt != null) {
        final satelliteCenter = Offset(
          radiusX * math.cos(satelliteAt),
          radiusY * math.sin(satelliteAt),
        );
        canvas.drawCircle(
          satelliteCenter,
          satelliteRadius + 2.6,
          Paint()
            ..color = _mauve.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          satelliteCenter,
          satelliteRadius,
          Paint()..color = _paleMauve,
        );
      }
      canvas.restore();
    }

    drawOrbit(
      radiusX: size.width * 0.46,
      radiusY: size.height * 0.27,
      angle: -0.42,
      color: _paleMauve.withValues(alpha: 0.40),
      satelliteAt: 3.9,
      satelliteRadius: 3.4,
    );
    drawOrbit(
      radiusX: size.width * 0.33,
      radiusY: size.height * 0.40,
      angle: 0.62,
      color: _mauve.withValues(alpha: 0.32),
      satelliteAt: 1.1,
      satelliteRadius: 2.6,
    );

    // Central glowing body.
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = _mauve.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      center,
      6.4,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFF1DCFF), _mauve],
        ).createShader(Rect.fromCircle(center: center, radius: 6.4)),
    );

    // Scattered stars.
    final starPaint = Paint()..color = _paleMauve.withValues(alpha: 0.55);
    const stars = <Offset>[
      Offset(0.10, 0.16),
      Offset(0.88, 0.12),
      Offset(0.94, 0.62),
      Offset(0.16, 0.82),
      Offset(0.55, 0.04),
    ];
    for (final star in stars) {
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        1.1,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitArtPainter oldDelegate) => false;
}

class _ScopePills extends StatelessWidget {
  const _ScopePills({
    required this.activeScope,
    required this.onScopeSelected,
  });

  final ReadingScope activeScope;
  final ValueChanged<ReadingScope> onScopeSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: <Widget>[
          for (final scope in ReadingScope.values) ...<Widget>[
            if (scope != ReadingScope.values.first) const SizedBox(width: 8),
            Semantics(
              button: true,
              selected: scope == activeScope,
              child: GestureDetector(
                onTap: () => onScopeSelected(scope),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: scope == activeScope
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF7D33C3),
                              Color(0xFF5A189A),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF5A189A)
                                  .withValues(alpha: 0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: TrikaalSurface.fill(),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                  child: Text(
                    scope.pillLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: scope == activeScope
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: scope == activeScope
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17.5),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        // IntrinsicHeight lets the accent bar stretch to the text's height
        // inside the unbounded scroll column.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFC77DFF), Color(0xFF5A189A)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<DailyMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DailyMetric metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    metric.glyph,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        metric.basis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricMeter(strength: metric.strength),
            const SizedBox(height: 7),
            Text(
              metric.tierLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricMeter extends StatelessWidget {
  const _MetricMeter({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 7,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(color: colorScheme.surfaceContainerHighest),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: strength.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF7D33C3), Color(0xFFC77DFF)],
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

class _PreviewFootnote extends StatelessWidget {
  const _PreviewFootnote();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85);
    return Row(
      children: <Widget>[
        Icon(Icons.auto_awesome_outlined, size: 12, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Preview levels — your precise Vedic engine is on its way.',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}


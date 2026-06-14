import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import '../data/models/transit_models.dart';
import '../domain/gochar_insights.dart';
import 'state/gochar_controller.dart';

const Color _goldAccent = Color(0xFFE8C97A);

const List<String> _monthAbbr = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdayAbbr = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Dedicated Gochar (planetary transit) page. It reads every graha's live
/// position against the user's natal Moon and Lagna and layers on the classical
/// transit verdict (phala + vedha), Saturn's Sade Sati window, and the
/// Ashtakavarga transit strength.
class GocharPage extends StatefulWidget {
  const GocharPage({
    required this.birthInputState,
    this.controller,
    this.now,
    super.key,
  });

  final BirthInputState birthInputState;
  final GocharController? controller;
  final DateTime Function()? now;

  @override
  State<GocharPage> createState() => _GocharPageState();
}

class _GocharPageState extends State<GocharPage> {
  late final GocharController _controller;
  late final bool _ownsController;
  late final DateTime Function() _now;

  bool _autoComputeAttempted = false;
  String? _lastSignature;
  bool _fromMoon = true;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now;
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? GocharController(now: _now);

    TerminologyModeState.shared.load();

    _lastSignature = _inputSignature();
    widget.birthInputState.addListener(_handleInputChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoComputeAttempted || !_canCompute) {
        return;
      }
      _autoComputeAttempted = true;
      _load();
    });
  }

  @override
  void dispose() {
    widget.birthInputState.removeListener(_handleInputChange);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool get _canCompute {
    final state = widget.birthInputState;
    return state.dateOfBirth.trim().isNotEmpty &&
        state.timeOfBirth.trim().isNotEmpty &&
        state.placeOfBirth.trim().isNotEmpty;
  }

  String? _inputSignature() {
    final state = widget.birthInputState;
    if (!_canCompute) {
      return null;
    }
    return <String>[
      state.dateOfBirth,
      state.timeOfBirth,
      state.placeOfBirth,
      state.placeForCurrentObservations,
    ].join('|');
  }

  Future<void> _load() {
    final state = widget.birthInputState;
    return _controller.load(
      dateOfBirth: state.dateOfBirth.trim(),
      timeOfBirth: state.timeOfBirth.trim(),
      placeOfBirth: state.placeOfBirth.trim(),
      customPlace: state.customPlace,
      observationPlace: state.placeForCurrentObservations,
      observationCustomPlace: state.customPlaceForCurrentObservations,
    );
  }

  void _handleInputChange() {
    final signature = _inputSignature();
    if (signature == _lastSignature) {
      return;
    }
    _lastSignature = signature;
    if (!_canCompute) {
      return;
    }
    _autoComputeAttempted = true;
    _load();
  }

  void _handleDockTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.charts,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.popOne,
    );
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onCurrentLocationTap: () => showCurrentLocationPickerSheet(
          context: context,
          birthInputState: widget.birthInputState,
        ),
        currentLocationLabel: widget.birthInputState.placeForCurrentObservations,
        onCalendarTap: () => openHinduCalendar(context, widget.birthInputState),
        onPremiumTap: () => _handleDockTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _controller,
              TerminologyModeState.shared,
              widget.birthInputState,
            ]),
            builder: (BuildContext context, Widget? _) => _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_canCompute) {
      return const _StateMessage(
        title: 'Birth details needed',
        body: 'Add your date, time and place of birth so we can measure the '
            'planets transiting against your Moon and Lagna.',
      );
    }

    if (_controller.loading && _controller.result == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_controller.error != null && _controller.result == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: <Widget>[
          _header(context, null),
          const SizedBox(height: 14),
          ErrorCard(
            message: _controller.error!,
            onRetry: _canCompute ? _load : null,
          ),
        ],
      );
    }

    final response = _controller.result;
    if (response == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final mode = TerminologyModeState.shared.mode;

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: <Widget>[
          _header(context, response),
          const SizedBox(height: 12),
          _DateNavigator(
            controller: _controller,
            onPickDate: () => _pickDate(context),
          ),
          const SizedBox(height: 12),
          _ReferenceToggle(
            fromMoon: _fromMoon,
            natal: response.natal,
            mode: mode,
            onChanged: (bool value) => setState(() => _fromMoon = value),
          ),
          if (response.highlights.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _HighlightsStrip(response: response, mode: mode),
          ],
          const SizedBox(height: 14),
          _SaturnCard(saturn: response.saturn, mode: mode),
          const SizedBox(height: 12),
          _DoubleTransitCard(
            doubleTransit: response.doubleTransit,
            natal: response.natal,
            mode: mode,
          ),
          const SizedBox(height: 12),
          _TransitTableCard(
            response: response,
            mode: mode,
            fromMoon: _fromMoon,
          ),
          const SizedBox(height: 12),
          _AshtakavargaCard(response: response, mode: mode),
          const SizedBox(height: 12),
          const _AboutGocharCard(),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = DateTime.tryParse(_controller.selectedDate) ?? _now();
    final today = _now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: today.subtract(const Duration(days: 366)),
      lastDate: today.add(const Duration(days: 366)),
      helpText: 'View transits for a day',
    );
    if (picked == null) {
      return;
    }
    final currentDay = DateTime(current.year, current.month, current.day);
    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    final delta = pickedDay.difference(currentDay).inDays;
    if (delta != 0) {
      await _controller.stepDay(delta);
    }
  }

  Widget _header(BuildContext context, TransitComputeResponse? response) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final mode = TerminologyModeState.shared.mode;
    final place = widget.birthInputState.placeForCurrentObservations;

    String? moonLine;
    if (response != null) {
      final moon = _pick(response.natal.moonRashi, mode);
      moonLine = 'Moon in $moon';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'GOCHAR',
          style: textTheme.labelLarge?.copyWith(
            color: _goldAccent,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Planet Transits',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          <String?>[moonLine, place]
              .where((String? part) => part != null && part.trim().isNotEmpty)
              .join('  ·  '),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _pick(LocalizedName name, TerminologyMode mode) =>
    mode == TerminologyMode.vedic ? name.vedic : name.english;

String? _formatDate(String? iso) {
  if (iso == null) {
    return null;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  return '${parsed.day} ${_monthAbbr[parsed.month - 1]} ${parsed.year}';
}

// --------------------------------------------------------------------------- //
// Date navigator
// --------------------------------------------------------------------------- //
class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.controller, required this.onPickDate});

  final GocharController controller;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final parsed = DateTime.tryParse(controller.selectedDate);
    final label = parsed == null
        ? controller.selectedDate
        : '${_weekdayAbbr[parsed.weekday - 1]}, ${parsed.day} '
            '${_monthAbbr[parsed.month - 1]} ${parsed.year}';

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme, radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.canStepBack
                  ? () => controller.stepDay(-1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous day',
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onPickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: <Widget>[
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!controller.isToday)
                        GestureDetector(
                          onTap: controller.goToToday,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Back to today',
                              style: textTheme.labelLarge?.copyWith(
                                color: _goldAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          'Today',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: controller.canStepForward
                  ? () => controller.stepDay(1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next day',
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Reference frame toggle (From Moon / From Lagna)
// --------------------------------------------------------------------------- //
class _ReferenceToggle extends StatelessWidget {
  const _ReferenceToggle({
    required this.fromMoon,
    required this.natal,
    required this.mode,
    required this.onChanged,
  });

  final bool fromMoon;
  final GocharNatal natal;
  final TerminologyMode mode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme, radius: 14),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: <Widget>[
            _segment(
              context,
              selected: fromMoon,
              label: 'From Moon',
              sub: _pick(natal.moonRashi, mode),
              onTap: () => onChanged(true),
            ),
            _segment(
              context,
              selected: !fromMoon,
              label: 'From Lagna',
              sub: _pick(natal.lagnaRashi, mode),
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required bool selected,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? _goldAccent.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _goldAccent.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? _goldAccent : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Highlights strip
// --------------------------------------------------------------------------- //
class _HighlightsStrip extends StatelessWidget {
  const _HighlightsStrip({required this.response, required this.mode});

  final TransitComputeResponse response;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final highlight in response.highlights) {
      final chip = _chipFor(context, highlight);
      if (chip != null) {
        chips.add(chip);
      }
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) => chips[index],
      ),
    );
  }

  Widget? _chipFor(BuildContext context, GocharHighlight highlight) {
    final insight = gocharInsightForKey(highlight.planetKey);
    final name = mode == TerminologyMode.vedic ? insight.sanskrit : insight.english;
    final (String text, Color color, IconData icon) = switch (highlight.type) {
      'double_transit' => ('Double transit', gocharBeneficColor, Icons.bolt_rounded),
      'sade_sati' => ('Sade Sati running', gocharObstructedColor, Icons.hourglass_bottom_rounded),
      'kantaka_dhaiya' => ('Kantaka Shani', gocharObstructedColor, Icons.hourglass_bottom_rounded),
      'ashtama_dhaiya' => ('Ashtama Shani', gocharChallengingColor, Icons.hourglass_bottom_rounded),
      'retrograde' => ('$name retrograde', insight.accent, Icons.u_turn_left_rounded),
      'exalted' => ('$name exalted', gocharBeneficColor, Icons.arrow_upward_rounded),
      'debilitated' => ('$name debilitated', gocharChallengingColor, Icons.arrow_downward_rounded),
      'sign_change' => (
          '$name → ${_signName(highlight.rashiIndex, mode)} ${_formatDate(highlight.date) ?? ''}'.trim(),
          insight.accent,
          Icons.swap_horiz_rounded,
        ),
      _ => ('', insight.accent, Icons.auto_awesome_rounded),
    };
    if (text.isEmpty) {
      return null;
    }
    final planet = response.planet(highlight.planetKey);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (planet != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 14, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
    if (planet == null) {
      return chip;
    }
    // Tapping a chip opens the planet behind it, where the dates and dignity
    // give the full context the compact chip can't.
    return GestureDetector(
      onTap: () => _showPlanetDetail(context, planet, mode),
      child: chip,
    );
  }
}

// --------------------------------------------------------------------------- //
// Saturn / Sade Sati card
// --------------------------------------------------------------------------- //
class _SaturnCard extends StatelessWidget {
  const _SaturnCard({required this.saturn, required this.mode});

  final SaturnGochar saturn;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = gocharInsightForKey('shani');
    final active = saturn.isActive;
    final accent = active ? gocharObstructedColor : gocharBeneficColor;

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 20,
        fillAlpha: active ? 0.30 : TrikaalSurface.cardFillAlpha,
        borderAlpha: active ? 0.55 : TrikaalSurface.cardBorderAlpha,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GlyphBadge(glyph: insight.glyph, color: insight.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SHANI GOCHAR',
                        style: textTheme.labelLarge?.copyWith(
                          color: _goldAccent,
                          letterSpacing: 2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        saturnStatusLabel(saturn.status),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  label: active ? saturnPhaseLabel(saturn.phase) : 'Clear',
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              saturnStatusBlurb(saturn.status),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.86),
                height: 1.3,
              ),
            ),
            if (active && saturn.windowEndDate != null) ...<Widget>[
              const SizedBox(height: 14),
              _SaturnProgress(saturn: saturn),
            ],
            if (saturn.isSadeSati && saturn.legs.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              ...saturn.legs.map(
                (SaturnPhaseLeg leg) => _SadeSatiLegRow(
                  leg: leg,
                  mode: mode,
                  active: leg.phase == saturn.phase,
                ),
              ),
            ],
            if (!active && saturn.nextStartDate != null) ...<Widget>[
              const SizedBox(height: 12),
              _MetaChip(
                icon: Icons.event_rounded,
                iconColor: _goldAccent,
                label: 'Next Sade Sati from ${_formatDate(saturn.nextStartDate)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaturnProgress extends StatelessWidget {
  const _SaturnProgress({required this.saturn});

  final SaturnGochar saturn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = ((saturn.progressPercent ?? 0) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(gocharObstructedColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _formatDate(saturn.windowStartDate) ?? '',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            Text(
              _formatDate(saturn.windowEndDate) ?? '',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SadeSatiLegRow extends StatelessWidget {
  const _SadeSatiLegRow({
    required this.leg,
    required this.mode,
    required this.active,
  });

  final SaturnPhaseLeg leg;
  final TerminologyMode mode;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dates = <String?>[_formatDate(leg.startDate), _formatDate(leg.endDate)]
        .where((String? value) => value != null)
        .join(' – ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              color: active
                  ? gocharObstructedColor
                  : colorScheme.onSurface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${saturnPhaseLabel(leg.phase)} · ${_pick(leg.rashi, mode)}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
                Text(
                  '${saturnPhaseSubtitle(leg.phase)}${dates.isEmpty ? '' : '  ·  $dates'}',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
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

// --------------------------------------------------------------------------- //
// Jupiter-Saturn double transit
// --------------------------------------------------------------------------- //
class _DoubleTransitCard extends StatelessWidget {
  const _DoubleTransitCard({
    required this.doubleTransit,
    required this.natal,
    required this.mode,
  });

  final DoubleTransit doubleTransit;
  final GocharNatal natal;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = doubleTransit.active;
    final eventWindow = doubleTransit.hasEventWindow;
    final accent = eventWindow
        ? gocharBeneficColor
        : active
            ? gocharObstructedColor
            : gocharNeutralColor;
    final guru = gocharInsightForKey('guru');
    final shani = gocharInsightForKey('shani');
    final sanskrit = mode == TerminologyMode.vedic;

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 20,
        fillAlpha: eventWindow ? 0.30 : TrikaalSurface.cardFillAlpha,
        borderAlpha: eventWindow ? 0.55 : TrikaalSurface.cardBorderAlpha,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DualGlyphBadge(
                  first: guru.glyph,
                  second: shani.glyph,
                  firstColor: guru.accent,
                  secondColor: shani.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'GURU–SHANI GOCHAR',
                        style: textTheme.labelLarge?.copyWith(
                          color: _goldAccent,
                          letterSpacing: 2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Double Transit',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  label: eventWindow
                      ? 'Major window'
                      : active
                          ? 'Active'
                          : 'Quiet',
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              active
                  ? 'Jupiter and Saturn jointly influence the sign(s) below. A house '
                      'lit from both your Lagna and Moon, while the running dasha '
                      'agrees, is the classical marker of a major life event.'
                  : 'Jupiter and Saturn are not jointly influencing any sign right '
                      'now, so no double-transit window is open.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.86),
                height: 1.3,
              ),
            ),
            if (doubleTransit.mahaDashaLord != null ||
                doubleTransit.antarDashaLord != null) ...<Widget>[
              const SizedBox(height: 10),
              _MetaChip(
                icon: Icons.timelapse_rounded,
                iconColor: _goldAccent,
                label: 'Dasha: '
                    '${dashaLordLabel(doubleTransit.mahaDashaLord, sanskrit)}'
                    ' / ${dashaLordLabel(doubleTransit.antarDashaLord, sanskrit)}',
              ),
            ],
            if (active) ...<Widget>[
              const SizedBox(height: 14),
              ...doubleTransit.signs.map(
                (DoubleTransitSign sign) => _DoubleTransitSignRow(
                  sign: sign,
                  mode: mode,
                ),
              ),
              if (doubleTransit.activatedBhavas.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'ACTIVATED HOUSES',
                  style: textTheme.labelLarge?.copyWith(
                    color: _goldAccent,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...doubleTransit.activatedBhavas.map(
                  (DoubleTransitBhava bhava) => _DoubleTransitBhavaRow(
                    bhava: bhava,
                    mode: mode,
                    activatingSigns: doubleTransit.signs
                        .where((DoubleTransitSign s) =>
                            s.houseFromLagna == bhava.house ||
                            s.houseFromMoon == bhava.house)
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DoubleTransitSignRow extends StatelessWidget {
  const _DoubleTransitSignRow({required this.sign, required this.mode});

  final DoubleTransitSign sign;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rashi = _pick(sign.rashi, mode);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TrikaalSurface.fill(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            rashi,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Jupiter ${aspectRelationLabel(sign.jupiterRelation)} · '
            'Saturn ${aspectRelationLabel(sign.saturnRelation)}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_ordinal(sign.houseFromLagna)} from Lagna · '
            '${_ordinal(sign.houseFromMoon)} from Moon',
            style: textTheme.labelLarge?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleTransitBhavaRow extends StatelessWidget {
  const _DoubleTransitBhavaRow({
    required this.bhava,
    required this.mode,
    required this.activatingSigns,
  });

  final DoubleTransitBhava bhava;
  final TerminologyMode mode;

  /// The double-transit sign(s) that light this house (from the Lagna or Moon
  /// frame), each carrying how Jupiter and Saturn touch it.
  final List<DoubleTransitSign> activatingSigns;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = bhavaTheme(bhava.house);
    final tierColor = doubleTransitTierColor(bhava.tier);

    // The classical legs first (primary frames, dasha gate, karaka confirmation);
    // the bhava lord is a softer, supportive signal shown muted.
    final primaryLegs = <String>[
      if (bhava.dashaLinked) 'Dasha',
      if (bhava.karakaUnderDoubleTransit) 'Karaka',
    ];

    // A house counted from the Lagna and from the Moon are different frames, so
    // one transit (e.g. Saturn in one sign) is a different house in each. Label
    // the frame so "8th from Lagna" and "4th from Moon" can't read as Saturn
    // sitting in two houses at once.
    final frames = <String>[
      if (bhava.fromLagna) 'Lagna',
      if (bhava.fromMoon) 'Moon',
    ];
    final houseLabel = frames.isEmpty
        ? 'H${bhava.house}'
        : '${_ordinal(bhava.house)} from ${frames.join(' & ')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (bhava.isEventWindow)
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.star_rounded,
                      size: 15, color: gocharBeneficColor),
                ),
              Expanded(
                child: Text(
                  '$houseLabel · ${theme.title}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Pill(
                label: doubleTransitTierLabel(bhava.tier),
                color: tierColor,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            bhava.significations.join(' · '),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          // How Jupiter & Saturn actually touch the sign that lights this house —
          // occupancy vs aspect, so the reading is transparent at a glance.
          ...activatingSigns.map(
            (DoubleTransitSign sign) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.brightness_1,
                      size: 5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_pick(sign.rashi, mode)}: '
                      'Jupiter ${aspectRelationLabel(sign.jupiterRelation)} · '
                      'Saturn ${aspectRelationLabel(sign.saturnRelation)}',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              ...primaryLegs.map((String leg) => _LegChip(label: leg)),
              if (bhava.lordUnderDoubleTransit)
                const _LegChip(label: 'Lord', muted: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegChip extends StatelessWidget {
  const _LegChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (muted) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onSurface.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 10,
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: gocharBeneficColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gocharBeneficColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 10,
              color: gocharBeneficColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DualGlyphBadge extends StatelessWidget {
  const _DualGlyphBadge({
    required this.first,
    required this.second,
    required this.firstColor,
    required this.secondColor,
  });

  final String first;
  final String second;
  final Color firstColor;
  final Color secondColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _goldAccent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _goldAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(first, style: TextStyle(color: firstColor, fontSize: 17, height: 1)),
          const SizedBox(width: 1),
          Text(second, style: TextStyle(color: secondColor, fontSize: 17, height: 1)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Transit table
// --------------------------------------------------------------------------- //
class _TransitTableCard extends StatelessWidget {
  const _TransitTableCard({
    required this.response,
    required this.mode,
    required this.fromMoon,
  });

  final TransitComputeResponse response;
  final TerminologyMode mode;
  final bool fromMoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme, radius: 18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('🪐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Live transits',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  fromMoon ? 'House from Moon' : 'House from Lagna',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...response.planets.map(
              (GocharPlanet planet) => _PlanetRow(
                planet: planet,
                mode: mode,
                fromMoon: fromMoon,
              ),
            ),
            _TransitBadgeLegend(planets: response.planets),
          ],
        ),
      ),
    );
  }
}

/// A small key for the row badges, showing only the ones actually present in the
/// current sky so it stays informative without becoming clutter.
class _TransitBadgeLegend extends StatelessWidget {
  const _TransitBadgeLegend({required this.planets});

  final List<GocharPlanet> planets;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dignities =
        planets.where((p) => isNotableDignity(p.dignity)).map((p) => p.dignity).toSet();
    final entries = <(String, String, Color)>[
      if (planets.any((p) => p.motion == 'retrograde'))
        ('℞', 'Retrograde', const Color(0xFFB69CE0)),
      if (planets.any((p) => p.combust)) ('C', 'Combust', const Color(0xFFEF9A8E)),
      for (final d in const <String>['exalted', 'moolatrikona', 'own', 'debilitated'])
        if (dignities.contains(d)) (dignityLabel(d)[0], dignityLabel(d), dignityColor(d)),
    ];
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 8),
          Text(
            'KEY',
            style: textTheme.labelLarge?.copyWith(
              color: _goldAccent,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: entries
                .map(
                  (entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _MiniBadge(label: entry.$1, color: entry.$3, leadingGap: false),
                      const SizedBox(width: 6),
                      Text(
                        entry.$2,
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PlanetRow extends StatelessWidget {
  const _PlanetRow({
    required this.planet,
    required this.mode,
    required this.fromMoon,
  });

  final GocharPlanet planet;
  final TerminologyMode mode;
  final bool fromMoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = gocharInsightForKey(planet.key);
    final name = _pick(planet.name, mode);
    final rashi = _pick(planet.rashi, mode);
    final house = planet.houseFor(fromMoon: fromMoon);
    final theme = bhavaTheme(house);
    final verdict = phalaVerdict(
      favourable: planet.phalaFromMoon.favourable,
      vedhaObstructed: planet.phalaFromMoon.vedhaObstructed,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showPlanetDetail(context, planet, mode),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 26,
                child: Text(
                  insight.glyph,
                  style: TextStyle(color: insight.accent, fontSize: 18),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (planet.motion == 'retrograde')
                          const _MiniBadge(label: '℞', color: Color(0xFFB69CE0)),
                        if (planet.combust)
                          const _MiniBadge(label: 'C', color: Color(0xFFEF9A8E)),
                        if (isNotableDignity(planet.dignity))
                          _MiniBadge(
                            label: dignityLabel(planet.dignity)[0],
                            color: dignityColor(planet.dignity),
                          ),
                      ],
                    ),
                    Text(
                      '$rashi · ${planet.nakshatra} ${planet.pada}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _NatureDot(color: phalaColor(verdict)),
                      const SizedBox(width: 6),
                      Text(
                        'H$house',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _goldAccent,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    theme.title,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Ashtakavarga overview
// --------------------------------------------------------------------------- //
class _AshtakavargaCard extends StatelessWidget {
  const _AshtakavargaCard({required this.response, required this.mode});

  final TransitComputeResponse response;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sarva = response.ashtakavarga.sarva;
    if (sarva.length != 12) {
      return const SizedBox.shrink();
    }
    final maxValue = sarva.reduce((int a, int b) => a > b ? a : b).clamp(1, 56);

    // Which transiting planets sit in each sign, for glyph markers.
    final glyphsBySign = <int, List<String>>{};
    for (final planet in response.planets) {
      glyphsBySign
          .putIfAbsent(planet.rashiIndex, () => <String>[])
          .add(gocharInsightForKey(planet.key).glyph);
    }

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme, radius: 18),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: _goldAccent,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          initiallyExpanded: false,
          title: Row(
            children: <Widget>[
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ashtakavarga · transit strength',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sarvashtakavarga bindus per sign. Planets transiting a high-bindu '
                'sign (28+ is above average) give freer, more supported results.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(12, (int sign) {
              return _SavBar(
                signIndex: sign,
                value: sarva[sign],
                maxValue: maxValue,
                glyphs: glyphsBySign[sign] ?? const <String>[],
                mode: mode,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SavBar extends StatelessWidget {
  const _SavBar({
    required this.signIndex,
    required this.value,
    required this.maxValue,
    required this.glyphs,
    required this.mode,
  });

  final int signIndex;
  final int value;
  final int maxValue;
  final List<String> glyphs;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    final color = value >= 30
        ? gocharBeneficColor
        : value >= 25
            ? gocharObstructedColor
            : gocharChallengingColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 30,
            child: Text(
              _signShort(signIndex, mode),
              style: textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            child: Text(
              glyphs.join(' '),
              style: const TextStyle(fontSize: 13, color: _goldAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// About
// --------------------------------------------------------------------------- //
class _AboutGocharCard extends StatelessWidget {
  const _AboutGocharCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.84),
      height: 1.35,
    );

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(colorScheme: colorScheme, radius: 18),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: _goldAccent,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          title: Row(
            children: <Widget>[
              const Text('🔭', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'What is Gochar?',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Gochar is the live movement of the grahas through the zodiac, '
                    'read against your birth chart. Classical Jyotisha measures it '
                    'mainly from the Janma Rashi — the sign of your natal Moon.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Each graha gives auspicious results from certain houses of the '
                    'Moon, but a malefic sitting in the "vedha" (obstruction) point '
                    'can cancel that good result — both are shown here.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Saturn\'s 7½-year Sade Sati over the 12th, 1st and 2nd from the '
                    'Moon, retrograde (vakri) spells, combustion, and Ashtakavarga '
                    'strength all refine the reading.',
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Planet detail sheet
// --------------------------------------------------------------------------- //
void _showPlanetDetail(
  BuildContext context,
  GocharPlanet planet,
  TerminologyMode mode,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _PlanetDetailSheet(planet: planet, mode: mode),
  );
}

class _PlanetDetailSheet extends StatelessWidget {
  const _PlanetDetailSheet({required this.planet, required this.mode});

  final GocharPlanet planet;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = gocharInsightForKey(planet.key);
    final name = _pick(planet.name, mode);
    final rashi = _pick(planet.rashi, mode);
    final moonHouse = planet.houseFromMoon;
    final moonTheme = bhavaTheme(moonHouse);
    final lagnaHouse = planet.houseFromLagna;
    final lagnaTheme = bhavaTheme(lagnaHouse);
    final verdict = phalaVerdict(
      favourable: planet.phalaFromMoon.favourable,
      vedhaObstructed: planet.phalaFromMoon.vedhaObstructed,
    );

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GlyphBadge(glyph: insight.glyph, color: insight.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$rashi ${planet.degreeInSign.toStringAsFixed(1)}° · '
                        '${planet.nakshatra} (pada ${planet.pada})',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _Pill(label: phalaLabel(verdict), color: phalaColor(verdict)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              insight.essence,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetaChip(
                  icon: planet.motion == 'retrograde'
                      ? Icons.u_turn_left_rounded
                      : Icons.trending_flat_rounded,
                  iconColor: insight.accent,
                  label: mode == TerminologyMode.vedic
                      ? motionSanskritLabel(planet.motion)
                      : motionLabel(planet.motion),
                ),
                if (planet.combust)
                  const _MetaChip(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Color(0xFFEF9A8E),
                    label: 'Combust (Asta)',
                  ),
                if (isNotableDignity(planet.dignity))
                  _MetaChip(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: dignityColor(planet.dignity),
                    label: mode == TerminologyMode.vedic
                        ? dignitySanskritLabel(planet.dignity)
                        : dignityLabel(planet.dignity),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailSection(
              title: 'House activated',
              children: <Widget>[
                _DetailRow(
                  label: 'From Moon',
                  value: 'H$moonHouse · ${moonTheme.title} (${moonTheme.areas})',
                ),
                _DetailRow(
                  label: 'From Lagna',
                  value: 'H$lagnaHouse · ${lagnaTheme.title} (${lagnaTheme.areas})',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Transit verdict (from Moon)',
              children: <Widget>[
                _DetailRow(
                  label: planet.phalaFromMoon.favourable ? 'Result' : 'Result',
                  value: planet.phalaFromMoon.favourable
                      ? 'Auspicious in the ${_ordinal(moonHouse)} from your Moon'
                      : 'Not among the auspicious houses for $name',
                ),
                if (planet.phalaFromMoon.favourable &&
                    planet.phalaFromMoon.hasVedhaRule)
                  _DetailRow(
                    label: 'Vedha',
                    value: planet.phalaFromMoon.vedhaObstructed
                        ? 'Obstructed by ${_capitalize(planet.phalaFromMoon.vedhaBy ?? 'a graha')} '
                            'in the ${_ordinal(planet.phalaFromMoon.vedhaHouseFromMoon ?? 0)}'
                        : 'Clear — no planet blocks the result',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Movement',
              children: <Widget>[
                if (planet.ingress.enteredDate != null)
                  _DetailRow(
                    label: 'Entered $rashi',
                    value: _formatDate(planet.ingress.enteredDate) ?? '—',
                  ),
                if (planet.ingress.leavesDate != null)
                  _DetailRow(
                    label: 'Leaves $rashi',
                    value: _formatDate(planet.ingress.leavesDate) ?? '—',
                  ),
                if (planet.station.sinceDate != null)
                  _DetailRow(
                    label: 'Retrograde since',
                    value: _formatDate(planet.station.sinceDate) ?? '—',
                  ),
                if (planet.station.nextStationDate != null)
                  _DetailRow(
                    label: nextStationLabel(planet.station.motion),
                    value: _formatDate(planet.station.nextStationDate) ?? '—',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _AshtakavargaDetail(planet: planet, rashi: rashi),
          ],
        ),
      ),
    );
  }
}

class _AshtakavargaDetail extends StatelessWidget {
  const _AshtakavargaDetail({required this.planet, required this.rashi});

  final GocharPlanet planet;
  final String rashi;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cell = planet.ashtakavarga;
    final bindus = cell.bindus;

    return _DetailSection(
      title: 'Transit strength (Ashtakavarga)',
      children: <Widget>[
        if (bindus != null)
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Own bindus in $rashi',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List<Widget>.generate(cell.maxBindus, (int i) {
                        final filled = i < bindus;
                        return Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: filled
                                ? bavStrengthColor(bindus)
                                : colorScheme.onSurface.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              _Pill(
                label: '${bavStrengthLabel(bindus)} · $bindus/8',
                color: bavStrengthColor(bindus),
              ),
            ],
          )
        else
          Text(
            'Nodes (Rahu/Ketu) carry no Ashtakavarga of their own.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        const SizedBox(height: 10),
        _DetailRow(
          label: 'Sign total (Sarva)',
          value: '${cell.sarvaBindus} · ${savStrengthLabel(cell.sarvaBindus)}',
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------- //
// Small shared widgets
// --------------------------------------------------------------------------- //
class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: _goldAccent,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlyphBadge extends StatelessWidget {
  const _GlyphBadge({required this.glyph, required this.color});

  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(glyph, style: TextStyle(color: color, fontSize: 24, height: 1)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color, this.leadingGap = true});

  final String label;
  final Color color;

  /// Inline use (after a planet name) wants a leading gap; the legend doesn't.
  final bool leadingGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: leadingGap ? 6 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NatureDot extends StatelessWidget {
  const _NatureDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: TrikaalSurface.fill(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// Name helpers
// --------------------------------------------------------------------------- //
const List<Map<String, String>> _rashiByIndex = <Map<String, String>>[
  <String, String>{'english': 'Aries', 'vedic': 'Mesha', 'short': 'Ari'},
  <String, String>{'english': 'Taurus', 'vedic': 'Vrishabha', 'short': 'Tau'},
  <String, String>{'english': 'Gemini', 'vedic': 'Mithuna', 'short': 'Gem'},
  <String, String>{'english': 'Cancer', 'vedic': 'Karka', 'short': 'Can'},
  <String, String>{'english': 'Leo', 'vedic': 'Simha', 'short': 'Leo'},
  <String, String>{'english': 'Virgo', 'vedic': 'Kanya', 'short': 'Vir'},
  <String, String>{'english': 'Libra', 'vedic': 'Tula', 'short': 'Lib'},
  <String, String>{'english': 'Scorpio', 'vedic': 'Vrischika', 'short': 'Sco'},
  <String, String>{'english': 'Sagittarius', 'vedic': 'Dhanu', 'short': 'Sag'},
  <String, String>{'english': 'Capricorn', 'vedic': 'Makara', 'short': 'Cap'},
  <String, String>{'english': 'Aquarius', 'vedic': 'Kumbha', 'short': 'Aqu'},
  <String, String>{'english': 'Pisces', 'vedic': 'Meena', 'short': 'Pis'},
];

String _signName(int? index, TerminologyMode mode) {
  if (index == null || index < 0 || index > 11) {
    return '';
  }
  final entry = _rashiByIndex[index];
  return (mode == TerminologyMode.vedic ? entry['vedic'] : entry['english']) ?? '';
}

String _signShort(int index, TerminologyMode mode) {
  if (index < 0 || index > 11) {
    return '';
  }
  return _rashiByIndex[index]['short'] ?? '';
}

String _ordinal(int n) {
  if (n <= 0) {
    return '$n';
  }
  if (n >= 11 && n <= 13) {
    return '${n}th';
  }
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}

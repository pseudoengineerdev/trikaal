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
import '../../panchang/data/models/panchang_models.dart';
import '../../panchang/domain/panchang_time_formatter.dart';
import '../../panchang/presentation/state/panchang_time_format_state.dart';
import '../domain/hora_insights.dart';
import 'state/hora_controller.dart';

const Color _goldAccent = Color(0xFFE8C97A);
const Color _nightBlue = Color(0xFFB9D4F1);

const List<String> _monthAbbreviations = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Dedicated Hora (planetary hours) page. It reuses the verified panchang
/// timeline (via [HoraController]) and layers on the interpretive meaning of
/// each ruling graha, with a live "current hour" hero and a full day/night
/// breakdown.
class HoraPage extends StatefulWidget {
  const HoraPage({
    required this.birthInputState,
    this.controller,
    this.now,
    super.key,
  });

  final BirthInputState birthInputState;

  /// Injectable for tests; otherwise created internally.
  final HoraController? controller;

  /// Injectable clock for deterministic "today" + live-hora detection.
  final DateTime Function()? now;

  @override
  State<HoraPage> createState() => _HoraPageState();
}

class _HoraPageState extends State<HoraPage> {
  late final HoraController _controller;
  late final bool _ownsController;
  late final DateTime Function() _now;

  bool _autoComputeAttempted = false;
  String? _lastPlaceSignature;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now;
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HoraController(now: _now);

    TerminologyModeState.shared.load();

    _lastPlaceSignature = _placeSignature();
    widget.birthInputState.addListener(_handleBirthInputChange);

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
    widget.birthInputState.removeListener(_handleBirthInputChange);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool get _canCompute =>
      widget.birthInputState.placeForCurrentObservations.trim().isNotEmpty;

  String _todayIso() {
    final now = _now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String? _placeSignature() {
    final place = widget.birthInputState.placeForCurrentObservations;
    if (place.trim().isEmpty) {
      return null;
    }
    final custom = widget.birthInputState.customPlaceForCurrentObservations;
    final customSignature = custom == null
        ? ''
        : '${custom.latitude.toStringAsFixed(6)}|'
            '${custom.longitude.toStringAsFixed(6)}|'
            '${custom.timezone}|${custom.elevationM.toStringAsFixed(1)}';
    return '$place|$customSignature';
  }

  Future<void> _load() {
    return _controller.load(
      date: _todayIso(),
      placeOfBirth: widget.birthInputState.placeForCurrentObservations,
      customPlace: widget.birthInputState.customPlaceForCurrentObservations,
    );
  }

  void _handleBirthInputChange() {
    final signature = _placeSignature();
    if (signature == _lastPlaceSignature) {
      return;
    }
    _lastPlaceSignature = signature;
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
        currentLocationLabel:
            widget.birthInputState.placeForCurrentObservations,
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
        title: 'Location needed',
        body: 'Set your current location so we can compute the planetary hours '
            'for your sky.',
      );
    }

    if (_controller.loading && _controller.result == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_controller.error != null && _controller.result == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: <Widget>[
          _header(context),
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
    // Hora always uses the 12-hour clock: this is a glance-and-go micro-timing
    // screen, so the panchang almanac's "roll past 24h" convention (which would
    // print night horas as 25:xx-30:00) is deliberately not offered here.
    const format = PanchangTimeFormat.h12;
    final panchang = response.panchang;
    final slots = panchang.advanced.horaTimeline;

    if (slots.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: <Widget>[
          _header(context),
          const SizedBox(height: 14),
          const _StateMessage(
            title: 'No horas for this day',
            body: 'Planetary hours are measured from sunrise to sunrise, which '
                "this location doesn't have today (polar day or night).",
            embedded: true,
          ),
        ],
      );
    }

    final dayEntries = <_IndexedSlot>[];
    final nightEntries = <_IndexedSlot>[];
    for (var i = 0; i < slots.length; i++) {
      final entry = _IndexedSlot(i, slots[i]);
      (slots[i].isDay ? dayEntries : nightEntries).add(entry);
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: <Widget>[
          _header(context),
          const SizedBox(height: 14),
          _currentHoraSection(context, panchang, mode, format),
          const SizedBox(height: 12),
          if (dayEntries.isNotEmpty)
            _HoraTimelineCard(
              emoji: '🌞',
              title: 'Day horas',
              subtitle: 'Sunrise to sunset · ${dayEntries.length} hours',
              entries: dayEntries,
              activeIndex: _controller.activeIndex,
              mode: mode,
              format: format,
              panchangDateIso: panchang.date,
            ),
          if (nightEntries.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _HoraTimelineCard(
              emoji: '🌙',
              title: 'Night horas',
              subtitle: 'Sunset to next sunrise · ${nightEntries.length} hours',
              entries: nightEntries,
              activeIndex: _controller.activeIndex,
              mode: mode,
              format: format,
              panchangDateIso: panchang.date,
            ),
          ],
          const SizedBox(height: 12),
          _AboutHoraCard(panchang: panchang, mode: mode),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final place = widget.birthInputState.placeForCurrentObservations;
    final response = _controller.result;
    final weekdayLabel = response == null
        ? null
        : (TerminologyModeState.shared.mode == TerminologyMode.vedic
            ? response.panchang.weekday.nameVedic
            : response.panchang.weekday.nameEnglish);
    final dateLabel =
        response == null ? null : _dateLabel(response.panchang.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'HORA',
          style: textTheme.labelLarge?.copyWith(
            color: _goldAccent,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Planetary Hours',
          style:
              textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          <String?>[dateLabel, weekdayLabel, place]
              .where((String? part) => part != null && part.trim().isNotEmpty)
              .join('  ·  '),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _currentHoraSection(
    BuildContext context,
    DailyPanchang panchang,
    TerminologyMode mode,
    PanchangTimeFormat format,
  ) {
    final active = _controller.activeHora;
    if (active == null) {
      final next = _controller.nextHora;
      return _NoActiveHoraCard(
        next: next,
        mode: mode,
        format: format,
        panchangDateIso: panchang.date,
      );
    }
    return _HoraHeroCard(
      slot: active,
      secondsRemaining: _controller.secondsRemaining,
      mode: mode,
      format: format,
      panchangDateIso: panchang.date,
    );
  }

  String? _dateLabel(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return null;
    }
    final month = _monthAbbreviations[parsed.month - 1];
    return '$month ${parsed.day}';
  }
}

class _IndexedSlot {
  const _IndexedSlot(this.index, this.slot);

  final int index;
  final PanchangHoraSlot slot;
}

String _localizedLord(PanchangHoraSlot slot, TerminologyMode mode) =>
    mode == TerminologyMode.vedic ? slot.lordVedic : slot.lordEnglish;

DateTime? _instant(String iso) => DateTime.tryParse(iso)?.toUtc();

PanchangRangeParts _range(
  PanchangHoraSlot slot, {
  required String panchangDateIso,
  required PanchangTimeFormat format,
}) {
  final parts = formatPanchangRangeParts(
    PanchangWindow(start: slot.start, end: slot.end),
    panchangDateIso: panchangDateIso,
    format: format,
  );
  // A night hora that ends after midnight belongs to the next civil day. Mark
  // it with a compact "(+1)" instead of a full date — the night card already
  // says "to next sunrise", so the offset is all the context the reader needs.
  final offset = _dayOffset(slot.end.localIso, panchangDateIso);
  if (offset <= 0) {
    return parts;
  }
  return PanchangRangeParts(span: '${parts.span} (+$offset)');
}

int _dayOffset(String localIso, String panchangDateIso) {
  if (localIso.length < 10) {
    return 0;
  }
  final eventDate = DateTime.tryParse(localIso.substring(0, 10));
  final baseDate = DateTime.tryParse(panchangDateIso);
  if (eventDate == null || baseDate == null) {
    return 0;
  }
  return eventDate
      .difference(DateTime(baseDate.year, baseDate.month, baseDate.day))
      .inDays;
}

String _formatRemaining(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final secs = safe % 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m left';
  }
  if (minutes > 0) {
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s left';
  }
  return '${secs}s left';
}

double _horaProgress(PanchangHoraSlot slot, int secondsRemaining) {
  final start = _instant(slot.start.localIso);
  final end = _instant(slot.end.localIso);
  if (start == null || end == null) {
    return 0;
  }
  final total = end.difference(start).inSeconds;
  if (total <= 0) {
    return 0;
  }
  final elapsed = total - secondsRemaining;
  return (elapsed / total).clamp(0.0, 1.0);
}

/// The live current-hour hero — the centrepiece of the page.
class _HoraHeroCard extends StatelessWidget {
  const _HoraHeroCard({
    required this.slot,
    required this.secondsRemaining,
    required this.mode,
    required this.format,
    required this.panchangDateIso,
  });

  final PanchangHoraSlot slot;
  final int secondsRemaining;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final String panchangDateIso;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = horaInsightForLord(slot.lordEnglish);
    final lord = _localizedLord(slot, mode);
    final range =
        _range(slot, panchangDateIso: panchangDateIso, format: format);
    final natureColor = horaNatureColor(insight.nature);
    final progress = _horaProgress(slot, secondsRemaining);

    return GestureDetector(
      onTap: () => _showHoraDetail(
        context,
        slot: slot,
        mode: mode,
        format: format,
        panchangDateIso: panchangDateIso,
        isActive: true,
      ),
      child: DecoratedBox(
        decoration: TrikaalSurface.decoration(
          colorScheme: colorScheme,
          radius: 20,
          fillAlpha: 0.30,
          borderAlpha: 0.55,
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
                          'CURRENT HORA',
                          style: textTheme.labelLarge?.copyWith(
                            color: _goldAccent,
                            letterSpacing: 2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$lord hora',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NaturePill(label: insight.natureLabel, color: natureColor),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                insight.essence,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.86),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _MetaChip(
                    icon: slot.isDay
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round_rounded,
                    iconColor: slot.isDay ? _goldAccent : _nightBlue,
                    label: slot.isDay ? 'Day hora' : 'Night hora',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaChip(
                      icon: Icons.schedule_rounded,
                      iconColor: colorScheme.onSurfaceVariant,
                      label: range.span,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(insight.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _nowDot(context),
                  Text(
                    _formatRemaining(secondsRemaining),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              if (insight.goodFor.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ActivityBlock(
                  label: 'Favourable for',
                  items: insight.goodFor,
                  accent: horaBeneficColor,
                ),
              ],
              if (insight.avoid.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _ActivityBlock(
                  label: 'Best to avoid',
                  items: insight.avoid,
                  accent: horaMaleficColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _nowDot(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          'Active now',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}

/// Shown only in the rare window where no hora matches the clock (e.g. the host
/// timezone differs from the observed location around sunrise).
class _NoActiveHoraCard extends StatelessWidget {
  const _NoActiveHoraCard({
    required this.next,
    required this.mode,
    required this.format,
    required this.panchangDateIso,
  });

  final PanchangHoraSlot? next;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final String panchangDateIso;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nextSlot = next;

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 20,
        fillAlpha: 0.30,
        borderAlpha: 0.55,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'CURRENT HORA',
              style: textTheme.labelLarge?.copyWith(
                color: _goldAccent,
                letterSpacing: 2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No hora is active right now.',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (nextSlot != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Next: ${_localizedLord(nextSlot, mode)} hora at '
                '${_range(nextSlot, panchangDateIso: panchangDateIso, format: format).span.split(' – ').first}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoraTimelineCard extends StatelessWidget {
  const _HoraTimelineCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.activeIndex,
    required this.mode,
    required this.format,
    required this.panchangDateIso,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<_IndexedSlot> entries;
  final int activeIndex;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final String panchangDateIso;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            ...entries.map(
              (_IndexedSlot entry) => _HoraRow(
                slot: entry.slot,
                isActive: entry.index == activeIndex,
                mode: mode,
                format: format,
                panchangDateIso: panchangDateIso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoraRow extends StatelessWidget {
  const _HoraRow({
    required this.slot,
    required this.isActive,
    required this.mode,
    required this.format,
    required this.panchangDateIso,
  });

  final PanchangHoraSlot slot;
  final bool isActive;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final String panchangDateIso;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = horaInsightForLord(slot.lordEnglish);
    final lord = _localizedLord(slot, mode);
    final range =
        _range(slot, panchangDateIso: panchangDateIso, format: format);
    final dim = isActive ? 1.0 : 0.82;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showHoraDetail(
        context,
        slot: slot,
        mode: mode,
        format: format,
        panchangDateIso: panchangDateIso,
        isActive: isActive,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 22,
                child: Text(
                  insight.glyph,
                  style: TextStyle(color: insight.accent, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        lord,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: dim),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _NatureDot(color: horaNatureColor(insight.nature)),
                    if (isActive) _nowPill(context),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _TimeCell(
                main: range.span,
                sub: range.dateSuffix,
                highlight: isActive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nowPill(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'NOW',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 9,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.main, this.sub, this.highlight = false});

  final String main;
  final String? sub;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            main,
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              color: highlight ? _goldAccent : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (sub != null && sub!.isNotEmpty)
            Text(
              sub!,
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.62),
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
      child: Text(
        glyph,
        style: TextStyle(color: color, fontSize: 24, height: 1),
      ),
    );
  }
}

class _NaturePill extends StatelessWidget {
  const _NaturePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
      width: 7,
      height: 7,
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
              style: textTheme.bodyMedium?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBlock extends StatelessWidget {
  const _ActivityBlock({
    required this.label,
    required this.items,
    required this.accent,
  });

  final String label;
  final List<String> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: accent,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (String item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.88),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutHoraCard extends StatelessWidget {
  const _AboutHoraCard({
    required this.panchang,
    required this.mode,
  });

  final DailyPanchang panchang;
  final TerminologyMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final slots = panchang.advanced.horaTimeline;
    final weekdayLord =
        slots.isNotEmpty ? _localizedLord(slots.first, mode) : null;

    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.84),
      height: 1.35,
    );

    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 18,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: _goldAccent,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          title: Row(
            children: <Widget>[
              const Text('🔆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'What is a hora?',
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
                    'A hora is a planetary hour. Sunrise to sunset is divided '
                    'into 12 day horas and sunset to the next sunrise into 12 '
                    'night horas — so day and night hours differ in length with '
                    'the season, never a flat 60 minutes.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    weekdayLord == null
                        ? 'The first hora after sunrise is ruled by the lord of '
                            'the weekday. Each following hora passes to the next '
                            'graha in the order Sun, Venus, Mercury, Moon, '
                            'Saturn, Jupiter, Mars.'
                        : 'The first hora after sunrise is ruled by the lord of '
                            'the weekday — today, $weekdayLord. Each following '
                            'hora passes to the next graha in the order Sun, '
                            'Venus, Mercury, Moon, Saturn, Jupiter, Mars.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Begin work when the ruling graha suits it — Jupiter and '
                    'Venus for auspicious starts, Mercury for study and trade, '
                    'the Moon for travel, the Sun for authority, and reserve '
                    'Saturn and Mars for hard, decisive labour.',
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.body,
    this.embedded = false,
  });

  final String title;
  final String body;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          embedded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          textAlign: embedded ? TextAlign.start : TextAlign.center,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: embedded ? TextAlign.start : TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.3),
        ),
      ],
    );
    if (embedded) {
      return DecoratedBox(
        decoration: TrikaalSurface.decoration(
          colorScheme: colorScheme,
          radius: 18,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: content,
      ),
    );
  }
}

void _showHoraDetail(
  BuildContext context, {
  required PanchangHoraSlot slot,
  required TerminologyMode mode,
  required PanchangTimeFormat format,
  required String panchangDateIso,
  required bool isActive,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _HoraDetailSheet(
      slot: slot,
      mode: mode,
      format: format,
      panchangDateIso: panchangDateIso,
      isActive: isActive,
    ),
  );
}

class _HoraDetailSheet extends StatelessWidget {
  const _HoraDetailSheet({
    required this.slot,
    required this.mode,
    required this.format,
    required this.panchangDateIso,
    required this.isActive,
  });

  final PanchangHoraSlot slot;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final String panchangDateIso;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = horaInsightForLord(slot.lordEnglish);
    final lord = _localizedLord(slot, mode);
    final range =
        _range(slot, panchangDateIso: panchangDateIso, format: format);
    final natureColor = horaNatureColor(insight.nature);

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
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
                        '$lord hora',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        range.dateSuffix == null
                            ? range.span
                            : '${range.span}  (${range.dateSuffix})',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _NaturePill(label: insight.natureLabel, color: natureColor),
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
            const SizedBox(height: 12),
            _MetaChip(
              icon: slot.isDay
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round_rounded,
              iconColor: slot.isDay ? _goldAccent : _nightBlue,
              label: slot.isDay ? 'Day hora' : 'Night hora',
            ),
            if (insight.goodFor.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              _ActivityBlock(
                label: 'Favourable for',
                items: insight.goodFor,
                accent: horaBeneficColor,
              ),
            ],
            if (insight.avoid.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              _ActivityBlock(
                label: 'Best to avoid',
                items: insight.avoid,
                accent: horaMaleficColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

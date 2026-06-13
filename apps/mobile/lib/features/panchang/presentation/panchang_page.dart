import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../shared/astrology/term_localizer.dart';
import '../data/models/panchang_models.dart';
import '../domain/panchang_time_formatter.dart';
import 'state/panchang_controller.dart';
import 'state/panchang_time_format_state.dart';

const Color _auspiciousAccent = Color(0xFF8FE3B0);
const Color _inauspiciousAccent = Color(0xFFF2A6A1);
const Color _goldAccent = Color(0xFFE8C97A);

class PanchangPage extends StatefulWidget {
  const PanchangPage({
    required this.birthInputState,
    this.controller,
    this.now,
    super.key,
  });

  final BirthInputState birthInputState;
  final PanchangController? controller;

  /// Injectable clock used for "today", live-window highlighting, and the NOW
  /// pill. Tests pass a fixed value so the rendered state is deterministic.
  final DateTime Function()? now;

  @override
  State<PanchangPage> createState() => _PanchangPageState();
}

class _PanchangPageState extends State<PanchangPage> {
  /// Virtual center of the page view; pages on either side are other days.
  static const int _todayPageIndex = 5000;

  late final PanchangController _controller;
  late final PageController _pageController;
  late final DateTime _today;
  int _currentPageIndex = _todayPageIndex;
  String? _lastPlaceSignature;

  @override
  void initState() {
    super.initState();
    final now = (widget.now ?? DateTime.now)();
    _today = DateTime(now.year, now.month, now.day);
    _controller = widget.controller ?? PanchangController();
    _pageController = PageController(initialPage: _todayPageIndex);
    PanchangTimeFormatState.shared.load();
    widget.birthInputState.addListener(_handleBirthInputChange);
    _lastPlaceSignature = _placeSignature();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computeForPage(_currentPageIndex);
    });
  }

  @override
  void dispose() {
    widget.birthInputState.removeListener(_handleBirthInputChange);
    _pageController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool get _canCompute {
    return widget.birthInputState.placeForCurrentObservations.trim().isNotEmpty;
  }

  DateTime _dateForPage(int pageIndex) {
    return _today.add(Duration(days: pageIndex - _todayPageIndex));
  }

  String _dateIsoForPage(int pageIndex) {
    final date = _dateForPage(pageIndex);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  void _handleBirthInputChange() {
    if (!mounted) {
      return;
    }
    final signature = _placeSignature();
    if (signature == _lastPlaceSignature) {
      return;
    }
    _lastPlaceSignature = signature;
    _controller.clear();
    _computeForPage(_currentPageIndex);
  }

  void _computeForPage(int pageIndex) {
    if (!_canCompute) {
      return;
    }
    _controller.compute(
      request: ComputePanchangRequest(
        date: _dateIsoForPage(pageIndex),
        placeOfBirth: widget.birthInputState.placeForCurrentObservations,
        customPlace:
            widget.birthInputState.customPlaceForCurrentObservations,
      ),
    );
  }

  void _goToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
        onCalendarTap: () =>
            openHinduCalendar(context, widget.birthInputState),
        onPremiumTap: () => _handleDockTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: !_canCompute
              ? _StateMessage(
                  title: 'Location needed',
                  body:
                      'Set your current location so we can compute the panchang for your sky.',
                  actionLabel: 'Go to Home',
                  onAction: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                )
              : MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Column(
                    children: <Widget>[
                      _DayNavigationHeader(
                        date: _dateForPage(_currentPageIndex),
                        isToday: _currentPageIndex == _todayPageIndex,
                        onPrevious: () => _goToPage(_currentPageIndex - 1),
                        onNext: () => _goToPage(_currentPageIndex + 1),
                        onToday: () => _goToPage(_todayPageIndex),
                      ),
                      const SizedBox(height: 4),
                      const _TimeFormatToggle(),
                      const SizedBox(height: 4),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (int pageIndex) {
                            setState(() => _currentPageIndex = pageIndex);
                            _computeForPage(pageIndex);
                          },
                          itemBuilder: (BuildContext context, int pageIndex) {
                            final dateIso = _dateIsoForPage(pageIndex);
                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (BuildContext context, Widget? _) {
                                final dayState =
                                    _controller.stateFor(dateIso);
                                if (dayState == null || dayState.loading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                if (dayState.error != null) {
                                  return _StateMessage(
                                    title: 'Unable to compute panchang',
                                    body: dayState.error!,
                                    actionLabel: 'Retry',
                                    onAction: () {
                                      _controller.invalidate(dateIso);
                                      _computeForPage(pageIndex);
                                    },
                                  );
                                }
                                final response = dayState.result;
                                if (response == null) {
                                  return const SizedBox.shrink();
                                }
                                return ValueListenableBuilder<
                                    TerminologyMode>(
                                  valueListenable:
                                      TerminologyModeState.shared,
                                  builder: (BuildContext context,
                                      TerminologyMode mode, Widget? _) {
                                    return ValueListenableBuilder<
                                        PanchangTimeFormat>(
                                      valueListenable:
                                          PanchangTimeFormatState.shared,
                                      builder: (BuildContext context,
                                          PanchangTimeFormat format,
                                          Widget? _) {
                                        return _PanchangDayView(
                                          panchang: response.panchang,
                                          placeLabel: response
                                              .resolvedPlace.placeLabel,
                                          mode: mode,
                                          format: format,
                                          now: widget.now ?? DateTime.now,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
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

class _DayNavigationHeader extends StatelessWidget {
  const _DayNavigationHeader({
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateLabel = '${date.day} ${_months[date.month - 1]} ${date.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  'Dainik Panchang',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: _goldAccent,
                    letterSpacing: 2.2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    dateLabel,
                    key: ValueKey<String>(dateLabel),
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isToday)
                  GestureDetector(
                    onTap: onToday,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Back to today',
                        style: textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right_rounded, size: 30),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _TimeFormatToggle extends StatelessWidget {
  const _TimeFormatToggle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<PanchangTimeFormat>(
      valueListenable: PanchangTimeFormatState.shared,
      builder:
          (BuildContext context, PanchangTimeFormat format, Widget? child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _formatChip(
                context,
                label: '12 Hrs',
                selected: format == PanchangTimeFormat.h12,
                onTap: () => PanchangTimeFormatState.shared
                    .setFormat(PanchangTimeFormat.h12),
              ),
              _formatChip(
                context,
                label: '24 Hrs+',
                selected: format == PanchangTimeFormat.h24plus,
                onTap: () => PanchangTimeFormatState.shared
                    .setFormat(PanchangTimeFormat.h24plus),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _formatChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: <Color>[Color(0xFFC77DFF), Color(0xFF7D33C3)],
                )
              : null,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

/// Right-pinned, intrinsic-width time cell: a main clock line plus an
/// optional small date sub-line. Never flexes, so the name column beside it
/// gets all remaining width and times stay on one line.
class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.main,
    this.sub,
    this.color,
    this.dimmed = false,
  });

  final String main;
  final String? sub;
  final Color? color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mainColor =
        color ?? colorScheme.onSurface.withValues(alpha: dimmed ? 0.62 : 0.85);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            main,
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              color: mainColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PanchangDayView extends StatelessWidget {
  const _PanchangDayView({
    required this.panchang,
    required this.placeLabel,
    required this.mode,
    required this.format,
    required this.now,
  });

  final DailyPanchang panchang;
  final String placeLabel;
  final TerminologyMode mode;
  final PanchangTimeFormat format;
  final DateTime Function() now;

  PanchangMomentParts _momentParts(PanchangTimeBundle bundle) {
    return formatPanchangMomentParts(
      bundle,
      panchangDateIso: panchang.date,
      format: format,
    );
  }

  PanchangRangeParts _rangeParts(PanchangWindow window) {
    return formatPanchangRangeParts(
      window,
      panchangDateIso: panchang.date,
      format: format,
    );
  }

  String _momentLine(PanchangTimeBundle bundle) {
    return formatPanchangMoment(
      bundle,
      panchangDateIso: panchang.date,
      format: format,
    );
  }

  bool _isLiveWindow(PanchangTimeBundle start, PanchangTimeBundle end) {
    final startInstant = _wallClock(start.localIso);
    final endInstant = _wallClock(end.localIso);
    if (startInstant == null || endInstant == null) {
      return false;
    }
    // Compare in the panchang location's own wall-clock: the window ISO carries
    // that location's local time, so we strip the offset and read the clock
    // there. This stays correct under any host timezone and any test clock.
    final current = now();
    final currentWall = DateTime(
      current.year,
      current.month,
      current.day,
      current.hour,
      current.minute,
      current.second,
    );
    return !currentWall.isBefore(startInstant) &&
        currentWall.isBefore(endInstant);
  }

  /// Parses the wall-clock portion of a local ISO string, dropping any
  /// timezone offset so comparisons are zone-independent.
  static DateTime? _wallClock(String localIso) {
    if (localIso.length < 19) {
      return null;
    }
    return DateTime.tryParse(localIso.substring(0, 19));
  }

  @override
  Widget build(BuildContext context) {
    final sunAvailable = panchang.sun.sunrise != null;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        150 + MediaQuery.of(context).padding.bottom,
      ),
      children: <Widget>[
        _buildHeroCard(context),
        const SizedBox(height: 12),
        _buildSunMoonCard(context),
        const SizedBox(height: 12),
        _buildFiveLimbsCard(context),
        const SizedBox(height: 12),
        _buildRashiCard(context),
        if (sunAvailable) ...<Widget>[
          const SizedBox(height: 12),
          _buildAuspiciousCard(context),
          const SizedBox(height: 12),
          _buildInauspiciousCard(context),
        ] else ...<Widget>[
          const SizedBox(height: 12),
          _buildPolarNotice(context),
        ],
        const SizedBox(height: 12),
        _buildBalaCard(context),
        if (panchang.advanced.horaTimeline.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _buildHoraCard(context),
        ],
        if (panchang.advanced.choghadiyaDay.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _buildChoghadiyaCard(context),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: Theme.of(context).colorScheme,
        radius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String emoji,
    String title, {
    Color? color,
  }) {
    return Row(
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _groupLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              letterSpacing: 1.4,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.62),
            ),
      ),
    );
  }

  Widget _groupDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Divider(
        height: 1,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.35),
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

  /// A limb entry: name (wraps left-aligned) + pinned time cell.
  Widget _limbRow(
    BuildContext context, {
    required String name,
    required _TimeCell cell,
    bool live = false,
    bool dimmed = false,
    bool warn = false,
    Color? nameColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resolvedNameColor = nameColor ??
        colorScheme.onSurface.withValues(alpha: dimmed && !live ? 0.82 : 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: resolvedNameColor,
                    ),
                  ),
                ),
                if (warn) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 13,
                    color: _inauspiciousAccent.withValues(alpha: 0.85),
                  ),
                ],
                if (live) _nowPill(context),
              ],
            ),
          ),
          const SizedBox(width: 12),
          cell,
        ],
      ),
    );
  }

  /// A muhurta row: accent dot, label, pinned accent time cell.
  Widget _muhurtaRow(
    BuildContext context, {
    required String label,
    required Color accent,
    PanchangWindow? window,
    String? noteMain,
    String? noteSub,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final live = window != null && _isLiveWindow(window.start, window.end);
    final parts = window == null ? null : _rangeParts(window);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: live ? 1.0 : 0.45),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.95),
                    ),
                  ),
                ),
                if (live) _nowPill(context),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (parts != null)
            _TimeCell(main: parts.span, sub: parts.dateSuffix, color: accent)
          else
            _TimeCell(
              main: noteMain ?? '—',
              sub: noteSub,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
        ],
      ),
    );
  }

  /// An info row: muted label + pinned value cell with optional sub-line.
  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
    String? sub,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _limbName(PanchangLimbEntry entry) {
    return mode == TerminologyMode.vedic ? entry.nameVedic : entry.nameEnglish;
  }

  Widget _buildHeroCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weekday = mode == TerminologyMode.vedic
        ? panchang.weekday.nameVedic
        : panchang.weekday.nameEnglish;
    final firstTithi = panchang.tithi.isNotEmpty ? panchang.tithi.first : null;
    final month = panchang.lunarMonth;
    final samvat = panchang.samvat;
    return DecoratedBox(
      decoration: TrikaalSurface.decoration(
        colorScheme: colorScheme,
        radius: 18,
        fillAlpha: 0.30,
        borderAlpha: 0.55,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    weekday,
                    style: textTheme.titleMedium?.copyWith(
                      color: _goldAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    placeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (firstTithi != null) ...<Widget>[
              Text(
                _limbName(firstTithi),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'upto ${_momentLine(firstTithi.end)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _heroChip(context, '${month.purnimanta} · Purnimanta'),
                _heroChip(context, '${month.amanta} · Amanta'),
                _heroChip(
                  context,
                  mode == TerminologyMode.vedic
                      ? '${month.paksha} Paksha'
                      : '${month.pakshaEnglish} Moon',
                ),
                _heroChip(context, '${panchang.ayanaRitu.rituNirayana} Ritu'),
                _heroChip(context, panchang.ayanaRitu.ayanaNirayana),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 8),
            _infoRow(
              context,
              label: 'Vikram Samvat',
              value: '${samvat.vikram} · ${samvat.vikramSamvatsara}',
            ),
            _infoRow(
              context,
              label: 'Shaka Samvat',
              value: '${samvat.shaka} · ${samvat.shakaSamvatsara}',
            ),
            _infoRow(
              context,
              label: 'Kali Samvat',
              value: '${samvat.kali}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.92),
            ),
      ),
    );
  }

  Widget _buildSunMoonCard(BuildContext context) {
    final sun = panchang.sun;
    final moon = panchang.moon;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(context, '🌞', 'Surya & Chandra'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _celestialTile(
                context,
                icon: Icons.wb_twilight_rounded,
                iconColor: _goldAccent,
                label: 'Sunrise',
                parts: sun.sunrise == null ? null : _momentParts(sun.sunrise!),
              ),
              _celestialTile(
                context,
                icon: Icons.nights_stay_rounded,
                iconColor: _goldAccent,
                label: 'Sunset',
                parts: sun.sunset == null ? null : _momentParts(sun.sunset!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _celestialTile(
                context,
                icon: Icons.arrow_upward_rounded,
                iconColor: const Color(0xFFB9D4F1),
                label: 'Moonrise',
                parts:
                    moon.moonrise == null ? null : _momentParts(moon.moonrise!),
              ),
              _celestialTile(
                context,
                icon: Icons.arrow_downward_rounded,
                iconColor: const Color(0xFFB9D4F1),
                label: 'Moonset',
                parts:
                    moon.moonset == null ? null : _momentParts(moon.moonset!),
              ),
            ],
          ),
          if (sun.dayDuration != null || sun.solarNoon != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              <String>[
                if (sun.dayDuration != null)
                  'Dinamana ${sun.dayDuration!.label}',
                if (sun.nightDuration != null)
                  'Ratrimana ${sun.nightDuration!.label}',
                if (sun.solarNoon != null)
                  'Madhyahna ${_momentLine(sun.solarNoon!)}',
              ].join('   ·   '),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _celestialTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required PanchangMomentParts? parts,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final dateSuffix = parts?.dateSuffix;
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                Text(
                  parts?.time ?? '—',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                // Next-day events keep the clock on one line and demote the
                // date to a small sub-line, matching _TimeCell elsewhere.
                if (dateSuffix != null)
                  Text(
                    dateSuffix,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveLimbsCard(BuildContext context) {
    final children = <Widget>[
      _sectionHeader(context, '🕉️', 'Panchangam'),
      const SizedBox(height: 4),
    ];

    var firstGroup = true;
    void addGroup(String label, List<Widget> rows) {
      if (!firstGroup) {
        children.add(_groupDivider(context));
      }
      firstGroup = false;
      children.add(_groupLabel(context, label));
      children.addAll(rows);
    }

    List<Widget> limbRows(
      List<PanchangLimbEntry> entries, {
      bool localizeAsNakshatra = false,
    }) {
      final anyLive = entries.any(
        (PanchangLimbEntry entry) => _isLiveWindow(entry.start, entry.end),
      );
      return entries.map((PanchangLimbEntry entry) {
        final live = _isLiveWindow(entry.start, entry.end);
        final name = localizeAsNakshatra
            ? localizeNakshatra(entry.nameVedic, mode)
            : _limbName(entry);
        final endParts = _momentParts(entry.end);
        return _limbRow(
          context,
          name: name,
          live: live,
          dimmed: anyLive && !live,
          warn: entry.isGandaMoola,
          nameColor: entry.isVishti ? _inauspiciousAccent : null,
          cell: _TimeCell(
            main: 'upto ${endParts.time}',
            sub: endParts.dateSuffix,
            color: entry.isVishti ? _inauspiciousAccent : null,
            dimmed: anyLive && !live,
          ),
        );
      }).toList(growable: false);
    }

    addGroup('Tithi', limbRows(panchang.tithi));
    addGroup(
      'Nakshatra',
      limbRows(panchang.nakshatra, localizeAsNakshatra: true),
    );
    addGroup('Yoga', limbRows(panchang.yoga));
    addGroup('Karana', limbRows(panchang.karana));

    final nextSunrise = panchang.sun.nextSunrise;
    final varaParts = nextSunrise == null ? null : _momentParts(nextSunrise);
    addGroup('Vara', <Widget>[
      _limbRow(
        context,
        name: mode == TerminologyMode.vedic
            ? panchang.weekday.nameVedic
            : panchang.weekday.nameEnglish,
        cell: varaParts == null
            ? const _TimeCell(main: '—')
            : _TimeCell(
                main: 'upto ${varaParts.time}',
                sub: varaParts.dateSuffix,
              ),
      ),
    ]);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRashiCard(BuildContext context) {
    final rashi = panchang.rashi;
    final change = rashi.moonRashiChange;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(context, '🌙', 'Rashi & Ayana'),
          const SizedBox(height: 6),
          _infoRow(
            context,
            label: 'Chandra Rashi',
            value: localizeRashi(rashi.moonRashi, mode),
            sub: change == null
                ? null
                : 'upto ${_momentLine(change.at)}, '
                    'then ${localizeRashi(change.nextRashi, mode)}',
          ),
          _infoRow(
            context,
            label: 'Surya Rashi',
            value: localizeRashi(rashi.sunRashi, mode),
          ),
          _infoRow(
            context,
            label: 'Surya Nakshatra',
            // The clean vedic-map form keeps this single-line; the pada is
            // the load-bearing datum, so it gets the sub-line.
            value: localizeNakshatra(
              rashi.sunNakshatraName,
              TerminologyMode.vedic,
            ),
            sub: 'Pada ${rashi.sunNakshatraPada}',
          ),
          _infoRow(
            context,
            label: 'Sayana Ayana',
            value: panchang.ayanaRitu.ayanaSayana,
          ),
          _infoRow(
            context,
            label: 'Sayana Ritu',
            value: panchang.ayanaRitu.rituSayana,
          ),
        ],
      ),
    );
  }

  Widget _buildAuspiciousCard(BuildContext context) {
    final auspicious = panchang.auspicious;
    final rows = <Widget>[];

    void addWindow(String label, PanchangWindow? window) {
      if (window == null) {
        return;
      }
      rows.add(
        _muhurtaRow(
          context,
          label: label,
          accent: _auspiciousAccent,
          window: window,
        ),
      );
    }

    addWindow('Brahma Muhurta', auspicious.brahmaMuhurta);
    addWindow('Pratah Sandhya', auspicious.pratahSandhya);
    if (auspicious.abhijitMuhurta != null) {
      addWindow('Abhijit Muhurta', auspicious.abhijitMuhurta);
    } else {
      rows.add(
        _muhurtaRow(
          context,
          label: 'Abhijit Muhurta',
          accent: _auspiciousAccent,
          noteMain: 'Not observed',
          noteSub: 'on Budhavara',
        ),
      );
    }
    addWindow('Vijaya Muhurta', auspicious.vijayaMuhurta);
    addWindow('Godhuli Muhurta', auspicious.godhuliMuhurta);
    addWindow('Sayahna Sandhya', auspicious.sayahnaSandhya);
    for (final window in auspicious.amritKalam) {
      addWindow('Amrit Kalam', window);
    }
    addWindow('Nishita Muhurta', auspicious.nishitaMuhurta);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            context,
            '✨',
            'Shubha Muhurat',
            color: _auspiciousAccent,
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInauspiciousCard(BuildContext context) {
    final inauspicious = panchang.inauspicious;
    final rows = <Widget>[];

    void addWindow(String label, PanchangWindow? window) {
      if (window == null) {
        return;
      }
      rows.add(
        _muhurtaRow(
          context,
          label: label,
          accent: _inauspiciousAccent,
          window: window,
        ),
      );
    }

    addWindow('Rahu Kalam', inauspicious.rahuKalam);
    addWindow('Yamaganda', inauspicious.yamaganda);
    addWindow('Gulikai Kalam', inauspicious.gulikaiKalam);
    for (final window in inauspicious.durMuhurtam) {
      addWindow('Dur Muhurtam', window);
    }
    for (final window in inauspicious.varjyam) {
      addWindow('Varjyam', window);
    }
    for (final window in inauspicious.bhadra) {
      addWindow('Bhadra (Vishti)', window);
    }
    for (final gandaMoola in inauspicious.gandaMoola) {
      addWindow(
        'Ganda Moola · ${localizeNakshatra(gandaMoola.nakshatra, TerminologyMode.vedic)}',
        PanchangWindow(start: gandaMoola.start, end: gandaMoola.end),
      );
    }
    final panchaka = panchang.advanced.panchaka;
    if (panchaka != null) {
      addWindow(
        panchaka.label,
        PanchangWindow(start: panchaka.start, end: panchaka.end),
      );
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            context,
            '⚠️',
            'Ashubha Muhurat',
            color: _inauspiciousAccent,
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildPolarNotice(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(context, '🧭', 'Muhurta unavailable'),
          const SizedBox(height: 6),
          Text(
            'The sun does not rise or set at this location today (polar day or night), '
            'so sunrise-anchored muhurtas cannot be computed. The five limbs above are '
            'anchored to local noon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalaCard(BuildContext context) {
    final advanced = panchang.advanced;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(context, '🧭', 'Bala & Shoola'),
          const SizedBox(height: 6),
          _infoRow(
            context,
            label: 'Disha Shoola',
            value: advanced.dishaShoola,
            sub: 'avoid travelling this way',
            valueColor: _inauspiciousAccent,
          ),
          const SizedBox(height: 6),
          _chipGroup(
            context,
            title: 'Chandrabala (favourable rashi)',
            values: advanced.chandrabalam
                .map((String rashi) => localizeRashi(rashi, mode))
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _chipGroup(
            context,
            title: 'Tarabala (favourable janma nakshatra)',
            values: advanced.tarabalam
                .map((String nakshatra) => localizeNakshatra(
                      nakshatra,
                      TerminologyMode.vedic,
                    ))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _chipGroup(
    BuildContext context, {
    required String title,
    required List<String> values,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values
              .map(
                (String value) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _auspiciousAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _auspiciousAccent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.92),
                          fontSize: 11.5,
                        ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildHoraCard(BuildContext context) {
    final slots = panchang.advanced.horaTimeline;
    return _ExpandableCard(
      emoji: '⏳',
      title: 'Hora Timeline',
      subtitle: '24 planetary hours from sunrise',
      children: slots.map((PanchangHoraSlot slot) {
        final window = PanchangWindow(start: slot.start, end: slot.end);
        final parts = _rangeParts(window);
        return _timelineRow(
          context,
          leading: slot.isDay
              ? Icons.wb_sunny_rounded
              : Icons.nightlight_round_rounded,
          leadingColor: slot.isDay ? _goldAccent : const Color(0xFFB9D4F1),
          title:
              mode == TerminologyMode.vedic ? slot.lordVedic : slot.lordEnglish,
          cell: _TimeCell(main: parts.span, sub: parts.dateSuffix),
          live: _isLiveWindow(slot.start, slot.end),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildChoghadiyaCard(BuildContext context) {
    final advanced = panchang.advanced;
    return _ExpandableCard(
      emoji: '🕰️',
      title: 'Choghadiya',
      subtitle: 'Day & night auspicious slots',
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: _groupLabel(context, 'Day'),
        ),
        ...advanced.choghadiyaDay.map(
          (PanchangChoghadiyaSlot slot) => _choghadiyaRow(context, slot),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _groupLabel(context, 'Night'),
        ),
        ...advanced.choghadiyaNight.map(
          (PanchangChoghadiyaSlot slot) => _choghadiyaRow(context, slot),
        ),
      ],
    );
  }

  Widget _choghadiyaRow(BuildContext context, PanchangChoghadiyaSlot slot) {
    final window = PanchangWindow(start: slot.start, end: slot.end);
    final parts = _rangeParts(window);
    return _timelineRow(
      context,
      leading: Icons.circle,
      leadingColor:
          slot.isAuspicious ? _auspiciousAccent : _inauspiciousAccent,
      leadingSize: 9,
      title: slot.name,
      cell: _TimeCell(main: parts.span, sub: parts.dateSuffix),
      live: _isLiveWindow(slot.start, slot.end),
    );
  }

  Widget _timelineRow(
    BuildContext context, {
    required IconData leading,
    required Color leadingColor,
    required String title,
    required _TimeCell cell,
    double leadingSize = 16,
    bool live = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: SizedBox(
              width: 20,
              child: Icon(leading, size: leadingSize, color: leadingColor),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (live) _nowPill(context),
              ],
            ),
          ),
          const SizedBox(width: 12),
          cell,
        ],
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _expanded = false;

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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(children: widget.children),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
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
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

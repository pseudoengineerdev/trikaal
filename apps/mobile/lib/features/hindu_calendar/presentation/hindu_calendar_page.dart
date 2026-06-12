import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_hindu_calendar_models.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import 'state/hindu_calendar_controller.dart';

class HinduCalendarPage extends StatefulWidget {
  const HinduCalendarPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<HinduCalendarPage> createState() => _HinduCalendarPageState();
}

class _HinduCalendarPageState extends State<HinduCalendarPage> {
  late final HinduCalendarController _controller;
  late DateTime _visibleMonth;
  String _monthType = 'purnimanta';
  String? _selectedDateIso;
  String? _lastRequestSignature;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _controller = HinduCalendarController();
    widget.birthInputState.addListener(_handleBirthInputChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_refreshRequestSignature() && _canCompute) {
        _compute();
      }
    });
  }

  @override
  void dispose() {
    widget.birthInputState.removeListener(_handleBirthInputChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleBirthInputChange() {
    if (!mounted) {
      return;
    }
    if (_refreshRequestSignature() && _canCompute) {
      _compute();
    }
  }

  bool get _canCompute {
    return widget.birthInputState.dateOfBirth.trim().isNotEmpty &&
        widget.birthInputState.timeOfBirth.trim().isNotEmpty &&
        widget.birthInputState.placeOfBirth.trim().isNotEmpty;
  }

  ComputeHinduCalendarRequest _buildRequest() {
    final currentPlace = widget.birthInputState.placeForCurrentObservations;
    final currentCustomPlace =
        widget.birthInputState.customPlaceForCurrentObservations;
    return ComputeHinduCalendarRequest(
      year: _visibleMonth.year,
      month: _visibleMonth.month,
      monthType: _monthType,
      placeOfBirth: currentPlace,
      customPlace: currentCustomPlace,
    );
  }

  Future<void> _compute() {
    if (!_canCompute) {
      return Future<void>.value();
    }
    return _controller.compute(request: _buildRequest());
  }

  String? _currentRequestSignature() {
    final currentPlace = widget.birthInputState.placeForCurrentObservations;
    final currentCustomPlace =
        widget.birthInputState.customPlaceForCurrentObservations;
    if (currentPlace.isEmpty) {
      return null;
    }
    final customSignature = currentCustomPlace == null
        ? ''
        : '${currentCustomPlace.latitude.toStringAsFixed(6)}|'
            '${currentCustomPlace.longitude.toStringAsFixed(6)}|'
            '${currentCustomPlace.timezone}|${currentCustomPlace.elevationM.toStringAsFixed(1)}';
    return '${widget.birthInputState.dateOfBirth}|${widget.birthInputState.timeOfBirth}|'
        '$currentPlace|$customSignature|${_visibleMonth.year}-${_visibleMonth.month}|$_monthType';
  }

  bool _refreshRequestSignature() {
    final requestSignature = _currentRequestSignature();
    if (requestSignature == null || _lastRequestSignature == requestSignature) {
      return false;
    }
    _lastRequestSignature = requestSignature;
    return true;
  }

  void _setMonthType(String value) {
    if (_monthType == value) {
      return;
    }
    setState(() => _monthType = value);
    _refreshRequestSignature();
    if (_canCompute) {
      _compute();
    }
  }

  void _setMonth(int delta) {
    final current =
        DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    setState(() {
      _visibleMonth = DateTime(current.year, current.month, 1);
    });
    _refreshRequestSignature();
    _compute();
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity.abs() < 180.0) {
      return;
    }
    if (velocity < 0) {
      _setMonth(1);
    } else {
      _setMonth(-1);
    }
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
        // Already on the calendar: keep the icon for bar consistency, but
        // tapping it is a no-op (same pattern as premium on subscription).
        onCalendarTap: () {},
        onPremiumTap: () => _handleDockTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              if (!_canCompute) {
                return _StateMessage(
                  title: 'Birth details needed',
                  body:
                      'Complete onboarding first so we can build your Sanatani calendar.',
                  actionLabel: 'Go to Home',
                  onAction: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                );
              }

              if (_controller.loading && _controller.result == null) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (_controller.error != null && _controller.result == null) {
                return _StateMessage(
                  title: 'Unable to compute calendar',
                  body: _controller.error!,
                  actionLabel: 'Retry',
                  onAction: _compute,
                );
              }

              final response = _controller.result;
              if (response == null) {
                return _StateMessage(
                  title: 'No calendar data yet',
                  body:
                      'Pull to refresh or try again after updating birth details.',
                  actionLabel: 'Retry',
                  onAction: _compute,
                );
              }

              final calendar = response.calendar;
              final selected = _selectedEntry(calendar);
              return RefreshIndicator(
                onRefresh: _compute,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    12,
                    0,
                    160 + MediaQuery.of(context).padding.bottom,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _monthSwitcher(context, calendar, selected),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onHorizontalDragEnd: _onHorizontalSwipe,
                      child: _calendarCard(context, calendar),
                    ),
                    if (_controller.loading) ...<Widget>[
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: LoadingHint(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  HinduCalendarMonthDay _selectedEntry(HinduCalendarMonth calendar) {
    if (_selectedDateIso != null) {
      final selected = calendar.days.firstWhere(
        (day) => day.gregorianDate == _selectedDateIso,
        orElse: () => calendar.selectedDay,
      );
      _selectedDateIso = selected.gregorianDate;
      return selected;
    }
    _selectedDateIso = calendar.selectedDate;
    return calendar.selectedDay;
  }

  Widget _monthSwitcher(
    BuildContext context,
    HinduCalendarMonth calendar,
    HinduCalendarMonthDay selected,
  ) {
    final monthColor = Theme.of(context).colorScheme.primary;
    final selectedDay =
        DateTime.tryParse(selected.gregorianDate)?.day ?? DateTime.now().day;
    final currentMonth = calendar.gregorianMonthLabel;
    final currentMonthText = Text(
      currentMonth,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
    );
    final navButton = _MonthNavButton(
      icon: Icons.chevron_left_rounded,
      onPressed: () => _setMonth(-1),
      color: monthColor,
    );
    final nextButton = _MonthNavButton(
      icon: Icons.chevron_right_rounded,
      onPressed: () => _setMonth(1),
      color: monthColor,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: TrikaalSurface.decoration(
        colorScheme: Theme.of(context).colorScheme,
        radius: 14,
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _selectedDayPhaseBlock(context, selected),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.topRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$selectedDay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    currentMonthText,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _MonthTypeButton(
                label: 'Purnimanta',
                emoji: '🌕',
                selected: _monthType == 'purnimanta',
                onTap: () => _setMonthType('purnimanta'),
              ),
              const SizedBox(width: 10),
              _MonthTypeButton(
                label: 'Amanta',
                emoji: '🌑',
                selected: _monthType == 'amanta',
                onTap: () => _setMonthType('amanta'),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  navButton,
                  const SizedBox(width: 6),
                  nextButton,
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
          ),
          const SizedBox(height: 10),
          _selectedDaySummary(context, selected),
        ],
      ),
    );
  }

  Widget _selectedDayPhaseBlock(
    BuildContext context,
    HinduCalendarMonthDay selected,
  ) {
    final lunarMonthLine = _formatLunarDay(selected);
    final pakshaLine = _formatPaksha(selected);
    final tithiLine = _formatTithi(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              _moonPhaseEmoji(selected),
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    lunarMonthLine,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pakshaLine $tithiLine'.trim(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPaksha(HinduCalendarMonthDay selected) {
    if (selected.paksha.isNotEmpty) {
      return selected.paksha;
    }
    if (selected.pakshaEnglish.isNotEmpty) {
      return selected.pakshaEnglish;
    }
    return 'Lunar phase';
  }

  String _formatTithi(HinduCalendarMonthDay selected) {
    final raw = _cleanTithiName(selected.tithiNameEnglish);
    if (raw.isEmpty) {
      return 'Tithi ${selected.tithiNumber}';
    }
    return raw;
  }

  String _formatLunarDay(HinduCalendarMonthDay selected) {
    return '${selected.lunarMonthName} ${selected.lunarDayOfMonth}'.trim();
  }

  String _cleanTithiName(String raw) {
    if (raw.trim().isEmpty) {
      return '';
    }
    final tokens = raw
        .split(RegExp(r'[\s-]+'))
        .where((String token) => token.trim().isNotEmpty)
        .map((String token) => token.toLowerCase())
        .where(
          (String token) =>
              token != 'waning' &&
              token != 'waxing' &&
              token != 'purnimanta' &&
              token != 'amanta',
        )
        .toList(growable: false);
    if (tokens.isEmpty) {
      return 'Tithi ${_selectedTithiFallback(raw)}';
    }
    final firstUpper = _toTitleCase(tokens.first);
    return <String>[
      if (firstUpper.isNotEmpty) ...<String>[
        firstUpper,
        ...tokens.sublist(1),
      ],
    ].join(' ');
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) {
      return '';
    }
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  String _selectedTithiFallback(String raw) {
    final number = RegExp(r'\d+').firstMatch(raw);
    if (number == null) {
      return '1';
    }
    return number.group(0)!;
  }

  String _moonPhaseEmoji(HinduCalendarMonthDay selected) {
    final paksha = selected.paksha.toLowerCase();
    final tithi = selected.tithiDay;
    if (paksha.contains('krishna')) {
      if (tithi >= 13) {
        return '🌑';
      }
      if (tithi >= 10) {
        return '🌘';
      }
      if (tithi >= 7) {
        return '🌗';
      }
      if (tithi >= 4) {
        return '🌖';
      }
      return '🌒';
    }
    if (paksha.contains('shukla')) {
      if (tithi >= 13) {
        return '🌕';
      }
      if (tithi >= 10) {
        return '🌖';
      }
      if (tithi >= 7) {
        return '🌔';
      }
      if (tithi >= 4) {
        return '🌒';
      }
      return '🌒';
    }
    if (selected.tithiNumber >= 15) {
      return '🌕';
    }
    if (selected.tithiNumber <= 15) {
      return '🌒';
    }
    return '🌑';
  }

  Widget _calendarCard(BuildContext context, HinduCalendarMonth calendar) {
    final layout = _buildVerticalWeekColumns(calendar);
    final weeks = layout.weeks;
    final todayIso = calendar.todayLocalDate.isNotEmpty
        ? calendar.todayLocalDate
        : _todayIso();
    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.12),
      ),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 360;
          final rowHeight = compact ? 84.0 : 94.0;
          final railWidth = compact ? 18.0 : 22.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _WeekdayRail(
                width: railWidth,
                colorScheme: Theme.of(context).colorScheme,
                rowHeight: rowHeight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int weekIndex = 0;
                        weekIndex < weeks.length;
                        weekIndex += 1) ...<Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            for (int weekday = 0; weekday < 7; weekday += 1)
                              SizedBox(
                                height: rowHeight,
                                child: _CalendarDayCell(
                                  day: weeks[weekIndex][weekday],
                                  selected: weeks[weekIndex][weekday] != null &&
                                      weeks[weekIndex][weekday]!
                                              .gregorianDate ==
                                          _selectedDateIso,
                                  isToday: weeks[weekIndex][weekday] != null &&
                                      weeks[weekIndex][weekday]!
                                              .gregorianDate ==
                                          todayIso,
                                  dimmed: weeks[weekIndex][weekday] != null &&
                                      layout.overflowDates.contains(
                                        weeks[weekIndex][weekday]!
                                            .gregorianDate,
                                      ),
                                  onTap: weeks[weekIndex][weekday] == null
                                      ? null
                                      : () {
                                          setState(
                                            () => _selectedDateIso =
                                                weeks[weekIndex][weekday]!
                                                    .gregorianDate,
                                          );
                                        },
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (weekIndex != weeks.length - 1)
                        const SizedBox(width: 3),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    // The grid's row heights are fixed; cap text scaling so accessibility
    // sizes shrink-to-fit (via the cells' FittedBoxes) instead of clipping.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: card,
    );
  }

  _MonthGridLayout _buildVerticalWeekColumns(
    HinduCalendarMonth calendar,
  ) {
    final firstOffset = calendar.firstWeekdaySunday0.clamp(0, 6);
    final totalSlots = firstOffset + calendar.days.length;
    final weekCount = (totalSlots + 6) ~/ 7;
    final compactWeekCount = weekCount > 5 ? 5 : weekCount;
    final shouldCompact = weekCount > 5;

    final weeks = List<List<HinduCalendarMonthDay?>>.generate(
      compactWeekCount,
      (_) => List<HinduCalendarMonthDay?>.filled(7, null),
    );

    final overflowDays = <HinduCalendarMonthDay>[];
    final overflowDates = <String>{};

    for (int dayIndex = 0; dayIndex < calendar.days.length; dayIndex += 1) {
      final slot = firstOffset + dayIndex;
      final weekIndex = slot ~/ 7;
      final weekday = slot % 7;
      if (shouldCompact && weekIndex >= compactWeekCount) {
        overflowDays.add(calendar.days[dayIndex]);
        continue;
      }
      weeks[weekIndex][weekday] = calendar.days[dayIndex];
    }

    if (overflowDays.isNotEmpty) {
      int topRow = 0;
      for (final day in overflowDays) {
        while (topRow < firstOffset && weeks[0][topRow] != null) {
          topRow += 1;
        }
        if (topRow >= firstOffset) {
          break;
        }
        weeks[0][topRow] = day;
        overflowDates.add(day.gregorianDate);
        topRow += 1;
      }
    }

    return _MonthGridLayout(weeks: weeks, overflowDates: overflowDates);
  }

  Widget _selectedDaySummary(
      BuildContext context, HinduCalendarMonthDay selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            _selectedDayInfoChip(
              context: context,
              label: 'Sunrise ${selected.sunriseLocalTime}',
              icon: Icons.wb_sunny_outlined,
            ),
            if (selected.sunsetLocalTime.isNotEmpty)
              _selectedDayInfoChip(
                context: context,
                label: 'Sunset ${selected.sunsetLocalTime}',
                icon: Icons.wb_twilight_rounded,
              ),
            _selectedDayInfoChip(
              context: context,
              label: 'Moon: ${selected.moonRashi}',
              icon: Icons.nightlight_round,
            ),
            if (selected.nakshatraName.isNotEmpty)
              _selectedDayInfoChip(
                context: context,
                label: 'Nakshatra: ${selected.nakshatraName}',
                icon: Icons.star_border_rounded,
              ),
            _selectedDayInfoChip(
              context: context,
              label: 'Sun: ${selected.sunRashi}',
              icon: Icons.wb_sunny_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectedDayInfoChip({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _todayIso() {
    final monthDate = _visibleMonth;
    final date = DateTime.now();
    if (date.year != monthDate.year || date.month != monthDate.month) {
      return '';
    }
    return DateTime(
      monthDate.year,
      monthDate.month,
      date.day,
    ).toIso8601String().split('T')[0];
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
}

class _MonthTypeButton extends StatelessWidget {
  const _MonthTypeButton({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(
                    alpha: 0.20,
                  ),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        width: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.50)),
        ),
        child: Icon(icon, size: 18, color: color),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _WeekdayRail extends StatelessWidget {
  const _WeekdayRail({
    required this.width,
    required this.rowHeight,
    required this.colorScheme,
  });

  final double width;
  final double rowHeight;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ];
    final Color sundayColor = colorScheme.primary.withValues(alpha: 0.30);
    final Color saturdayColor = colorScheme.secondary.withValues(alpha: 0.24);
    final Color weekdayColor =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.95);
    final Color borderColor =
        colorScheme.outlineVariant.withValues(alpha: 0.40);
    final Color textColor = colorScheme.onSurfaceVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < labels.length; index += 1)
            _WeekdayRailCell(
              label: labels[index],
              width: width,
              height: rowHeight,
              color: index == 0
                  ? sundayColor
                  : index == 6
                      ? saturdayColor
                      : weekdayColor,
              textColor: textColor,
              borderColor: borderColor,
            ),
        ],
      ),
    );
  }
}

class _WeekdayRailCell extends StatelessWidget {
  const _WeekdayRailCell({
    required this.label,
    required this.width,
    required this.height,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final double width;
  final double height;
  final Color color;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: label
            .split('')
            .map(
              (letter) => Text(
                letter,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MonthGridLayout {
  const _MonthGridLayout({
    required this.weeks,
    required this.overflowDates,
  });

  final List<List<HinduCalendarMonthDay?>> weeks;

  /// Dates relocated into empty leading slots because the month spans more
  /// than five week columns; rendered faded so they read as out-of-sequence.
  final Set<String> overflowDates;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.dimmed,
    this.onTap,
  });

  final HinduCalendarMonthDay? day;
  final bool selected;
  final bool isToday;
  final bool dimmed;
  final VoidCallback? onTap;

  /// "Krishna Pratipada" -> "Pratipada K", "Shukla Ashtami" -> "Ashtami S".
  /// Leads with the distinctive tithi name so narrow cells never truncate it
  /// down to the repeated paksha word. Purnima/Amavasya stay as-is.
  String _tithiLabel() {
    final name = (day!.tithiNameVedic.isNotEmpty
            ? day!.tithiNameVedic
            : day!.tithiNameEnglish)
        .trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        (parts.first == 'Krishna' || parts.first == 'Shukla')) {
      return '${parts.sublist(1).join(' ')} ${parts.first[0]}';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (day == null) {
      return Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.16),
          ),
        ),
      );
    }
    final backgroundColor = selected
        ? const Color(0xFF6B5F12).withValues(alpha: 0.88)
        : isToday
            ? colorScheme.primary.withValues(alpha: 0.28)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.16);
    final borderColor = selected
        ? const Color(0xFFFFD66B).withValues(alpha: 0.70)
        : colorScheme.outlineVariant.withValues(alpha: 0.28);
    final accentColor =
        selected ? const Color(0xFFFFECB0) : colorScheme.onSurfaceVariant;
    final detailColor = selected
        ? Colors.white.withValues(alpha: 0.86)
        : colorScheme.onSurfaceVariant;
    final nakshatra = day!.nakshatraName.isNotEmpty
        ? day!.nakshatraName
        : day!.sunRashi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
        child: Opacity(
          opacity: dimmed && !selected && !isToday ? 0.45 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _tithiLabel(),
                  maxLines: 1,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(
                height: 22,
                child: Stack(
                  children: <Widget>[
                    // Side insets keep the centered day number clear of the
                    // lunar-day label; FittedBox absorbs large text scales.
                    Positioned.fill(
                      left: 11,
                      right: 11,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${day!.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${day!.lunarDayOfMonth}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: day!.sunsetLocalTime.isEmpty
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: Text(
                        day!.sunriseLocalTime,
                        maxLines: 1,
                        style: TextStyle(
                          color: detailColor,
                          fontSize: 7.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  if (day!.sunsetLocalTime.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 3),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          day!.sunsetLocalTime,
                          maxLines: 1,
                          style: TextStyle(
                            color: detailColor,
                            fontSize: 7.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  day!.moonRashi,
                  maxLines: 1,
                  style: TextStyle(
                    color: detailColor,
                    fontSize: 8.5,
                    height: 1.0,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  nakshatra,
                  maxLines: 1,
                  style: TextStyle(
                    color: detailColor,
                    fontSize: 8.5,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

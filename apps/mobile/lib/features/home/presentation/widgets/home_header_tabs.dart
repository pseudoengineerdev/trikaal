import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/state/terminology_mode_state.dart';
import '../../../shared/widgets/terminology_toggle.dart';

enum HomeTab { today, feed }

/// The home screen's second header row: Today and Feed tabs flanking the
/// Sanskrit/English terminology toggle. Only the home screen renders this
/// row — every other screen shows just the primary app bar.
///
/// A single underline indicator sits flush with the bar's bottom edge and
/// slides across the row to whichever tab is active (left-to-right towards
/// Feed, right-to-left back to Today).
class HomeHeaderTabs extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeaderTabs({
    required this.activeTab,
    required this.onTabSelected,
    required this.terminologyListenable,
    required this.onTerminologyChanged,
    super.key,
  });

  static const double _horizontalPadding = 10;
  static const double _tabPadding = 8;
  static const TextStyle _activeLabelStyle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabSelected;
  final ValueListenable<TerminologyMode> terminologyListenable;
  final ValueChanged<TerminologyMode> onTerminologyChanged;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  /// Width of a tab's label plus its internal padding, so the indicator
  /// matches the tab it sits under.
  double _tabWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _activeLabelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width + 2 * _tabPadding;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = activeTab == HomeTab.today;
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            2,
            _horizontalPadding,
            6,
          ),
          child: Row(
            children: <Widget>[
              _HeaderTab(
                label: 'Today',
                selected: isToday,
                onTap: () => onTabSelected(HomeTab.today),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: ValueListenableBuilder<TerminologyMode>(
                    valueListenable: terminologyListenable,
                    builder: (
                      BuildContext context,
                      TerminologyMode mode,
                      Widget? child,
                    ) {
                      return TerminologyToggle(
                        mode: mode,
                        onChanged: onTerminologyChanged,
                        alignment: Alignment.center,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderTab(
                label: 'Feed',
                selected: !isToday,
                onTap: () => onTabSelected(HomeTab.feed),
              ),
            ],
          ),
        ),
        // The sliding indicator, flush with the bar's bottom edge.
        Positioned(
          left: _horizontalPadding,
          right: _horizontalPadding,
          bottom: 0,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment:
                isToday ? Alignment.bottomLeft : Alignment.bottomRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: 3,
              width: _tabWidth(isToday ? 'Today' : 'Feed'),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0xFFC77DFF),
                    Color(0xFF7D33C3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      // GestureDetector instead of InkWell: no ripple/highlight rectangle.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeHeaderTabs._tabPadding,
            vertical: 8,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: HomeHeaderTabs._activeLabelStyle.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

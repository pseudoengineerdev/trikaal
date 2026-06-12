import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/state/terminology_mode_state.dart';
import '../../../shared/widgets/terminology_toggle.dart';

enum HomeTab { today, feed }

/// The home screen's second header row: Today and Feed tabs flanking the
/// Sanskrit/English terminology toggle. Only the home screen renders this
/// row — every other screen shows just the primary app bar.
class HomeHeaderTabs extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeaderTabs({
    required this.activeTab,
    required this.onTabSelected,
    required this.terminologyListenable,
    required this.onTerminologyChanged,
    super.key,
  });

  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabSelected;
  final ValueListenable<TerminologyMode> terminologyListenable;
  final ValueChanged<TerminologyMode> onTerminologyChanged;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Row(
        children: <Widget>[
          _HeaderTab(
            label: 'Today',
            selected: activeTab == HomeTab.today,
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
            selected: activeTab == HomeTab.feed,
            onTap: () => onTabSelected(HomeTab.feed),
          ),
        ],
      ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 28),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF7D33C3),
                      Color(0xFF5A189A),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.9)
                  : colorScheme.outline.withValues(alpha: 0.5),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF5A189A).withValues(alpha: 0.30),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.95),
            ),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

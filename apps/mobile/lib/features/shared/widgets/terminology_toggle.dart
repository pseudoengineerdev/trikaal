import 'package:flutter/material.dart';

import '../../../app/state/terminology_mode_state.dart';
import '../../../app/theme/trikaal_surface.dart';

class TerminologyToggle extends StatelessWidget {
  const TerminologyToggle({
    required this.mode,
    required this.onChanged,
    this.alignment = Alignment.centerRight,
    super.key,
  });

  final TerminologyMode mode;
  final ValueChanged<TerminologyMode> onChanged;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: TrikaalSurface.decoration(
          colorScheme: colorScheme,
          radius: 14,
          fillAlpha: 0.32,
          borderAlpha: 0.56,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ModeChip(
                label: 'Vedic',
                icon: Icons.auto_awesome_rounded,
                selected: mode == TerminologyMode.vedic,
                onTap: () => onChanged(TerminologyMode.vedic),
              ),
              const SizedBox(width: 4),
              _ModeChip(
                label: 'English',
                icon: Icons.translate_rounded,
                selected: mode == TerminologyMode.english,
                onTap: () => onChanged(TerminologyMode.english),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
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
          color: selected ? null : Colors.transparent,
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.9)
                : Colors.transparent,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 12,
              color: selected
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

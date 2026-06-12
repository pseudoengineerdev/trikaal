import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../features/shared/widgets/terminology_toggle.dart';
import '../state/terminology_mode_state.dart';

final ValueNotifier<TerminologyMode> _headerTerminologyMode =
    ValueNotifier<TerminologyMode>(TerminologyMode.vedic);

PreferredSizeWidget buildTrikaalAppBar(
  BuildContext context, {
  VoidCallback? onPremiumTap,
  List<Widget>? actions,
  TerminologyMode? terminologyMode,
  ValueListenable<TerminologyMode>? terminologyModeListenable,
  ValueChanged<TerminologyMode>? onTerminologyChanged,
  VoidCallback? onCurrentLocationTap,
  String? currentLocationLabel,
  VoidCallback? onLeftCtaTap,
  VoidCallback? onRightCtaTap,
  String leftCtaLabel = 'Today',
  String rightCtaLabel = 'Actions',
  bool showControlsRow = true,
}) {
  final mergedActions = <Widget>[
    if (onPremiumTap != null)
      IconButton(
        tooltip: 'Premium',
        icon: const Icon(Icons.auto_awesome_rounded),
        onPressed: onPremiumTap,
      ),
    ...?actions,
  ];

  if (terminologyModeListenable == null &&
      terminologyMode != null &&
      _headerTerminologyMode.value != terminologyMode) {
    _headerTerminologyMode.value = terminologyMode;
  }

  final ValueListenable<TerminologyMode> activeTerminologyListenable =
      terminologyModeListenable ?? _headerTerminologyMode;

  void handleLeftCtaTap() {
    if (onLeftCtaTap != null) {
      onLeftCtaTap();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Today highlights are coming soon.')),
      );
  }

  void handleRightCtaTap() {
    if (onRightCtaTap != null) {
      onRightCtaTap();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('More quick actions are coming soon.')),
      );
  }

  Widget buildCtaButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(
          context,
        )
            .textTheme
            .labelLarge
            ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget buildToggle({
    required TerminologyMode mode,
    required ValueChanged<TerminologyMode> onChanged,
  }) {
    return TerminologyToggle(
      mode: mode,
      onChanged: onChanged,
      alignment: Alignment.center,
    );
  }

  final shouldReplaceLeftCtaWithLocation = onCurrentLocationTap != null &&
      onLeftCtaTap == null &&
      leftCtaLabel == 'Today';

  final controlsRow = showControlsRow
      ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: ValueListenableBuilder<TerminologyMode>(
              valueListenable: activeTerminologyListenable,
              builder:
                  (BuildContext context, TerminologyMode mode, Widget? child) {
                final leftSlot = shouldReplaceLeftCtaWithLocation
                    ? IconButton(
                        tooltip: currentLocationLabel == null
                            ? 'Set current location'
                            : 'Current location: $currentLocationLabel',
                        icon: const Icon(Icons.location_on_rounded),
                        onPressed: onCurrentLocationTap,
                      )
                    : buildCtaButton(
                        label: leftCtaLabel,
                        onPressed: handleLeftCtaTap,
                      );

                return Row(
                  children: <Widget>[
                    leftSlot,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: buildToggle(
                          mode: mode,
                          onChanged: (TerminologyMode selectedMode) {
                            if (terminologyModeListenable == null) {
                              _headerTerminologyMode.value = selectedMode;
                            }
                            onTerminologyChanged?.call(selectedMode);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    buildCtaButton(
                      label: rightCtaLabel,
                      onPressed: handleRightCtaTap,
                    ),
                  ],
                );
              },
            ),
          ),
        )
      : null;

  return AppBar(
    automaticallyImplyLeading: false,
    leading: IconButton(
      tooltip: 'Notifications',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications and home-screen widget controls are coming soon.',
              ),
            ),
          );
      },
    ),
    centerTitle: true,
    title: Text(
      'Trikaal',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'Samarkan',
            fontSize: 40,
            fontWeight: FontWeight.w500,
          ),
    ),
    actions: mergedActions.isEmpty ? null : mergedActions,
    bottom: controlsRow,
  );
}

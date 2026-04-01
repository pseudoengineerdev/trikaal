import 'package:flutter/material.dart';

import '../../../app/state/terminology_mode_state.dart';

class TerminologyToggle extends StatelessWidget {
  const TerminologyToggle({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final TerminologyMode mode;
  final ValueChanged<TerminologyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SegmentedButton<TerminologyMode>(
        segments: const <ButtonSegment<TerminologyMode>>[
          ButtonSegment<TerminologyMode>(
            value: TerminologyMode.vedic,
            label: Text('Vedic'),
          ),
          ButtonSegment<TerminologyMode>(
            value: TerminologyMode.english,
            label: Text('English'),
          ),
        ],
        selected: <TerminologyMode>{mode},
        onSelectionChanged: (Set<TerminologyMode> selection) {
          final selected = selection.first;
          onChanged(selected);
        },
      ),
    );
  }
}

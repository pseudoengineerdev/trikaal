import 'package:flutter/material.dart';

import '../../../app/state/birth_input_state.dart';
import 'state/dasha_controller.dart';
import 'widgets/dasha_state_widgets.dart';

class DashaPage extends StatefulWidget {
  const DashaPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<DashaPage> createState() => _DashaPageState();
}

class _DashaPageState extends State<DashaPage> {
  final _controller = DashaController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dasha')),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _controller,
          widget.birthInputState,
        ]),
        builder: (BuildContext context, Widget? child) {
          if (_controller.loading) {
            return const DashaLoadingState();
          }
          if (_controller.error != null) {
            return DashaErrorState(
              message: _controller.error!,
              onRetry: _loadSampleDasha,
            );
          }
          if (_controller.summary == null) {
            return DashaEmptyState(
              dateOfBirth: widget.birthInputState.dateOfBirth,
              timeOfBirth: widget.birthInputState.timeOfBirth,
              placeOfBirth: widget.birthInputState.placeOfBirth,
            );
          }
          return DashaSummaryCard(
            summary: _controller.summary!,
            dateOfBirth: widget.birthInputState.dateOfBirth,
            timeOfBirth: widget.birthInputState.timeOfBirth,
            placeOfBirth: widget.birthInputState.placeOfBirth,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.loading ? null : _loadSampleDasha,
        label: const Text('Compute Dasha'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }

  Future<void> _loadSampleDasha() {
    return _controller.loadCurrentDasha(
      dateOfBirth: widget.birthInputState.dateOfBirth,
      timeOfBirth: widget.birthInputState.timeOfBirth,
      placeOfBirth: widget.birthInputState.placeOfBirth,
    );
  }
}

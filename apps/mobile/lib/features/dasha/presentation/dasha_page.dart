import 'package:flutter/material.dart';

import 'state/dasha_controller.dart';
import 'widgets/dasha_state_widgets.dart';

class DashaPage extends StatefulWidget {
  const DashaPage({super.key});

  @override
  State<DashaPage> createState() => _DashaPageState();
}

class _DashaPageState extends State<DashaPage> {
  final _controller = DashaController();
  static const _sampleDob = '1999-07-04';
  static const _sampleTime = '12:22';
  static const _samplePlace = 'Mumbai';

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
        animation: _controller,
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
            return const DashaEmptyState();
          }
          return DashaSummaryCard(summary: _controller.summary!);
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
      dateOfBirth: _sampleDob,
      timeOfBirth: _sampleTime,
      placeOfBirth: _samplePlace,
    );
  }
}

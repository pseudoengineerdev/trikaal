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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dasha (Preview)')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          if (_controller.loading) {
            return const DashaLoadingState();
          }
          if (_controller.error != null) {
            return DashaErrorState(
              message: _controller.error!,
              onRetry: _controller.loadPreview,
            );
          }
          if (_controller.summary == null) {
            return const DashaEmptyState();
          }
          return DashaSummaryCard(summary: _controller.summary!);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.loading ? null : _controller.loadPreview,
        label: const Text('Load Preview'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}

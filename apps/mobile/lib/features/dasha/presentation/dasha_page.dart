import 'dart:async';

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
  Timer? _recomputeDebounce;

  @override
  void initState() {
    super.initState();
    widget.birthInputState.addListener(_onBirthInputChanged);
    _computeFromSharedInputs();
  }

  @override
  void dispose() {
    _recomputeDebounce?.cancel();
    widget.birthInputState.removeListener(_onBirthInputChanged);
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
              onRetry: _computeFromSharedInputs,
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
    );
  }

  void _onBirthInputChanged() {
    _recomputeDebounce?.cancel();
    _recomputeDebounce = Timer(const Duration(milliseconds: 450), () {
      _computeFromSharedInputs();
    });
  }

  Future<void> _computeFromSharedInputs() {
    if (!_isInputValid()) {
      return Future<void>.value();
    }
    return _controller.loadCurrentDasha(
      dateOfBirth: widget.birthInputState.dateOfBirth,
      timeOfBirth: widget.birthInputState.timeOfBirth,
      placeOfBirth: widget.birthInputState.placeOfBirth,
    );
  }

  bool _isInputValid() {
    final date = widget.birthInputState.dateOfBirth.trim();
    final time = widget.birthInputState.timeOfBirth.trim();
    final place = widget.birthInputState.placeOfBirth.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return false;
    }
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      return false;
    }
    return place.isNotEmpty;
  }
}

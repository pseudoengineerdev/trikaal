import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../shared/widgets/terminology_toggle.dart';
import 'state/dasha_controller.dart';
import 'widgets/dasha_state_widgets.dart';

class DashaPage extends StatefulWidget {
  const DashaPage({
    required this.birthInputState,
    required this.terminologyModeState,
    required this.astrologyTermsState,
    super.key,
  });

  final BirthInputState birthInputState;
  final TerminologyModeState terminologyModeState;
  final AstrologyTermsState astrologyTermsState;

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
          widget.terminologyModeState,
          widget.astrologyTermsState,
        ]),
        builder: (BuildContext context, Widget? child) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: TerminologyToggle(
                  mode: widget.terminologyModeState.mode,
                  onChanged: widget.terminologyModeState.setMode,
                ),
              ),
              Expanded(
                child: _buildBodyContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBodyContent() {
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
      mode: widget.terminologyModeState.mode,
      termsState: widget.astrologyTermsState,
    );
  }

  void _onBirthInputChanged() {
    if (!widget.birthInputState.hasComputedChart) {
      _recomputeDebounce?.cancel();
      _controller.clear();
      return;
    }
    _recomputeDebounce?.cancel();
    _recomputeDebounce = Timer(const Duration(milliseconds: 450), () {
      _computeFromSharedInputs();
    });
  }

  Future<void> _computeFromSharedInputs() {
    if (!widget.birthInputState.hasComputedChart || !_isInputValid()) {
      _controller.clear();
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

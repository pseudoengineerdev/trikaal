import 'package:flutter/material.dart';

import '../../../app/models/custom_place_payload.dart';
import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../data/models/place_search_models.dart';
import '../../shared/widgets/terminology_toggle.dart';
import 'state/birth_chart_controller.dart';
import 'widgets/chart_result_card.dart';
import 'widgets/chart_state_widgets.dart';

class BirthInputPage extends StatefulWidget {
  const BirthInputPage({
    required this.birthInputState,
    required this.terminologyModeState,
    required this.astrologyTermsState,
    super.key,
  });

  final BirthInputState birthInputState;
  final TerminologyModeState terminologyModeState;
  final AstrologyTermsState astrologyTermsState;

  @override
  State<BirthInputPage> createState() => _BirthInputPageState();
}

class _BirthInputPageState extends State<BirthInputPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _placeController;
  final _controller = BirthChartController();

  @override
  void initState() {
    super.initState();
    _dateController =
        TextEditingController(text: widget.birthInputState.dateOfBirth);
    _timeController =
        TextEditingController(text: widget.birthInputState.timeOfBirth);
    _placeController =
        TextEditingController(text: widget.birthInputState.placeOfBirth);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    await _controller.submit(
      dateOfBirth: _dateController.text.trim(),
      timeOfBirth: _timeController.text.trim(),
      placeOfBirth: _placeController.text.trim(),
      customPlace: widget.birthInputState.customPlace,
    );
    if (_controller.result != null && _controller.error == null) {
      final resolvedPlace = _controller.result!.resolvedPlace;
      widget.birthInputState
          .setResolvedPlace(resolvedPlace.toCustomPlacePayload());
      _placeController.text = resolvedPlace.placeLabel;
      _placeController.selection = TextSelection.collapsed(
        offset: _placeController.text.length,
      );
      widget.birthInputState
          .markChartComputed(dashaSummary: _controller.dashaResult);
    } else {
      widget.birthInputState.clearComputedChart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trikaal Birth Chart')),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _controller,
          widget.terminologyModeState,
          widget.astrologyTermsState,
        ]),
        builder: (BuildContext context, Widget? _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TerminologyToggle(
                    mode: widget.terminologyModeState.mode,
                    onChanged: widget.terminologyModeState.setMode,
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          enabled: !_controller.loading,
                          onTap: _pickDate,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: _validateDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          enabled: !_controller.loading,
                          onTap: _pickTime,
                          decoration: const InputDecoration(
                            labelText: 'Time of Birth',
                            hintText: 'HH:MM',
                            suffixIcon: Icon(Icons.schedule),
                          ),
                          validator: _validateTime,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _placeController,
                          enabled: !_controller.loading,
                          decoration: const InputDecoration(
                            labelText: 'Place of Birth',
                            hintText: 'Mumbai',
                          ),
                          onChanged: (String value) {
                            widget.birthInputState
                                .updatePlaceOfBirth(value.trim());
                            _controller.onPlaceQueryChanged(value);
                          },
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Place is required';
                            }
                            return null;
                          },
                        ),
                        if (_controller.loadingPlaceSuggestions) ...<Widget>[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        if (_controller
                            .placeSuggestions.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          PlaceSuggestionList(
                            suggestions: _controller.placeSuggestions,
                            onTap: _onPlaceSelected,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _controller.loading ? null : _submit,
                            child: _controller.loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Compute Chart'),
                          ),
                        ),
                        if (_controller.loading) ...<Widget>[
                          const SizedBox(height: 10),
                          const LoadingHint(),
                        ],
                      ],
                    ),
                  ),
                  if (_controller.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    ErrorCard(
                      message: _controller.error!,
                      onRetry: _controller.loading ? null : _submit,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_controller.result == null &&
                      !_controller.loading) ...<Widget>[
                    const EmptyResultHint(),
                  ] else if (_controller.result != null) ...<Widget>[
                    ChartResultCard(
                      result: _controller.result!,
                      mode: widget.terminologyModeState.mode,
                      termsState: widget.astrologyTermsState,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onPlaceSelected(PlaceMatch place) {
    _placeController.text = place.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    if (place.isCustom) {
      widget.birthInputState.updatePlaceOfBirth(_placeController.text);
    } else {
      widget.birthInputState.setResolvedPlace(
        CustomPlacePayload(
          placeLabel: place.placeLabel,
          latitude: place.latitude,
          longitude: place.longitude,
          timezone: place.timezone,
          elevationM: place.elevationM,
        ),
      );
    }
    _controller.clearPlaceSuggestions();
  }

  String? _validateDate(String? value) {
    final input = value?.trim() ?? '';
    final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input);
    if (!ok) {
      return 'Use format YYYY-MM-DD';
    }
    return null;
  }

  String? _validateTime(String? value) {
    final input = value?.trim() ?? '';
    final ok = RegExp(r'^\d{2}:\d{2}$').hasMatch(input);
    if (!ok) {
      return 'Use format HH:MM';
    }
    return null;
  }

  Future<void> _pickDate() async {
    if (_controller.loading) {
      return;
    }
    final initialDate =
        _parseDate(_dateController.text.trim()) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected == null) {
      return;
    }
    _dateController.text = _formatDate(selected);
    widget.birthInputState.updateDateOfBirth(_dateController.text);
  }

  Future<void> _pickTime() async {
    if (_controller.loading) {
      return;
    }
    final initialTime = _parseTimeOfDay(_timeController.text.trim()) ??
        TimeOfDay.fromDateTime(DateTime.now());
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null) {
      return;
    }
    _timeController.text = _formatTimeOfDay(selected);
    widget.birthInputState.updateTimeOfBirth(_timeController.text);
  }

  DateTime? _parseDate(String input) {
    final parts = input.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime.tryParse('$year-${_two(month)}-${_two(day)}');
  }

  TimeOfDay? _parseTimeOfDay(String input) {
    final parts = input.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${_two(time.hour)}:${_two(time.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

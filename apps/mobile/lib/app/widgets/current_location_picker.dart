import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/charts/data/chart_api_client.dart';
import '../../features/charts/data/models/place_search_models.dart';
import '../../features/charts/presentation/widgets/chart_state_widgets.dart';
import '../models/custom_place_payload.dart';
import '../state/birth_input_state.dart';

Future<void> showCurrentLocationPickerSheet({
  required BuildContext context,
  required BirthInputState birthInputState,
}) async {
  final result = await showModalBottomSheet<_CurrentLocationSelectionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return _CurrentLocationPickerSheet(
        birthInputState: birthInputState,
      );
    },
  );

  if (!context.mounted || result == null) {
    return;
  }

  if (result.useBirthLocation) {
    birthInputState.clearCurrentObservationLocation();
    return;
  }

  if (result.placeLabel.isEmpty) {
    return;
  }

  birthInputState.setCurrentObservationLocation(
    placeLabel: result.placeLabel,
    customPlace: result.customPlace,
  );
}

class _CurrentLocationSelectionResult {
  const _CurrentLocationSelectionResult.useBirth()
      : useBirthLocation = true,
        placeLabel = '',
        customPlace = null;

  const _CurrentLocationSelectionResult.custom({
    required this.placeLabel,
    required this.customPlace,
  }) : useBirthLocation = false;

  final bool useBirthLocation;
  final String placeLabel;
  final CustomPlacePayload? customPlace;
}

class _CurrentLocationPickerSheet extends StatefulWidget {
  const _CurrentLocationPickerSheet({
    required this.birthInputState,
  });

  final BirthInputState birthInputState;

  @override
  State<_CurrentLocationPickerSheet> createState() =>
      _CurrentLocationPickerSheetState();
}

class _CurrentLocationPickerSheetState
    extends State<_CurrentLocationPickerSheet> {
  late final TextEditingController _controller;
  final _apiClient = ChartApiClient();
  final List<PlaceMatch> _suggestions = <PlaceMatch>[];
  bool _isSearching = false;
  String _lastSignature = '';
  CustomPlacePayload? _selectedCustomPlace;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialLabel = widget.birthInputState.hasCurrentObservationLocation
        ? widget.birthInputState.currentObservationPlaceLabel ??
            widget.birthInputState.placeOfBirth
        : widget.birthInputState.placeOfBirth;
    _controller = TextEditingController(text: initialLabel);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _apiClient.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _selectedCustomPlace = null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    if (trimmed.length < 2) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    _debounce?.cancel();
    final signature = trimmed.toLowerCase();
    if (_lastSignature == signature) {
      return;
    }
    _lastSignature = signature;

    _debounce = Timer(const Duration(milliseconds: 220), () {
      _search(signature);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
    });
    try {
      final response = await _apiClient.searchPlaces(query);
      if (!mounted || _lastSignature != query) {
        return;
      }
      setState(() {
        _suggestions
          ..clear()
          ..addAll(response.matches);
      });
    } catch (_) {
      if (!mounted || _lastSignature != query) {
        return;
      }
      setState(() {
        _suggestions.clear();
      });
    } finally {
      final shouldUpdate = mounted &&
          _lastSignature == query &&
          _controller.text.trim().isNotEmpty;
      if (shouldUpdate) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSuggestionSelected(PlaceMatch place) {
    _controller.text = place.placeLabel;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _selectedCustomPlace = _toPayloadIfResolved(place);
    setState(() {
      _suggestions.clear();
    });
  }

  CustomPlacePayload? _toPayloadIfResolved(PlaceMatch place) {
    if (place.isCustom) {
      return null;
    }
    return CustomPlacePayload(
      placeLabel: place.placeLabel,
      latitude: place.latitude,
      longitude: place.longitude,
      timezone: place.timezone,
      elevationM: place.elevationM,
    );
  }

  void _applyCurrent() {
    final placeLabel = _controller.text.trim();
    if (placeLabel.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final payload = _selectedCustomPlace;

    final result = _CurrentLocationSelectionResult.custom(
      placeLabel: placeLabel,
      customPlace: payload,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final birthLabel = widget.birthInputState.placeOfBirth.trim();
    final hasCurrent = widget.birthInputState.hasCurrentObservationLocation;
    final birthLabelProvided = birthLabel.isNotEmpty;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetMaxHeight = MediaQuery.of(context).size.height -
        keyboardInset -
        MediaQuery.of(context).padding.top -
        24;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: sheetMaxHeight > 0 ? sheetMaxHeight : 420,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  hasCurrent
                      ? 'Set a city used across features for live calculations.'
                      : 'Set a city for live features like calendar and timing. Birth location remains default.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Search City',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _controller.clear();
                              _onQueryChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: 8),
                if (_isSearching)
                  const LinearProgressIndicator(minHeight: 2)
                else if (_suggestions.isNotEmpty)
                  PlaceSuggestionList(
                    suggestions: _suggestions,
                    onTap: _onSuggestionSelected,
                  ),
                const SizedBox(height: 10),
                if (hasCurrent)
                  Text(
                    'Current: ${widget.birthInputState.currentObservationPlaceLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (birthLabelProvided)
                  Text(
                    'Default: $birthLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            const _CurrentLocationSelectionResult.useBirth(),
                          );
                        },
                        child: const Text('Use birth location'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyCurrent,
                        child: const Text('Apply location'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

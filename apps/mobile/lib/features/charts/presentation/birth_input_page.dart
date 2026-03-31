import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chart_api_client.dart';
import '../data/models/compute_chart_models.dart';
import '../data/models/place_search_models.dart';

class BirthInputPage extends StatefulWidget {
  const BirthInputPage({super.key});

  @override
  State<BirthInputPage> createState() => _BirthInputPageState();
}

class _BirthInputPageState extends State<BirthInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: '1999-07-04');
  final _timeController = TextEditingController(text: '12:22');
  final _placeController = TextEditingController(text: 'Mumbai');
  final _apiClient = ChartApiClient();

  bool _loading = false;
  bool _loadingPlaceSuggestions = false;
  String? _error;
  ComputeChartResponse? _result;
  List<PlaceMatch> _placeSuggestions = <PlaceMatch>[];
  Timer? _placeSearchDebounce;
  int _placeSearchRequestId = 0;

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.computeChart(
        ComputeChartRequest(
          dateOfBirth: _dateController.text.trim(),
          timeOfBirth: _timeController.text.trim(),
          placeOfBirth: _placeController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = response;
        _placeSuggestions = <PlaceMatch>[];
      });
    } on ChartApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trikaal Birth Chart')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      enabled: !_loading,
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
                      enabled: !_loading,
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
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Place of Birth',
                        hintText: 'Mumbai',
                      ),
                      onChanged: _onPlaceChanged,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Place is required';
                        }
                        return null;
                      },
                    ),
                    if (_loadingPlaceSuggestions) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_placeSuggestions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      _PlaceSuggestionList(
                        suggestions: _placeSuggestions,
                        onTap: _onPlaceSelected,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Compute Chart'),
                      ),
                    ),
                    if (_loading) ...<Widget>[
                      const SizedBox(height: 10),
                      const _LoadingHint(),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                _ErrorCard(
                  message: _error!,
                  onRetry: _loading ? null : _submit,
                ),
              ],
              const SizedBox(height: 20),
              if (_result == null && !_loading) ...<Widget>[
                const _EmptyResultHint(),
              ] else if (_result != null) ...<Widget>[
                _ResultCard(result: _result!),
              ],
            ],
          ),
        ),
      ),
    );
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

  void _onPlaceChanged(String value) {
    _placeSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _placeSuggestions = <PlaceMatch>[];
        _loadingPlaceSuggestions = false;
      });
      return;
    }

    _placeSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    final requestId = ++_placeSearchRequestId;
    setState(() {
      _loadingPlaceSuggestions = true;
    });

    try {
      final response = await _apiClient.searchPlaces(query);
      if (!mounted || requestId != _placeSearchRequestId) {
        return;
      }
      setState(() {
        _placeSuggestions = response.matches;
      });
    } catch (_) {
      if (!mounted || requestId != _placeSearchRequestId) {
        return;
      }
      setState(() {
        _placeSuggestions = <PlaceMatch>[];
      });
    } finally {
      if (mounted && requestId == _placeSearchRequestId) {
        setState(() {
          _loadingPlaceSuggestions = false;
        });
      }
    }
  }

  void _onPlaceSelected(PlaceMatch place) {
    _placeController.text = place.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    setState(() {
      _placeSuggestions = <PlaceMatch>[];
    });
  }

  Future<void> _pickDate() async {
    if (_loading) {
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
  }

  Future<void> _pickTime() async {
    if (_loading) {
      return;
    }
    final initialTime = _parseTimeOfDay(_timeController.text.trim()) ??
        TimeOfDay.fromDateTime(DateTime.now());
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null) {
      return;
    }
    _timeController.text = _formatTimeOfDay(selected);
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ComputeChartResponse result;

  @override
  Widget build(BuildContext context) {
    final vedic = _asMap(result.snapshot['vedic']);
    final meta = _asMap(result.snapshot['meta']);
    final bhava = _asMap(result.snapshot['bhava']);

    return Column(
      children: <Widget>[
        _SectionCard(
          title: 'Chart Summary',
          children: <Widget>[
            _KeyValueRow(
              label: 'Resolved Place',
              value: result.resolvedPlace.placeLabel,
            ),
            _KeyValueRow(
                label: 'Timezone', value: result.resolvedPlace.timezone),
            _KeyValueRow(label: 'Status', value: '${meta['status'] ?? '-'}'),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Lagna Overview',
          children: <Widget>[
            _KeyValueRow(
                label: 'Lagna Rashi', value: '${vedic['lagna_rashi'] ?? '-'}'),
            _KeyValueRow(
              label: 'Lagna Nakshatra',
              value:
                  '${vedic['lagna_nakshatra'] ?? '-'} (${vedic['lagna_pada'] ?? '-'})',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Graha Highlights',
          children: <Widget>[
            _KeyValueRow(
              label: 'Surya',
              value:
                  '${vedic['sun_rashi'] ?? '-'} • ${vedic['sun_nakshatra'] ?? '-'} (${vedic['sun_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Chandra',
              value:
                  '${vedic['moon_rashi'] ?? '-'} • ${vedic['moon_nakshatra'] ?? '-'} (${vedic['moon_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Mangal',
              value:
                  '${vedic['mangal_rashi'] ?? '-'} • ${vedic['mangal_nakshatra'] ?? '-'} (${vedic['mangal_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Budha',
              value:
                  '${vedic['budha_rashi'] ?? '-'} • ${vedic['budha_nakshatra'] ?? '-'} (${vedic['budha_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Guru',
              value:
                  '${vedic['guru_rashi'] ?? '-'} • ${vedic['guru_nakshatra'] ?? '-'} (${vedic['guru_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Shukra',
              value:
                  '${vedic['shukra_rashi'] ?? '-'} • ${vedic['shukra_nakshatra'] ?? '-'} (${vedic['shukra_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Shani',
              value:
                  '${vedic['shani_rashi'] ?? '-'} • ${vedic['shani_nakshatra'] ?? '-'} (${vedic['shani_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Rahu',
              value:
                  '${vedic['rahu_rashi'] ?? '-'} • ${vedic['rahu_nakshatra'] ?? '-'} (${vedic['rahu_pada'] ?? '-'})',
            ),
            _KeyValueRow(
              label: 'Ketu',
              value:
                  '${vedic['ketu_rashi'] ?? '-'} • ${vedic['ketu_nakshatra'] ?? '-'} (${vedic['ketu_pada'] ?? '-'})',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Bhava (House Placements)',
          children: <Widget>[
            _KeyValueRow(
                label: 'Surya House', value: '${bhava['sun_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Chandra House', value: '${bhava['moon_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Mangal House',
                value: '${bhava['mangal_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Budha House', value: '${bhava['budha_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Guru House', value: '${bhava['guru_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Shukra House',
                value: '${bhava['shukra_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Shani House', value: '${bhava['shani_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Rahu House', value: '${bhava['rahu_house'] ?? '-'}'),
            _KeyValueRow(
                label: 'Ketu House', value: '${bhava['ketu_house'] ?? '-'}'),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PlaceSuggestionList extends StatelessWidget {
  const _PlaceSuggestionList({
    required this.suggestions,
    required this.onTap,
  });

  final List<PlaceMatch> suggestions;
  final ValueChanged<PlaceMatch> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: suggestions
            .take(5)
            .map(
              (place) => ListTile(
                dense: true,
                title: Text(place.placeLabel),
                subtitle: Text(place.timezone),
                onTap: () => onTap(place),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('Computing chart using Drik profile...'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultHint extends StatelessWidget {
  const _EmptyResultHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'No chart computed yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Select date, time, and place, then tap "Compute Chart".',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

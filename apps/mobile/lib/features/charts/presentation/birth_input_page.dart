import 'package:flutter/material.dart';

import '../data/chart_api_client.dart';
import '../data/models/compute_chart_models.dart';

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
  String? _error;
  ComputeChartResponse? _result;

  @override
  void dispose() {
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
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: _validateDate,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time of Birth',
                        hintText: 'HH:MM',
                      ),
                      validator: _validateTime,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: 'Place of Birth',
                        hintText: 'Mumbai',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Place is required';
                        }
                        return null;
                      },
                    ),
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
                  ],
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_result != null) ...<Widget>[
                const SizedBox(height: 20),
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
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ComputeChartResponse result;

  @override
  Widget build(BuildContext context) {
    final vedic = _asMap(result.snapshot['vedic']);
    final meta = _asMap(result.snapshot['meta']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resolved Place: ${result.resolvedPlace.placeLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Timezone: ${result.resolvedPlace.timezone}'),
            Text('Status: ${meta['status'] ?? '-'}'),
            const Divider(height: 24),
            Text('Lagna: ${vedic['lagna_rashi'] ?? '-'}'),
            Text('Surya Rashi: ${vedic['sun_rashi'] ?? '-'}'),
            Text('Chandra Rashi: ${vedic['moon_rashi'] ?? '-'}'),
            Text('Lagna Nakshatra: ${vedic['lagna_nakshatra'] ?? '-'}'),
            Text('Surya Nakshatra: ${vedic['sun_nakshatra'] ?? '-'}'),
            Text('Chandra Nakshatra: ${vedic['moon_nakshatra'] ?? '-'}'),
          ],
        ),
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

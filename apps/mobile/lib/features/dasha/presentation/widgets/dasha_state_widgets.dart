import 'package:flutter/material.dart';

import '../../../../app/state/astrology_terms_state.dart';
import '../../../../app/state/terminology_mode_state.dart';
import '../../data/models/dasha_models.dart';
import '../../../shared/astrology/term_localizer.dart';

class DashaEmptyState extends StatelessWidget {
  const DashaEmptyState({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    super.key,
  });

  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;

  @override
  Widget build(BuildContext context) {
    final hasAnyInput = dateOfBirth.trim().isNotEmpty ||
        timeOfBirth.trim().isNotEmpty ||
        placeOfBirth.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Compute chart first. Dasha auto-computes from the same birth input.',
            ),
            if (hasAnyInput) ...<Widget>[
              const SizedBox(height: 8),
              Text('Using: $dateOfBirth, $timeOfBirth, $placeOfBirth'),
            ],
          ],
        ),
      ),
    );
  }
}

class DashaLoadingState extends StatelessWidget {
  const DashaLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class DashaErrorState extends StatelessWidget {
  const DashaErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashaSummaryCard extends StatelessWidget {
  const DashaSummaryCard({
    required this.summary,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.mode,
    required this.termsState,
    super.key,
  });

  final DashaSummary summary;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final TerminologyMode mode;
  final AstrologyTermsState termsState;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Current Dasha (${summary.system})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _row('Birth Input', '$dateOfBirth, $timeOfBirth'),
            _row('Place', placeOfBirth),
            _row(
              'Maha Dasha',
              localizeGraha(
                summary.currentMahaDasha,
                mode,
                termsState: termsState,
              ),
            ),
            _row(
              'Antar Dasha',
              localizeGraha(
                summary.currentAntarDasha,
                mode,
                termsState: termsState,
              ),
            ),
            _row('Active From', summary.activeFrom),
            _row('Active Until', summary.activeUntil),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

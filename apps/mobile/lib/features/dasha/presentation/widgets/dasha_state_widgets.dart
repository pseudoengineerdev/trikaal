import 'package:flutter/material.dart';

import '../../data/models/dasha_models.dart';

class DashaEmptyState extends StatelessWidget {
  const DashaEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tap "Load Preview" to fetch Dasha placeholder data.'),
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
  const DashaSummaryCard({required this.summary, super.key});

  final DashaSummary summary;

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
              'Dasha Preview (${summary.system})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _row('Maha Dasha', summary.currentMahaDasha),
            _row('Antar Dasha', summary.currentAntarDasha),
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

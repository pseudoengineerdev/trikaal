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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Compute chart first. Dasha auto-computes from the same birth input.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (hasAnyInput) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Using: $dateOfBirth, $timeOfBirth, $placeOfBirth',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashaLoadingState extends StatelessWidget {
  const DashaLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(
            'Calculating dasha periods...',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 94),
      child: Card(
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
              _row('Active From', _formatIso(summary.activeFrom)),
              _row('Active Until', _formatIso(summary.activeUntil)),
              const SizedBox(height: 16),
              Text(
                'Mahadasha Timeline',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...summary.mahaTimeline
                  .map((DashaPeriod period) => _periodTile(context, period)),
              const SizedBox(height: 16),
              Text(
                'Antardasha Timeline (Current Maha)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...summary.antarTimelineCurrentMaha
                  .map((DashaPeriod period) => _periodTile(context, period)),
            ],
          ),
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

  Widget _periodTile(BuildContext context, DashaPeriod period) {
    final title = localizeGraha(period.lord, mode, termsState: termsState);
    final subtitle = '${_formatIso(period.start)} → ${_formatIso(period.end)}';
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: period.active
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surface.withValues(alpha: 0.15),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (period.active)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle, size: 16),
            ),
        ],
      ),
    );
  }

  String _formatIso(String raw) {
    if (raw.trim().isEmpty) {
      return '-';
    }
    return raw.replaceFirst('T', ' ').split('.').first;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'state/birth_input_state.dart';
import 'widgets/astro_page_background.dart';
import '../features/charts/data/chart_api_client.dart';
import '../features/charts/data/models/compute_chart_models.dart';
import '../features/features/domain/report_refresh_policy.dart';
import '../features/home/presentation/home_overview_page.dart';
import '../features/onboarding/presentation/onboarding_flow_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, this.chartApiClient, this.now});

  /// Injectable for tests; production uses the default [ChartApiClient].
  final ChartApiClient? chartApiClient;

  /// Injectable clock for the staleness check; defaults to the wall clock.
  final DateTime? now;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final BirthInputState _birthInputState = BirthInputState();
  late final ChartApiClient _chartApiClient;
  late final bool _ownsChartApiClient;
  bool _sessionReady = false;
  bool _refreshAttempted = false;

  @override
  void initState() {
    super.initState();
    _ownsChartApiClient = widget.chartApiClient == null;
    _chartApiClient = widget.chartApiClient ?? ChartApiClient();
    _bootstrap();
  }

  @override
  void dispose() {
    _birthInputState.dispose();
    if (_ownsChartApiClient) {
      _chartApiClient.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Restore the cached session before saved profiles so a restored
    // (non-empty) input is not overwritten by the default saved profile.
    // Both reads are local-only and never touch the network.
    await _birthInputState.restoreSession();
    await _birthInputState.loadSavedProfiles();
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionReady = true;
    });
    // A stale report is refreshed in the background and never gates startup.
    unawaited(_maybeRefreshStaleReport());
  }

  Future<void> _maybeRefreshStaleReport() async {
    if (_refreshAttempted) {
      return;
    }
    _refreshAttempted = true;

    final report = _birthInputState.computedReport;
    if (report == null || !_birthInputState.onboardingCompleted) {
      return;
    }
    if (_birthInputState.dateOfBirth.trim().isEmpty ||
        _birthInputState.timeOfBirth.trim().isEmpty ||
        _birthInputState.placeOfBirth.trim().isEmpty) {
      return;
    }
    if (!shouldAutoRefreshReportForDay(
      report.dasha.asOfIso,
      now: widget.now ?? DateTime.now(),
    )) {
      return;
    }

    try {
      final refreshed = await _chartApiClient.computeReport(
        ComputeChartRequest(
          dateOfBirth: _birthInputState.dateOfBirth,
          timeOfBirth: _birthInputState.timeOfBirth,
          placeOfBirth: _birthInputState.placeOfBirth,
          customPlace: _birthInputState.customPlace,
        ),
      );
      if (!mounted) {
        return;
      }
      _birthInputState.markReportComputed(refreshed);
    } catch (_) {
      // API unreachable: keep the cached report as-is.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const Scaffold(
        body: AstroPageBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _birthInputState,
      builder: (BuildContext context, Widget? child) {
        if (!_birthInputState.onboardingCompleted ||
            !_birthInputState.hasComputedChart ||
            _birthInputState.computedReport == null) {
          return OnboardingFlowPage(
            birthInputState: _birthInputState,
            onCompleted: () {
              setState(() {});
            },
          );
        }

        return HomeOverviewPage(
          birthInputState: _birthInputState,
        );
      },
    );
  }
}

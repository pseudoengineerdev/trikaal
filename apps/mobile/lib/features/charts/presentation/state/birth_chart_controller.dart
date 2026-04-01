import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../app/models/custom_place_payload.dart';
import '../../../dasha/data/models/dasha_models.dart';
import '../../data/chart_api_client.dart';
import '../../data/models/compute_chart_models.dart';
import '../../data/models/compute_report_models.dart';
import '../../data/models/place_search_models.dart';

class BirthChartController extends ChangeNotifier {
  BirthChartController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;

  bool loading = false;
  bool loadingPlaceSuggestions = false;
  String? error;
  ComputeReportResponse? result;
  DashaSummary? dashaResult;
  List<PlaceMatch> placeSuggestions = <PlaceMatch>[];

  Timer? _placeSearchDebounce;
  int _placeSearchRequestId = 0;

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> submit({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    CustomPlacePayload? customPlace,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      dashaResult = null;
      final response = await _apiClient.computeReport(
        ComputeChartRequest(
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          placeOfBirth: placeOfBirth,
          customPlace: customPlace,
        ),
      );
      result = response;
      dashaResult = response.dasha;
      placeSuggestions = <PlaceMatch>[];
    } on ChartApiException catch (exception) {
      dashaResult = null;
      error = exception.message;
    } catch (_) {
      dashaResult = null;
      error = 'Something went wrong. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void applyComputedResult({
    required ComputeReportResponse report,
    DashaSummary? dasha,
  }) {
    result = report;
    dashaResult = dasha;
    error = null;
    loading = false;
    notifyListeners();
  }

  void clearComputedResult() {
    result = null;
    dashaResult = null;
    notifyListeners();
  }

  void onPlaceQueryChanged(String value) {
    _placeSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      placeSuggestions = <PlaceMatch>[];
      loadingPlaceSuggestions = false;
      notifyListeners();
      return;
    }

    _placeSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    final requestId = ++_placeSearchRequestId;
    loadingPlaceSuggestions = true;
    notifyListeners();

    try {
      final response = await _apiClient.searchPlaces(query);
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = _withCustomSuggestion(
        query: query,
        matches: response.matches,
      );
    } catch (_) {
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = _withCustomSuggestion(
        query: query,
        matches: const <PlaceMatch>[],
      );
    } finally {
      if (requestId == _placeSearchRequestId) {
        loadingPlaceSuggestions = false;
        notifyListeners();
      }
    }
  }

  void clearPlaceSuggestions() {
    placeSuggestions = <PlaceMatch>[];
    notifyListeners();
  }

  List<PlaceMatch> _withCustomSuggestion({
    required String query,
    required List<PlaceMatch> matches,
  }) {
    final normalizedQuery = _normalize(query);
    final hasExact = matches.any((PlaceMatch match) {
      return _normalize(match.placeLabel) == normalizedQuery;
    });
    if (hasExact) {
      return matches;
    }
    return <PlaceMatch>[
      ...matches,
      PlaceMatch.custom(query),
    ];
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }
}

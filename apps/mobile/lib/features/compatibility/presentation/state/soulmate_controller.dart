import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../charts/data/chart_api_client.dart';
import '../../../charts/data/models/compute_compatibility_models.dart';
import '../../../charts/data/models/place_search_models.dart';

class SoulmateController extends ChangeNotifier {
  SoulmateController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;

  bool loading = false;
  bool loadingPartnerPlaceSuggestions = false;
  String? error;
  ComputeCompatibilityResponse? result;
  List<PlaceMatch> partnerPlaceSuggestions = <PlaceMatch>[];

  Timer? _partnerPlaceSearchDebounce;
  int _partnerPlaceSearchRequestId = 0;

  @override
  void dispose() {
    _partnerPlaceSearchDebounce?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> compute({
    required CompatibilityPersonRequestPayload primary,
    required CompatibilityPersonRequestPayload partner,
    required String primaryRole,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiClient.computeCompatibility(
        ComputeCompatibilityRequest(
          primary: primary,
          partner: partner,
          primaryRole: primaryRole,
        ),
      );
      result = response;
      partnerPlaceSuggestions = <PlaceMatch>[];
    } on ChartApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not compute compatibility right now. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clearComputedResult() {
    result = null;
    error = null;
    loading = false;
    notifyListeners();
  }

  void onPartnerPlaceQueryChanged(String value) {
    _partnerPlaceSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      partnerPlaceSuggestions = <PlaceMatch>[];
      loadingPartnerPlaceSuggestions = false;
      notifyListeners();
      return;
    }

    _partnerPlaceSearchDebounce = Timer(const Duration(milliseconds: 220), () {
      _fetchPartnerPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPartnerPlaceSuggestions(String query) async {
    final requestId = ++_partnerPlaceSearchRequestId;
    partnerPlaceSuggestions = <PlaceMatch>[PlaceMatch.custom(query)];
    loadingPartnerPlaceSuggestions = true;
    notifyListeners();

    try {
      final response = await _apiClient
          .searchPlaces(query)
          .timeout(const Duration(seconds: 4));
      if (requestId != _partnerPlaceSearchRequestId) {
        return;
      }
      partnerPlaceSuggestions = _withCustomSuggestion(
        query: query,
        matches: response.matches,
      );
    } catch (_) {
      if (requestId != _partnerPlaceSearchRequestId) {
        return;
      }
      partnerPlaceSuggestions = _withCustomSuggestion(
        query: query,
        matches: const <PlaceMatch>[],
      );
    } finally {
      if (requestId == _partnerPlaceSearchRequestId) {
        loadingPartnerPlaceSuggestions = false;
        notifyListeners();
      }
    }
  }

  void clearPartnerPlaceSuggestions() {
    partnerPlaceSuggestions = <PlaceMatch>[];
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

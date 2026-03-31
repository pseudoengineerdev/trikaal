import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/chart_api_client.dart';
import '../../data/models/compute_chart_models.dart';
import '../../data/models/place_search_models.dart';

class BirthChartController extends ChangeNotifier {
  BirthChartController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;

  bool loading = false;
  bool loadingPlaceSuggestions = false;
  String? error;
  ComputeChartResponse? result;
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
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiClient.computeChart(
        ComputeChartRequest(
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          placeOfBirth: placeOfBirth,
        ),
      );
      result = response;
      placeSuggestions = <PlaceMatch>[];
    } on ChartApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
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
      placeSuggestions = response.matches;
    } catch (_) {
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = <PlaceMatch>[];
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
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../app/models/custom_place_payload.dart';
import '../../../charts/data/chart_api_client.dart';
import '../../../charts/data/models/place_search_models.dart';
import '../../data/models/pancha_pakshi_models.dart';

class PanchaPakshiController extends ChangeNotifier {
  PanchaPakshiController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient(),
        _ownsApiClient = apiClient == null;

  final ChartApiClient _apiClient;
  final bool _ownsApiClient;
  Timer? _ticker;
  Timer? _placeSearchDebounce;

  bool loading = false;
  bool refreshing = false;
  String? error;
  PanchaPakshiResponse? result;
  int secondsRemaining = 0;
  bool loadingPlaceSuggestions = false;
  List<PlaceMatch> placeSuggestions = <PlaceMatch>[];

  String? _lastDateOfBirth;
  String? _lastTimeOfBirth;
  String? _lastPlaceOfBirth;
  CustomPlacePayload? _lastCustomPlace;
  String? _lastRuntimePlaceOfObservation;
  CustomPlacePayload? _lastRuntimeCustomPlace;
  bool _isRefreshingBoundary = false;
  int _placeSearchRequestId = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    _placeSearchDebounce?.cancel();
    if (_ownsApiClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  void onRuntimePlaceQueryChanged(String value) {
    _placeSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _placeSearchRequestId += 1;
      placeSuggestions = <PlaceMatch>[];
      loadingPlaceSuggestions = false;
      notifyListeners();
      return;
    }

    _placeSearchDebounce = Timer(const Duration(milliseconds: 220), () {
      _fetchRuntimePlaceSuggestions(query);
    });
  }

  Future<void> _fetchRuntimePlaceSuggestions(String query) async {
    final requestId = ++_placeSearchRequestId;
    loadingPlaceSuggestions = true;
    notifyListeners();
    try {
      final response = await _apiClient
          .searchPlaces(query)
          .timeout(const Duration(seconds: 4));
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
    _placeSearchRequestId += 1;
    placeSuggestions = <PlaceMatch>[];
    loadingPlaceSuggestions = false;
    notifyListeners();
  }

  Future<void> load({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    CustomPlacePayload? customPlace,
    String? runtimePlaceOfObservation,
    CustomPlacePayload? runtimeCustomPlace,
  }) async {
    _lastDateOfBirth = dateOfBirth;
    _lastTimeOfBirth = timeOfBirth;
    _lastPlaceOfBirth = placeOfBirth;
    _lastCustomPlace = customPlace;
    _lastRuntimePlaceOfObservation = runtimePlaceOfObservation;
    _lastRuntimeCustomPlace = runtimeCustomPlace;

    loading = true;
    error = null;
    notifyListeners();
    await _fetch(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      placeOfBirth: placeOfBirth,
      customPlace: customPlace,
      runtimePlaceOfObservation: runtimePlaceOfObservation,
      runtimeCustomPlace: runtimeCustomPlace,
      asRefresh: false,
    );
  }

  Future<void> refresh() async {
    if (_lastDateOfBirth == null ||
        _lastTimeOfBirth == null ||
        _lastPlaceOfBirth == null) {
      return;
    }
    await _fetch(
      dateOfBirth: _lastDateOfBirth!,
      timeOfBirth: _lastTimeOfBirth!,
      placeOfBirth: _lastPlaceOfBirth!,
      customPlace: _lastCustomPlace,
      runtimePlaceOfObservation: _lastRuntimePlaceOfObservation,
      runtimeCustomPlace: _lastRuntimeCustomPlace,
      asRefresh: true,
    );
  }

  Future<void> _fetch({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    required CustomPlacePayload? customPlace,
    required String? runtimePlaceOfObservation,
    required CustomPlacePayload? runtimeCustomPlace,
    required bool asRefresh,
  }) async {
    if (asRefresh) {
      refreshing = true;
    }
    notifyListeners();

    try {
      final response = await _apiClient.computePanchaPakshi(
        PanchaPakshiRequest(
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          placeOfBirth: placeOfBirth,
          customPlace: customPlace,
          runtimePlaceOfObservation: runtimePlaceOfObservation,
          runtimeCustomPlace: runtimeCustomPlace,
        ),
      );
      result = response;
      error = null;
      secondsRemaining = response
          .panchaPakshi.runtime.secondsRemainingInActiveSubActivity
          .clamp(0, 7 * 24 * 60 * 60);
      _startTicker();
    } on ChartApiException catch (exception) {
      error = exception.message;
      if (result == null) {
        secondsRemaining = 0;
      }
    } catch (_) {
      error = 'Unable to load Pancha Pakshi right now. Please try again.';
      if (result == null) {
        secondsRemaining = 0;
      }
    } finally {
      loading = false;
      refreshing = false;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining > 0) {
        secondsRemaining -= 1;
        notifyListeners();
        return;
      }
      if (_isRefreshingBoundary || loading || refreshing) {
        return;
      }
      _isRefreshingBoundary = true;
      refresh().whenComplete(() {
        _isRefreshingBoundary = false;
      });
    });
  }
}

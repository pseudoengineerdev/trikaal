import 'package:flutter/foundation.dart';

import '../../../../app/models/custom_place_payload.dart';
import '../../../charts/data/chart_api_client.dart';
import '../../data/models/transit_models.dart';

/// Drives the Gochar (planetary transit) page.
///
/// It calls `/v1/transit/compute` with the user's natal birth details (which fix
/// the Moon and Lagna the whole reading is measured from) plus the observation
/// place and the day being viewed. A small date cursor lets the page walk
/// forward and back through the transit sky; "today" snaps the cursor home and
/// reads the live moment.
class GocharController extends ChangeNotifier {
  GocharController({
    ChartApiClient? apiClient,
    DateTime Function()? now,
  })  : _apiClient = apiClient ?? ChartApiClient(),
        _ownsApiClient = apiClient == null,
        _now = now ?? DateTime.now;

  final ChartApiClient _apiClient;
  final bool _ownsApiClient;
  final DateTime Function() _now;

  bool loading = false;
  bool refreshing = false;
  String? error;
  TransitComputeResponse? result;

  /// The day currently being viewed (YYYY-MM-DD), defaulting to today.
  late String selectedDate = _todayIso();

  // How far the cursor may roam from today, so the picker stays sensible.
  static const int _maxDaysAhead = 366;
  static const int _maxDaysBehind = 366;

  String? _dateOfBirth;
  String? _timeOfBirth;
  String? _placeOfBirth;
  CustomPlacePayload? _customPlace;
  String? _observationPlace;
  CustomPlacePayload? _observationCustomPlace;
  bool _disposed = false;

  bool get isToday => selectedDate == _todayIso();
  bool get canStepBack => _dayOffsetFromToday(selectedDate) > -_maxDaysBehind;
  bool get canStepForward => _dayOffsetFromToday(selectedDate) < _maxDaysAhead;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_ownsApiClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  Future<void> load({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    CustomPlacePayload? customPlace,
    required String observationPlace,
    CustomPlacePayload? observationCustomPlace,
    String? asOfDate,
  }) {
    _dateOfBirth = dateOfBirth;
    _timeOfBirth = timeOfBirth;
    _placeOfBirth = placeOfBirth;
    _customPlace = customPlace;
    _observationPlace = observationPlace;
    _observationCustomPlace = observationCustomPlace;
    selectedDate = asOfDate ?? _todayIso();

    loading = true;
    error = null;
    notifyListeners();
    return _fetch(asRefresh: false);
  }

  Future<void> refresh() async {
    if (_dateOfBirth == null) {
      return;
    }
    await _fetch(asRefresh: true);
  }

  Future<void> goToToday() async {
    if (_dateOfBirth == null) {
      return;
    }
    final today = _todayIso();
    if (selectedDate == today && result != null) {
      return;
    }
    selectedDate = today;
    loading = true;
    notifyListeners();
    await _fetch(asRefresh: false);
  }

  Future<void> stepDay(int delta) async {
    if (_dateOfBirth == null) {
      return;
    }
    final target = _shiftIso(selectedDate, delta);
    final offset = _dayOffsetFromToday(target);
    if (offset > _maxDaysAhead || offset < -_maxDaysBehind) {
      return;
    }
    selectedDate = target;
    loading = true;
    notifyListeners();
    await _fetch(asRefresh: false);
  }

  Future<void> _fetch({required bool asRefresh}) async {
    if (asRefresh) {
      refreshing = true;
      notifyListeners();
    }
    try {
      final response = await _apiClient.computeTransit(
        TransitComputeRequest(
          dateOfBirth: _dateOfBirth!,
          timeOfBirth: _timeOfBirth!,
          placeOfBirth: _placeOfBirth!,
          customPlace: _customPlace,
          observationPlace: _observationPlace,
          observationCustomPlace: _observationCustomPlace,
          asOfDate: selectedDate,
        ),
      );
      if (_disposed) {
        return;
      }
      result = response;
      error = null;
    } on ChartApiException catch (exception) {
      if (_disposed) {
        return;
      }
      error = exception.message;
    } catch (_) {
      if (_disposed) {
        return;
      }
      error = 'Unable to load transits right now. Please try again.';
    } finally {
      if (!_disposed) {
        loading = false;
        refreshing = false;
        notifyListeners();
      }
    }
  }

  String _todayIso() {
    final now = _now();
    return _iso(DateTime(now.year, now.month, now.day));
  }

  static String _iso(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _shiftIso(String iso, int days) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return iso;
    }
    return _iso(
      DateTime(parsed.year, parsed.month, parsed.day).add(Duration(days: days)),
    );
  }

  int _dayOffsetFromToday(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return 0;
    }
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(parsed.year, parsed.month, parsed.day)
        .difference(today)
        .inDays;
  }
}

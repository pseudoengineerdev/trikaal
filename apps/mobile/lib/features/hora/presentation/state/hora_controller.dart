import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../app/models/custom_place_payload.dart';
import '../../../charts/data/chart_api_client.dart';
import '../../../panchang/data/models/panchang_models.dart';

/// Drives the dedicated Hora page.
///
/// Hora (planetary hours) needs no endpoint of its own: the engine already
/// ships the verified 24-slot timeline inside the panchang payload
/// (`advanced.hora_timeline`). This controller reuses `computePanchang`, then
/// derives — entirely on the client — which hora is live *now* and how long it
/// has left, so the page can show a real, ticking "current hour" without any
/// server round-trip per hora.
class HoraController extends ChangeNotifier {
  HoraController({
    ChartApiClient? apiClient,
    DateTime Function()? now,
  })  : _apiClient = apiClient ?? ChartApiClient(),
        _ownsApiClient = apiClient == null,
        _now = now ?? DateTime.now;

  final ChartApiClient _apiClient;
  final bool _ownsApiClient;
  final DateTime Function() _now;

  Timer? _ticker;

  bool loading = false;
  bool refreshing = false;
  String? error;
  ComputePanchangResponse? result;

  /// Index into [horaSlots] of the currently-live hora, or -1 if none is
  /// active for the loaded day (e.g. before sunrise on a different timezone).
  int activeIndex = -1;
  int secondsRemaining = 0;

  String? _lastDate;
  String? _lastPlace;
  CustomPlacePayload? _lastCustomPlace;
  bool _triedPreviousDay = false;
  bool _isRollingDay = false;
  bool _disposed = false;

  List<PanchangHoraSlot> get horaSlots =>
      result?.panchang.advanced.horaTimeline ?? const <PanchangHoraSlot>[];

  PanchangHoraSlot? get activeHora =>
      (activeIndex >= 0 && activeIndex < horaSlots.length)
          ? horaSlots[activeIndex]
          : null;

  PanchangHoraSlot? get nextHora {
    final slots = horaSlots;
    if (activeIndex < 0) {
      return slots.isNotEmpty ? slots.first : null;
    }
    final next = activeIndex + 1;
    return next < slots.length ? slots[next] : null;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _ticker?.cancel();
    if (_ownsApiClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  Future<void> load({
    required String date,
    required String placeOfBirth,
    CustomPlacePayload? customPlace,
  }) async {
    _lastDate = date;
    _lastPlace = placeOfBirth;
    _lastCustomPlace = customPlace;
    _triedPreviousDay = false;

    loading = true;
    error = null;
    notifyListeners();
    await _fetch(date: date, asRefresh: false);
  }

  Future<void> refresh() async {
    if (_lastDate == null || _lastPlace == null) {
      return;
    }
    _triedPreviousDay = false;
    await _fetch(date: _lastDate!, asRefresh: true);
  }

  Future<void> _fetch({required String date, required bool asRefresh}) async {
    if (asRefresh) {
      refreshing = true;
      notifyListeners();
    }
    try {
      final response = await _apiClient.computePanchang(
        ComputePanchangRequest(
          date: date,
          placeOfBirth: _lastPlace!,
          customPlace: _lastCustomPlace,
        ),
      );
      if (_disposed) {
        return;
      }
      result = response;
      error = null;
      _lastDate = date;
      _recomputeActive();

      // The panchang day runs sunrise -> next sunrise, so a moment before
      // today's sunrise belongs to yesterday's hora timeline. When that
      // happens, fall back once to the previous day so "current hora" is
      // correct around the clock.
      if (activeIndex < 0 && !_triedPreviousDay && _isBeforeFirstSlot()) {
        _triedPreviousDay = true;
        await _fetch(date: _shiftDate(date, -1), asRefresh: asRefresh);
        return;
      }

      _startTicker();
    } on ChartApiException catch (exception) {
      error = exception.message;
      if (result == null) {
        activeIndex = -1;
        secondsRemaining = 0;
      }
    } catch (_) {
      error = 'Unable to load Hora right now. Please try again.';
      if (result == null) {
        activeIndex = -1;
        secondsRemaining = 0;
      }
    } finally {
      if (!_disposed) {
        loading = false;
        refreshing = false;
        notifyListeners();
      }
    }
  }

  /// Finds the slot bracketing "now" and the seconds left in it. Both sides are
  /// compared as absolute UTC instants, so detection is correct even when the
  /// host device and the observed location sit in different timezones.
  void _recomputeActive() {
    final slots = horaSlots;
    final now = _now().toUtc();
    activeIndex = -1;
    secondsRemaining = 0;
    for (var i = 0; i < slots.length; i++) {
      final start = _instant(slots[i].start.localIso);
      final end = _instant(slots[i].end.localIso);
      if (start == null || end == null) {
        continue;
      }
      if (!now.isBefore(start) && now.isBefore(end)) {
        activeIndex = i;
        secondsRemaining = end.difference(now).inSeconds.clamp(0, 24 * 60 * 60);
        return;
      }
    }
  }

  bool _isBeforeFirstSlot() {
    final slots = horaSlots;
    if (slots.isEmpty) {
      return false;
    }
    final firstStart = _instant(slots.first.start.localIso);
    if (firstStart == null) {
      return false;
    }
    return _now().toUtc().isBefore(firstStart);
  }

  void _startTicker() {
    _ticker?.cancel();
    if (horaSlots.isEmpty) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || _isRollingDay || loading) {
        return;
      }
      final previousIndex = activeIndex;
      final previousSeconds = secondsRemaining;
      _recomputeActive();

      if (activeIndex >= 0) {
        // Only repaint when something the UI shows actually changed; otherwise
        // a fixed-clock widget test would schedule frames forever.
        if (activeIndex != previousIndex ||
            secondsRemaining != previousSeconds) {
          notifyListeners();
        }
        return;
      }

      // Ran off the end of the timeline (we have crossed the next sunrise):
      // roll forward to the following day's horas.
      final date = _lastDate;
      if (date == null) {
        return;
      }
      _isRollingDay = true;
      _triedPreviousDay = true;
      _fetch(date: _shiftDate(date, 1), asRefresh: true)
          .whenComplete(() => _isRollingDay = false);
    });
  }

  /// Parses an offset-aware ISO timestamp into an absolute UTC instant.
  static DateTime? _instant(String iso) => DateTime.tryParse(iso)?.toUtc();

  static String _shiftDate(String iso, int days) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return iso;
    }
    final shifted = DateTime(parsed.year, parsed.month, parsed.day)
        .add(Duration(days: days));
    final month = shifted.month.toString().padLeft(2, '0');
    final day = shifted.day.toString().padLeft(2, '0');
    return '${shifted.year}-$month-$day';
  }
}

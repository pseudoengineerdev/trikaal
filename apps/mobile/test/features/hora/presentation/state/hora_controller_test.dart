import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/hora/presentation/state/hora_controller.dart';
import 'package:trikaal_mobile/features/panchang/data/models/panchang_models.dart';

import '../../../../helpers/sample_hora.dart';

/// 09:00 IST on the Vadodara Friday (expressed as a UTC instant) lands inside
/// the third day hora (Moon), 08:09:30 - 09:16:15 IST -> 975 seconds left.
DateTime _noonish() => DateTime.utc(2026, 6, 12, 3, 30);

/// 05:30 IST — before the 05:56 sunrise, so the live hora belongs to the
/// previous panchang day (the pre-dawn fallback).
DateTime _preDawn() => DateTime.utc(2026, 6, 12, 0, 0);

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({this.exception});

  final Exception? exception;
  final List<String> requestedDates = <String>[];

  @override
  Future<ComputePanchangResponse> computePanchang(
    ComputePanchangRequest request,
  ) async {
    requestedDates.add(request.date);
    if (exception != null) {
      throw exception!;
    }
    return ComputePanchangResponse.fromJson(
        sampleHoraResponseJson(request.date));
  }
}

void main() {
  test('load stores the 24-hour timeline and the live current hora', () async {
    final apiClient = _FakeChartApiClient();
    final controller = HoraController(apiClient: apiClient, now: _noonish);

    await controller.load(date: '2026-06-12', placeOfBirth: 'Vadodara');

    expect(controller.error, isNull);
    expect(controller.result, isNotNull);
    expect(controller.horaSlots, hasLength(24));
    expect(apiClient.requestedDates, <String>['2026-06-12']);

    expect(controller.activeIndex, 2);
    expect(controller.activeHora?.lordEnglish, 'Moon');
    expect(controller.secondsRemaining, 975);
    expect(controller.nextHora?.lordEnglish, 'Saturn');

    controller.dispose();
  });

  test('detection is timezone-correct regardless of host clock', () async {
    // Same instant as _noonish (09:00 IST) but expressed in a different frame
    // (UTC). A naive/offset-stripped comparison would have drifted by 5h30m.
    final apiClient = _FakeChartApiClient();
    final controller = HoraController(
      apiClient: apiClient,
      now: () => DateTime.utc(2026, 6, 12, 3, 30),
    );

    await controller.load(date: '2026-06-12', placeOfBirth: 'Vadodara');

    expect(controller.activeIndex, 2);
    expect(controller.activeHora?.lordEnglish, 'Moon');

    controller.dispose();
  });

  test('falls back to the previous panchang day before sunrise', () async {
    final apiClient = _FakeChartApiClient();
    final controller = HoraController(apiClient: apiClient, now: _preDawn);

    await controller.load(date: '2026-06-12', placeOfBirth: 'Vadodara');

    // Today has no live hora before sunrise, so it re-fetches yesterday once.
    expect(apiClient.requestedDates, <String>['2026-06-12', '2026-06-11']);
    expect(controller.result, isNotNull);
    // The active hora is the previous day's final (night) hora.
    expect(controller.activeIndex, 23);
    expect(controller.activeHora?.isDay, isFalse);
    expect(controller.secondsRemaining, greaterThan(0));

    controller.dispose();
  });

  test('load failure surfaces the API message and clears state', () async {
    final apiClient = _FakeChartApiClient(
      exception: const ChartApiException('Place not found'),
    );
    final controller = HoraController(apiClient: apiClient, now: _noonish);

    await controller.load(date: '2026-06-12', placeOfBirth: 'Atlantis');

    expect(controller.error, 'Place not found');
    expect(controller.result, isNull);
    expect(controller.activeIndex, -1);
    expect(controller.secondsRemaining, 0);

    controller.dispose();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/gochar/data/models/transit_models.dart';
import 'package:trikaal_mobile/features/gochar/presentation/state/gochar_controller.dart';

import '../../../../helpers/sample_transit.dart';

DateTime _fixedNow() => DateTime(2026, 6, 14, 12, 0);

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({this.exception});

  final Exception? exception;
  final List<String?> requestedDates = <String?>[];

  @override
  Future<TransitComputeResponse> computeTransit(
    TransitComputeRequest request,
  ) async {
    requestedDates.add(request.asOfDate);
    if (exception != null) {
      throw exception!;
    }
    return TransitComputeResponse.fromJson(
      sampleTransitResponseJson(request.asOfDate ?? '2026-06-14'),
    );
  }
}

GocharController _controller(_FakeChartApiClient client) =>
    GocharController(apiClient: client, now: _fixedNow);

Future<void> _load(GocharController controller) {
  return controller.load(
    dateOfBirth: '1995-03-21',
    timeOfBirth: '22:10',
    placeOfBirth: 'Mumbai',
    observationPlace: 'Mumbai',
  );
}

void main() {
  test('load fetches today and stores the transit reading', () async {
    final client = _FakeChartApiClient();
    final controller = _controller(client);

    await _load(controller);

    expect(controller.error, isNull);
    expect(controller.result, isNotNull);
    expect(controller.result!.planets, hasLength(9));
    expect(controller.selectedDate, '2026-06-14');
    expect(controller.isToday, isTrue);
    expect(client.requestedDates, <String>['2026-06-14']);

    controller.dispose();
  });

  test('stepDay moves the cursor and refetches that day', () async {
    final client = _FakeChartApiClient();
    final controller = _controller(client);
    await _load(controller);

    await controller.stepDay(1);
    expect(controller.selectedDate, '2026-06-15');
    expect(controller.isToday, isFalse);

    await controller.stepDay(-1);
    expect(controller.selectedDate, '2026-06-14');
    expect(client.requestedDates, <String>['2026-06-14', '2026-06-15', '2026-06-14']);

    controller.dispose();
  });

  test('goToToday snaps the cursor home', () async {
    final client = _FakeChartApiClient();
    final controller = _controller(client);
    await _load(controller);

    await controller.stepDay(5);
    expect(controller.selectedDate, '2026-06-19');

    await controller.goToToday();
    expect(controller.selectedDate, '2026-06-14');
    expect(controller.isToday, isTrue);

    controller.dispose();
  });

  test('cursor cannot roam past the bounded window', () async {
    final client = _FakeChartApiClient();
    final controller = _controller(client);
    await _load(controller);

    expect(controller.canStepBack, isTrue);
    expect(controller.canStepForward, isTrue);

    // Far past the +366 ceiling is rejected (no extra fetch).
    final before = client.requestedDates.length;
    await controller.stepDay(400);
    expect(controller.selectedDate, '2026-06-14');
    expect(client.requestedDates.length, before);

    controller.dispose();
  });

  test('load failure surfaces the API message', () async {
    final client =
        _FakeChartApiClient(exception: const ChartApiException('Place not found'));
    final controller = _controller(client);

    await _load(controller);

    expect(controller.error, 'Place not found');
    expect(controller.result, isNull);

    controller.dispose();
  });
}

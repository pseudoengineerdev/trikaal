import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/dasha/data/dasha_api_client.dart';
import 'package:trikaal_mobile/features/dasha/data/models/dasha_models.dart';
import 'package:trikaal_mobile/features/dasha/presentation/state/dasha_controller.dart';

void main() {
  group('DashaController', () {
    test('loadCurrentDasha sets summary on success', () async {
      final controller = DashaController(
        apiClient: _FakeDashaApiClient(
          response: const DashaComputeResponse(
            profile: <String, dynamic>{},
            normalizedInput: <String, dynamic>{},
            resolvedPlace: <String, dynamic>{},
            dasha: DashaSummary(
              system: 'Vimshottari',
              currentMahaDasha: 'Guru',
              currentAntarDasha: 'Shani',
              activeFrom: '2026-01-01',
              activeUntil: '2027-03-01',
              currentMahaStart: '2024-06-01',
              currentMahaEnd: '2040-06-01',
              mahaTimeline: <DashaPeriod>[],
              antarTimelineCurrentMaha: <DashaPeriod>[],
            ),
          ),
        ),
      );

      await controller.loadCurrentDasha(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.summary, isNotNull);
      expect(controller.summary!.currentMahaDasha, 'Guru');
    });

    test('loadCurrentDasha sets error on failure', () async {
      final controller = DashaController(
        apiClient: _FakeDashaApiClient(throwError: true),
      );

      await controller.loadCurrentDasha(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
      );

      expect(controller.loading, isFalse);
      expect(controller.summary, isNull);
      expect(controller.error, isNotNull);
    });
  });
}

class _FakeDashaApiClient extends DashaApiClient {
  _FakeDashaApiClient({this.response, this.throwError = false});

  final DashaComputeResponse? response;
  final bool throwError;

  @override
  Future<DashaComputeResponse> computeDasha(DashaComputeRequest request) async {
    if (throwError) {
      throw const DashaApiException('failed');
    }
    return response ??
        const DashaComputeResponse(
          profile: <String, dynamic>{},
          normalizedInput: <String, dynamic>{},
          resolvedPlace: <String, dynamic>{},
          dasha: DashaSummary(
            system: 'Vimshottari',
            currentMahaDasha: 'Placeholder',
            currentAntarDasha: 'Placeholder',
            activeFrom: 'TBD',
            activeUntil: 'TBD',
            currentMahaStart: 'TBD',
            currentMahaEnd: 'TBD',
            mahaTimeline: <DashaPeriod>[],
            antarTimelineCurrentMaha: <DashaPeriod>[],
          ),
        );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/dasha/data/dasha_api_client.dart';
import 'package:trikaal_mobile/features/dasha/data/models/dasha_models.dart';
import 'package:trikaal_mobile/features/dasha/presentation/state/dasha_controller.dart';

void main() {
  group('DashaController', () {
    test('loadPreview sets summary on success', () async {
      final controller = DashaController(
        apiClient: _FakeDashaApiClient(
          summary: const DashaSummary(
            system: 'Vimshottari',
            currentMahaDasha: 'Guru',
            currentAntarDasha: 'Shani',
            activeFrom: '2026-01-01',
            activeUntil: '2027-03-01',
          ),
        ),
      );

      await controller.loadPreview();

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.summary, isNotNull);
      expect(controller.summary!.currentMahaDasha, 'Guru');
    });

    test('loadPreview sets error on failure', () async {
      final controller = DashaController(
        apiClient: _FakeDashaApiClient(throwError: true),
      );

      await controller.loadPreview();

      expect(controller.loading, isFalse);
      expect(controller.summary, isNull);
      expect(controller.error, isNotNull);
    });
  });
}

class _FakeDashaApiClient extends DashaApiClient {
  _FakeDashaApiClient({this.summary, this.throwError = false});

  final DashaSummary? summary;
  final bool throwError;

  @override
  Future<DashaSummary> fetchCurrentDasha({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
  }) async {
    if (throwError) {
      throw Exception('failed');
    }
    return summary ??
        const DashaSummary(
          system: 'Vimshottari',
          currentMahaDasha: 'Placeholder',
          currentAntarDasha: 'Placeholder',
          activeFrom: 'TBD',
          activeUntil: 'TBD',
        );
  }
}

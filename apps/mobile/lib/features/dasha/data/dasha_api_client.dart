import 'models/dasha_models.dart';

class DashaApiClient {
  Future<DashaSummary> fetchCurrentDasha({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const DashaSummary(
      system: 'Vimshottari',
      currentMahaDasha: 'Placeholder',
      currentAntarDasha: 'Placeholder',
      activeFrom: 'TBD',
      activeUntil: 'TBD',
    );
  }
}

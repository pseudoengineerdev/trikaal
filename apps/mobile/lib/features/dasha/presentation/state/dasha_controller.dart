import 'package:flutter/foundation.dart';

import '../../data/dasha_api_client.dart';
import '../../data/models/dasha_models.dart';

class DashaController extends ChangeNotifier {
  DashaController({DashaApiClient? apiClient})
      : _apiClient = apiClient ?? DashaApiClient();

  final DashaApiClient _apiClient;

  bool loading = false;
  String? error;
  DashaSummary? summary;

  void clear() {
    loading = false;
    error = null;
    summary = null;
    notifyListeners();
  }

  Future<void> loadCurrentDasha({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiClient.computeDasha(
        DashaComputeRequest(
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          placeOfBirth: placeOfBirth,
        ),
      );
      summary = response.dasha;
    } on DashaApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to compute Dasha right now.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

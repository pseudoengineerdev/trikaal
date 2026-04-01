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

  Future<void> loadPreview() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      summary = await _apiClient.fetchCurrentDasha(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
      );
    } catch (_) {
      error = 'Unable to load Dasha preview right now.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

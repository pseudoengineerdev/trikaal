import 'package:flutter/foundation.dart';

import '../../../charts/data/chart_api_client.dart';
import '../../../charts/data/models/compute_kaal_sarpa_models.dart';

class KaalSarpaController extends ChangeNotifier {
  KaalSarpaController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;

  bool loading = false;
  String? error;
  ComputeKaalSarpaResponse? result;

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> compute({
    required ComputeKaalSarpaRequest request,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      result = await _apiClient.computeKaalSarpa(request);
    } on ChartApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not compute Kaal Sarpa right now. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

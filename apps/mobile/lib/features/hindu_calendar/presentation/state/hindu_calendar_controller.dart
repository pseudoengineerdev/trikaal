import 'package:flutter/foundation.dart';

import '../../../charts/data/chart_api_client.dart';
import '../../../charts/data/models/compute_hindu_calendar_models.dart';

class HinduCalendarController extends ChangeNotifier {
  HinduCalendarController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;
  bool loading = false;
  String? error;
  ComputeHinduCalendarResponse? result;
  int _requestSequence = 0;

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> compute({
    required ComputeHinduCalendarRequest request,
  }) async {
    final int requestSequence = ++_requestSequence;
    loading = true;
    error = null;
    result = null;
    notifyListeners();

    try {
      final nextResult = await _apiClient.computeHinduCalendar(request);
      if (requestSequence != _requestSequence) {
        return;
      }
      result = nextResult;
    } on ChartApiException catch (exception) {
      if (requestSequence != _requestSequence) {
        return;
      }
      if (exception.message.startsWith('Endpoint not found on API')) {
        error =
            'Calendar endpoint missing in API build. Please restart backend from this branch.';
      } else {
        error = exception.message;
      }
    } catch (_) {
      if (requestSequence != _requestSequence) {
        return;
      }
      error =
          'Could not compute Sanatani calendar right now. Please try again.';
    } finally {
      if (requestSequence == _requestSequence) {
        loading = false;
        notifyListeners();
      }
    }
  }
}

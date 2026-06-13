import 'package:flutter/foundation.dart';

import '../../../charts/data/chart_api_client.dart';
import '../../data/models/panchang_models.dart';

class PanchangDayState {
  PanchangDayState({
    this.loading = false,
    this.error,
    this.result,
  });

  bool loading;
  String? error;
  ComputePanchangResponse? result;
}

/// Holds one panchang result per date so day swipes keep already-computed
/// days instantly available.
class PanchangController extends ChangeNotifier {
  PanchangController({ChartApiClient? apiClient})
      : _apiClient = apiClient ?? ChartApiClient();

  final ChartApiClient _apiClient;
  final Map<String, PanchangDayState> _days = <String, PanchangDayState>{};
  int _generation = 0;

  PanchangDayState? stateFor(String dateIso) => _days[dateIso];

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  /// Drops every cached day, e.g. after the observation location changes.
  void clear() {
    _generation++;
    _days.clear();
    notifyListeners();
  }

  Future<void> compute({required ComputePanchangRequest request}) async {
    final existing = _days[request.date];
    if (existing != null && (existing.loading || existing.result != null)) {
      return;
    }
    final generation = _generation;
    final dayState = PanchangDayState(loading: true);
    _days[request.date] = dayState;
    notifyListeners();

    try {
      final result = await _apiClient.computePanchang(request);
      if (generation != _generation) {
        return;
      }
      dayState.result = result;
    } on ChartApiException catch (exception) {
      if (generation != _generation) {
        return;
      }
      dayState.error = exception.message;
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      dayState.error =
          'Could not compute the panchang right now. Please try again.';
    } finally {
      if (generation == _generation) {
        dayState.loading = false;
        notifyListeners();
      }
    }
  }

  /// Allows a manual retry after an error.
  void invalidate(String dateIso) {
    _days.remove(dateIso);
    notifyListeners();
  }
}

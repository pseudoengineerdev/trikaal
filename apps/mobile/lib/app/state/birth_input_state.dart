import 'package:flutter/foundation.dart';

class BirthInputState extends ChangeNotifier {
  BirthInputState({
    String dateOfBirth = '',
    String timeOfBirth = '',
    String placeOfBirth = '',
  })  : _dateOfBirth = dateOfBirth,
        _timeOfBirth = timeOfBirth,
        _placeOfBirth = placeOfBirth;

  String _dateOfBirth;
  String _timeOfBirth;
  String _placeOfBirth;
  bool _hasComputedChart = false;

  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;
  bool get hasComputedChart => _hasComputedChart;

  void updateDateOfBirth(String value) {
    if (_dateOfBirth == value) {
      return;
    }
    _dateOfBirth = value;
    _hasComputedChart = false;
    notifyListeners();
  }

  void updateTimeOfBirth(String value) {
    if (_timeOfBirth == value) {
      return;
    }
    _timeOfBirth = value;
    _hasComputedChart = false;
    notifyListeners();
  }

  void updatePlaceOfBirth(String value) {
    if (_placeOfBirth == value) {
      return;
    }
    _placeOfBirth = value;
    _hasComputedChart = false;
    notifyListeners();
  }

  void markChartComputed() {
    if (_hasComputedChart) {
      return;
    }
    _hasComputedChart = true;
    notifyListeners();
  }

  void clearComputedChart() {
    if (!_hasComputedChart) {
      return;
    }
    _hasComputedChart = false;
    notifyListeners();
  }
}

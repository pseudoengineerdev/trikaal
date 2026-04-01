import 'package:flutter/foundation.dart';

import '../models/custom_place_payload.dart';

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
  CustomPlacePayload? _customPlace;
  bool _hasComputedChart = false;

  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;
  CustomPlacePayload? get customPlace => _customPlace;
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
    _customPlace = null;
    _hasComputedChart = false;
    notifyListeners();
  }

  void setResolvedPlace(CustomPlacePayload place) {
    _placeOfBirth = place.placeLabel;
    _customPlace = place;
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

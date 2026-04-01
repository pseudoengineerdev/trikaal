import 'package:flutter/foundation.dart';

import '../models/custom_place_payload.dart';
import '../../features/dasha/data/models/dasha_models.dart';

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
  DashaSummary? _computedDasha;

  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;
  CustomPlacePayload? get customPlace => _customPlace;
  bool get hasComputedChart => _hasComputedChart;
  DashaSummary? get computedDasha => _computedDasha;

  void updateDateOfBirth(String value) {
    if (_dateOfBirth == value) {
      return;
    }
    _dateOfBirth = value;
    _hasComputedChart = false;
    _computedDasha = null;
    notifyListeners();
  }

  void updateTimeOfBirth(String value) {
    if (_timeOfBirth == value) {
      return;
    }
    _timeOfBirth = value;
    _hasComputedChart = false;
    _computedDasha = null;
    notifyListeners();
  }

  void updatePlaceOfBirth(String value) {
    if (_placeOfBirth == value) {
      return;
    }
    _placeOfBirth = value;
    _customPlace = null;
    _hasComputedChart = false;
    _computedDasha = null;
    notifyListeners();
  }

  void setResolvedPlace(CustomPlacePayload place) {
    _placeOfBirth = place.placeLabel;
    _customPlace = place;
    _hasComputedChart = false;
    _computedDasha = null;
    notifyListeners();
  }

  void markChartComputed({DashaSummary? dashaSummary}) {
    _hasComputedChart = true;
    _computedDasha = dashaSummary;
    notifyListeners();
  }

  void clearComputedChart() {
    if (!_hasComputedChart && _computedDasha == null) {
      return;
    }
    _hasComputedChart = false;
    _computedDasha = null;
    notifyListeners();
  }
}

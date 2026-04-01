import 'package:flutter/foundation.dart';

class BirthInputState extends ChangeNotifier {
  BirthInputState({
    String dateOfBirth = '1999-07-04',
    String timeOfBirth = '12:22',
    String placeOfBirth = 'Mumbai',
  })  : _dateOfBirth = dateOfBirth,
        _timeOfBirth = timeOfBirth,
        _placeOfBirth = placeOfBirth;

  String _dateOfBirth;
  String _timeOfBirth;
  String _placeOfBirth;

  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;

  void updateDateOfBirth(String value) {
    if (_dateOfBirth == value) {
      return;
    }
    _dateOfBirth = value;
    notifyListeners();
  }

  void updateTimeOfBirth(String value) {
    if (_timeOfBirth == value) {
      return;
    }
    _timeOfBirth = value;
    notifyListeners();
  }

  void updatePlaceOfBirth(String value) {
    if (_placeOfBirth == value) {
      return;
    }
    _placeOfBirth = value;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

enum TerminologyMode {
  vedic,
  english,
}

class TerminologyModeState extends ChangeNotifier {
  TerminologyMode _mode = TerminologyMode.vedic;

  TerminologyMode get mode => _mode;

  void setMode(TerminologyMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }
}

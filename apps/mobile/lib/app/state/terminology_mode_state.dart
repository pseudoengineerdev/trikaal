import 'package:flutter/foundation.dart';

enum TerminologyMode {
  vedic,
  english,
}

class TerminologyModeState extends ChangeNotifier
    implements ValueListenable<TerminologyMode> {
  TerminologyMode _mode = TerminologyMode.vedic;

  TerminologyMode get mode => _mode;

  @override
  TerminologyMode get value => _mode;

  void setMode(TerminologyMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }
}

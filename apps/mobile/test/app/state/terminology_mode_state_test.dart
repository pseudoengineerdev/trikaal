import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/state/terminology_mode_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminologyModeState', () {
    test('defaults to Sanskrit terminology and hydrates a saved choice',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'terminology_mode': 'english',
      });
      final state = TerminologyModeState();
      addTearDown(state.dispose);

      expect(state.mode, TerminologyMode.vedic);

      await state.load();
      expect(state.mode, TerminologyMode.english);
    });

    test('setMode persists, so a fresh instance restores it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = TerminologyModeState();
      addTearDown(first.dispose);

      await first.load();
      first.setMode(TerminologyMode.english);
      // Let the async persist write complete.
      await Future<void>.delayed(Duration.zero);

      final second = TerminologyModeState();
      addTearDown(second.dispose);
      await second.load();
      expect(second.mode, TerminologyMode.english);
    });

    test('ignores an unknown stored value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'terminology_mode': 'klingon',
      });
      final state = TerminologyModeState();
      addTearDown(state.dispose);

      await state.load();
      expect(state.mode, TerminologyMode.vedic);
    });

    test('notifies listeners on mode changes only', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = TerminologyModeState();
      addTearDown(state.dispose);
      var notifications = 0;
      state.addListener(() => notifications++);

      state.setMode(TerminologyMode.vedic);
      expect(notifications, 0);

      state.setMode(TerminologyMode.english);
      expect(notifications, 1);
    });
  });
}

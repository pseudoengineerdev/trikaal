import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TerminologyMode {
  vedic,
  english,
}

/// App-wide Sanskrit/English terminology preference. The only toggle lives
/// in the home header, so every term-rendering screen must observe [shared]:
/// a change made on home applies everywhere and persists across restarts.
class TerminologyModeState extends ChangeNotifier
    implements ValueListenable<TerminologyMode> {
  TerminologyModeState({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  /// Single app-wide instance. Separate instances would never see each
  /// other's changes, leaving screens stuck on their own default mode.
  static final TerminologyModeState shared = TerminologyModeState();

  static const String _storageKey = 'terminology_mode';

  final Future<SharedPreferences> Function() _prefsLoader;
  TerminologyMode _mode = TerminologyMode.vedic;
  bool _disposed = false;
  Future<void>? _pendingLoad;

  TerminologyMode get mode => _mode;

  @override
  TerminologyMode get value => _mode;

  /// Hydrates the saved preference once; repeated calls are no-ops.
  Future<void> load() {
    return _pendingLoad ??= _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await _prefsLoader();
      final raw = prefs.getString(_storageKey);
      if (_disposed || raw == null) {
        return;
      }
      final saved = TerminologyMode.values.asNameMap()[raw];
      if (saved != null && saved != _mode) {
        _mode = saved;
        notifyListeners();
      }
    } catch (_) {
      // Unreadable preference: keep the in-memory default.
    }
  }

  void setMode(TerminologyMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    _persist(mode);
  }

  Future<void> _persist(TerminologyMode mode) async {
    try {
      final prefs = await _prefsLoader();
      await prefs.setString(_storageKey, mode.name);
    } catch (_) {
      // Best-effort: the in-memory mode is already applied everywhere.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

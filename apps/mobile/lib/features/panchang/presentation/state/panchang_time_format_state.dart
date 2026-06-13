import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PanchangTimeFormat {
  h12,
  h24plus,
}

/// Persisted 12-hour / 24-hour-plus clock preference for the panchang page.
/// In 24+ mode, events past midnight stay anchored to the panchang date and
/// roll beyond 24 (e.g. 01:13 AM next day renders as 25:13).
class PanchangTimeFormatState extends ChangeNotifier
    implements ValueListenable<PanchangTimeFormat> {
  PanchangTimeFormatState({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  /// Single app-wide instance, mirroring [TerminologyModeState.shared].
  static final PanchangTimeFormatState shared = PanchangTimeFormatState();

  static const String _storageKey = 'panchang_time_format';

  final Future<SharedPreferences> Function() _prefsLoader;
  PanchangTimeFormat _format = PanchangTimeFormat.h12;
  bool _disposed = false;
  Future<void>? _pendingLoad;

  PanchangTimeFormat get format => _format;

  @override
  PanchangTimeFormat get value => _format;

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
      final saved = PanchangTimeFormat.values.asNameMap()[raw];
      if (saved != null && saved != _format) {
        _format = saved;
        notifyListeners();
      }
    } catch (_) {
      // Unreadable preference: keep the in-memory default.
    }
  }

  void setFormat(PanchangTimeFormat format) {
    if (_format == format) {
      return;
    }
    _format = format;
    notifyListeners();
    _persist(format);
  }

  Future<void> _persist(PanchangTimeFormat format) async {
    try {
      final prefs = await _prefsLoader();
      await prefs.setString(_storageKey, format.name);
    } catch (_) {
      // Best-effort: the in-memory format is already applied.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

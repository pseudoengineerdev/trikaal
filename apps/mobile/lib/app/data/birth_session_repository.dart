import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/birth_session.dart';

abstract class BirthSessionRepository {
  Future<BirthSession?> loadSession();

  Future<void> saveSession(BirthSession session);

  Future<void> clearSession();
}

class SharedPreferencesBirthSessionRepository
    implements BirthSessionRepository {
  SharedPreferencesBirthSessionRepository({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const String _storageKey = 'trikaal_birth_session_v1';
  final Future<SharedPreferences> Function() _prefsLoader;
  bool _useMemoryFallback = false;
  BirthSession? _memoryFallback;

  @override
  Future<BirthSession?> loadSession() async {
    if (_useMemoryFallback) {
      return _memoryFallback;
    }

    try {
      final prefs = await _prefsLoader();
      final rawValue = prefs.getString(_storageKey);
      if (rawValue == null || rawValue.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        return null;
      }
      final map = decoded.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      return BirthSession.fromJson(map);
    } catch (_) {
      // Corrupt or unreadable cache must never block startup: fall back to a
      // clean onboarding state rather than surfacing an error.
      return _useMemoryFallback ? _memoryFallback : null;
    }
  }

  @override
  Future<void> saveSession(BirthSession session) async {
    _memoryFallback = session;
    if (_useMemoryFallback) {
      return;
    }

    try {
      final prefs = await _prefsLoader();
      final encoded = jsonEncode(session.toJson());
      final didSave = await prefs.setString(_storageKey, encoded);
      if (!didSave) {
        _useMemoryFallback = true;
      }
    } catch (_) {
      _useMemoryFallback = true;
    }
  }

  @override
  Future<void> clearSession() async {
    _memoryFallback = null;
    if (_useMemoryFallback) {
      return;
    }

    try {
      final prefs = await _prefsLoader();
      await prefs.remove(_storageKey);
    } catch (_) {
      _useMemoryFallback = true;
    }
  }
}

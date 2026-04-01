import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_birth_profile.dart';

abstract class SavedProfilesRepository {
  Future<List<SavedBirthProfile>> loadProfiles();

  Future<void> saveProfiles(List<SavedBirthProfile> profiles);
}

class SharedPreferencesSavedProfilesRepository
    implements SavedProfilesRepository {
  SharedPreferencesSavedProfilesRepository({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const String _storageKey = 'trikaal_saved_birth_profiles_v1';
  final Future<SharedPreferences> Function() _prefsLoader;

  @override
  Future<List<SavedBirthProfile>> loadProfiles() async {
    final prefs = await _prefsLoader();
    final rawValue = prefs.getString(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return <SavedBirthProfile>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        return <SavedBirthProfile>[];
      }

      final parsed = <SavedBirthProfile>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final map = entry.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );
        final profile = SavedBirthProfile.fromJson(map);
        if (profile.id.isEmpty || profile.name.trim().isEmpty) {
          continue;
        }
        parsed.add(profile);
      }
      return parsed;
    } catch (_) {
      return <SavedBirthProfile>[];
    }
  }

  @override
  Future<void> saveProfiles(List<SavedBirthProfile> profiles) async {
    final prefs = await _prefsLoader();
    final payload = profiles.map((profile) => profile.toJson()).toList();
    final encoded = jsonEncode(payload);
    final didSave = await prefs.setString(_storageKey, encoded);
    if (!didSave) {
      throw StateError('SharedPreferences save returned false.');
    }
  }
}

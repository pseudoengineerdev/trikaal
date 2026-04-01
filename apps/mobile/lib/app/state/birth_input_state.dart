import 'package:flutter/foundation.dart';

import '../data/saved_profiles_repository.dart';
import '../models/custom_place_payload.dart';
import '../models/saved_birth_profile.dart';
import '../../features/dasha/data/models/dasha_models.dart';

class BirthInputState extends ChangeNotifier {
  BirthInputState({
    String dateOfBirth = '',
    String timeOfBirth = '',
    String placeOfBirth = '',
    SavedProfilesRepository? profilesRepository,
  })  : _dateOfBirth = dateOfBirth,
        _timeOfBirth = timeOfBirth,
        _placeOfBirth = placeOfBirth,
        _profilesRepository =
            profilesRepository ?? SharedPreferencesSavedProfilesRepository();

  String _dateOfBirth;
  String _timeOfBirth;
  String _placeOfBirth;
  CustomPlacePayload? _customPlace;
  bool _hasComputedChart = false;
  DashaSummary? _computedDasha;
  final SavedProfilesRepository _profilesRepository;
  List<SavedBirthProfile> _savedProfiles = <SavedBirthProfile>[];
  String? _activeProfileId;
  bool _profilesLoaded = false;
  bool _profilesLoading = false;
  String? _profilesError;

  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;
  CustomPlacePayload? get customPlace => _customPlace;
  bool get hasComputedChart => _hasComputedChart;
  DashaSummary? get computedDasha => _computedDasha;
  List<SavedBirthProfile> get savedProfiles =>
      List<SavedBirthProfile>.unmodifiable(_savedProfiles);
  String? get activeProfileId => _activeProfileId;
  bool get profilesLoaded => _profilesLoaded;
  bool get profilesLoading => _profilesLoading;
  String? get profilesError => _profilesError;
  bool get canSaveCurrentAsProfile =>
      _dateOfBirth.trim().isNotEmpty &&
      _timeOfBirth.trim().isNotEmpty &&
      _placeOfBirth.trim().isNotEmpty;

  void updateDateOfBirth(String value) {
    if (_dateOfBirth == value) {
      return;
    }
    _dateOfBirth = value;
    _activeProfileId = null;
    _clearComputedState();
    notifyListeners();
  }

  void updateTimeOfBirth(String value) {
    if (_timeOfBirth == value) {
      return;
    }
    _timeOfBirth = value;
    _activeProfileId = null;
    _clearComputedState();
    notifyListeners();
  }

  void updatePlaceOfBirth(String value) {
    if (_placeOfBirth == value) {
      return;
    }
    _placeOfBirth = value;
    _customPlace = null;
    _activeProfileId = null;
    _clearComputedState();
    notifyListeners();
  }

  void setResolvedPlace(
    CustomPlacePayload place, {
    bool preserveActiveProfile = false,
  }) {
    _placeOfBirth = place.placeLabel;
    _customPlace = place;
    if (!preserveActiveProfile) {
      _activeProfileId = null;
    }
    _clearComputedState();
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

  Future<void> loadSavedProfiles() async {
    if (_profilesLoaded || _profilesLoading) {
      return;
    }
    _profilesLoading = true;
    _profilesError = null;
    notifyListeners();

    try {
      final loadedProfiles = await _profilesRepository.loadProfiles();
      _savedProfiles = _sortProfiles(_normalizeDefaultProfiles(loadedProfiles));
      _profilesLoaded = true;
      if (_savedProfiles.isNotEmpty && _isCurrentInputEmpty()) {
        final preferredProfile = _savedProfiles.firstWhere(
          (SavedBirthProfile profile) => profile.isDefault,
          orElse: () => _savedProfiles.first,
        );
        _applyProfile(preferredProfile, notify: false);
      }
    } catch (_) {
      _profilesError = 'Unable to load saved profiles right now.';
    } finally {
      _profilesLoading = false;
      notifyListeners();
    }
  }

  void applyProfile(String profileId) {
    final profile = _savedProfiles.where((item) => item.id == profileId);
    if (profile.isEmpty) {
      return;
    }
    _applyProfile(profile.first);
  }

  Future<bool> createProfile({
    required String name,
    bool setAsDefault = false,
  }) async {
    final profileName = name.trim();
    if (profileName.isEmpty || !canSaveCurrentAsProfile) {
      _profilesError = 'Enter complete birth details before saving a profile.';
      notifyListeners();
      return false;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final profile = SavedBirthProfile(
      id: _newProfileId(),
      name: profileName,
      dateOfBirth: _dateOfBirth.trim(),
      timeOfBirth: _timeOfBirth.trim(),
      placeOfBirth: _placeOfBirth.trim(),
      customPlace: _customPlace,
      isDefault: setAsDefault || _savedProfiles.isEmpty,
      createdAtUtcIso: nowIso,
      updatedAtUtcIso: nowIso,
    );

    _savedProfiles = <SavedBirthProfile>[profile, ..._savedProfiles];
    if (profile.isDefault) {
      _savedProfiles = _savedProfiles
          .map(
            (item) => item.id == profile.id
                ? item.copyWith(isDefault: true)
                : item.copyWith(isDefault: false),
          )
          .toList();
    }
    _savedProfiles = _sortProfiles(_normalizeDefaultProfiles(_savedProfiles));
    _activeProfileId = profile.id;
    return _persistProfiles();
  }

  Future<bool> renameProfile({
    required String profileId,
    required String name,
  }) async {
    final profileName = name.trim();
    if (profileName.isEmpty) {
      _profilesError = 'Profile name cannot be empty.';
      notifyListeners();
      return false;
    }
    final index = _savedProfiles.indexWhere((item) => item.id == profileId);
    if (index < 0) {
      return false;
    }
    _savedProfiles[index] = _savedProfiles[index].copyWith(
      name: profileName,
      updatedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
    );
    _savedProfiles = _sortProfiles(_savedProfiles);
    return _persistProfiles();
  }

  Future<bool> updateProfileFromCurrent(String profileId) async {
    if (!canSaveCurrentAsProfile) {
      _profilesError = 'Enter complete birth details before updating profile.';
      notifyListeners();
      return false;
    }
    final index = _savedProfiles.indexWhere((item) => item.id == profileId);
    if (index < 0) {
      return false;
    }
    final current = _savedProfiles[index];
    _savedProfiles[index] = current.copyWith(
      dateOfBirth: _dateOfBirth.trim(),
      timeOfBirth: _timeOfBirth.trim(),
      placeOfBirth: _placeOfBirth.trim(),
      customPlace: _customPlace,
      clearCustomPlace: _customPlace == null,
      updatedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
    );
    _savedProfiles = _sortProfiles(_savedProfiles);
    _activeProfileId = profileId;
    return _persistProfiles();
  }

  Future<bool> setDefaultProfile(String profileId) async {
    if (_savedProfiles.every((item) => item.id != profileId)) {
      return false;
    }
    _savedProfiles = _savedProfiles
        .map(
          (item) => item.id == profileId
              ? item.copyWith(isDefault: true)
              : item.copyWith(isDefault: false),
        )
        .toList();
    _savedProfiles = _sortProfiles(_savedProfiles);
    return _persistProfiles();
  }

  Future<bool> deleteProfile(String profileId) async {
    final hadProfile = _savedProfiles.any((item) => item.id == profileId);
    if (!hadProfile) {
      return false;
    }

    _savedProfiles =
        _savedProfiles.where((item) => item.id != profileId).toList();
    if (_savedProfiles.isNotEmpty &&
        _savedProfiles.every((item) => !item.isDefault)) {
      _savedProfiles[0] = _savedProfiles[0].copyWith(isDefault: true);
    }
    if (_activeProfileId == profileId) {
      _activeProfileId = null;
    }
    _savedProfiles = _sortProfiles(_savedProfiles);
    return _persistProfiles();
  }

  void _applyProfile(SavedBirthProfile profile, {bool notify = true}) {
    _dateOfBirth = profile.dateOfBirth;
    _timeOfBirth = profile.timeOfBirth;
    _placeOfBirth = profile.placeOfBirth;
    _customPlace = profile.customPlace;
    _activeProfileId = profile.id;
    _clearComputedState();
    if (notify) {
      notifyListeners();
    }
  }

  bool _isCurrentInputEmpty() {
    return _dateOfBirth.trim().isEmpty &&
        _timeOfBirth.trim().isEmpty &&
        _placeOfBirth.trim().isEmpty;
  }

  List<SavedBirthProfile> _normalizeDefaultProfiles(
    List<SavedBirthProfile> profiles,
  ) {
    if (profiles.isEmpty) {
      return <SavedBirthProfile>[];
    }
    final normalized = List<SavedBirthProfile>.from(profiles);
    final firstDefaultIndex = normalized.indexWhere((item) => item.isDefault);

    if (firstDefaultIndex < 0) {
      normalized[0] = normalized[0].copyWith(isDefault: true);
      return normalized;
    }

    for (var index = 0; index < normalized.length; index += 1) {
      if (index == firstDefaultIndex) {
        continue;
      }
      if (normalized[index].isDefault) {
        normalized[index] = normalized[index].copyWith(isDefault: false);
      }
    }
    return normalized;
  }

  List<SavedBirthProfile> _sortProfiles(List<SavedBirthProfile> profiles) {
    final sorted = List<SavedBirthProfile>.from(profiles);
    sorted.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      final aUpdated = DateTime.tryParse(a.updatedAtUtcIso);
      final bUpdated = DateTime.tryParse(b.updatedAtUtcIso);
      if (aUpdated == null && bUpdated == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (aUpdated == null) {
        return 1;
      }
      if (bUpdated == null) {
        return -1;
      }
      return bUpdated.compareTo(aUpdated);
    });
    return sorted;
  }

  String _newProfileId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<bool> _persistProfiles() async {
    try {
      await _profilesRepository.saveProfiles(_savedProfiles);
      _profilesError = null;
      notifyListeners();
      return true;
    } catch (_) {
      _profilesError = 'Unable to save profile changes right now.';
      notifyListeners();
      return false;
    }
  }

  void _clearComputedState() {
    _hasComputedChart = false;
    _computedDasha = null;
  }
}

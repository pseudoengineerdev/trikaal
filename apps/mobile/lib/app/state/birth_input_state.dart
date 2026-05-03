import 'package:flutter/foundation.dart';

import '../data/saved_profiles_repository.dart';
import '../models/compatibility_partner_profile.dart';
import '../models/custom_place_payload.dart';
import '../models/person_gender.dart';
import '../models/saved_birth_profile.dart';
import '../../features/charts/data/models/compute_report_models.dart';
import '../../features/dasha/data/models/dasha_models.dart';

class BirthInputState extends ChangeNotifier {
  BirthInputState({
    String firstName = '',
    PersonGender gender = PersonGender.unspecified,
    String dateOfBirth = '',
    String timeOfBirth = '',
    String placeOfBirth = '',
    SavedProfilesRepository? profilesRepository,
  })  : _firstName = firstName,
        _gender = gender,
        _dateOfBirth = dateOfBirth,
        _timeOfBirth = timeOfBirth,
        _placeOfBirth = placeOfBirth,
        _profilesRepository =
            profilesRepository ?? SharedPreferencesSavedProfilesRepository();

  String _firstName;
  PersonGender _gender;
  String _dateOfBirth;
  String _timeOfBirth;
  String _placeOfBirth;
  CustomPlacePayload? _customPlace;
  bool _hasComputedChart = false;
  DashaSummary? _computedDasha;
  ComputeReportResponse? _computedReport;
  bool _onboardingCompleted = false;
  final SavedProfilesRepository _profilesRepository;
  List<SavedBirthProfile> _savedProfiles = <SavedBirthProfile>[];
  String? _activeProfileId;
  bool _profilesLoaded = false;
  bool _profilesLoading = false;
  String? _profilesError;
  CompatibilityPartnerProfile? _compatibilityPartnerProfile;

  String get firstName => _firstName;
  PersonGender get gender => _gender;
  String get dateOfBirth => _dateOfBirth;
  String get timeOfBirth => _timeOfBirth;
  String get placeOfBirth => _placeOfBirth;
  CustomPlacePayload? get customPlace => _customPlace;
  bool get hasComputedChart => _hasComputedChart;
  DashaSummary? get computedDasha => _computedDasha;
  ComputeReportResponse? get computedReport => _computedReport;
  bool get onboardingCompleted => _onboardingCompleted;
  List<SavedBirthProfile> get savedProfiles =>
      List<SavedBirthProfile>.unmodifiable(_savedProfiles);
  String? get activeProfileId => _activeProfileId;
  bool get profilesLoaded => _profilesLoaded;
  bool get profilesLoading => _profilesLoading;
  String? get profilesError => _profilesError;
  CompatibilityPartnerProfile? get compatibilityPartnerProfile =>
      _compatibilityPartnerProfile;
  bool get canSaveCurrentAsProfile =>
      _dateOfBirth.trim().isNotEmpty &&
      _timeOfBirth.trim().isNotEmpty &&
      _placeOfBirth.trim().isNotEmpty;

  void updateFirstName(String value, {bool clearComputed = true}) {
    if (_firstName == value) {
      return;
    }
    _firstName = value;
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void updateGender(PersonGender value, {bool clearComputed = false}) {
    if (_gender == value) {
      return;
    }
    _gender = value;
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void updateDateOfBirth(String value, {bool clearComputed = true}) {
    if (_dateOfBirth == value) {
      return;
    }
    _dateOfBirth = value;
    _activeProfileId = null;
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void updateTimeOfBirth(String value, {bool clearComputed = true}) {
    if (_timeOfBirth == value) {
      return;
    }
    _timeOfBirth = value;
    _activeProfileId = null;
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void updatePlaceOfBirth(String value, {bool clearComputed = true}) {
    if (_placeOfBirth == value) {
      return;
    }
    _placeOfBirth = value;
    _customPlace = null;
    _activeProfileId = null;
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void setResolvedPlace(
    CustomPlacePayload place, {
    bool preserveActiveProfile = false,
    bool clearComputed = true,
  }) {
    _placeOfBirth = place.placeLabel;
    _customPlace = place;
    if (!preserveActiveProfile) {
      _activeProfileId = null;
    }
    if (clearComputed) {
      _clearComputedState();
      _onboardingCompleted = false;
    }
    notifyListeners();
  }

  void markChartComputed({
    DashaSummary? dashaSummary,
    ComputeReportResponse? report,
  }) {
    _hasComputedChart = true;
    _computedDasha = dashaSummary;
    if (report != null) {
      _computedReport = report;
    }
    notifyListeners();
  }

  void markReportComputed(ComputeReportResponse report) {
    _hasComputedChart = true;
    _computedReport = report;
    _computedDasha = report.dasha;
    notifyListeners();
  }

  void completeOnboarding() {
    if (_onboardingCompleted) {
      return;
    }
    _onboardingCompleted = true;
    notifyListeners();
  }

  void reopenOnboarding() {
    if (!_onboardingCompleted) {
      return;
    }
    _onboardingCompleted = false;
    notifyListeners();
  }

  void clearComputedChart() {
    if (!_hasComputedChart &&
        _computedDasha == null &&
        _computedReport == null) {
      return;
    }
    _hasComputedChart = false;
    _computedDasha = null;
    _computedReport = null;
    _onboardingCompleted = false;
    notifyListeners();
  }

  void setCompatibilityPartnerProfile(CompatibilityPartnerProfile profile) {
    _compatibilityPartnerProfile = profile;
    notifyListeners();
  }

  void clearCompatibilityPartnerProfile() {
    if (_compatibilityPartnerProfile == null) {
      return;
    }
    _compatibilityPartnerProfile = null;
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
    } catch (error, stackTrace) {
      assert(() {
        debugPrint(
          'Saved profile load failed. Continuing without persisted data: '
          '$error\n$stackTrace',
        );
        return true;
      }());
      _savedProfiles = <SavedBirthProfile>[];
      _profilesLoaded = true;
      _profilesError = null;
    } finally {
      _profilesLoading = false;
      notifyListeners();
    }
  }

  void applyProfile(String profileId) {
    _profilesError = null;
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
    _profilesError = null;
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
      gender: _gender,
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
    _profilesError = null;
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
    _profilesError = null;
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
      gender: _gender,
      updatedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
    );
    _savedProfiles = _sortProfiles(_savedProfiles);
    _activeProfileId = profileId;
    return _persistProfiles();
  }

  Future<bool> setDefaultProfile(String profileId) async {
    _profilesError = null;
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
    _profilesError = null;
    final hadProfile = _savedProfiles.any((item) => item.id == profileId);
    if (!hadProfile) {
      return false;
    }
    final wasActiveProfile = _activeProfileId == profileId;

    _savedProfiles =
        _savedProfiles.where((item) => item.id != profileId).toList();
    if (_savedProfiles.isNotEmpty &&
        _savedProfiles.every((item) => !item.isDefault)) {
      _savedProfiles[0] = _savedProfiles[0].copyWith(isDefault: true);
    }
    _savedProfiles = _sortProfiles(_savedProfiles);

    if (wasActiveProfile) {
      if (_savedProfiles.isEmpty) {
        _clearCurrentInput();
      } else {
        final fallbackProfile = _savedProfiles.firstWhere(
          (SavedBirthProfile profile) => profile.isDefault,
          orElse: () => _savedProfiles.first,
        );
        _applyProfile(fallbackProfile, notify: false);
      }
    }
    return _persistProfiles();
  }

  void _applyProfile(SavedBirthProfile profile, {bool notify = true}) {
    _firstName = profile.name;
    _gender = profile.gender;
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
    } catch (error, stackTrace) {
      assert(() {
        debugPrint(
          'Saved profile persist failed: $error\n$stackTrace',
        );
        return true;
      }());
      _profilesError = 'Unable to save profile changes right now.';
      notifyListeners();
      return false;
    }
  }

  void _clearComputedState() {
    _hasComputedChart = false;
    _computedDasha = null;
    _computedReport = null;
  }

  void _clearCurrentInput() {
    _firstName = '';
    _gender = PersonGender.unspecified;
    _dateOfBirth = '';
    _timeOfBirth = '';
    _placeOfBirth = '';
    _customPlace = null;
    _activeProfileId = null;
    _clearComputedState();
    _onboardingCompleted = false;
  }
}

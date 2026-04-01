import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/data/saved_profiles_repository.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/app/models/saved_birth_profile.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';

void main() {
  group('BirthInputState saved profiles', () {
    test(
        'loadSavedProfiles applies default profile when current input is empty',
        () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Primary',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
          _profile(
            id: 'p2',
            name: 'Secondary',
            date: '2001-09-09',
            time: '01:30',
            place: 'New York, New York, United States',
            timezone: 'America/New_York',
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);

      await state.loadSavedProfiles();

      expect(state.profilesLoaded, isTrue);
      expect(state.savedProfiles.length, 2);
      expect(state.dateOfBirth, '1999-07-04');
      expect(state.timeOfBirth, '12:22');
      expect(state.placeOfBirth, 'Mumbai, Maharashtra, India');
      expect(state.customPlace, isNotNull);
      expect(state.customPlace!.timezone, 'Asia/Kolkata');
      expect(state.activeProfileId, 'p1');
    });

    test('createProfile saves current input and marks first profile as default',
        () async {
      final repository = _MemorySavedProfilesRepository();
      final state = BirthInputState(profilesRepository: repository);
      state.updateDateOfBirth('1999-07-04');
      state.updateTimeOfBirth('12:22');
      state.setResolvedPlace(
        const CustomPlacePayload(
          placeLabel: 'Mumbai, Maharashtra, India',
          latitude: 19.076,
          longitude: 72.8777,
          timezone: 'Asia/Kolkata',
          elevationM: 14,
        ),
      );

      final didCreate = await state.createProfile(name: 'My Profile');

      expect(didCreate, isTrue);
      expect(repository.saveCalls, 1);
      expect(state.savedProfiles.length, 1);
      expect(state.savedProfiles.first.name, 'My Profile');
      expect(state.savedProfiles.first.isDefault, isTrue);
      expect(state.activeProfileId, state.savedProfiles.first.id);
    });

    test('applyProfile swaps current input to selected profile', () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Mumbai',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
          _profile(
            id: 'p2',
            name: 'Tokyo',
            date: '2005-06-21',
            time: '15:10',
            place: 'Tokyo, Japan',
            timezone: 'Asia/Tokyo',
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);
      await state.loadSavedProfiles();

      state.applyProfile('p2');

      expect(state.dateOfBirth, '2005-06-21');
      expect(state.timeOfBirth, '15:10');
      expect(state.placeOfBirth, 'Tokyo, Japan');
      expect(state.customPlace!.timezone, 'Asia/Tokyo');
      expect(state.activeProfileId, 'p2');
    });

    test('setDefaultProfile and deleteProfile keep defaults consistent',
        () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Mumbai',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
          _profile(
            id: 'p2',
            name: 'Tokyo',
            date: '2005-06-21',
            time: '15:10',
            place: 'Tokyo, Japan',
            timezone: 'Asia/Tokyo',
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);
      await state.loadSavedProfiles();

      final didSetDefault = await state.setDefaultProfile('p2');
      expect(didSetDefault, isTrue);
      expect(state.savedProfiles.first.id, 'p2');
      expect(state.savedProfiles.first.isDefault, isTrue);
      expect(state.savedProfiles[1].isDefault, isFalse);

      final didDelete = await state.deleteProfile('p2');
      expect(didDelete, isTrue);
      expect(state.savedProfiles.length, 1);
      expect(state.savedProfiles.first.id, 'p1');
      expect(state.savedProfiles.first.isDefault, isTrue);
    });

    test('updateProfileFromCurrent overwrites selected profile details',
        () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Mumbai',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);
      await state.loadSavedProfiles();

      state.updateDateOfBirth('2010-01-01');
      state.updateTimeOfBirth('04:05');
      state.setResolvedPlace(
        const CustomPlacePayload(
          placeLabel: 'Sydney, New South Wales, Australia',
          latitude: -33.8688,
          longitude: 151.2093,
          timezone: 'Australia/Sydney',
          elevationM: 58,
        ),
      );

      final didUpdate = await state.updateProfileFromCurrent('p1');

      expect(didUpdate, isTrue);
      expect(state.savedProfiles.first.dateOfBirth, '2010-01-01');
      expect(state.savedProfiles.first.timeOfBirth, '04:05');
      expect(
        state.savedProfiles.first.placeOfBirth,
        'Sydney, New South Wales, Australia',
      );
      expect(
        state.savedProfiles.first.customPlace!.timezone,
        'Australia/Sydney',
      );
    });

    test('successful retry clears stale persistence error', () async {
      final repository = _FlakySavedProfilesRepository();
      final state = BirthInputState(profilesRepository: repository);
      state.updateDateOfBirth('1999-07-04');
      state.updateTimeOfBirth('12:22');
      state.setResolvedPlace(
        const CustomPlacePayload(
          placeLabel: 'Mumbai, Maharashtra, India',
          latitude: 19.076,
          longitude: 72.8777,
          timezone: 'Asia/Kolkata',
          elevationM: 14,
        ),
      );

      final firstAttempt = await state.createProfile(name: 'First');
      expect(firstAttempt, isFalse);
      expect(state.profilesError, 'Unable to save profile changes right now.');

      final secondAttempt = await state.createProfile(name: 'Second');
      expect(secondAttempt, isTrue);
      expect(state.profilesError, isNull);
    });

    test('load failure falls back without persistent banner error', () async {
      final state = BirthInputState(
        profilesRepository: _ThrowingLoadSavedProfilesRepository(),
      );

      await state.loadSavedProfiles();

      expect(state.profilesLoaded, isTrue);
      expect(state.profilesLoading, isFalse);
      expect(state.savedProfiles, isEmpty);
      expect(state.profilesError, isNull);
    });

    test('deleting active profile switches input to fallback profile',
        () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Primary',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
          _profile(
            id: 'p2',
            name: 'Secondary',
            date: '2006-07-31',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);
      await state.loadSavedProfiles();
      state.applyProfile('p2');

      final didDelete = await state.deleteProfile('p2');

      expect(didDelete, isTrue);
      expect(state.savedProfiles.length, 1);
      expect(state.activeProfileId, 'p1');
      expect(state.dateOfBirth, '1999-07-04');
      expect(state.timeOfBirth, '12:22');
      expect(state.placeOfBirth, 'Mumbai, Maharashtra, India');
    });

    test('deleting last active profile clears current input values', () async {
      final repository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Only',
            date: '1999-07-04',
            time: '12:22',
            place: 'Mumbai, Maharashtra, India',
            timezone: 'Asia/Kolkata',
            isDefault: true,
          ),
        ],
      );
      final state = BirthInputState(profilesRepository: repository);
      await state.loadSavedProfiles();
      state.applyProfile('p1');

      final didDelete = await state.deleteProfile('p1');

      expect(didDelete, isTrue);
      expect(state.savedProfiles, isEmpty);
      expect(state.activeProfileId, isNull);
      expect(state.dateOfBirth, isEmpty);
      expect(state.timeOfBirth, isEmpty);
      expect(state.placeOfBirth, isEmpty);
      expect(state.customPlace, isNull);
      expect(state.hasComputedChart, isFalse);
      expect(state.computedDasha, isNull);
    });
  });
}

class _MemorySavedProfilesRepository implements SavedProfilesRepository {
  _MemorySavedProfilesRepository({
    List<SavedBirthProfile>? initialProfiles,
  }) : _profiles = List<SavedBirthProfile>.from(initialProfiles ?? const []);

  List<SavedBirthProfile> _profiles;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<SavedBirthProfile>> loadProfiles() async {
    loadCalls += 1;
    return List<SavedBirthProfile>.from(_profiles);
  }

  @override
  Future<void> saveProfiles(List<SavedBirthProfile> profiles) async {
    saveCalls += 1;
    _profiles = List<SavedBirthProfile>.from(profiles);
  }
}

class _FlakySavedProfilesRepository extends _MemorySavedProfilesRepository {
  bool _failedOnce = false;

  @override
  Future<void> saveProfiles(List<SavedBirthProfile> profiles) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw Exception('disk locked');
    }
    await super.saveProfiles(profiles);
  }
}

class _ThrowingLoadSavedProfilesRepository implements SavedProfilesRepository {
  @override
  Future<List<SavedBirthProfile>> loadProfiles() async {
    throw Exception('load failed');
  }

  @override
  Future<void> saveProfiles(List<SavedBirthProfile> profiles) async {}
}

SavedBirthProfile _profile({
  required String id,
  required String name,
  required String date,
  required String time,
  required String place,
  required String timezone,
  bool isDefault = false,
}) {
  return SavedBirthProfile(
    id: id,
    name: name,
    dateOfBirth: date,
    timeOfBirth: time,
    placeOfBirth: place,
    customPlace: CustomPlacePayload(
      placeLabel: place,
      latitude: 0,
      longitude: 0,
      timezone: timezone,
      elevationM: 0,
    ),
    isDefault: isDefault,
    createdAtUtcIso: '2026-04-01T00:00:00Z',
    updatedAtUtcIso: '2026-04-01T00:00:00Z',
  );
}

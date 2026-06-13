import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/data/birth_session_repository.dart';
import 'package:trikaal_mobile/app/data/saved_profiles_repository.dart';
import 'package:trikaal_mobile/app/models/birth_session.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/app/models/person_gender.dart';
import 'package:trikaal_mobile/app/models/saved_birth_profile.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';

import '../../helpers/sample_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The default session repository falls back to SharedPreferences for any
    // state that does not inject its own; keep that deterministic in tests.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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

    test('allows selecting and clearing current observation location', () {
      final state = BirthInputState();
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

      expect(state.hasCurrentObservationLocation, isFalse);
      expect(state.placeForCurrentObservations, 'Mumbai, Maharashtra, India');
      expect(state.currentObservationPlaceLabel, isNull);

      state.setCurrentObservationLocation(
        placeLabel: 'Detroit, Michigan, United States',
        customPlace: const CustomPlacePayload(
          placeLabel: 'Detroit, Michigan, United States',
          latitude: 42.3314,
          longitude: -83.0458,
          timezone: 'America/Detroit',
          elevationM: 177,
        ),
      );

      expect(state.hasCurrentObservationLocation, isTrue);
      expect(
        state.placeForCurrentObservations,
        'Detroit, Michigan, United States',
      );
      expect(
        state.currentObservationPlaceLabel,
        'Detroit, Michigan, United States',
      );
      expect(state.customPlaceForCurrentObservations, isNotNull);
      expect(
          state.customPlaceForCurrentObservations!.timezone, 'America/Detroit');

      state.clearCurrentObservationLocation();

      expect(state.hasCurrentObservationLocation, isFalse);
      expect(state.placeForCurrentObservations, 'Mumbai, Maharashtra, India');
      expect(state.currentObservationPlaceLabel, isNull);
      expect(state.customPlaceForCurrentObservations!.timezone, 'Asia/Kolkata');
    });
  });

  group('BirthInputState session persistence', () {
    test('restoreSession rehydrates inputs, report, and onboarding flag',
        () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(sessionRepository: repository);

      await state.restoreSession();

      expect(state.onboardingCompleted, isTrue);
      expect(state.hasComputedChart, isTrue);
      expect(state.computedReport, isNotNull);
      expect(state.computedDasha, isNotNull);
      expect(state.firstName, 'Asha');
      expect(state.gender, PersonGender.female);
      expect(state.dateOfBirth, '1999-07-04');
      expect(state.timeOfBirth, '12:22');
      expect(state.placeOfBirth, 'Mumbai, Maharashtra, India');
      expect(state.customPlace!.timezone, 'Asia/Kolkata');
    });

    test('restoreSession is a no-op when nothing is persisted', () async {
      final repository = _MemoryBirthSessionRepository();
      final state = BirthInputState(sessionRepository: repository);

      await state.restoreSession();

      expect(state.onboardingCompleted, isFalse);
      expect(state.hasComputedChart, isFalse);
      expect(state.computedReport, isNull);
      expect(state.firstName, isEmpty);
    });

    test('restoreSession runs at most once', () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(sessionRepository: repository);

      await state.restoreSession();
      await state.restoreSession();

      expect(repository.loadCalls, 1);
    });

    test('restoreSession drops an unparseable report and falls back', () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(
          reportJson: <String, dynamic>{'totally': 'broken'},
        ),
      );
      final state = BirthInputState(sessionRepository: repository);

      await state.restoreSession();

      expect(state.onboardingCompleted, isFalse);
      expect(state.computedReport, isNull);
      expect(repository.clearCalls, greaterThanOrEqualTo(1));
    });

    test('completeOnboarding persists the full session', () async {
      final repository = _MemoryBirthSessionRepository();
      final state = BirthInputState(sessionRepository: repository);
      state.updateFirstName('Asha');
      state.updateDateOfBirth('1999-07-04', clearComputed: false);
      state.updateTimeOfBirth('12:22', clearComputed: false);
      state.updatePlaceOfBirth(
        'Mumbai, Maharashtra, India',
        clearComputed: false,
      );
      state.markReportComputed(_sampleReport());

      state.completeOnboarding();
      await _settle();

      expect(repository.saveCalls, greaterThanOrEqualTo(1));
      expect(repository.session, isNotNull);
      expect(repository.session!.onboardingCompleted, isTrue);
      expect(repository.session!.dateOfBirth, '1999-07-04');
      expect(repository.session!.reportJson.isNotEmpty, isTrue);
    });

    test('markReportComputed persists when onboarding is already complete',
        () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(sessionRepository: repository);
      await state.restoreSession();
      repository.saveCalls = 0;

      state.markReportComputed(_sampleReport());
      await _settle();

      expect(repository.saveCalls, greaterThanOrEqualTo(1));
      expect(repository.session, isNotNull);
      expect(repository.session!.onboardingCompleted, isTrue);
    });

    test('clearComputedChart clears the persisted session', () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(sessionRepository: repository);
      await state.restoreSession();

      state.clearComputedChart();
      await _settle();

      expect(repository.clearCalls, greaterThanOrEqualTo(1));
      expect(repository.session, isNull);
    });

    test('applying a saved profile clears the persisted session', () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(
        profilesRepository: _MemorySavedProfilesRepository(
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
              name: 'Tokyo',
              date: '2005-06-21',
              time: '15:10',
              place: 'Tokyo, Japan',
              timezone: 'Asia/Tokyo',
            ),
          ],
        ),
        sessionRepository: repository,
      );
      await state.restoreSession();
      await state.loadSavedProfiles();

      state.applyProfile('p2');
      await _settle();

      expect(repository.clearCalls, greaterThanOrEqualTo(1));
      expect(repository.session, isNull);
    });

    test('loadSavedProfiles does not clobber a restored session', () async {
      final sessionRepository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final profilesRepository = _MemorySavedProfilesRepository(
        initialProfiles: <SavedBirthProfile>[
          _profile(
            id: 'p1',
            name: 'Tokyo',
            date: '2005-06-21',
            time: '15:10',
            place: 'Tokyo, Japan',
            timezone: 'Asia/Tokyo',
            isDefault: true,
          ),
        ],
      );
      final state = BirthInputState(
        profilesRepository: profilesRepository,
        sessionRepository: sessionRepository,
      );

      await state.restoreSession();
      await state.loadSavedProfiles();

      // The restored session (Asha / 1999-07-04) must survive: the default
      // profile is auto-applied only when the current input is empty.
      expect(state.firstName, 'Asha');
      expect(state.dateOfBirth, '1999-07-04');
      expect(state.timeOfBirth, '12:22');
      expect(state.placeOfBirth, 'Mumbai, Maharashtra, India');
      expect(state.onboardingCompleted, isTrue);
      expect(state.computedReport, isNotNull);
      // The saved profile is still loaded and available, just not applied.
      expect(state.savedProfiles.length, 1);
    });

    test('markReportComputed without rawJson clears rather than persists',
        () async {
      final repository = _MemoryBirthSessionRepository(
        session: _completedSession(),
      );
      final state = BirthInputState(sessionRepository: repository);
      await state.restoreSession();
      expect(repository.session, isNotNull);
      repository.clearCalls = 0;

      // A report that was not decoded from a response carries no rawJson and so
      // cannot be re-encoded; persisting it would leave an unrestorable
      // half-session, so the cache is cleared instead.
      state.markReportComputed(_reportWithoutRawJson());
      await _settle();

      expect(repository.session, isNull);
      expect(repository.clearCalls, greaterThanOrEqualTo(1));
    });
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

ComputeReportResponse _sampleReport() {
  return ComputeReportResponse.fromJson(sampleReportJson());
}

ComputeReportResponse _reportWithoutRawJson() {
  final base = ComputeReportResponse.fromJson(sampleReportJson());
  return ComputeReportResponse(
    profile: base.profile,
    normalizedInput: base.normalizedInput,
    resolvedPlace: base.resolvedPlace,
    snapshot: base.snapshot,
    dasha: base.dasha,
    interpretations: base.interpretations,
    dailyTransit: base.dailyTransit,
  );
}

BirthSession _completedSession({Map<String, dynamic>? reportJson}) {
  return BirthSession(
    onboardingCompleted: true,
    firstName: 'Asha',
    gender: PersonGender.female,
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: 'Mumbai, Maharashtra, India',
    customPlace: const CustomPlacePayload(
      placeLabel: 'Mumbai, Maharashtra, India',
      latitude: 19.076,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
      elevationM: 14,
    ),
    reportJson: reportJson ?? sampleReportJson(),
  );
}

class _MemoryBirthSessionRepository implements BirthSessionRepository {
  _MemoryBirthSessionRepository({this.session});

  BirthSession? session;
  int loadCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<BirthSession?> loadSession() async {
    loadCalls += 1;
    return session;
  }

  @override
  Future<void> saveSession(BirthSession session) async {
    saveCalls += 1;
    this.session = session;
  }

  @override
  Future<void> clearSession() async {
    clearCalls += 1;
    session = null;
  }
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

import 'custom_place_payload.dart';
import 'person_gender.dart';

/// The persisted snapshot of a completed onboarding session: the birth inputs
/// the user entered plus the report computed for them.
///
/// [reportJson] is the raw decoded compute-report response map (see
/// `ComputeReportResponse.rawJson`). It is stored verbatim so the report can be
/// re-hydrated with `ComputeReportResponse.fromJson` on restore, avoiding a
/// hand-written `toJson` for the whole report model tree. This model lives in
/// the app layer and intentionally does not depend on the feature models that
/// know how to parse that map.
class BirthSession {
  const BirthSession({
    required this.onboardingCompleted,
    required this.firstName,
    required this.gender,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.customPlace,
    required this.reportJson,
  });

  final bool onboardingCompleted;
  final String firstName;
  final PersonGender gender;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;
  final Map<String, dynamic> reportJson;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'onboarding_completed': onboardingCompleted,
      'first_name': firstName.trim(),
      'gender': gender.storageValue,
      'date_of_birth': dateOfBirth.trim(),
      'time_of_birth': timeOfBirth.trim(),
      'place_of_birth': placeOfBirth.trim(),
      'custom_place': customPlace?.sanitized().toJson(),
      'report': reportJson,
    };
  }

  factory BirthSession.fromJson(Map<String, dynamic> json) {
    final rawCustomPlace = json['custom_place'];
    final customPlaceMap = rawCustomPlace is Map
        ? rawCustomPlace.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          )
        : null;

    final rawReport = json['report'];
    if (rawReport is! Map) {
      throw const FormatException('Field "report" must be an object');
    }
    final reportMap = rawReport.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), value),
    );

    return BirthSession(
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? false,
      firstName: (json['first_name'] as String?) ?? '',
      gender: PersonGender.fromStorageValue(json['gender'] as String?),
      dateOfBirth: (json['date_of_birth'] as String?) ?? '',
      timeOfBirth: (json['time_of_birth'] as String?) ?? '',
      placeOfBirth: (json['place_of_birth'] as String?) ?? '',
      customPlace: customPlaceMap == null
          ? null
          : CustomPlacePayload.fromJson(customPlaceMap),
      reportJson: reportMap,
    );
  }
}

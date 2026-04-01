import 'custom_place_payload.dart';

class SavedBirthProfile {
  const SavedBirthProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.createdAtUtcIso,
    required this.updatedAtUtcIso,
    this.customPlace,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;
  final bool isDefault;
  final String createdAtUtcIso;
  final String updatedAtUtcIso;

  SavedBirthProfile copyWith({
    String? id,
    String? name,
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    CustomPlacePayload? customPlace,
    bool clearCustomPlace = false,
    bool? isDefault,
    String? createdAtUtcIso,
    String? updatedAtUtcIso,
  }) {
    return SavedBirthProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      customPlace: clearCustomPlace ? null : (customPlace ?? this.customPlace),
      isDefault: isDefault ?? this.isDefault,
      createdAtUtcIso: createdAtUtcIso ?? this.createdAtUtcIso,
      updatedAtUtcIso: updatedAtUtcIso ?? this.updatedAtUtcIso,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      'custom_place': customPlace?.toJson(),
      'is_default': isDefault,
      'created_at_utc_iso': createdAtUtcIso,
      'updated_at_utc_iso': updatedAtUtcIso,
    };
  }

  factory SavedBirthProfile.fromJson(Map<String, dynamic> json) {
    final rawCustomPlace = json['custom_place'];
    final customPlaceMap = rawCustomPlace is Map
        ? rawCustomPlace.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          )
        : null;

    return SavedBirthProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      dateOfBirth: (json['date_of_birth'] as String?) ?? '',
      timeOfBirth: (json['time_of_birth'] as String?) ?? '',
      placeOfBirth: (json['place_of_birth'] as String?) ?? '',
      customPlace: customPlaceMap == null
          ? null
          : CustomPlacePayload.fromJson(customPlaceMap),
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAtUtcIso: (json['created_at_utc_iso'] as String?) ?? '',
      updatedAtUtcIso: (json['updated_at_utc_iso'] as String?) ?? '',
    );
  }
}

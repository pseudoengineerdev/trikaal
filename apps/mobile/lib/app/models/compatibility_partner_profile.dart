import 'custom_place_payload.dart';
import 'person_gender.dart';

class CompatibilityPartnerProfile {
  const CompatibilityPartnerProfile({
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.customPlace,
  });

  final String name;
  final PersonGender gender;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;

  bool get isComplete {
    return name.trim().isNotEmpty &&
        gender != PersonGender.unspecified &&
        dateOfBirth.trim().isNotEmpty &&
        timeOfBirth.trim().isNotEmpty &&
        placeOfBirth.trim().isNotEmpty;
  }
}

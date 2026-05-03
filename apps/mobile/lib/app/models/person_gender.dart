enum PersonGender {
  male('male'),
  female('female'),
  unspecified('unspecified');

  const PersonGender(this.storageValue);

  final String storageValue;

  static PersonGender fromStorageValue(String? raw) {
    if (raw == null) {
      return PersonGender.unspecified;
    }
    return PersonGender.values.firstWhere(
      (PersonGender value) => value.storageValue == raw,
      orElse: () => PersonGender.unspecified,
    );
  }
}

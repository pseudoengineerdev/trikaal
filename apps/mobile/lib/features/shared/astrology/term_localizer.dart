import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/terminology_mode_state.dart';

const Map<String, String> _vedicRashi = <String, String>{
  'Mesh': 'Mesha',
  'Vrish': 'Vrishabha',
  'Mith': 'Mithuna',
  'Mitu': 'Mithuna',
  'Kark': 'Karka',
  'Simh': 'Simha',
  'Kany': 'Kanya',
  'Tula': 'Tula',
  'Vrsc': 'Vrischika',
  'Dhanu': 'Dhanu',
  'Makar': 'Makara',
  'Maka': 'Makara',
  'Kumb': 'Kumbha',
  'Meen': 'Meena',
};

const Map<String, String> _englishRashi = <String, String>{
  'Mesh': 'Aries',
  'Vrish': 'Taurus',
  'Mith': 'Gemini',
  'Mitu': 'Gemini',
  'Kark': 'Cancer',
  'Simh': 'Leo',
  'Kany': 'Virgo',
  'Tula': 'Libra',
  'Vrsc': 'Scorpio',
  'Dhanu': 'Sagittarius',
  'Makar': 'Capricorn',
  'Maka': 'Capricorn',
  'Kumb': 'Aquarius',
  'Meen': 'Pisces',
};

const Map<String, String> _vedicNakshatra = <String, String>{
  'Ashwini': 'Ashwini',
  'Bharani': 'Bharani',
  'Krittika': 'Krittika',
  'Rohini': 'Rohini',
  'Mrigashirsha': 'Mrigashirsha',
  'Ardra': 'Ardra',
  'Punarvasu': 'Punarvasu',
  'Pushya': 'Pushya',
  'Ashlesha': 'Ashlesha',
  'Magha': 'Magha',
  'P Phalguni': 'Purva Phalguni',
  'U Phalguni': 'Uttara Phalguni',
  'Hasta': 'Hasta',
  'Chitra': 'Chitra',
  'Swati': 'Swati',
  'Vishakha': 'Vishakha',
  'Anuradha': 'Anuradha',
  'Jyeshtha': 'Jyeshtha',
  'Mula': 'Mula',
  'P Ashadha': 'Purva Ashadha',
  'U Ashadha': 'Uttara Ashadha',
  'Shravana': 'Shravana',
  'Dhanishta': 'Dhanishta',
  'Shatabhisha': 'Shatabhisha',
  'P Bhadrapada': 'Purva Bhadrapada',
  'U Bhadrapada': 'Uttara Bhadrapada',
  'Revati': 'Revati',
};

const Map<String, String> _englishNakshatra = <String, String>{
  'Ashwini': "Ashwini (Horse's Head)",
  'Bharani': 'Bharani (The Bearer)',
  'Krittika': 'Krittika (The Cutters)',
  'Rohini': 'Rohini (The Red One)',
  'Mrigashirsha': "Mrigashira (Deer's Head)",
  'Ardra': 'Ardra (The Moist One)',
  'Punarvasu': 'Punarvasu (Return of Light)',
  'Pushya': 'Pushya (The Nourisher)',
  'Ashlesha': 'Ashlesha (The Entwiner)',
  'Magha': 'Magha (The Mighty)',
  'P Phalguni': 'Purva Phalguni (Former Reddish)',
  'U Phalguni': 'Uttara Phalguni (Latter Reddish)',
  'Hasta': 'Hasta (The Hand)',
  'Chitra': 'Chitra (The Bright One)',
  'Swati': 'Swati (The Independent)',
  'Vishakha': 'Vishakha (Forked Branches)',
  'Anuradha': 'Anuradha (Following Radha)',
  'Jyeshtha': 'Jyeshtha (The Eldest)',
  'Mula': 'Mula (The Root)',
  'P Ashadha': 'Purva Ashadha (Former Invincible)',
  'U Ashadha': 'Uttara Ashadha (Latter Invincible)',
  'Shravana': 'Shravana (The Ear)',
  'Dhanishta': 'Dhanishta (The Wealthy)',
  'Shatabhisha': 'Shatabhisha (Hundred Healers)',
  'P Bhadrapada': 'Purva Bhadrapada (Former Blessed Feet)',
  'U Bhadrapada': 'Uttara Bhadrapada (Latter Blessed Feet)',
  'Revati': 'Revati (The Prosperous)',
};

const Map<String, String> _vedicGraha = <String, String>{
  'sun': 'Surya',
  'moon': 'Chandra',
  'mangal': 'Mangal',
  'budha': 'Budha',
  'guru': 'Guru',
  'shukra': 'Shukra',
  'shani': 'Shani',
  'rahu': 'Rahu',
  'ketu': 'Ketu',
  'lagna': 'Lagna',
  'Surya': 'Surya',
  'Chandra': 'Chandra',
  'Mangal': 'Mangal',
  'Budha': 'Budha',
  'Guru': 'Guru',
  'Shukra': 'Shukra',
  'Shani': 'Shani',
  'Rahu': 'Rahu',
  'Ketu': 'Ketu',
  'Lagna': 'Lagna',
};

const Map<String, String> _englishGraha = <String, String>{
  'sun': 'Sun',
  'moon': 'Moon',
  'mangal': 'Mars',
  'budha': 'Mercury',
  'guru': 'Jupiter',
  'shukra': 'Venus',
  'shani': 'Saturn',
  'rahu': 'Rahu',
  'ketu': 'Ketu',
  'lagna': 'Ascendant',
  'Surya': 'Sun',
  'Chandra': 'Moon',
  'Mangal': 'Mars',
  'Budha': 'Mercury',
  'Guru': 'Jupiter',
  'Shukra': 'Venus',
  'Shani': 'Saturn',
  'Rahu': 'Rahu',
  'Ketu': 'Ketu',
  'Lagna': 'Ascendant',
};

String localizeRashi(
  String raw,
  TerminologyMode mode, {
  AstrologyTermsState? termsState,
}) {
  final remote = _lookupFromTermsState(
    termsState: termsState,
    category: 'rashi',
    key: raw,
    mode: mode,
  );
  if (remote != null) {
    return remote;
  }
  if (mode == TerminologyMode.vedic) {
    return _vedicRashi[raw] ?? raw;
  }
  return _englishRashi[raw] ?? raw;
}

String localizeNakshatra(
  String raw,
  TerminologyMode mode, {
  AstrologyTermsState? termsState,
}) {
  final remote = _lookupFromTermsState(
    termsState: termsState,
    category: 'nakshatra',
    key: raw,
    mode: mode,
  );
  if (remote != null) {
    return remote;
  }
  if (mode == TerminologyMode.vedic) {
    return _vedicNakshatra[raw] ?? raw;
  }
  return _englishNakshatra[raw] ?? raw;
}

String localizeGraha(
  String raw,
  TerminologyMode mode, {
  AstrologyTermsState? termsState,
}) {
  final remote = _lookupFromTermsState(
    termsState: termsState,
    category: 'graha',
    key: raw,
    mode: mode,
  );
  if (remote != null) {
    return remote;
  }
  if (mode == TerminologyMode.vedic) {
    return _vedicGraha[raw] ?? raw;
  }
  return _englishGraha[raw] ?? raw;
}

String? _lookupFromTermsState({
  required AstrologyTermsState? termsState,
  required String category,
  required String key,
  required TerminologyMode mode,
}) {
  if (termsState == null || !termsState.loaded) {
    return null;
  }
  final field = mode == TerminologyMode.vedic ? 'vedic' : 'english';
  return termsState.lookup(category: category, key: key, field: field);
}

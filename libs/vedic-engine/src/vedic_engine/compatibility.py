from __future__ import annotations

from dataclasses import dataclass
from typing import Any

_RASHI_SEQUENCE = (
    "Mesh",
    "Vrish",
    "Mith",
    "Kark",
    "Simh",
    "Kany",
    "Tula",
    "Vrsc",
    "Dhanu",
    "Makar",
    "Kumb",
    "Meen",
)

_RASHI_ALIASES = {
    "Mesh": "Mesh",
    "Vrish": "Vrish",
    "Mith": "Mith",
    "Mitu": "Mith",
    "Kark": "Kark",
    "Simh": "Simh",
    "Kany": "Kany",
    "Tula": "Tula",
    "Vrsc": "Vrsc",
    "Dhanu": "Dhanu",
    "Makar": "Makar",
    "Maka": "Makar",
    "Kumb": "Kumb",
    "Meen": "Meen",
}

_RASHI_TO_INDEX = {name: idx + 1 for idx, name in enumerate(_RASHI_SEQUENCE)}

# Ashta-kuta max points in canonical order.
_KUTA_WEIGHTS = (
    ("varna", "Varna", 1.0),
    ("vashya", "Vashya", 2.0),
    ("tara", "Tara", 3.0),
    ("yoni", "Yoni", 4.0),
    ("graha_maitri", "Graha Maitri", 5.0),
    ("gana", "Gana", 6.0),
    ("bhakoot", "Bhakoot", 7.0),
    ("nadi", "Nadi", 8.0),
)

_BHAKOOT_MAX_SCORE = 7.0
_NADI_MAX_SCORE = 8.0

# Moon-rashi to varna index (0 highest .. 3 lowest) per Reference tutorial mapping.
_VARNA_BY_RASHI = {
    1: 1,   # Mesh  -> Kshatriya
    2: 2,   # Vrish -> Vaishya
    3: 3,   # Mith  -> Shudra
    4: 0,   # Kark  -> Brahmin
    5: 1,   # Simh  -> Kshatriya
    6: 2,   # Kany  -> Vaishya
    7: 3,   # Tula  -> Shudra
    8: 0,   # Vrsc  -> Brahmin
    9: 1,   # Dhanu -> Kshatriya
    10: 2,  # Makar -> Vaishya
    11: 3,  # Kumb  -> Shudra
    12: 0,  # Meen  -> Brahmin
}

_VARNA_NAMES = ("Brahmin", "Kshatriya", "Vaishya", "Shudra")

_VASHYA_CATEGORIES = (
    "Chatushpada",
    "Manava",
    "Jalachara",
    "Vanachara",
    "Keet",
)

_VASHYA_MATRIX = (
    (2.0, 1.0, 1.0, 0.0, 1.0),
    (1.0, 2.0, 0.5, 0.0, 1.0),
    (1.0, 0.5, 2.0, 1.0, 1.0),
    (0.0, 0.0, 1.0, 2.0, 0.0),
    (1.0, 1.0, 1.0, 0.0, 2.0),
)

_YONI_MAPPING_BY_NAKSHATRA = (
    0,
    1,
    2,
    3,
    3,
    4,
    5,
    2,
    5,
    6,
    6,
    7,
    8,
    9,
    8,
    9,
    10,
    10,
    4,
    11,
    12,
    11,
    13,
    0,
    13,
    7,
    1,
)

_YONI_NAMES = (
    "Horse",
    "Elephant",
    "Sheep",
    "Serpent",
    "Dog",
    "Cat",
    "Rat",
    "Cow",
    "Buffalo",
    "Tiger",
    "Hare",
    "Monkey",
    "Mongoose",
    "Lion",
)

_YONI_MATRIX = (
    (4.0, 2.0, 3.0, 1.0, 2.0, 3.0, 3.0, 3.0, 0.0, 1.0, 3.0, 2.0, 2.0, 1.0),
    (2.0, 4.0, 2.0, 2.0, 2.0, 3.0, 2.0, 2.0, 2.0, 1.0, 2.0, 2.0, 2.0, 0.0),
    (3.0, 2.0, 4.0, 1.0, 2.0, 3.0, 2.0, 3.0, 3.0, 1.0, 3.0, 0.0, 3.0, 1.0),
    (1.0, 2.0, 1.0, 4.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 1.0, 1.0, 0.0, 2.0),
    (2.0, 2.0, 2.0, 1.0, 4.0, 1.0, 1.0, 1.0, 2.0, 1.0, 0.0, 2.0, 1.0, 1.0),
    (3.0, 3.0, 3.0, 1.0, 1.0, 4.0, 0.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0),
    (3.0, 2.0, 2.0, 1.0, 1.0, 0.0, 4.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0),
    (3.0, 2.0, 3.0, 1.0, 1.0, 2.0, 2.0, 4.0, 3.0, 0.0, 2.0, 2.0, 2.0, 1.0),
    (0.0, 3.0, 3.0, 2.0, 2.0, 2.0, 2.0, 3.0, 4.0, 1.0, 2.0, 2.0, 2.0, 1.0),
    (1.0, 1.0, 1.0, 2.0, 1.0, 2.0, 2.0, 0.0, 1.0, 4.0, 1.0, 1.0, 2.0, 2.0),
    (3.0, 2.0, 3.0, 1.0, 0.0, 2.0, 2.0, 2.0, 3.0, 1.0, 4.0, 2.0, 2.0, 1.0),
    (2.0, 2.0, 0.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0, 2.0, 4.0, 2.0, 2.0),
    (2.0, 2.0, 3.0, 0.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 2.0),
    (1.0, 0.0, 1.0, 2.0, 1.0, 2.0, 1.0, 1.0, 1.0, 2.0, 1.0, 2.0, 2.0, 4.0),
)

_GANA_BY_NAKSHATRA = (
    0,  # Ashwini
    1,
    2,
    1,
    0,
    1,
    0,
    0,
    2,
    2,
    1,
    1,
    0,
    2,
    0,
    2,
    0,
    2,
    2,
    1,
    1,
    0,
    2,
    2,
    1,
    1,
    0,
)

_GANA_NAMES = ("Deva", "Manushya", "Rakshasa")

_GANA_MATRIX = (
    (6.0, 5.0, 1.0),
    (6.0, 6.0, 0.0),
    (0.0, 0.0, 6.0),
)

# Sign lord index by rashi number (Sun=0, Moon=1, Mars=2, Mercury=3, Jupiter=4, Venus=5, Saturn=6).
_SIGN_LORD_BY_RASHI = (
    2,
    5,
    3,
    1,
    0,
    3,
    5,
    2,
    4,
    6,
    6,
    4,
)

_LORD_NAMES = ("Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn")

_GRAHA_MAITRI_MATRIX = (
    (5.0, 5.0, 5.0, 4.0, 5.0, 0.0, 0.0),
    (5.0, 5.0, 4.0, 1.0, 4.0, 0.5, 0.5),
    (5.0, 4.0, 5.0, 0.5, 5.0, 3.0, 0.5),
    (4.0, 1.0, 0.5, 5.0, 0.5, 5.0, 4.0),
    (5.0, 4.0, 5.0, 0.5, 5.0, 0.5, 3.0),
    (0.0, 0.5, 3.0, 5.0, 0.5, 5.0, 5.0),
    (0.0, 0.5, 0.5, 4.0, 3.0, 5.0, 5.0),
)

_NADI_GROUP_BY_NAKSHATRA = (
    0,
    1,
    2,
    2,
    1,
    0,
    0,
    1,
    2,
    2,
    1,
    0,
    0,
    1,
    2,
    2,
    1,
    0,
    0,
    1,
    2,
    2,
    1,
    0,
    0,
    1,
    2,
)

_NADI_NAMES = ("Adi", "Madhya", "Antya")

_RASHI_DISPLAY_NAMES = (
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
)

_GANA_DISPLAY_NAMES = ("Deva", "Manava", "Rakshasa")
_NADI_DISPLAY_NAMES = ("Aadi", "Madhya", "Antya")

_TARA_NAMES = {
    1: "Janma",
    2: "Sampat",
    3: "Vipat",
    4: "Kshema",
    5: "Pratyari",
    6: "Sadhaka",
    7: "Naidhana",
    8: "Mitra",
    0: "Parama Mitra",
}

_KUTA_AREA_OF_LIFE = {
    "varna": "Obedience",
    "vashya": "Mutual Control",
    "tara": "Luck",
    "yoni": "Sexual Aspects",
    "graha_maitri": "Affection",
    "gana": "Nature",
    "bhakoot": "Love",
    "nadi": "Health",
}

_KUTA_DESCRIPTIONS = {
    "varna": (
        "Varna Kuta is assigned 1 point. It reflects mutual love, comfort, obedience, "
        "and the grade of spiritual development."
    ),
    "vashya": (
        "Vashya Kuta is assigned 2 points. It reflects mutual control or dominance, "
        "plus friendship and amenability between the couple."
    ),
    "tara": (
        "Tara Kuta is assigned 3 points. It reflects luck, auspiciousness, and mutual "
        "benefic support in the relationship."
    ),
    "yoni": (
        "Yoni Kuta is assigned 4 points. It reflects sexual and physical compatibility, "
        "including attraction and intimate comfort."
    ),
    "graha_maitri": (
        "Graha Maitri Kuta is assigned 5 points. It reflects psychological disposition, "
        "mental qualities, and affection between partners."
    ),
    "gana": (
        "Gana Kuta is assigned 6 points. It reflects nature, temperament, prosperity, "
        "longevity, and harmony in behavior."
    ),
    "bhakoot": (
        "Bhakoot Kuta is assigned 7 points. It reflects family growth, comforts, "
        "well-being, and long-term relationship support."
    ),
    "nadi": (
        "Nadi Kuta is assigned 8 points. It reflects temperament, vitality, and health "
        "compatibility, and is treated as a high-priority factor in matching."
    ),
}

_ELEMENT_BY_RASHI_INDEX = {
    1: "Fire",
    2: "Earth",
    3: "Air",
    4: "Water",
    5: "Fire",
    6: "Earth",
    7: "Air",
    8: "Water",
    9: "Fire",
    10: "Earth",
    11: "Air",
    12: "Water",
}

_MANGAL_DOSHA_HOUSES = {1, 2, 4, 7, 8, 12}
_MANGAL_DOSHA_HOUSES_SORTED = tuple(sorted(_MANGAL_DOSHA_HOUSES))
_MANGAL_DOSHA_RULE_PROFILE_ID = "mangal_dosha_v2"
_MANGAL_DOSHA_METHOD = (
    "mars_in_1_2_4_7_8_12_from_lagna_moon_venus_with_house_sign_exceptions"
)
_MANGAL_DOSHA_REFERENCE_LABELS = {
    "lagna": "Lagna",
    "moon": "Moon",
    "venus": "Venus",
}
_MANGAL_DOSHA_HOUSE_SIGN_EXCEPTION_RULES: dict[tuple[int, int], tuple[str, str]] = {
    (1, 1): ("house_1_mesha_exception", "Mangal in Mesha coinciding First House"),
    (2, 3): (
        "house_2_mercury_sign_exception",
        "Mangal in Mithuna coinciding Second House",
    ),
    (2, 6): (
        "house_2_mercury_sign_exception",
        "Mangal in Kanya coinciding Second House",
    ),
    (4, 1): ("house_4_mars_sign_exception", "Mangal in Mesha coinciding Fourth House"),
    (4, 8): (
        "house_4_mars_sign_exception",
        "Mangal in Vrishchika coinciding Fourth House",
    ),
    (7, 4): (
        "house_7_cancer_capricorn_exception",
        "Mangal in Karka coinciding Seventh House",
    ),
    (7, 10): (
        "house_7_cancer_capricorn_exception",
        "Mangal in Makara coinciding Seventh House",
    ),
    (8, 9): (
        "house_8_jupiter_sign_exception",
        "Mangal in Dhanu coinciding Eighth House",
    ),
    (8, 12): (
        "house_8_jupiter_sign_exception",
        "Mangal in Meena coinciding Eighth House",
    ),
    (12, 2): (
        "house_12_venus_sign_exception",
        "Mangal in Vrishabha coinciding Twelfth House",
    ),
    (12, 7): ("house_12_venus_sign_exception", "Mangal in Tula coinciding Twelfth House"),
    (12, 9): (
        "house_12_dhanu_muhurta_exception",
        "Mangal in Dhanu coinciding Twelfth House *as per Muhurta Deepak",
    ),
}
_MANGAL_DOSHA_BASE_PERCENT_BY_HOUSE = {
    12: 50,
    1: 60,
    2: 80,
    4: 80,
    7: 100,
    8: 100,
}
_MANGAL_DOSHA_HELPER_PLANETS = ("shani", "sun", "rahu", "ketu")
_MANGAL_DOSHA_HELPER_PLANET_RASHI_FIELDS = {
    "sun": "sun_rashi",
    "shani": "shani_rashi",
    "rahu": "rahu_rashi",
    "ketu": "ketu_rashi",
}
_MANGAL_DOSHA_HELPER_PLANET_LABELS = {
    "sun": "Surya",
    "shani": "Shani",
    "rahu": "Rahu",
    "ketu": "Ketu",
}
_MANGAL_DOSHA_JUPITER_CANCELLATION_ASPECTS = (5, 7, 9)
_MANGAL_DOSHA_ANY_HOUSE_EXCEPTION_BY_RASHI = {
    5: (
        "simha_any_house_exception",
        "Mangal in Simha coinciding any House creating Dosha",
    ),
    11: (
        "kumbha_any_house_exception",
        "Mangal in Kumbha coinciding any House creating Dosha",
    ),
}
_MANGAL_DOSHA_CONJUNCTION_PLANETS = {
    "guru_rashi": (
        "jupiter_conjunction_cancellation",
        "Brihaspati conjoins Mangal",
    ),
    "moon_rashi": ("moon_conjunction_cancellation", "Chandra conjoins Mangal"),
    "rahu_rashi": ("rahu_conjunction_cancellation", "Rahu conjoins Mangal"),
}
_HOUSE_ORDINAL_LABELS = {
    1: "First",
    2: "Second",
    3: "Third",
    4: "Fourth",
    5: "Fifth",
    6: "Sixth",
    7: "Seventh",
    8: "Eighth",
    9: "Ninth",
    10: "Tenth",
    11: "Eleventh",
    12: "Twelfth",
}
_KAAL_SARPA_RULE_PROFILE_ID = "kaal_sarpa_dosha_v1"
_KAAL_SARPA_METHOD = "all_seven_classical_planets_within_rahu_ketu_axis_no_partial"
_KAAL_SARPA_CLASSICAL_PLANETS = (
    "sun",
    "moon",
    "mangal",
    "budha",
    "guru",
    "shukra",
    "shani",
)
_KAAL_SARPA_TYPE_BY_RAHU_HOUSE = {
    1: "Ananta",
    2: "Kulika",
    3: "Vasuki",
    4: "Sankhapala",
    5: "Padma",
    6: "Maha Padma",
    7: "Takshaka",
    8: "Karkotaka",
    9: "Shankhachura",
    10: "Ghataka",
    11: "Vishadhara",
    12: "Sheshanaga",
}


@dataclass(frozen=True)
class _MoonProfile:
    rashi_index: int
    rashi_code: str
    nakshatra_number: int
    pada: int
    moon_degree_in_rashi: float


def compute_kundali_compatibility(
    *,
    boy_snapshot: dict[str, Any],
    girl_snapshot: dict[str, Any],
) -> dict[str, Any]:
    boy = _moon_profile_from_snapshot(boy_snapshot)
    girl = _moon_profile_from_snapshot(girl_snapshot)
    ashta = _compute_ashta_kuta(boy=boy, girl=girl)
    manglik = _compute_manglik_pair(boy_snapshot=boy_snapshot, girl_snapshot=girl_snapshot)
    kaal_sarpa = _compute_kaal_sarpa_pair(
        boy_snapshot=boy_snapshot,
        girl_snapshot=girl_snapshot,
    )
    d1_d9 = _compute_d1_d9_checks(boy_snapshot=boy_snapshot, girl_snapshot=girl_snapshot)

    return {
        "version": "v1",
        "ashta_kuta": ashta,
        "manglik": manglik,
        "kaal_sarpa": kaal_sarpa,
        "d1_d9": d1_d9,
        "summary": {
            "overall_band": _overall_band(ashta["total_score"]),
            "guna_score": ashta["total_score"],
            "guna_score_max": 36.0,
            "manglik_alignment": manglik["pair_alignment"],
            "nadi_match": ashta["nadi_match"],
            "bhakoot_match": ashta["bhakoot_match"],
        },
    }


def _compute_kaal_sarpa_pair(
    *,
    boy_snapshot: dict[str, Any],
    girl_snapshot: dict[str, Any],
) -> dict[str, Any]:
    boy = compute_kaal_sarpa_for_snapshot(boy_snapshot)
    girl = compute_kaal_sarpa_for_snapshot(girl_snapshot)
    same_status = bool(boy["is_kaal_sarpa"]) == bool(girl["is_kaal_sarpa"])
    pair_alignment = "Balanced" if same_status else "Unbalanced"
    if same_status:
        verdict = "Kaal Sarpa status is aligned between both charts."
    else:
        verdict = "Kaal Sarpa status differs between the two charts."
    return {
        "rule_profile_id": _KAAL_SARPA_RULE_PROFILE_ID,
        "method": _KAAL_SARPA_METHOD,
        "pair_alignment": pair_alignment,
        "verdict": verdict,
        "evidence": {
            "same_kaal_sarpa_status": same_status,
            "boy_outside_planet_count": int(boy["outside_planet_count"]),
            "girl_outside_planet_count": int(girl["outside_planet_count"]),
        },
        "boy": boy,
        "girl": girl,
    }


def compute_kaal_sarpa_for_snapshot(snapshot: dict[str, Any]) -> dict[str, Any]:
    rahu_degree = _planet_sidereal_degree(snapshot=snapshot, planet_key="rahu")
    ketu_degree = _planet_sidereal_degree(snapshot=snapshot, planet_key="ketu")

    per_planet: dict[str, dict[str, Any]] = {}
    for planet_key in _KAAL_SARPA_CLASSICAL_PLANETS:
        degree = _planet_sidereal_degree(snapshot=snapshot, planet_key=planet_key)
        in_rahu_to_ketu = _degree_on_axis_arc(
            start_degree=rahu_degree,
            end_degree=ketu_degree,
            target_degree=degree,
        )
        in_ketu_to_rahu = _degree_on_axis_arc(
            start_degree=ketu_degree,
            end_degree=rahu_degree,
            target_degree=degree,
        )
        per_planet[planet_key] = {
            "sidereal_degree": _round_2(degree),
            "within_rahu_to_ketu_arc": in_rahu_to_ketu,
            "within_ketu_to_rahu_arc": in_ketu_to_rahu,
        }

    outside_from_rahu_to_ketu = [
        planet_key
        for planet_key in _KAAL_SARPA_CLASSICAL_PLANETS
        if not bool(per_planet[planet_key]["within_rahu_to_ketu_arc"])
    ]
    outside_from_ketu_to_rahu = [
        planet_key
        for planet_key in _KAAL_SARPA_CLASSICAL_PLANETS
        if not bool(per_planet[planet_key]["within_ketu_to_rahu_arc"])
    ]
    enclosed_rahu_to_ketu = len(outside_from_rahu_to_ketu) == 0
    enclosed_ketu_to_rahu = len(outside_from_ketu_to_rahu) == 0
    is_kaal_sarpa = enclosed_rahu_to_ketu or enclosed_ketu_to_rahu

    if enclosed_rahu_to_ketu and enclosed_ketu_to_rahu:
        enclosed_side = "both_sides"
        outside_planets: list[str] = []
    elif enclosed_rahu_to_ketu:
        enclosed_side = "rahu_to_ketu"
        outside_planets = outside_from_rahu_to_ketu
    elif enclosed_ketu_to_rahu:
        enclosed_side = "ketu_to_rahu"
        outside_planets = outside_from_ketu_to_rahu
    else:
        enclosed_side = "none"
        outside_planets = outside_from_rahu_to_ketu

    outside_planet_count = len(outside_planets)

    rahu_house = _extract_house_from_snapshot(snapshot=snapshot, planet_key="rahu")
    ketu_house = _extract_house_from_snapshot(snapshot=snapshot, planet_key="ketu")
    type_name = _kaal_sarpa_type_name(rahu_house=rahu_house)

    if is_kaal_sarpa:
        verdict = f"Kaal Sarpa Dosha present ({type_name}) with planets enclosed on one side."
    else:
        verdict = "No Kaal Sarpa Dosha: one or more planets are outside the Rahu-Ketu enclosure."

    return {
        "rule_profile_id": _KAAL_SARPA_RULE_PROFILE_ID,
        "method": _KAAL_SARPA_METHOD,
        "is_kaal_sarpa": is_kaal_sarpa,
        "kaal_sarpa_type": type_name if is_kaal_sarpa else "",
        "rahu_house": rahu_house,
        "ketu_house": ketu_house,
        "enclosed_side": enclosed_side,
        "outside_planets": outside_planets,
        "outside_planet_count": outside_planet_count,
        "axis": {
            "rahu_degree": _round_2(rahu_degree),
            "ketu_degree": _round_2(ketu_degree),
            "rahu_to_ketu_enclosure": enclosed_rahu_to_ketu,
            "ketu_to_rahu_enclosure": enclosed_ketu_to_rahu,
        },
        "classical_planets": list(_KAAL_SARPA_CLASSICAL_PLANETS),
        "planet_evidence": per_planet,
        "verdict": verdict,
    }


def _compute_ashta_kuta(*, boy: _MoonProfile, girl: _MoonProfile) -> dict[str, Any]:
    varna_score = _varna_score(boy=boy, girl=girl)
    vashya_score = _vashya_score(boy=boy, girl=girl)
    tara_score = _tara_score(boy=boy, girl=girl)
    yoni_score = _yoni_score(boy=boy, girl=girl)
    graha_maitri_score = _graha_maitri_score(boy=boy, girl=girl)
    gana_score = _gana_score(boy=boy, girl=girl)
    bhakoot_score = _bhakoot_score(boy=boy, girl=girl)
    nadi_score = _nadi_score(boy=boy, girl=girl)
    bhakoot_score, nadi_score = _apply_reference_same_nakshatra_overrides(
        boy=boy,
        girl=girl,
        bhakoot_score=bhakoot_score,
        nadi_score=nadi_score,
    )
    raw_scores = {
        "varna": varna_score,
        "vashya": vashya_score,
        "tara": tara_score,
        "yoni": yoni_score,
        "graha_maitri": graha_maitri_score,
        "gana": gana_score,
        "bhakoot": bhakoot_score,
        "nadi": nadi_score,
    }
    components = []
    for key, label, max_score in _KUTA_WEIGHTS:
        boy_value, girl_value = _kuta_value_labels(key=key, boy=boy, girl=girl)
        components.append(
            {
                "key": key,
                "label": label,
                "score": _round_2(raw_scores[key]),
                "max_score": max_score,
                "percent": _round_2((raw_scores[key] / max_score) * 100.0),
                "boy_value": boy_value,
                "girl_value": girl_value,
                "area_of_life": _KUTA_AREA_OF_LIFE[key],
                "description": _KUTA_DESCRIPTIONS[key],
            }
        )
    total_raw = sum(raw_scores.values())
    total_display = float(int(total_raw))
    return {
        "total_score": total_display,
        "max_score": 36.0,
        "percentage": _round_2((total_display / 36.0) * 100.0),
        "classification": _ashta_classification(total=total_display, bhakoot_score=bhakoot_score),
        "components": components,
        "nadi_match": nadi_score > 0.0,
        "bhakoot_match": bhakoot_score > 0.0,
    }


def _ashta_classification(*, total: float, bhakoot_score: float) -> str:
    # Based on Reference's published ranges for Ashta-kuta interpretation.
    if bhakoot_score <= 0.0:
        if total >= 26.0:
            return "Very Good"
        if total >= 21.0:
            return "Middling"
        return "Inauspicious"
    if total >= 31.0:
        return "Excellent"
    if total >= 21.0:
        return "Very Good"
    if total >= 17.0:
        return "Middling"
    return "Inauspicious"


def _overall_band(score: float) -> str:
    if score >= 31.0:
        return "Excellent"
    if score >= 21.0:
        return "Very Good"
    if score >= 17.0:
        return "Middling"
    return "Inauspicious"


def _varna_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_varna = _VARNA_BY_RASHI[boy.rashi_index]
    girl_varna = _VARNA_BY_RASHI[girl.rashi_index]
    return 1.0 if boy_varna <= girl_varna else 0.0


def _kuta_value_labels(*, key: str, boy: _MoonProfile, girl: _MoonProfile) -> tuple[str, str]:
    if key == "varna":
        boy_varna = _VARNA_BY_RASHI[boy.rashi_index]
        girl_varna = _VARNA_BY_RASHI[girl.rashi_index]
        return _VARNA_NAMES[boy_varna], _VARNA_NAMES[girl_varna]

    if key == "vashya":
        boy_cat = _vashya_category(
            rashi_index=boy.rashi_index,
            moon_degree_in_rashi=boy.moon_degree_in_rashi,
        )
        girl_cat = _vashya_category(
            rashi_index=girl.rashi_index,
            moon_degree_in_rashi=girl.moon_degree_in_rashi,
        )
        return _VASHYA_CATEGORIES[boy_cat], _VASHYA_CATEGORIES[girl_cat]

    if key == "tara":
        from_boy = _count_cycle(start=boy.nakshatra_number, end=girl.nakshatra_number, size=27)
        from_girl = _count_cycle(start=girl.nakshatra_number, end=boy.nakshatra_number, size=27)
        return _tara_name(from_boy % 9), _tara_name(from_girl % 9)

    if key == "yoni":
        boy_yoni = _YONI_MAPPING_BY_NAKSHATRA[boy.nakshatra_number - 1]
        girl_yoni = _YONI_MAPPING_BY_NAKSHATRA[girl.nakshatra_number - 1]
        return _YONI_NAMES[boy_yoni], _YONI_NAMES[girl_yoni]

    if key == "graha_maitri":
        boy_lord = _SIGN_LORD_BY_RASHI[boy.rashi_index - 1]
        girl_lord = _SIGN_LORD_BY_RASHI[girl.rashi_index - 1]
        return _LORD_NAMES[boy_lord], _LORD_NAMES[girl_lord]

    if key == "gana":
        boy_gana = _GANA_BY_NAKSHATRA[boy.nakshatra_number - 1]
        girl_gana = _GANA_BY_NAKSHATRA[girl.nakshatra_number - 1]
        return _GANA_DISPLAY_NAMES[boy_gana], _GANA_DISPLAY_NAMES[girl_gana]

    if key == "bhakoot":
        return (
            _RASHI_DISPLAY_NAMES[boy.rashi_index - 1],
            _RASHI_DISPLAY_NAMES[girl.rashi_index - 1],
        )

    if key == "nadi":
        boy_nadi = _NADI_GROUP_BY_NAKSHATRA[boy.nakshatra_number - 1]
        girl_nadi = _NADI_GROUP_BY_NAKSHATRA[girl.nakshatra_number - 1]
        return _NADI_DISPLAY_NAMES[boy_nadi], _NADI_DISPLAY_NAMES[girl_nadi]

    return "-", "-"


def _vashya_category(*, rashi_index: int, moon_degree_in_rashi: float) -> int:
    if rashi_index in {1, 2}:  # Mesh, Vrish
        return 0
    if rashi_index == 9:  # Dhanu
        return 1 if moon_degree_in_rashi < 15.0 else 0
    if rashi_index == 10:  # Makar
        return 0 if moon_degree_in_rashi < 15.0 else 2
    if rashi_index in {3, 6, 7, 11}:  # Mith, Kany, Tula, Kumb
        return 1
    if rashi_index in {4, 12}:  # Kark, Meen
        return 2
    if rashi_index == 5:  # Simh
        return 3
    return 4  # Vrsc


def _vashya_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_cat = _vashya_category(
        rashi_index=boy.rashi_index,
        moon_degree_in_rashi=boy.moon_degree_in_rashi,
    )
    girl_cat = _vashya_category(
        rashi_index=girl.rashi_index,
        moon_degree_in_rashi=girl.moon_degree_in_rashi,
    )
    return _VASHYA_MATRIX[girl_cat][boy_cat]


def _tara_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    from_girl = _count_cycle(start=girl.nakshatra_number, end=boy.nakshatra_number, size=27)
    from_boy = _count_cycle(start=boy.nakshatra_number, end=girl.nakshatra_number, size=27)
    girl_mod = from_girl % 9
    boy_mod = from_boy % 9
    pair = (girl_mod, boy_mod)
    if pair in {(0, 2), (1, 1), (2, 0)}:
        return 3.0
    if pair in {(3, 8), (4, 7), (5, 6), (6, 5), (7, 4), (8, 3)}:
        return 1.5
    return 0.0


def _yoni_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_yoni = _YONI_MAPPING_BY_NAKSHATRA[boy.nakshatra_number - 1]
    girl_yoni = _YONI_MAPPING_BY_NAKSHATRA[girl.nakshatra_number - 1]
    return _YONI_MATRIX[girl_yoni][boy_yoni]


def _gana_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_gana = _GANA_BY_NAKSHATRA[boy.nakshatra_number - 1]
    girl_gana = _GANA_BY_NAKSHATRA[girl.nakshatra_number - 1]
    return _GANA_MATRIX[girl_gana][boy_gana]


def _graha_maitri_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_lord = _SIGN_LORD_BY_RASHI[boy.rashi_index - 1]
    girl_lord = _SIGN_LORD_BY_RASHI[girl.rashi_index - 1]
    return _GRAHA_MAITRI_MATRIX[girl_lord][boy_lord]


def _bhakoot_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    offset = _count_cycle(start=girl.rashi_index, end=boy.rashi_index, size=12)
    return 7.0 if offset in {1, 3, 4, 7, 10, 11} else 0.0


def _nadi_score(*, boy: _MoonProfile, girl: _MoonProfile) -> float:
    boy_group = _NADI_GROUP_BY_NAKSHATRA[boy.nakshatra_number - 1]
    girl_group = _NADI_GROUP_BY_NAKSHATRA[girl.nakshatra_number - 1]
    return 0.0 if boy_group == girl_group else _NADI_MAX_SCORE


def _tara_name(mod9: int) -> str:
    return _TARA_NAMES.get(mod9, "Unknown")


def _apply_reference_same_nakshatra_overrides(
    *,
    boy: _MoonProfile,
    girl: _MoonProfile,
    bhakoot_score: float,
    nadi_score: float,
) -> tuple[float, float]:
    """Apply Reference-parity exception rules for same-nakshatra matches.

    Observed Reference behavior:
    - Same Nakshatra + same Pada   => Bhakoot 0, Nadi 0.
    - Same Nakshatra + different Pada => Bhakoot 7, Nadi 8.
    """
    if boy.nakshatra_number != girl.nakshatra_number:
        return bhakoot_score, nadi_score
    if boy.pada == girl.pada:
        return 0.0, 0.0
    return _BHAKOOT_MAX_SCORE, _NADI_MAX_SCORE


def _compute_manglik_pair(
    *,
    boy_snapshot: dict[str, Any],
    girl_snapshot: dict[str, Any],
) -> dict[str, Any]:
    boy = _compute_manglik_for_snapshot(boy_snapshot)
    girl = _compute_manglik_for_snapshot(girl_snapshot)
    same_status = boy["is_manglik"] == girl["is_manglik"]

    if same_status:
        score = 8.0
        alignment = "Balanced"
        verdict = "Manglik profile aligned between both charts."
        pair_rule = "same_manglik_status"
    else:
        intensity_gap = abs(boy["trigger_count"] - girl["trigger_count"])
        score = 4.0 if intensity_gap <= 1 else 2.0
        alignment = "Unbalanced"
        verdict = "One chart has stronger Manglik triggers than the other."
        pair_rule = "mismatched_manglik_status"

    return {
        "rule_profile_id": _MANGAL_DOSHA_RULE_PROFILE_ID,
        "method": _MANGAL_DOSHA_METHOD,
        "max_score": 8.0,
        "score": score,
        "pair_alignment": alignment,
        "verdict": verdict,
        "evidence": {
            "pair_rule": pair_rule,
            "boy_trigger_count": int(boy["trigger_count"]),
            "girl_trigger_count": int(girl["trigger_count"]),
            "trigger_count_gap": abs(int(boy["trigger_count"]) - int(girl["trigger_count"])),
            "boy_raw_trigger_count": int(boy["raw_trigger_count"]),
            "girl_raw_trigger_count": int(girl["raw_trigger_count"]),
            "same_manglik_status": same_status,
            "boy_cancellation_applied": bool(boy["cancellation_applied"]),
            "girl_cancellation_applied": bool(girl["cancellation_applied"]),
        },
        "boy": boy,
        "girl": girl,
    }


def _compute_manglik_for_snapshot(snapshot: dict[str, Any]) -> dict[str, Any]:
    graha_table = snapshot["graha_table"]
    vedic = snapshot["vedic"]
    bhava = snapshot["bhava"]

    mars_house_lagna = int(bhava["mangal_house"])
    lagna_rashi_code = str(
        vedic.get("lagna_rashi") or vedic.get("moon_rashi") or vedic["mangal_rashi"]
    )
    lagna_rashi = _rashi_index(lagna_rashi_code)
    mars_rashi = _rashi_index(vedic["mangal_rashi"])
    moon_rashi = _rashi_index(vedic["moon_rashi"])
    venus_rashi = _rashi_index(vedic["shukra_rashi"])
    house_from_moon = _count_cycle(start=moon_rashi, end=mars_rashi, size=12)
    house_from_venus = _count_cycle(start=venus_rashi, end=mars_rashi, size=12)

    reference_evidence = {
        "lagna": _build_manglik_reference_evidence(
            reference_key="lagna",
            mars_house=mars_house_lagna,
            mars_rashi_index=mars_rashi,
            reference_rashi_index=lagna_rashi,
            vedic=vedic,
            bhava=bhava,
        ),
        "moon": _build_manglik_reference_evidence(
            reference_key="moon",
            mars_house=house_from_moon,
            mars_rashi_index=mars_rashi,
            reference_rashi_index=moon_rashi,
            vedic=vedic,
            bhava=bhava,
        ),
        "venus": _build_manglik_reference_evidence(
            reference_key="venus",
            mars_house=house_from_venus,
            mars_rashi_index=mars_rashi,
            reference_rashi_index=venus_rashi,
            vedic=vedic,
            bhava=bhava,
        ),
    }
    raw_triggers = {
        "from_lagna": bool(reference_evidence["lagna"]["triggered"]),
        "from_moon": bool(reference_evidence["moon"]["triggered"]),
        "from_venus": bool(reference_evidence["venus"]["triggered"]),
    }
    effective_triggers = {
        "from_lagna": bool(reference_evidence["lagna"]["effective_triggered"]),
        "from_moon": bool(reference_evidence["moon"]["effective_triggered"]),
        "from_venus": bool(reference_evidence["venus"]["effective_triggered"]),
    }
    raw_trigger_count = sum(1 for value in raw_triggers.values() if value)
    trigger_count = sum(1 for value in effective_triggers.values() if value)
    is_manglik = trigger_count > 0
    active_references = [
        reference_key
        for reference_key, reference in reference_evidence.items()
        if bool(reference["effective_triggered"])
    ]
    inactive_references = [
        reference_key
        for reference_key, reference in reference_evidence.items()
        if not bool(reference["effective_triggered"])
    ]
    cancelled_references = [
        reference_key
        for reference_key, reference in reference_evidence.items()
        if bool(reference["triggered"]) and bool(reference["cancelled"])
    ]
    cancellation_reasons = [
        str(reason)
        for reference in reference_evidence.values()
        for reason in reference["cancellation_reasons"]
    ]
    dosha_reasons = _dedupe_reasons(
        [
            str(reason)
            for reference in reference_evidence.values()
            for reason in reference["dosha_reasons"]
        ]
    )
    nullification_reasons = _dedupe_reasons(
        [
            str(reason)
            for reference in reference_evidence.values()
            for reason in reference["nullification_reasons"]
        ]
    )
    dosha_percent = max(
        (
            int(reference["dosha_percent"])
            for reference in reference_evidence.values()
            if int(reference["dosha_percent"]) > 0
        ),
        default=0,
    )
    raw_dosha_percent = max(
        (
            int(reference["raw_dosha_percent"])
            for reference in reference_evidence.values()
            if int(reference["raw_dosha_percent"]) > 0
        ),
        default=0,
    )
    return {
        "rule_profile_id": _MANGAL_DOSHA_RULE_PROFILE_ID,
        "method": _MANGAL_DOSHA_METHOD,
        "is_manglik": is_manglik,
        "trigger_count": trigger_count,
        "raw_trigger_count": raw_trigger_count,
        "dosha_percent": dosha_percent,
        "raw_dosha_percent": raw_dosha_percent,
        "trigger_houses": list(_MANGAL_DOSHA_HOUSES_SORTED),
        "active_references": active_references,
        "inactive_references": inactive_references,
        "cancelled_references": cancelled_references,
        "cancellation_applied": len(cancelled_references) > 0,
        "cancellation_reasons": cancellation_reasons,
        "dosha_reasons": dosha_reasons,
        "nullification_reasons": nullification_reasons,
        "reference_evidence": reference_evidence,
        "mars_house_from_lagna": mars_house_lagna,
        "mars_house_from_moon": house_from_moon,
        "mars_house_from_venus": house_from_venus,
        "mars_rashi": str(vedic["mangal_rashi"]),
        "mars_rashi_index": mars_rashi,
        "d9_mars_house": int(graha_table["mangal"]["d9_house"]),
        "triggers": effective_triggers,
        "raw_triggers": raw_triggers,
    }


def _build_manglik_reference_evidence(
    *,
    reference_key: str,
    mars_house: int,
    mars_rashi_index: int,
    reference_rashi_index: int,
    vedic: dict[str, Any],
    bhava: dict[str, Any],
) -> dict[str, Any]:
    triggered = mars_house in _MANGAL_DOSHA_HOUSES
    exception = _manglik_house_sign_exception(
        mars_house=mars_house,
        mars_rashi_index=mars_rashi_index,
    )
    jupiter_house: int | None = None
    jupiter_aspects_mars = False
    jupiter_aspect_house: int | None = None
    guru_rashi = vedic.get("guru_rashi")
    if guru_rashi is not None:
        jupiter_house = _house_from_reference(
            reference_rashi_index=reference_rashi_index,
            target_rashi_index=_rashi_index(str(guru_rashi)),
        )
        jupiter_aspects_mars, jupiter_aspect_house = _does_planet_aspect_house(
            source_house=jupiter_house,
            target_house=mars_house,
            aspect_houses=_MANGAL_DOSHA_JUPITER_CANCELLATION_ASPECTS,
        )
    helper_planet_houses = _helper_planet_houses_from_reference(
        reference_rashi_index=reference_rashi_index,
        vedic=vedic,
    )
    helper_hits = [
        planet_key
        for planet_key, house in helper_planet_houses.items()
        if house in _MANGAL_DOSHA_HOUSES
    ]
    raw_dosha_percent = _manglik_raw_percent(
        mars_house=mars_house,
        helper_count=len(helper_hits),
        triggered=triggered,
    )
    reference_label = _MANGAL_DOSHA_REFERENCE_LABELS[reference_key]
    cancellation_rule_ids: list[str] = []
    cancellation_reasons: list[str] = []
    if triggered:
        if exception is not None:
            cancellation_rule_ids.append(str(exception["rule_id"]))
            cancellation_reasons.append(str(exception["reason"]))
        extra_cancellations = _manglik_additional_cancellations(
            mars_rashi_index=mars_rashi_index,
            bhava=bhava,
            vedic=vedic,
        )
        for rule_id, reason in extra_cancellations:
            cancellation_rule_ids.append(rule_id)
            cancellation_reasons.append(reason)
        if jupiter_aspects_mars and jupiter_aspect_house is not None:
            cancellation_rule_ids.append("jupiter_aspect_cancellation")
            cancellation_reasons.append(
                f"Brihaspati {jupiter_aspect_house}th sight aspects Mangal"
            )
    cancelled = triggered and len(cancellation_rule_ids) > 0
    effective_triggered = triggered and not cancelled
    dosha_percent = 0 if cancelled else raw_dosha_percent
    mars_rashi_code = _RASHI_SEQUENCE[mars_rashi_index - 1]
    mars_rashi_name = _RASHI_DISPLAY_NAMES[mars_rashi_index - 1]
    helper_labels = [_MANGAL_DOSHA_HELPER_PLANET_LABELS[key] for key in helper_hits]
    helping_reason = _manglik_helper_reason(helper_labels)
    dosha_reasons: list[str] = []
    nullification_reasons = _dedupe_reasons(cancellation_reasons)
    if triggered:
        dosha_reasons.append(_manglik_dosha_house_reason(mars_house))
        if helping_reason is not None:
            dosha_reasons.append(helping_reason)
    if not triggered:
        reason = (
            f"Mars is in house {mars_house} from {reference_label}, outside trigger houses."
        )
    elif cancelled:
        reason = (
            f"Mars is in house {mars_house} from {reference_label}, but dosha is nullified by"
            f" cancellation rules."
        )
    else:
        reason = f"Mars is in house {mars_house} from {reference_label}."
    return {
        "reference_key": reference_key,
        "reference_label": reference_label,
        "mars_house": mars_house,
        "mars_rashi": mars_rashi_code,
        "mars_rashi_english": mars_rashi_name,
        "triggered": triggered,
        "effective_triggered": effective_triggered,
        "cancelled": cancelled,
        "raw_dosha_percent": raw_dosha_percent,
        "dosha_percent": dosha_percent,
        "helper_planet_count": len(helper_hits),
        "helper_planets": helper_hits,
        "helper_planet_labels": helper_labels,
        "helper_planet_houses": helper_planet_houses,
        "helping_reason": helping_reason,
        "jupiter_house_from_reference": jupiter_house,
        "jupiter_aspects_mars": jupiter_aspects_mars,
        "jupiter_aspect_house": jupiter_aspect_house,
        "exception_rule_id": None if exception is None else str(exception["rule_id"]),
        "exception_reason": None if exception is None else str(exception["reason"]),
        "cancellation_rule_ids": _dedupe_reasons(cancellation_rule_ids),
        "cancellation_reasons": _dedupe_reasons(cancellation_reasons),
        "dosha_reasons": dosha_reasons,
        "nullification_reasons": nullification_reasons,
        "rule_houses": list(_MANGAL_DOSHA_HOUSES_SORTED),
        "reason": reason,
    }


def _manglik_additional_cancellations(
    *,
    mars_rashi_index: int,
    bhava: dict[str, Any],
    vedic: dict[str, Any],
) -> list[tuple[str, str]]:
    cancellations: list[tuple[str, str]] = []
    any_house_rule = _MANGAL_DOSHA_ANY_HOUSE_EXCEPTION_BY_RASHI.get(mars_rashi_index)
    if any_house_rule is not None:
        cancellations.append(any_house_rule)

    for planet_rashi_field, rule in _MANGAL_DOSHA_CONJUNCTION_PLANETS.items():
        planet_rashi = vedic.get(planet_rashi_field)
        if planet_rashi is None:
            continue
        if _rashi_index(str(planet_rashi)) == mars_rashi_index:
            cancellations.append(rule)

    guru_house = _safe_house_index(bhava.get("guru_house"))
    shukra_house = _safe_house_index(bhava.get("shukra_house"))
    if guru_house == 1:
        cancellations.append(
            ("jupiter_in_lagna_house_cancellation", "Brihaspati in Lagna house in the chart")
        )
    if shukra_house == 1:
        cancellations.append(
            ("venus_in_lagna_house_cancellation", "Shukra in Lagna house in the chart")
        )
    if shukra_house == 7:
        cancellations.append(("venus_in_seventh_house_cancellation", "Shukra in Seventh house"))
    return cancellations


def _manglik_dosha_house_reason(mars_house: int) -> str:
    if mars_house == 1:
        return "Mars in First House *considered by North astrologers"
    if mars_house == 2:
        return "Mars in Second House *considered by South astrologers"
    return f"Mars in {_house_ordinal_label(mars_house)} House"


def _manglik_helper_reason(helper_labels: list[str]) -> str | None:
    if not helper_labels:
        return None
    if len(helper_labels) == 1:
        return f"{helper_labels[0]} is helping Mangal"
    if len(helper_labels) == 2:
        return f"{helper_labels[0]} and {helper_labels[1]} are helping Mangal"
    return f"{', '.join(helper_labels[:-1])} and {helper_labels[-1]} are helping Mangal"


def reference_label_for(reference_key: str) -> str:
    return _MANGAL_DOSHA_REFERENCE_LABELS.get(reference_key, reference_key)


def _house_ordinal_label(house: int) -> str:
    return _HOUSE_ORDINAL_LABELS.get(house, str(house))


def _dedupe_reasons(reasons: list[str]) -> list[str]:
    deduped: list[str] = []
    seen: set[str] = set()
    for reason in reasons:
        normalized = reason.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        deduped.append(normalized)
    return deduped


def _safe_house_index(value: Any) -> int | None:
    if value is None:
        return None
    try:
        house = int(value)
    except (TypeError, ValueError):
        return None
    if 1 <= house <= 12:
        return house
    return None


def _extract_house_from_snapshot(
    *,
    snapshot: dict[str, Any],
    planet_key: str,
) -> int:
    bhava = snapshot.get("bhava", {})
    house = _safe_house_index(bhava.get(f"{planet_key}_house"))
    if house is not None:
        return house
    graha_table = snapshot.get("graha_table", {})
    graha_entry = graha_table.get(planet_key, {}) if isinstance(graha_table, dict) else {}
    table_house = _safe_house_index(graha_entry.get("house"))
    if table_house is not None:
        return table_house
    raise ValueError(f"Missing house for planet '{planet_key}' in snapshot.")


def _planet_sidereal_degree(
    *,
    snapshot: dict[str, Any],
    planet_key: str,
) -> float:
    graha_table = snapshot.get("graha_table", {})
    if isinstance(graha_table, dict):
        graha_entry = graha_table.get(planet_key, {})
        if isinstance(graha_entry, dict) and "sidereal_deg" in graha_entry:
            return float(graha_entry["sidereal_deg"]) % 360.0
    astronomy = snapshot.get("astronomy", {})
    astronomy_key = f"{planet_key}_sidereal_deg"
    if isinstance(astronomy, dict) and astronomy_key in astronomy:
        return float(astronomy[astronomy_key]) % 360.0
    raise ValueError(f"Missing sidereal degree for planet '{planet_key}' in snapshot.")


def _degree_on_axis_arc(
    *,
    start_degree: float,
    end_degree: float,
    target_degree: float,
) -> bool:
    start = float(start_degree) % 360.0
    end = float(end_degree) % 360.0
    target = float(target_degree) % 360.0
    if start <= end:
        return start <= target <= end
    return target >= start or target <= end


def _kaal_sarpa_type_name(*, rahu_house: int) -> str:
    return _KAAL_SARPA_TYPE_BY_RAHU_HOUSE.get(rahu_house, "Unknown")


def _house_from_reference(
    *,
    reference_rashi_index: int,
    target_rashi_index: int,
) -> int:
    return _count_cycle(start=reference_rashi_index, end=target_rashi_index, size=12)


def _helper_planet_houses_from_reference(
    *,
    reference_rashi_index: int,
    vedic: dict[str, Any],
) -> dict[str, int]:
    houses: dict[str, int] = {}
    for planet_key in _MANGAL_DOSHA_HELPER_PLANETS:
        rashi_field = _MANGAL_DOSHA_HELPER_PLANET_RASHI_FIELDS[planet_key]
        rashi_code = vedic.get(rashi_field)
        if rashi_code is None:
            continue
        target_rashi_index = _rashi_index(str(rashi_code))
        houses[planet_key] = _house_from_reference(
            reference_rashi_index=reference_rashi_index,
            target_rashi_index=target_rashi_index,
        )
    return houses


def _does_planet_aspect_house(
    *,
    source_house: int,
    target_house: int,
    aspect_houses: tuple[int, ...],
) -> tuple[bool, int | None]:
    for aspect_house in aspect_houses:
        aspected_house = ((source_house + aspect_house - 2) % 12) + 1
        if aspected_house == target_house:
            return True, aspect_house
    return False, None


def _manglik_raw_percent(
    *,
    mars_house: int,
    helper_count: int,
    triggered: bool,
) -> int:
    if not triggered:
        return 0
    base_percent = int(_MANGAL_DOSHA_BASE_PERCENT_BY_HOUSE.get(mars_house, 0))
    if mars_house in {12, 1, 2, 4}:
        if helper_count >= 2:
            return 200
        if helper_count >= 1:
            return 150
        return base_percent
    if mars_house in {7, 8}:
        if helper_count >= 2:
            return 250
        if helper_count >= 1:
            return 200
        return base_percent
    return base_percent


def _manglik_house_sign_exception(
    *,
    mars_house: int,
    mars_rashi_index: int,
) -> dict[str, str] | None:
    rule = _MANGAL_DOSHA_HOUSE_SIGN_EXCEPTION_RULES.get((mars_house, mars_rashi_index))
    if rule is None:
        return None
    rule_id, reason = rule
    return {"rule_id": rule_id, "reason": reason}


def _compute_d1_d9_checks(
    *,
    boy_snapshot: dict[str, Any],
    girl_snapshot: dict[str, Any],
) -> dict[str, Any]:
    boy_lagna_d1 = _rashi_index(boy_snapshot["vedic"]["lagna_rashi"])
    girl_lagna_d1 = _rashi_index(girl_snapshot["vedic"]["lagna_rashi"])
    boy_moon_d1 = _rashi_index(boy_snapshot["vedic"]["moon_rashi"])
    girl_moon_d1 = _rashi_index(girl_snapshot["vedic"]["moon_rashi"])
    boy_lagna_d9 = _rashi_index(boy_snapshot["varga"]["d9"]["lagna_rashi"])
    girl_lagna_d9 = _rashi_index(girl_snapshot["varga"]["d9"]["lagna_rashi"])

    d1_lagna_distance = _count_cycle(start=girl_lagna_d1, end=boy_lagna_d1, size=12)
    d1_moon_distance = _count_cycle(start=girl_moon_d1, end=boy_moon_d1, size=12)
    d9_lagna_distance = _count_cycle(start=girl_lagna_d9, end=boy_lagna_d9, size=12)

    boy_mars_d9_house = int(boy_snapshot["graha_table"]["mangal"]["d9_house"])
    girl_mars_d9_house = int(girl_snapshot["graha_table"]["mangal"]["d9_house"])

    return {
        "d1": {
            "lagna_distance": d1_lagna_distance,
            "moon_distance": d1_moon_distance,
            "same_lagna_element": _same_element(boy_lagna_d1, girl_lagna_d1),
            "same_moon_element": _same_element(boy_moon_d1, girl_moon_d1),
        },
        "d9": {
            "lagna_distance": d9_lagna_distance,
            "same_lagna_element": _same_element(boy_lagna_d9, girl_lagna_d9),
            "same_lagna_rashi": boy_lagna_d9 == girl_lagna_d9,
            "mars_house_gap": abs(boy_mars_d9_house - girl_mars_d9_house),
        },
    }


def _moon_profile_from_snapshot(snapshot: dict[str, Any]) -> _MoonProfile:
    vedic = snapshot["vedic"]
    panchanga = snapshot["panchanga"]
    moon_sidereal_deg = float(snapshot["astronomy"]["moon_sidereal_deg"])
    return _MoonProfile(
        rashi_index=_rashi_index(vedic["moon_rashi"]),
        rashi_code=str(vedic["moon_rashi"]),
        nakshatra_number=int(panchanga["nakshatra"]["number"]),
        pada=int(vedic["moon_pada"]),
        moon_degree_in_rashi=moon_sidereal_deg % 30.0,
    )


def _rashi_index(rashi_code: str) -> int:
    normalized = _RASHI_ALIASES.get(str(rashi_code), str(rashi_code))
    if normalized not in _RASHI_TO_INDEX:
        raise ValueError(f"Unsupported rashi code: {rashi_code}")
    return _RASHI_TO_INDEX[normalized]


def _count_cycle(*, start: int, end: int, size: int) -> int:
    return ((end + size - start) % size) + 1


def _same_element(a: int, b: int) -> bool:
    return _ELEMENT_BY_RASHI_INDEX[a] == _ELEMENT_BY_RASHI_INDEX[b]


def _round_2(value: float) -> float:
    return round(float(value), 2)


def describe_kuta_component(key: str, score: float) -> str:
    if key == "nadi":
        return "Nadi match" if score > 0 else "Nadi dosha"
    if key == "bhakoot":
        return "Bhakoot match" if score > 0 else "Bhakoot dosha"
    if score <= 0:
        return "Weak"
    if key in {"varna", "vashya", "tara", "yoni", "graha_maitri", "gana"} and score > 0:
        return "Favorable"
    return "Moderate"


def compatibility_reference_tables() -> dict[str, Any]:
    # Exposed for debugging/audit tooling and parity checks.
    return {
        "kuta_weights": {key: weight for key, _, weight in _KUTA_WEIGHTS},
        "varna_names": list(_VARNA_NAMES),
        "vashya_categories": list(_VASHYA_CATEGORIES),
        "yoni_names": list(_YONI_NAMES),
        "gana_names": list(_GANA_NAMES),
        "nadi_names": list(_NADI_NAMES),
        "lord_names": list(_LORD_NAMES),
    }

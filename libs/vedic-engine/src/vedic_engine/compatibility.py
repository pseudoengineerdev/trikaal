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

# Moon-rashi to varna index (0 highest .. 3 lowest) per Drik tutorial mapping.
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
_MANGAL_DOSHA_HOUSE_SIGN_EXCEPTION_RULES = {
    2: ("house_2_mercury_sign_exception", frozenset({3, 6})),
    4: ("house_4_mars_sign_exception", frozenset({1, 8})),
    7: ("house_7_cancer_capricorn_exception", frozenset({4, 10})),
    8: ("house_8_jupiter_sign_exception", frozenset({9, 12})),
    12: ("house_12_venus_sign_exception", frozenset({2, 7})),
}
_MANGAL_DOSHA_BASE_PERCENT_BY_HOUSE = {
    12: 50,
    1: 60,
    2: 80,
    4: 80,
    7: 100,
    8: 100,
}
_MANGAL_DOSHA_HELPER_PLANETS = ("sun", "shani", "rahu", "ketu")
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
    d1_d9 = _compute_d1_d9_checks(boy_snapshot=boy_snapshot, girl_snapshot=girl_snapshot)

    return {
        "version": "v1",
        "ashta_kuta": ashta,
        "manglik": manglik,
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


def _compute_ashta_kuta(*, boy: _MoonProfile, girl: _MoonProfile) -> dict[str, Any]:
    varna_score = _varna_score(boy=boy, girl=girl)
    vashya_score = _vashya_score(boy=boy, girl=girl)
    tara_score = _tara_score(boy=boy, girl=girl)
    yoni_score = _yoni_score(boy=boy, girl=girl)
    graha_maitri_score = _graha_maitri_score(boy=boy, girl=girl)
    gana_score = _gana_score(boy=boy, girl=girl)
    bhakoot_score = _bhakoot_score(boy=boy, girl=girl)
    nadi_score = _nadi_score(boy=boy, girl=girl)
    bhakoot_score, nadi_score = _apply_drik_same_nakshatra_overrides(
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
    # Based on Drik's published ranges for Ashta-kuta interpretation.
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


def _apply_drik_same_nakshatra_overrides(
    *,
    boy: _MoonProfile,
    girl: _MoonProfile,
    bhakoot_score: float,
    nadi_score: float,
) -> tuple[float, float]:
    """Apply Drik-parity exception rules for same-nakshatra matches.

    Observed Drik behavior:
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
        ),
        "moon": _build_manglik_reference_evidence(
            reference_key="moon",
            mars_house=house_from_moon,
            mars_rashi_index=mars_rashi,
            reference_rashi_index=moon_rashi,
            vedic=vedic,
        ),
        "venus": _build_manglik_reference_evidence(
            reference_key="venus",
            mars_house=house_from_venus,
            mars_rashi_index=mars_rashi,
            reference_rashi_index=venus_rashi,
            vedic=vedic,
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
    cancellation_rule_ids: list[str] = []
    cancellation_reasons: list[str] = []
    if exception is not None:
        cancellation_rule_ids.append(str(exception["rule_id"]))
        cancellation_reasons.append(str(exception["reason"]))
    if triggered and jupiter_aspects_mars and jupiter_aspect_house is not None:
        cancellation_rule_ids.append("jupiter_aspect_cancellation")
        cancellation_reasons.append(
            f"Jupiter aspects Mars with {jupiter_aspect_house}th aspect from {reference_label_for(reference_key)}."
        )
    cancelled = triggered and len(cancellation_rule_ids) > 0
    effective_triggered = triggered and not cancelled
    dosha_percent = 0 if cancelled else raw_dosha_percent
    reference_label = _MANGAL_DOSHA_REFERENCE_LABELS[reference_key]
    mars_rashi_code = _RASHI_SEQUENCE[mars_rashi_index - 1]
    mars_rashi_name = _RASHI_DISPLAY_NAMES[mars_rashi_index - 1]
    helper_labels = [_MANGAL_DOSHA_HELPER_PLANET_LABELS[key] for key in helper_hits]
    helping_reason = None if not helper_labels else f"{helper_labels[0]} is helping Mangal."
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
        "cancellation_rule_ids": cancellation_rule_ids,
        "cancellation_reasons": cancellation_reasons,
        "rule_houses": list(_MANGAL_DOSHA_HOUSES_SORTED),
        "reason": reason,
    }


def reference_label_for(reference_key: str) -> str:
    return _MANGAL_DOSHA_REFERENCE_LABELS.get(reference_key, reference_key)


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
    rule = _MANGAL_DOSHA_HOUSE_SIGN_EXCEPTION_RULES.get(mars_house)
    if rule is None:
        return None
    rule_id, allowed_rashi_indices = rule
    if mars_rashi_index not in allowed_rashi_indices:
        return None
    allowed_signs = ", ".join(
        _RASHI_DISPLAY_NAMES[rashi_index - 1] for rashi_index in sorted(allowed_rashi_indices)
    )
    return {
        "rule_id": rule_id,
        "reason": (
            f"House {mars_house} Manglik condition is exempt when Mars is in {allowed_signs}."
        ),
    }


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

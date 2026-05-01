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
    else:
        intensity_gap = abs(boy["trigger_count"] - girl["trigger_count"])
        score = 4.0 if intensity_gap <= 1 else 2.0
        alignment = "Unbalanced"
        verdict = "One chart has stronger Manglik triggers than the other."

    return {
        "max_score": 8.0,
        "score": score,
        "pair_alignment": alignment,
        "verdict": verdict,
        "boy": boy,
        "girl": girl,
    }


def _compute_manglik_for_snapshot(snapshot: dict[str, Any]) -> dict[str, Any]:
    graha_table = snapshot["graha_table"]
    vedic = snapshot["vedic"]
    bhava = snapshot["bhava"]

    mars_house_lagna = int(bhava["mangal_house"])
    mars_rashi = _rashi_index(vedic["mangal_rashi"])
    moon_rashi = _rashi_index(vedic["moon_rashi"])
    venus_rashi = _rashi_index(vedic["shukra_rashi"])
    house_from_moon = _count_cycle(start=moon_rashi, end=mars_rashi, size=12)
    house_from_venus = _count_cycle(start=venus_rashi, end=mars_rashi, size=12)

    triggers = {
        "from_lagna": mars_house_lagna in _MANGAL_DOSHA_HOUSES,
        "from_moon": house_from_moon in _MANGAL_DOSHA_HOUSES,
        "from_venus": house_from_venus in _MANGAL_DOSHA_HOUSES,
    }
    trigger_count = sum(1 for value in triggers.values() if value)
    is_manglik = trigger_count > 0
    return {
        "is_manglik": is_manglik,
        "trigger_count": trigger_count,
        "mars_house_from_lagna": mars_house_lagna,
        "mars_house_from_moon": house_from_moon,
        "mars_house_from_venus": house_from_venus,
        "d9_mars_house": int(graha_table["mangal"]["d9_house"]),
        "triggers": triggers,
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

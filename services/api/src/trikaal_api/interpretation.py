from __future__ import annotations

from typing import Any

from trikaal_api.report_contract import GrahaEntryContract, SnapshotContract

_CORE_GRAHAS: tuple[str, ...] = (
    "sun",
    "moon",
    "mangal",
    "budha",
    "guru",
    "shukra",
    "shani",
    "rahu",
    "ketu",
)

_GRAHA_NAMES: dict[str, dict[str, str]] = {
    "sun": {"english": "Sun", "vedic": "Surya"},
    "moon": {"english": "Moon", "vedic": "Chandra"},
    "mangal": {"english": "Mars", "vedic": "Mangal"},
    "budha": {"english": "Mercury", "vedic": "Budha"},
    "guru": {"english": "Jupiter", "vedic": "Guru"},
    "shukra": {"english": "Venus", "vedic": "Shukra"},
    "shani": {"english": "Saturn", "vedic": "Shani"},
    "rahu": {"english": "Rahu", "vedic": "Rahu"},
    "ketu": {"english": "Ketu", "vedic": "Ketu"},
}

_RASHI_NAMES: dict[str, dict[str, str]] = {
    "Mesh": {"english": "Aries", "vedic": "Mesha"},
    "Vrish": {"english": "Taurus", "vedic": "Vrishabha"},
    "Mith": {"english": "Gemini", "vedic": "Mithuna"},
    "Mitu": {"english": "Gemini", "vedic": "Mithuna"},
    "Kark": {"english": "Cancer", "vedic": "Karka"},
    "Simh": {"english": "Leo", "vedic": "Simha"},
    "Kany": {"english": "Virgo", "vedic": "Kanya"},
    "Tula": {"english": "Libra", "vedic": "Tula"},
    "Vrsc": {"english": "Scorpio", "vedic": "Vrischika"},
    "Dhanu": {"english": "Sagittarius", "vedic": "Dhanu"},
    "Maka": {"english": "Capricorn", "vedic": "Makara"},
    "Makar": {"english": "Capricorn", "vedic": "Makara"},
    "Kumb": {"english": "Aquarius", "vedic": "Kumbha"},
    "Meen": {"english": "Pisces", "vedic": "Meena"},
}

_HOUSE_THEME_ENGLISH: dict[int, str] = {
    1: "self and vitality",
    2: "wealth and speech",
    3: "courage and effort",
    4: "home and emotional roots",
    5: "creativity and children",
    6: "service and challenges",
    7: "partnership and marriage",
    8: "transformation and longevity",
    9: "dharma and fortune",
    10: "career and karma",
    11: "gains and networks",
    12: "release and spiritual retreat",
}

_HOUSE_THEME_VEDIC: dict[int, str] = {
    1: "tanu (self and vitality)",
    2: "dhana (wealth and speech)",
    3: "sahaja (courage and effort)",
    4: "sukha (home and emotional roots)",
    5: "putra (creativity and children)",
    6: "ripu (service and challenges)",
    7: "yuvati (partnership and marriage)",
    8: "randhra (transformation and longevity)",
    9: "dharma (fortune and blessings)",
    10: "karma (work and public life)",
    11: "labha (gains and networks)",
    12: "vyaya (release and spiritual retreat)",
}

_GRAHA_THEMES: dict[str, dict[str, str]] = {
    "sun": {
        "english": "leadership and identity",
        "vedic": "atma bala and authority",
    },
    "moon": {
        "english": "mind, emotions, and belonging",
        "vedic": "manas, rasa, and emotional flow",
    },
    "mangal": {
        "english": "action, drive, and courage",
        "vedic": "shakti, initiative, and protection",
    },
    "budha": {
        "english": "thinking, analysis, and communication",
        "vedic": "buddhi, logic, and vak",
    },
    "guru": {
        "english": "wisdom, guidance, and expansion",
        "vedic": "jnana, dharma, and growth",
    },
    "shukra": {
        "english": "relationships, comfort, and art",
        "vedic": "sukha, rasa, and harmony",
    },
    "shani": {
        "english": "discipline, responsibility, and structure",
        "vedic": "niyam, karma pressure, and endurance",
    },
    "rahu": {
        "english": "ambition, desire, and unusual pathways",
        "vedic": "maya, craving, and worldly pull",
    },
    "ketu": {
        "english": "detachment, insight, and inner release",
        "vedic": "moksha impulse and inner vairagya",
    },
}

_DIGNITY_RULES: dict[str, dict[str, Any]] = {
    "sun": {"exalted": "Mesh", "debilitated": "Tula", "own": {"Simh"}},
    "moon": {"exalted": "Vrish", "debilitated": "Vrsc", "own": {"Kark"}},
    "mangal": {"exalted": "Maka", "debilitated": "Kark", "own": {"Mesh", "Vrsc"}},
    "budha": {"exalted": "Kany", "debilitated": "Meen", "own": {"Mitu", "Kany"}},
    "guru": {"exalted": "Kark", "debilitated": "Maka", "own": {"Dhanu", "Meen"}},
    "shukra": {"exalted": "Meen", "debilitated": "Kany", "own": {"Vrish", "Tula"}},
    "shani": {"exalted": "Tula", "debilitated": "Mesh", "own": {"Maka", "Kumb"}},
}

_RASHI_LORDS: dict[str, str] = {
    "Mesh": "mangal",
    "Vrish": "shukra",
    "Mith": "budha",
    "Mitu": "budha",
    "Kark": "moon",
    "Simh": "sun",
    "Kany": "budha",
    "Tula": "shukra",
    "Vrsc": "mangal",
    "Dhanu": "guru",
    "Maka": "shani",
    "Makar": "shani",
    "Kumb": "shani",
    "Meen": "guru",
}


def build_interpretations(snapshot: SnapshotContract) -> dict[str, Any]:
    yoga_cards = _build_yoga_cards(snapshot)
    house_lord_cards = _build_house_lord_cards(snapshot)
    aspect_cards = _build_aspect_cards(snapshot)
    return {
        "version": "v1",
        "cards": yoga_cards + house_lord_cards + aspect_cards,
    }


def _build_aspect_cards(snapshot: SnapshotContract) -> list[dict[str, Any]]:
    rows = _core_rows(snapshot)
    scored_cards: list[tuple[float, dict[str, Any]]] = []

    for graha_key, row in rows.items():
        targets = _aspected_houses(row.house, graha_key)
        score = _aspect_strength(row, graha_key)
        confidence = _confidence_from_score(score)
        graha_english = _graha_name(graha_key, "english")
        graha_vedic = _graha_name(graha_key, "vedic")
        rashi_english = _rashi_name(row.rashi, "english")
        rashi_vedic = _rashi_name(row.rashi, "vedic")

        title_en = f"{graha_english} aspects {_house_short_list(targets)}"
        title_ve = f"{graha_vedic} drishti on {_bhava_short_list(targets)}"
        summary_en = (
            f"{graha_english} is placed in H{row.house} ({_house_theme_en(row.house)}) "
            f"in {rashi_english}. From there, it influences {_house_short_list(targets)}."
        )
        summary_ve = (
            f"{graha_vedic} is in {row.house}th Bhava ({_house_theme_ve(row.house)}) "
            f"in {rashi_vedic}. From there, its drishti goes to {_bhava_short_list(targets)}."
        )
        impact_en = (
            f"This can activate {_theme_span(targets, 'english')} through "
            f"{_graha_theme(graha_key, 'english')}."
        )
        impact_ve = (
            f"This can activate {_theme_span(targets, 'vedic')} through "
            f"{_graha_theme(graha_key, 'vedic')}."
        )

        evidence = [
            _localized_text(
                english=f"Rule applied: {_aspect_rule_label(graha_key, 'english')}.",
                vedic=f"Rule applied: {_aspect_rule_label(graha_key, 'vedic')}.",
            ),
            _localized_text(
                english=(
                    f"Computed from H{row.house}: targets are {_house_short_list(targets)}."
                ),
                vedic=(
                    f"Computed from {row.house}th Bhava: targets are "
                    f"{_bhava_short_list(targets)}."
                ),
            ),
        ]

        scored_cards.append(
            (
                score,
                {
                    "card_id": f"aspect_{graha_key}",
                    "category": "aspects",
                    "confidence": confidence,
                    "strength_score": round(score, 3),
                    "title": _localized_text(title_en, title_ve),
                    "summary": _localized_text(summary_en, summary_ve),
                    "impact": _localized_text(impact_en, impact_ve),
                    "evidence": evidence,
                },
            )
        )

    scored_cards.sort(key=lambda item: item[0], reverse=True)
    return [card for _, card in scored_cards[:4]]


def _build_yoga_cards(snapshot: SnapshotContract) -> list[dict[str, Any]]:
    rows = _core_rows(snapshot)
    cards: list[dict[str, Any]] = []

    sun = rows["sun"]
    budha = rows["budha"]
    moon = rows["moon"]
    guru = rows["guru"]
    mangal = rows["mangal"]

    if sun.house == budha.house:
        score = 0.86 if not budha.combust else 0.74
        cards.append(
            {
                "card_id": "yoga_budha_aditya",
                "category": "yoga",
                "confidence": _confidence_from_score(score),
                "strength_score": round(score, 3),
                "title": _localized_text(
                    english="Budha-Aditya Yoga pattern detected",
                    vedic="Budha-Aditya yoga pattern detected",
                ),
                "summary": _localized_text(
                    english=(
                        "Sun and Mercury are in the same house, creating a classical "
                        "Budha-Aditya combination."
                    ),
                    vedic=(
                        "Surya and Budha are in the same bhava, creating a classical "
                        "Budha-Aditya combination."
                    ),
                ),
                "impact": _localized_text(
                    english=(
                        "This can support clear expression, planning ability, and a "
                        "visible thinking style."
                    ),
                    vedic=(
                        "This can support buddhi, articulate speech, and stronger "
                        "intellectual presence."
                    ),
                ),
                "evidence": [
                    _localized_text(
                        english=f"Sun and Mercury both occupy H{sun.house}.",
                        vedic=f"Surya and Budha both occupy {sun.house}th Bhava.",
                    ),
                ],
            }
        )

    moon_to_guru = _relative_house_distance(moon.house, guru.house)
    if moon_to_guru in {1, 4, 7, 10}:
        score = 0.88 if _dignity_status("guru", guru.rashi) != "debilitated" else 0.76
        cards.append(
            {
                "card_id": "yoga_gaja_kesari",
                "category": "yoga",
                "confidence": _confidence_from_score(score),
                "strength_score": round(score, 3),
                "title": _localized_text(
                    english="Gaja-Kesari style support detected",
                    vedic="Gaja-Kesari style support detected",
                ),
                "summary": _localized_text(
                    english=(
                        "Jupiter is in a kendra (1/4/7/10) from the Moon, matching "
                        "a key Gaja-Kesari condition."
                    ),
                    vedic=(
                        "Guru is in a kendra (1/4/7/10) from Chandra, matching "
                        "a key Gaja-Kesari condition."
                    ),
                ),
                "impact": _localized_text(
                    english=(
                        "This may support judgment, social respect, and emotional "
                        "stability over time."
                    ),
                    vedic=(
                        "This may support dharmic thinking, public regard, and "
                        "better emotional steadiness."
                    ),
                ),
                "evidence": [
                    _localized_text(
                        english=(
                            f"Moon is in H{moon.house}; Jupiter is in H{guru.house} "
                            f"(distance {moon_to_guru})."
                        ),
                        vedic=(
                            f"Chandra is in {moon.house}th Bhava; Guru is in "
                            f"{guru.house}th Bhava (distance {moon_to_guru})."
                        ),
                    ),
                ],
            }
        )

    if moon.house == mangal.house:
        score = 0.8
        cards.append(
            {
                "card_id": "yoga_chandra_mangala",
                "category": "yoga",
                "confidence": _confidence_from_score(score),
                "strength_score": round(score, 3),
                "title": _localized_text(
                    english="Chandra-Mangala pattern detected",
                    vedic="Chandra-Mangala pattern detected",
                ),
                "summary": _localized_text(
                    english=(
                        "Moon and Mars are conjoined in one house, matching the "
                        "starter Chandra-Mangala condition."
                    ),
                    vedic=(
                        "Chandra and Mangal are conjoined in one bhava, matching "
                        "the starter Chandra-Mangala condition."
                    ),
                ),
                "impact": _localized_text(
                    english=(
                        "This can amplify emotional drive, initiative, and strong "
                        "material focus."
                    ),
                    vedic=(
                        "This can increase emotional fire, initiative, and "
                        "artha-oriented effort."
                    ),
                ),
                "evidence": [
                    _localized_text(
                        english=f"Moon and Mars both occupy H{moon.house}.",
                        vedic=f"Chandra and Mangal both occupy {moon.house}th Bhava.",
                    ),
                ],
            }
        )

    house_signs = _d1_house_signs(snapshot)
    ninth_lord_key = _RASHI_LORDS[_normalize_rashi(house_signs[9])]
    tenth_lord_key = _RASHI_LORDS[_normalize_rashi(house_signs[10])]
    ninth_lord = rows[ninth_lord_key]
    tenth_lord = rows[tenth_lord_key]
    if ninth_lord.house == tenth_lord.house:
        score = 0.84
        cards.append(
            {
                "card_id": "yoga_dharma_karmadhipati",
                "category": "yoga",
                "confidence": _confidence_from_score(score),
                "strength_score": round(score, 3),
                "title": _localized_text(
                    english="Dharma-Karmadhipati linkage detected",
                    vedic="Dharma-Karmadhipati linkage detected",
                ),
                "summary": _localized_text(
                    english=(
                        "The 9th-house lord and 10th-house lord are conjoined, "
                        "forming a dharma-karma link."
                    ),
                    vedic=(
                        "The 9th-bhava lord and 10th-bhava lord are conjoined, "
                        "forming a dharma-karma link."
                    ),
                ),
                "impact": _localized_text(
                    english=(
                        "This can connect purpose, merit, and professional path "
                        "more strongly."
                    ),
                    vedic=(
                        "This can align dharma with karma and strengthen purposeful work."
                    ),
                ),
                "evidence": [
                    _localized_text(
                        english=(
                            f"9th lord ({_graha_name(ninth_lord_key, 'english')}) and "
                            f"10th lord ({_graha_name(tenth_lord_key, 'english')}) "
                            f"meet in H{ninth_lord.house}."
                        ),
                        vedic=(
                            f"9th lord ({_graha_name(ninth_lord_key, 'vedic')}) and "
                            f"10th lord ({_graha_name(tenth_lord_key, 'vedic')}) "
                            f"meet in {ninth_lord.house}th Bhava."
                        ),
                    ),
                ],
            }
        )

    if cards:
        return cards
    return [
        {
            "card_id": "yoga_scan_summary",
            "category": "yoga",
            "confidence": "emerging",
            "strength_score": 0.52,
            "title": _localized_text(
                english="Yoga scan complete (starter rule-set)",
                vedic="Yoga scan complete (starter rule-set)",
            ),
            "summary": _localized_text(
                english=(
                    "No major classical yoga matched in the current v1 rule-set "
                    "for this chart."
                ),
                vedic=(
                    "No major classical yoga matched in the current v1 rule-set "
                    "for this chart."
                ),
            ),
            "impact": _localized_text(
                english=(
                    "This is normal. Chart strength can still come from aspects, "
                    "house lords, and dasha timing."
                ),
                vedic=(
                    "This is normal. Chart strength can still come from drishti, "
                    "bhava lords, and dasha timing."
                ),
            ),
            "evidence": [
                _localized_text(
                    english=(
                        "Checked v1 patterns: Budha-Aditya, Gaja-Kesari, "
                        "Chandra-Mangala, and Dharma-Karmadhipati."
                    ),
                    vedic=(
                        "Checked v1 patterns: Budha-Aditya, Gaja-Kesari, "
                        "Chandra-Mangala, and Dharma-Karmadhipati."
                    ),
                ),
            ],
        }
    ]


def _build_house_lord_cards(snapshot: SnapshotContract) -> list[dict[str, Any]]:
    rows = _core_rows(snapshot)
    house_signs = _d1_house_signs(snapshot)
    cards: list[dict[str, Any]] = []

    for house in (1, 4, 7, 10):
        sign = _normalize_rashi(house_signs[house])
        lord_key = _RASHI_LORDS[sign]
        lord_row = rows[lord_key]
        score = _house_lord_strength(lord_row, lord_key)

        title_en = (
            f"{_ordinal(house)} house lord {_graha_name(lord_key, 'english')} "
            f"in H{lord_row.house}"
        )
        title_ve = (
            f"{house} Bhava swami {_graha_name(lord_key, 'vedic')} "
            f"in {lord_row.house}th Bhava"
        )
        summary_en = (
            f"H{house} starts in {_rashi_name(sign, 'english')}. Its lord "
            f"{_graha_name(lord_key, 'english')} sits in H{lord_row.house} "
            f"({_house_theme_en(lord_row.house)})."
        )
        summary_ve = (
            f"{house}th Bhava starts in {_rashi_name(sign, 'vedic')}. Its lord "
            f"{_graha_name(lord_key, 'vedic')} sits in {lord_row.house}th Bhava "
            f"({_house_theme_ve(lord_row.house)})."
        )
        impact_en = (
            f"This links {_house_theme_en(house)} with "
            f"{_house_theme_en(lord_row.house)} in life outcomes."
        )
        impact_ve = (
            f"This links {_house_theme_ve(house)} with "
            f"{_house_theme_ve(lord_row.house)} in life outcomes."
        )

        evidence = [
            _localized_text(
                english="Rule applied: a house expresses strongly through its lord's placement.",
                vedic="Rule applied: a bhava expresses strongly through its lord's placement.",
            ),
            _localized_text(
                english=(
                    f"{_graha_name(lord_key, 'english')} owns H{house} and is currently "
                    f"placed in H{lord_row.house} ({_rashi_name(lord_row.rashi, 'english')})."
                ),
                vedic=(
                    f"{_graha_name(lord_key, 'vedic')} owns {house}th Bhava and is "
                    f"currently in {lord_row.house}th Bhava "
                    f"({_rashi_name(lord_row.rashi, 'vedic')})."
                ),
            ),
        ]

        cards.append(
            {
                "card_id": f"house_lord_{house}",
                "category": "house_lord",
                "confidence": _confidence_from_score(score),
                "strength_score": round(score, 3),
                "title": _localized_text(title_en, title_ve),
                "summary": _localized_text(summary_en, summary_ve),
                "impact": _localized_text(impact_en, impact_ve),
                "evidence": evidence,
            }
        )

    return cards


def _core_rows(snapshot: SnapshotContract) -> dict[str, GrahaEntryContract]:
    return {
        graha_key: getattr(snapshot.graha_table, graha_key)
        for graha_key in _CORE_GRAHAS
    }


def _d1_house_signs(snapshot: SnapshotContract) -> dict[int, str]:
    return {
        int(house_key): house_entry.rashi
        for house_key, house_entry in snapshot.varga.d1.houses.items()
    }


def _aspected_houses(base_house: int, graha_key: str) -> list[int]:
    targets = {
        ((base_house + offset - 2) % 12) + 1
        for offset in _aspect_offsets(graha_key)
    }
    return sorted(targets)


def _aspect_offsets(graha_key: str) -> tuple[int, ...]:
    if graha_key == "mangal":
        return (4, 7, 8)
    if graha_key == "guru":
        return (5, 7, 9)
    if graha_key == "shani":
        return (3, 7, 10)
    return (7,)


def _aspect_rule_label(graha_key: str, mode: str) -> str:
    if mode == "vedic":
        if graha_key == "mangal":
            return "Mangal aspects 4th, 7th, and 8th Bhava"
        if graha_key == "guru":
            return "Guru aspects 5th, 7th, and 9th Bhava"
        if graha_key == "shani":
            return "Shani aspects 3rd, 7th, and 10th Bhava"
        return f"{_graha_name(graha_key, 'vedic')} aspects the 7th Bhava"

    if graha_key == "mangal":
        return "Mars aspects the 4th, 7th, and 8th houses"
    if graha_key == "guru":
        return "Jupiter aspects the 5th, 7th, and 9th houses"
    if graha_key == "shani":
        return "Saturn aspects the 3rd, 7th, and 10th houses"
    return f"{_graha_name(graha_key, 'english')} aspects the 7th house"


def _aspect_strength(row: GrahaEntryContract, graha_key: str) -> float:
    score = 0.62
    dignity = _dignity_status(graha_key, row.rashi)
    if dignity == "exalted":
        score += 0.2
    elif dignity == "own":
        score += 0.12
    elif dignity == "debilitated":
        score -= 0.18

    if row.retrograde:
        score += 0.05
    if row.combust:
        score -= 0.08
    if graha_key in {"mangal", "guru", "shani"}:
        score += 0.04
    return _clamp(score, minimum=0.35, maximum=0.95)


def _house_lord_strength(row: GrahaEntryContract, graha_key: str) -> float:
    score = 0.68
    dignity = _dignity_status(graha_key, row.rashi)
    if dignity == "exalted":
        score += 0.18
    elif dignity == "own":
        score += 0.1
    elif dignity == "debilitated":
        score -= 0.14
    if row.retrograde:
        score += 0.03
    if row.combust:
        score -= 0.06
    return _clamp(score, minimum=0.45, maximum=0.9)


def _dignity_status(graha_key: str, rashi_key: str) -> str:
    rule = _DIGNITY_RULES.get(graha_key)
    if rule is None:
        return "na"
    normalized_rashi = _normalize_rashi(rashi_key)
    if normalized_rashi == rule["exalted"]:
        return "exalted"
    if normalized_rashi == rule["debilitated"]:
        return "debilitated"
    if normalized_rashi in rule["own"]:
        return "own"
    return "neutral"


def _relative_house_distance(from_house: int, to_house: int) -> int:
    return ((to_house - from_house) % 12) + 1


def _theme_span(houses: list[int], mode: str) -> str:
    if not houses:
        return "multiple houses"
    labels = [_house_theme_en(h) if mode == "english" else _house_theme_ve(h) for h in houses[:2]]
    if len(houses) > 2:
        return ", ".join(labels) + ", and related houses"
    return " and ".join(labels)


def _house_short_list(houses: list[int]) -> str:
    return ", ".join(f"H{house}" for house in houses)


def _bhava_short_list(houses: list[int]) -> str:
    return ", ".join(f"{house}th Bhava" for house in houses)


def _graha_theme(graha_key: str, mode: str) -> str:
    return _GRAHA_THEMES[graha_key][mode]


def _house_theme_en(house: int) -> str:
    return _HOUSE_THEME_ENGLISH[house]


def _house_theme_ve(house: int) -> str:
    return _HOUSE_THEME_VEDIC[house]


def _graha_name(graha_key: str, mode: str) -> str:
    return _GRAHA_NAMES[graha_key][mode]


def _rashi_name(rashi_key: str, mode: str) -> str:
    normalized = _normalize_rashi(rashi_key)
    return _RASHI_NAMES.get(normalized, {"english": normalized, "vedic": normalized})[mode]


def _normalize_rashi(rashi_key: str) -> str:
    key = rashi_key.strip()
    if key == "Makar":
        return "Maka"
    if key == "Mith":
        return "Mitu"
    return key


def _ordinal(number: int) -> str:
    if 10 <= number % 100 <= 20:
        suffix = "th"
    else:
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(number % 10, "th")
    return f"{number}{suffix}"


def _confidence_from_score(score: float) -> str:
    if score >= 0.82:
        return "high"
    if score >= 0.66:
        return "medium"
    return "emerging"


def _clamp(value: float, *, minimum: float, maximum: float) -> float:
    if value < minimum:
        return minimum
    if value > maximum:
        return maximum
    return value


def _localized_text(english: str, vedic: str) -> dict[str, str]:
    return {"english": english, "vedic": vedic}

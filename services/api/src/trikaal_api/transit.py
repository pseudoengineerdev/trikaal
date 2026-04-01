from __future__ import annotations

from typing import Any

from trikaal_api.report_contract import SnapshotContract

_RASHI_ORDER = [
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
]

_RASHI_ALIASES = {
    "Mitu": "Mith",
    "Maka": "Makar",
}

_TRANSIT_GRAHA_CONFIG: tuple[dict[str, str], ...] = (
    {
        "key": "moon",
        "focus_tag": "Emotions",
        "title_english": "Transit Moon focus for today",
        "title_vedic": "Daily Chandra transit focus",
    },
    {
        "key": "sun",
        "focus_tag": "Leadership",
        "title_english": "Transit Sun focus for today",
        "title_vedic": "Daily Surya transit focus",
    },
    {
        "key": "shani",
        "focus_tag": "Discipline",
        "title_english": "Transit Saturn focus for today",
        "title_vedic": "Daily Shani transit focus",
    },
)

_HOUSE_THEMES_EN = {
    1: "self and vitality",
    2: "wealth and speech",
    3: "effort and communication",
    4: "home and emotional grounding",
    5: "creativity and children",
    6: "service and problem-solving",
    7: "partnerships and agreements",
    8: "change and deep processing",
    9: "learning and guidance",
    10: "career and visible work",
    11: "gains and networks",
    12: "rest, closure, and release",
}

_HOUSE_THEMES_VE = {
    1: "tanu (self and vitality)",
    2: "dhana (wealth and speech)",
    3: "sahaja (effort and communication)",
    4: "sukha (home and grounding)",
    5: "putra (creativity and legacy)",
    6: "ripu (service and obstacles)",
    7: "yuvati (partnerships and agreements)",
    8: "randhra (transformation and depth)",
    9: "dharma (learning and guidance)",
    10: "karma (work and public role)",
    11: "labha (gains and circles)",
    12: "vyaya (release and retreat)",
}

_RASHI_NAMES = {
    "Mesh": {"english": "Aries", "vedic": "Mesha"},
    "Vrish": {"english": "Taurus", "vedic": "Vrishabha"},
    "Mith": {"english": "Gemini", "vedic": "Mithuna"},
    "Kark": {"english": "Cancer", "vedic": "Karka"},
    "Simh": {"english": "Leo", "vedic": "Simha"},
    "Kany": {"english": "Virgo", "vedic": "Kanya"},
    "Tula": {"english": "Libra", "vedic": "Tula"},
    "Vrsc": {"english": "Scorpio", "vedic": "Vrischika"},
    "Dhanu": {"english": "Sagittarius", "vedic": "Dhanu"},
    "Makar": {"english": "Capricorn", "vedic": "Makara"},
    "Kumb": {"english": "Aquarius", "vedic": "Kumbha"},
    "Meen": {"english": "Pisces", "vedic": "Meena"},
}

_GRAHA_NAMES = {
    "moon": {"english": "Moon", "vedic": "Chandra"},
    "sun": {"english": "Sun", "vedic": "Surya"},
    "shani": {"english": "Saturn", "vedic": "Shani"},
}


def build_daily_transit_brief(
    *,
    natal_snapshot: SnapshotContract,
    transit_snapshot: SnapshotContract,
    as_of_local_iso: str,
    timezone: str,
) -> dict[str, Any]:
    natal_lagna = _normalize_rashi(natal_snapshot.varga.d1.lagna_rashi)
    cards: list[dict[str, Any]] = []

    for config in _TRANSIT_GRAHA_CONFIG:
        key = config["key"]
        transit_row = getattr(transit_snapshot.graha_table, key)
        natal_row = getattr(natal_snapshot.graha_table, key)

        transit_rashi = _normalize_rashi(transit_row.rashi)
        house_from_lagna = _house_from_lagna(
            lagna_rashi=natal_lagna,
            transit_rashi=transit_rashi,
        )
        delta_deg = _angular_distance(
            transit_row.sidereal_deg_raw,
            natal_row.sidereal_deg_raw,
        )
        intensity = _intensity_label(delta_deg)

        do_items, watch_items = _build_action_lines(
            key=key,
            house=house_from_lagna,
            intensity=intensity,
        )

        cards.append(
            {
                "card_id": f"daily_transit_{key}",
                "transit_graha_key": key,
                "transit_house_from_lagna": house_from_lagna,
                "transit_rashi": transit_rashi,
                "focus_tag": config["focus_tag"],
                "title": _localized_text(
                    config["title_english"],
                    config["title_vedic"],
                ),
                "summary": _localized_text(
                    (
                        f"Transit {_graha_name(key, 'english')} is in "
                        f"H{house_from_lagna} ({_HOUSE_THEMES_EN[house_from_lagna]}) "
                        f"in {_rashi_name(transit_rashi, 'english')} today."
                    ),
                    (
                        f"Transit {_graha_name(key, 'vedic')} is in "
                        f"{house_from_lagna}th Bhava "
                        f"({_HOUSE_THEMES_VE[house_from_lagna]}) "
                        f"in {_rashi_name(transit_rashi, 'vedic')} today."
                    ),
                ),
                "do_items": do_items,
                "watch_items": watch_items,
            }
        )

    return {
        "version": "v1",
        "as_of_local_iso": as_of_local_iso,
        "timezone": timezone,
        "cards": cards,
    }


def _build_action_lines(
    *,
    key: str,
    house: int,
    intensity: str,
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    if key == "moon":
        do_items = [
            _localized_text(
                (
                    "Keep emotional decisions inside a 24-hour review cycle "
                    f"while Moon activates H{house}."
                ),
                (
                    f"While Chandra activates {house}th Bhava, review "
                    "emotional decisions after one full day."
                ),
            ),
            _localized_text(
                "Protect sleep and hydration first; mental clarity depends on it today.",
                "Prioritize nidra and hydration first; manas clarity depends on this today.",
            ),
        ]
        watch_items = [
            _localized_text(
                "Avoid taking temporary mood shifts as final truth.",
                "Do not treat temporary manas shifts as final reality.",
            ),
            _localized_text(
                f"Intensity is {intensity}; avoid overreaction in {_HOUSE_THEMES_EN[house]}.",
                f"Intensity is {intensity}; avoid overreaction in {_HOUSE_THEMES_VE[house]}.",
            ),
        ]
        return do_items, watch_items

    if key == "sun":
        do_items = [
            _localized_text(
                f"Take one visible leadership action in {_HOUSE_THEMES_EN[house]} today.",
                f"Take one visible Surya-aligned action in {_HOUSE_THEMES_VE[house]} today.",
            ),
            _localized_text(
                "Lead by clarity and accountability, not force.",
                "Lead through clarity and kartavya, not pressure.",
            ),
        ]
        watch_items = [
            _localized_text(
                "Avoid ego-driven confrontation in sensitive conversations.",
                "Avoid ahankara-driven confrontation in sensitive talks.",
            ),
            _localized_text(
                f"With {intensity} intensity, avoid overcommitting your energy reserves.",
                f"With {intensity} intensity, avoid overextending your prana.",
            ),
        ]
        return do_items, watch_items

    do_items = [
        _localized_text(
            f"Build one disciplined routine for {_HOUSE_THEMES_EN[house]} and follow it today.",
            f"Build one Shani-style routine for {_HOUSE_THEMES_VE[house]} and follow it today.",
        ),
        _localized_text(
            "Focus on steady output over quick wins.",
            "Prefer stable karma output over fast but unstable wins.",
        ),
    ]
    watch_items = [
        _localized_text(
            "Avoid fear-based delay once the right next step is clear.",
            "Avoid bhaya-driven delay once the next dharmic step is clear.",
        ),
        _localized_text(
            f"At {intensity} intensity, keep boundaries with workload and obligations.",
            f"At {intensity} intensity, keep clear limits around commitments and duties.",
        ),
    ]
    return do_items, watch_items


def _house_from_lagna(*, lagna_rashi: str, transit_rashi: str) -> int:
    normalized_lagna = _normalize_rashi(lagna_rashi)
    normalized_transit = _normalize_rashi(transit_rashi)
    lagna_index = _RASHI_ORDER.index(normalized_lagna)
    transit_index = _RASHI_ORDER.index(normalized_transit)
    return ((transit_index - lagna_index) % 12) + 1


def _intensity_label(delta_deg: float) -> str:
    if delta_deg <= 4.0:
        return "high"
    if delta_deg <= 12.0:
        return "medium"
    return "emerging"


def _angular_distance(left: float, right: float) -> float:
    raw = abs((left - right) % 360.0)
    return min(raw, 360.0 - raw)


def _normalize_rashi(raw: str) -> str:
    key = raw.strip()
    return _RASHI_ALIASES.get(key, key)


def _rashi_name(rashi_key: str, mode: str) -> str:
    normalized = _normalize_rashi(rashi_key)
    return _RASHI_NAMES.get(normalized, {"english": normalized, "vedic": normalized})[mode]


def _graha_name(key: str, mode: str) -> str:
    return _GRAHA_NAMES[key][mode]


def _localized_text(english: str, vedic: str) -> dict[str, str]:
    return {"english": english, "vedic": vedic}

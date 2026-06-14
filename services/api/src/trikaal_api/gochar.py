"""Gochar (planetary transit) compute endpoint.

Builds the full transit reading the mobile feature renders: every graha's live
sign / nakshatra / motion / combustion, its house from both the natal Moon
(classical Chandra-gochara) and the natal Lagna, the classical phala verdict with
Vedha obstruction, sign-ingress and retrograde-station dates, the Saturn Sade
Sati / Dhaiya windows, and the Ashtakavarga transit strength.

The astronomy (positions, ingress/station searches, Ashtakavarga) comes from the
engine — this module only assembles it and applies the classical *rule* tables
(which houses-from-Moon are auspicious, the Vedha pairs, the dignity signs). Those
tables were independently derived and reconciled against BPHS / Phaladeepika.
"""

from __future__ import annotations

import sys
from datetime import datetime
from typing import Any
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.place_models import CustomPlaceInput
from trikaal_api.resolver import PlaceResolution, resolve_place

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import (
    BirthEvent,
    CalculationProfile,
    compute_chart_snapshot,
    compute_vimshottari_dasha,
)
from vedic_engine import gochar as engine_gochar

# --------------------------------------------------------------------------- #
# Vocabulary
# --------------------------------------------------------------------------- #
_GRAHA_ORDER = (
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

_RASHI_BY_INDEX: tuple[dict[str, str], ...] = (
    {"english": "Aries", "vedic": "Mesha"},
    {"english": "Taurus", "vedic": "Vrishabha"},
    {"english": "Gemini", "vedic": "Mithuna"},
    {"english": "Cancer", "vedic": "Karka"},
    {"english": "Leo", "vedic": "Simha"},
    {"english": "Virgo", "vedic": "Kanya"},
    {"english": "Libra", "vedic": "Tula"},
    {"english": "Scorpio", "vedic": "Vrischika"},
    {"english": "Sagittarius", "vedic": "Dhanu"},
    {"english": "Capricorn", "vedic": "Makara"},
    {"english": "Aquarius", "vedic": "Kumbha"},
    {"english": "Pisces", "vedic": "Meena"},
)

# --------------------------------------------------------------------------- #
# Classical rule tables (derived + reconciled against BPHS / Phaladeepika).
# House numbers are counted FROM THE NATAL MOON (Janma Rashi).
# --------------------------------------------------------------------------- #
# Houses-from-Moon where each graha's transit gives auspicious results.
_PHALA_FAVOURABLE_HOUSES: dict[str, frozenset[int]] = {
    "sun": frozenset({3, 6, 10, 11}),
    "moon": frozenset({1, 3, 6, 7, 10, 11}),
    "mangal": frozenset({3, 6, 11}),
    "budha": frozenset({2, 4, 6, 8, 10, 11}),
    "guru": frozenset({2, 5, 7, 9, 11}),
    "shukra": frozenset({1, 2, 3, 4, 5, 8, 9, 11, 12}),
    "shani": frozenset({3, 6, 11}),
    "rahu": frozenset({3, 6, 11}),
    "ketu": frozenset({3, 6, 11}),
}

# {favourable house: obstructing vedha house}. Only the seven classical planets
# have a Vedha table; the nodes have none.
_VEDHA_POINTS: dict[str, dict[int, int]] = {
    "sun": {3: 9, 6: 12, 10: 4, 11: 5},
    "moon": {1: 5, 3: 9, 6: 12, 7: 2, 10: 4, 11: 8},
    "mangal": {3: 12, 6: 9, 11: 5},
    "budha": {2: 5, 4: 3, 6: 9, 8: 1, 10: 8, 11: 12},
    "guru": {2: 12, 5: 4, 7: 3, 9: 10, 11: 8},
    "shukra": {1: 8, 2: 7, 3: 1, 4: 10, 5: 9, 8: 5, 9: 11, 11: 6, 12: 3},
    "shani": {3: 12, 6: 9, 11: 5},
}

# Planet pairs that never obstruct (cast Vedha on) each other.
_VEDHA_EXCEPTIONS: frozenset[frozenset[str]] = frozenset(
    {frozenset({"sun", "shani"}), frozenset({"moon", "budha"})}
)
_VEDHA_CASTERS = frozenset(_VEDHA_POINTS.keys())

# Dignity signs by sign index (0 = Aries). Nodes carry no classical dignity.
# Exaltation/debilitation/own are read whole-sign (the universal convention),
# but moolatrikona is a *degree band* within its sign — beyond it the graha is
# merely in its own sign — so it carries an explicit (lo, hi) degree range.
def _dignity(
    exalted: int,
    debilitated: int,
    mt_sign: int,
    mt_deg: tuple[float, float],
    own: set[int],
) -> dict[str, object]:
    return {
        "exalted": exalted,
        "debilitated": debilitated,
        "moolatrikona": mt_sign,
        "mt_deg": mt_deg,
        "own": frozenset(own),
    }


_DIGNITY: dict[str, dict[str, object]] = {
    "sun": _dignity(0, 6, 4, (0.0, 20.0), {4}),
    "moon": _dignity(1, 7, 1, (3.0, 30.0), {3}),
    "mangal": _dignity(9, 3, 0, (0.0, 12.0), {0, 7}),
    "budha": _dignity(5, 11, 5, (16.0, 20.0), {2, 5}),
    "guru": _dignity(3, 9, 8, (0.0, 10.0), {8, 11}),
    "shukra": _dignity(11, 5, 6, (0.0, 15.0), {1, 6}),
    "shani": _dignity(6, 0, 10, (0.0, 20.0), {9, 10}),
}

_SADE_SATI_HOUSES = frozenset({12, 1, 2})
_KANTAKA_DHAIYA_HOUSE = 4
_ASHTAMA_DHAIYA_HOUSE = 8

_BAV_KEYS = frozenset({"sun", "moon", "mangal", "budha", "guru", "shukra", "shani"})

# Only the slow planets' exaltation/debilitation is steady enough to headline.
_DIGNITY_HIGHLIGHT_PLANETS = frozenset({"mangal", "guru", "shani"})

# The Vimshottari dasha engine names its lords in English (venus, mars, jupiter,
# saturn, mercury); the gochar tables use the Sanskrit graha keys. Translate at
# the boundary so the dasha-connection check actually matches (they only overlap
# on sun/moon/rahu/ketu, which is why this bug hid for those dashas).
_DASHA_LORD_TO_GOCHAR = {
    "venus": "shukra",
    "mars": "mangal",
    "jupiter": "guru",
    "saturn": "shani",
    "mercury": "budha",
}

# --------------------------------------------------------------------------- #
# Jupiter-Saturn double transit (Guru-Shani gochar) — the classical event-timing
# marker. A graha "influences" a sign that it OCCUPIES or ASPECTS by graha
# drishti. Beyond the universal 7th aspect, Jupiter casts special full aspects on
# the 5th and 9th, and Saturn on the 3rd and 10th (BPHS graha drishti). Offsets
# are signs ahead of the planet's own sign (0 = occupies).
_JUPITER_INFLUENCE: dict[int, str] = {0: "occupies", 4: "aspect_5", 6: "aspect_7", 8: "aspect_9"}
_SATURN_INFLUENCE: dict[int, str] = {0: "occupies", 2: "aspect_3", 6: "aspect_7", 9: "aspect_10"}

# Natal graha drishti — signs (offsets ahead of a planet's own) it aspects. Every
# graha casts the universal 7th aspect; Mars adds 4th/8th, Jupiter 5th/9th,
# Saturn 3rd/10th (BPHS). Used for the dasha-connection (sambandha) test. The
# mean nodes are given no classical graha drishti, so a Rahu/Ketu dasha lord
# connects to a bhava only by occupying it.
_ASPECT_OFFSETS: dict[str, tuple[int, ...]] = {
    "sun": (6,),
    "moon": (6,),
    "mangal": (3, 6, 7),
    "budha": (6,),
    "guru": (4, 6, 8),
    "shukra": (6,),
    "shani": (2, 6, 9),
    "rahu": (),
    "ketu": (),
}

# Rashi lords (graha-adhipati), index 0 = Aries. Traditional 7-graha rulership —
# no outer planets, since this is sidereal Jyotisha.
_SIGN_LORDS: tuple[str, ...] = (
    "mangal",  # Aries
    "shukra",  # Taurus
    "budha",   # Gemini
    "moon",    # Cancer
    "sun",     # Leo
    "budha",   # Virgo
    "shukra",  # Libra
    "mangal",  # Scorpio
    "guru",    # Sagittarius
    "shani",   # Capricorn
    "shani",   # Aquarius
    "guru",    # Pisces
)

# Dominant event significator (karaka) per bhava. Classical houses carry several
# naisargika karakas; this is a curated "primary significator" table — the
# event-critical picks (5=Jupiter/children, 7=Venus/spouse, 8=Saturn/longevity,
# 10=Saturn/karma) are the standard ones — not the verbatim full BPHS list.
_BHAVA_KARAKA: dict[int, str] = {
    1: "sun",      # body / self (atma)
    2: "guru",     # wealth / family (dhana)
    3: "mangal",   # courage / siblings
    4: "moon",     # mother / happiness (sukha)
    5: "guru",     # children (putra)
    6: "mangal",   # enemies / competition / debt
    7: "shukra",   # spouse (kalatra)
    8: "shani",    # longevity / transformation (ayush)
    9: "guru",     # fortune / dharma (bhagya)
    10: "shani",   # profession (karma)
    11: "guru",    # gains (labha)
    12: "shani",   # loss / moksha (vyaya)
}

_BHAVA_DT_SIGNIFICATIONS: dict[int, list[str]] = {
    1: ["fresh starts", "health & vitality", "a new self-image"],
    2: ["wealth & savings", "family additions", "speech & food"],
    3: ["courage & initiative", "new skills", "siblings & short travel"],
    4: ["home & property", "vehicles", "mother & inner peace"],
    5: ["children", "education & exams", "romance & creativity"],
    6: ["clearing debts", "recovery & service/job", "winning disputes"],
    7: ["marriage", "partnership & business", "contracts"],
    8: ["inheritance & insurance", "deep change", "occult & longevity"],
    9: ["fortune & dharma", "higher studies", "pilgrimage & the guru"],
    10: ["career rise & promotion", "status", "public recognition"],
    11: ["gains & income", "fulfilled desires", "network growth"],
    12: ["foreign moves", "spiritual retreat", "large expenses & letting go"],
}


# --------------------------------------------------------------------------- #
# Request / response models
# --------------------------------------------------------------------------- #
class TransitComputeRequest(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None
    as_of_date: str | None = Field(default=None, pattern=r"^\d{4}-\d{2}-\d{2}$")
    observation_place: str | None = None
    observation_custom_place: CustomPlaceInput | None = None


class LocalizedName(BaseModel):
    english: str
    vedic: str


class GocharAsOf(BaseModel):
    date: str
    local_iso: str
    timezone: str
    is_today: bool


class GocharPlaceInfo(BaseModel):
    place_label: str
    latitude: float
    longitude: float
    timezone: str


class GocharNatal(BaseModel):
    moon_rashi_index: int
    moon_rashi: LocalizedName
    moon_nakshatra: str
    moon_pada: int
    lagna_rashi_index: int
    lagna_rashi: LocalizedName
    sun_rashi_index: int
    sun_rashi: LocalizedName


class GocharPhala(BaseModel):
    favourable: bool
    has_vedha_rule: bool
    vedha_obstructed: bool
    vedha_house_from_moon: int | None
    vedha_by: str | None


class GocharIngress(BaseModel):
    entered_iso: str | None
    entered_date: str | None
    leaves_iso: str | None
    leaves_date: str | None


class GocharStation(BaseModel):
    motion: str
    next_station_iso: str | None
    next_station_date: str | None
    since_iso: str | None
    since_date: str | None


class GocharAshtakavargaCell(BaseModel):
    bindus: int | None
    max_bindus: int
    sarva_bindus: int


class GocharPlanet(BaseModel):
    key: str
    name: LocalizedName
    rashi_index: int
    rashi: LocalizedName
    degree_in_sign: float
    nakshatra: str
    pada: int
    motion: str
    retrograde: bool
    combust: bool
    dignity: str
    house_from_moon: int
    house_from_lagna: int
    phala_from_moon: GocharPhala
    ingress: GocharIngress
    station: GocharStation
    ashtakavarga: GocharAshtakavargaCell


class SaturnPhaseLeg(BaseModel):
    phase: str
    house_from_moon: int
    rashi_index: int
    rashi: LocalizedName
    start_iso: str | None
    start_date: str | None
    end_iso: str | None
    end_date: str | None


class SaturnGochar(BaseModel):
    house_from_moon: int
    rashi_index: int
    rashi: LocalizedName
    status: str
    phase: str | None
    window_start_iso: str | None
    window_start_date: str | None
    window_end_iso: str | None
    window_end_date: str | None
    progress_percent: float | None
    legs: list[SaturnPhaseLeg]
    next_start_iso: str | None
    next_start_date: str | None


class GocharHighlight(BaseModel):
    type: str
    planet_key: str
    date: str | None
    rashi_index: int | None


class AshtakavargaTables(BaseModel):
    sarva: list[int]
    bhinna: dict[str, list[int]]


class DoubleTransitSign(BaseModel):
    """A sign jointly influenced by transiting Jupiter and Saturn."""

    sign_index: int
    rashi: LocalizedName
    jupiter_relation: str  # occupies | aspect_5 | aspect_7 | aspect_9
    saturn_relation: str  # occupies | aspect_3 | aspect_7 | aspect_10
    house_from_moon: int
    house_from_lagna: int


class DoubleTransitBhava(BaseModel):
    """A natal bhava (from Lagna) and how strongly the double transit lights it.

    Faithful to the classical Guru-Shani timing method: the bhava is *primary*
    when Jupiter and Saturn jointly influence it from the Lagna AND the Moon; the
    natural karaka being hit *confirms* it; and — the load-bearing leg — the
    event only ripens when the running Vimshottari dasha lord is connected to the
    bhava by any of the four classical sambandha types (lordship, occupancy,
    karaka, or aspect). ("Dasha promises, transit times.") The bhava lord being
    hit by the double transit is a supportive signal kept for information only
    (not scored).
    """

    house: int
    sign_index: int
    rashi: LocalizedName
    from_lagna: bool  # primary
    from_moon: bool  # primary
    karaka_key: str
    karaka_under_double_transit: bool  # confirmation
    dasha_linked: bool  # the dasha gate
    lord_key: str
    lord_under_double_transit: bool  # supportive only, not scored
    is_double_transit: bool  # from_lagna and from_moon (a strong transit)
    is_event_window: bool  # double transit AND dasha agrees (the real marker)
    tier: str  # event | strong | building | mild | quiet
    strength_score: int  # weighted 0..7: lagna2 + moon2 + karaka1 + dasha2
    significations: list[str]


class DoubleTransit(BaseModel):
    jupiter_sign_index: int
    saturn_sign_index: int
    double_transit_sign_indices: list[int]
    active: bool
    maha_dasha_lord: str | None
    antar_dasha_lord: str | None
    headline_houses: list[int]  # bhavas hit from BOTH Lagna and Moon (strong transit)
    event_window_houses: list[int]  # strong transit AND dasha agrees
    signs: list[DoubleTransitSign]
    bhavas: list[DoubleTransitBhava]


class TransitComputeResponse(BaseModel):
    profile: dict[str, Any]
    as_of: GocharAsOf
    observation_place: GocharPlaceInfo
    natal: GocharNatal
    planets: list[GocharPlanet]
    saturn: SaturnGochar
    double_transit: DoubleTransit
    ashtakavarga: AshtakavargaTables
    highlights: list[GocharHighlight]


# --------------------------------------------------------------------------- #
# Builder
# --------------------------------------------------------------------------- #
def compute_transit(request: TransitComputeRequest) -> TransitComputeResponse:
    profile = CalculationProfile()

    natal_place = _resolve(request.place_of_birth, request.custom_place)
    natal_event = _birth_event(
        date=request.date_of_birth,
        time=request.time_of_birth,
        place=natal_place,
    )
    natal_snapshot = compute_chart_snapshot(birth_event=natal_event, profile=profile)

    observation_place = (
        _resolve(request.observation_place, request.observation_custom_place)
        if request.observation_place or request.observation_custom_place
        else natal_place
    )
    tz = ZoneInfo(observation_place.timezone)
    instant, is_today = _resolve_instant(request.as_of_date, tz)

    transit_event = _birth_event(
        date=instant.strftime("%Y-%m-%d"),
        time=instant.strftime("%H:%M"),
        place=observation_place,
    )
    transit_snapshot = compute_chart_snapshot(birth_event=transit_event, profile=profile)
    jd = engine_gochar.julian_day_from_utc(instant.astimezone(ZoneInfo("UTC")))

    moon_sign = engine_gochar.sign_index_from_rashi_name(
        natal_snapshot["vedic"]["moon_rashi"]
    )
    lagna_sign = engine_gochar.sign_index_from_rashi_name(
        natal_snapshot["vedic"]["lagna_rashi"]
    )

    natal_indices = {
        key: engine_gochar.sign_index_from_rashi_name(
            natal_snapshot["graha_table"][key]["rashi"]
        )
        for key in (*_GRAHA_ORDER, "lagna")
    }
    ashtakavarga = engine_gochar.compute_ashtakavarga(natal_indices)

    # Transit sign index + house-from-Moon for every graha (needed up front so
    # Vedha can look at who else occupies the obstructing house).
    transit_sign: dict[str, int] = {}
    house_from_moon: dict[str, int] = {}
    for key in _GRAHA_ORDER:
        sign = engine_gochar.sign_index_from_rashi_name(
            transit_snapshot["graha_table"][key]["rashi"]
        )
        transit_sign[key] = sign
        house_from_moon[key] = ((sign - moon_sign) % 12) + 1

    occupants_by_house: dict[int, list[str]] = {house: [] for house in range(1, 13)}
    for key, house in house_from_moon.items():
        occupants_by_house[house].append(key)

    planets = [
        _build_planet(
            key=key,
            jd=jd,
            tz=tz,
            transit_row=transit_snapshot["graha_table"][key],
            transit_sign=transit_sign[key],
            moon_sign=moon_sign,
            lagna_sign=lagna_sign,
            house_from_moon=house_from_moon[key],
            occupants_by_house=occupants_by_house,
            ashtakavarga=ashtakavarga,
        )
        for key in _GRAHA_ORDER
    ]

    # Running Vimshottari dasha at the viewed instant gates the double transit:
    # the dasha promises an event, the transit times it.
    dasha = compute_vimshottari_dasha(
        birth_event=natal_event,
        profile=profile,
        as_of=instant.astimezone(ZoneInfo("UTC")),
    )
    maha_lord = _active_lord(dasha.get("maha_timeline"))
    antar_lord = _active_lord(dasha.get("antar_timeline_current_maha"))

    saturn = _build_saturn(jd=jd, tz=tz, moon_sign=moon_sign)
    double_transit = _build_double_transit(
        guru_sign=transit_sign["guru"],
        shani_sign=transit_sign["shani"],
        lagna_sign=lagna_sign,
        moon_sign=moon_sign,
        natal_indices=natal_indices,
        maha_lord=maha_lord,
        antar_lord=antar_lord,
    )
    highlights = _build_highlights(
        planets=planets, saturn=saturn, double_transit=double_transit, tz=tz, jd=jd
    )

    return TransitComputeResponse(
        profile=_profile_as_dict(profile),
        as_of=GocharAsOf(
            date=instant.strftime("%Y-%m-%d"),
            local_iso=instant.isoformat(timespec="minutes"),
            timezone=observation_place.timezone,
            is_today=is_today,
        ),
        observation_place=GocharPlaceInfo(
            place_label=observation_place.place_label,
            latitude=observation_place.latitude,
            longitude=observation_place.longitude,
            timezone=observation_place.timezone,
        ),
        natal=GocharNatal(
            moon_rashi_index=moon_sign,
            moon_rashi=_rashi_name(moon_sign),
            moon_nakshatra=natal_snapshot["vedic"]["moon_nakshatra"],
            moon_pada=natal_snapshot["vedic"]["moon_pada"],
            lagna_rashi_index=lagna_sign,
            lagna_rashi=_rashi_name(lagna_sign),
            sun_rashi_index=engine_gochar.sign_index_from_rashi_name(
                natal_snapshot["vedic"]["sun_rashi"]
            ),
            sun_rashi=_rashi_name(
                engine_gochar.sign_index_from_rashi_name(
                    natal_snapshot["vedic"]["sun_rashi"]
                )
            ),
        ),
        planets=planets,
        saturn=saturn,
        double_transit=double_transit,
        ashtakavarga=AshtakavargaTables(
            sarva=ashtakavarga["sav"],
            bhinna=ashtakavarga["bav"],
        ),
        highlights=highlights,
    )


def _build_planet(
    *,
    key: str,
    jd: float,
    tz: ZoneInfo,
    transit_row: dict[str, Any],
    transit_sign: int,
    moon_sign: int,
    lagna_sign: int,
    house_from_moon: int,
    occupants_by_house: dict[int, list[str]],
    ashtakavarga: dict[str, Any],
) -> GocharPlanet:
    motion = engine_gochar.motion_state(jd, key)
    entered, leaves = engine_gochar.sign_occupancy_window(jd, key)
    next_station = engine_gochar.next_station(jd, key)
    since_station = (
        engine_gochar.previous_station(jd, key) if motion == "retrograde" else None
    )

    house_from_lagna = ((transit_sign - lagna_sign) % 12) + 1
    bindus = ashtakavarga["bav"][key][transit_sign] if key in _BAV_KEYS else None
    degree_in_sign = round(float(transit_row["sidereal_deg"]) % 30.0, 2)

    return GocharPlanet(
        key=key,
        name=LocalizedName(**_GRAHA_NAMES[key]),
        rashi_index=transit_sign,
        rashi=_rashi_name(transit_sign),
        degree_in_sign=degree_in_sign,
        nakshatra=str(transit_row["nakshatra"]),
        pada=int(transit_row["pada"]),
        motion=motion,
        retrograde=motion == "retrograde",
        combust=bool(transit_row["combust"]),
        dignity=_dignity_for(key, transit_sign, degree_in_sign),
        house_from_moon=house_from_moon,
        house_from_lagna=house_from_lagna,
        phala_from_moon=_phala(
            key=key,
            house_from_moon=house_from_moon,
            occupants_by_house=occupants_by_house,
        ),
        ingress=GocharIngress(
            entered_iso=_iso(entered, tz),
            entered_date=_date(entered, tz),
            leaves_iso=_iso(leaves, tz),
            leaves_date=_date(leaves, tz),
        ),
        station=GocharStation(
            motion=motion,
            next_station_iso=_iso(next_station, tz),
            next_station_date=_date(next_station, tz),
            since_iso=_iso(since_station, tz),
            since_date=_date(since_station, tz),
        ),
        ashtakavarga=GocharAshtakavargaCell(
            bindus=bindus,
            max_bindus=8,
            sarva_bindus=ashtakavarga["sav"][transit_sign],
        ),
    )


def _phala(
    *,
    key: str,
    house_from_moon: int,
    occupants_by_house: dict[int, list[str]],
) -> GocharPhala:
    favourable = house_from_moon in _PHALA_FAVOURABLE_HOUSES.get(key, frozenset())
    vedha_table = _VEDHA_POINTS.get(key, {})
    has_vedha_rule = key in _VEDHA_CASTERS
    vedha_house = vedha_table.get(house_from_moon)

    vedha_obstructed = False
    vedha_by: str | None = None
    if favourable and vedha_house is not None:
        for other in occupants_by_house.get(vedha_house, []):
            if other == key or other not in _VEDHA_CASTERS:
                continue
            if frozenset({key, other}) in _VEDHA_EXCEPTIONS:
                continue
            vedha_obstructed = True
            vedha_by = other
            break

    return GocharPhala(
        favourable=favourable,
        has_vedha_rule=has_vedha_rule,
        vedha_obstructed=vedha_obstructed,
        vedha_house_from_moon=vedha_house if favourable else None,
        vedha_by=vedha_by,
    )


def _dignity_for(key: str, sign_index: int, degree_in_sign: float) -> str:
    table = _DIGNITY.get(key)
    if table is None:
        return "none"
    # Exaltation/debilitation are read whole-sign (the mainstream convention, and
    # consistent with how every graha is treated here). This intentionally takes
    # precedence over the moolatrikona degree band. For the Moon (exalt &
    # moolatrikona both Taurus) and Mercury (both Virgo) the two signs coincide,
    # so those grahas always read "exalted" across the whole sign and never
    # "moolatrikona" — by design. The mt_deg band is consulted only for grahas
    # whose moolatrikona sign differs from their exaltation sign (Sun, Mars,
    # Jupiter, Venus, Saturn). See test_dignity_moon_mercury_whole_sign_exalted.
    #
    # TODO(dignity): whole-sign exaltation is chosen for now. Revisit whether the
    # Moon (3-30° Taurus) and Mercury (16-20° Virgo) should instead show a
    # degree-precise "moolatrikona" in those bands. Deferred decision — see
    # gochar-feature-architecture memory note.
    if sign_index == table["exalted"]:
        return "exalted"
    if sign_index == table["debilitated"]:
        return "debilitated"
    if sign_index == table["moolatrikona"]:
        low, high = table["mt_deg"]  # type: ignore[misc]
        if low <= degree_in_sign < high:
            return "moolatrikona"
        # In the moolatrikona sign but past its degree band -> own sign.
    if sign_index in table["own"]:  # type: ignore[operator]
        return "own"
    return "none"


def _build_saturn(*, jd: float, tz: ZoneInfo, moon_sign: int) -> SaturnGochar:
    saturn_sign = engine_gochar.sign_index(jd, "shani")
    house = engine_gochar.saturn_relative_house(jd, moon_sign)

    if house in _SADE_SATI_HOUSES:
        status = "sade_sati"
    elif house == _KANTAKA_DHAIYA_HOUSE:
        status = "kantaka_dhaiya"
    elif house == _ASHTAMA_DHAIYA_HOUSE:
        status = "ashtama_dhaiya"
    else:
        status = "none"

    phase = {12: "rising", 1: "peak", 2: "setting"}.get(house) if status == "sade_sati" else None

    window_start = window_end = None
    progress = None
    legs: list[SaturnPhaseLeg] = []
    next_start = None

    if status == "sade_sati":
        window_start, window_end = engine_gochar.saturn_band_window(
            jd, moon_sign, set(_SADE_SATI_HOUSES)
        )
        if window_start is not None and window_end is not None:
            span = window_end - window_start
            if span > 0:
                progress = round(((jd - window_start) / span) * 100.0, 1)
            legs = _sade_sati_legs(window_start, window_end, moon_sign, tz)
    elif status in {"kantaka_dhaiya", "ashtama_dhaiya"}:
        band = {house}
        window_start, window_end = engine_gochar.saturn_band_window(jd, moon_sign, band)
        if window_start is not None and window_end is not None:
            span = window_end - window_start
            if span > 0:
                progress = round(((jd - window_start) / span) * 100.0, 1)
    else:
        next_start = engine_gochar.next_saturn_band_entry(jd, moon_sign, set(_SADE_SATI_HOUSES))

    return SaturnGochar(
        house_from_moon=house,
        rashi_index=saturn_sign,
        rashi=_rashi_name(saturn_sign),
        status=status,
        phase=phase,
        window_start_iso=_iso(window_start, tz),
        window_start_date=_date(window_start, tz),
        window_end_iso=_iso(window_end, tz),
        window_end_date=_date(window_end, tz),
        progress_percent=progress,
        legs=legs,
        next_start_iso=_iso(next_start, tz),
        next_start_date=_date(next_start, tz),
    )


def _sade_sati_legs(
    window_start: float,
    window_end: float,
    moon_sign: int,
    tz: ZoneInfo,
) -> list[SaturnPhaseLeg]:
    rising_sign = (moon_sign + 11) % 12
    peak_sign = moon_sign % 12
    setting_sign = (moon_sign + 1) % 12

    peak_start = engine_gochar.next_band_entry(
        window_start + 1.0, "shani", {peak_sign}, horizon_days=3500.0
    )
    setting_start = (
        engine_gochar.next_band_entry(
            peak_start + 1.0, "shani", {setting_sign}, horizon_days=3500.0
        )
        if peak_start is not None
        else None
    )

    legs = [
        SaturnPhaseLeg(
            phase="rising",
            house_from_moon=12,
            rashi_index=rising_sign,
            rashi=_rashi_name(rising_sign),
            start_iso=_iso(window_start, tz),
            start_date=_date(window_start, tz),
            end_iso=_iso(peak_start, tz),
            end_date=_date(peak_start, tz),
        ),
        SaturnPhaseLeg(
            phase="peak",
            house_from_moon=1,
            rashi_index=peak_sign,
            rashi=_rashi_name(peak_sign),
            start_iso=_iso(peak_start, tz),
            start_date=_date(peak_start, tz),
            end_iso=_iso(setting_start, tz),
            end_date=_date(setting_start, tz),
        ),
        SaturnPhaseLeg(
            phase="setting",
            house_from_moon=2,
            rashi_index=setting_sign,
            rashi=_rashi_name(setting_sign),
            start_iso=_iso(setting_start, tz),
            start_date=_date(setting_start, tz),
            end_iso=_iso(window_end, tz),
            end_date=_date(window_end, tz),
        ),
    ]
    return legs


def _build_highlights(
    *,
    planets: list[GocharPlanet],
    saturn: SaturnGochar,
    double_transit: DoubleTransit,
    tz: ZoneInfo,
    jd: float,
) -> list[GocharHighlight]:
    """A compact list of marquee events for the page's top strip. The mobile
    layer turns each tag into prose; here we only flag what is noteworthy."""
    highlights: list[GocharHighlight] = []

    # A double transit confirmed by the running dasha is the single strongest
    # event marker, so it leads the strip.
    if double_transit.event_window_houses:
        first_sign = (
            double_transit.double_transit_sign_indices[0]
            if double_transit.double_transit_sign_indices
            else None
        )
        highlights.append(
            GocharHighlight(
                type="double_transit",
                planet_key="guru",
                date=None,
                rashi_index=first_sign,
            )
        )

    if saturn.status != "none":
        highlights.append(
            GocharHighlight(
                type=saturn.status,
                planet_key="shani",
                date=saturn.window_end_date,
                rashi_index=saturn.rashi_index,
            )
        )

    now_utc = engine_gochar.jd_to_utc(jd)
    soon_threshold_days = 45.0
    for planet in planets:
        if planet.retrograde and planet.key not in {"rahu", "ketu"}:
            highlights.append(
                GocharHighlight(
                    type="retrograde",
                    planet_key=planet.key,
                    date=planet.station.next_station_date,
                    rashi_index=planet.rashi_index,
                )
            )
        # Only the slow planets' dignity is worth flagging: the Moon is exalted
        # for ~2 days every month and the Sun/Mercury/Venus for a few weeks, so
        # highlighting their dignity just makes the strip flicker. Mars, Jupiter
        # and Saturn hold a dignity for weeks-to-years — a real headline.
        if planet.key in _DIGNITY_HIGHLIGHT_PLANETS:
            if planet.dignity == "exalted":
                highlights.append(
                    GocharHighlight(
                        type="exalted",
                        planet_key=planet.key,
                        date=None,
                        rashi_index=planet.rashi_index,
                    )
                )
            elif planet.dignity == "debilitated":
                highlights.append(
                    GocharHighlight(
                        type="debilitated",
                        planet_key=planet.key,
                        date=None,
                        rashi_index=planet.rashi_index,
                    )
                )
        # Imminent sign change for the slower movers (the headline transit events).
        if planet.key in {"guru", "shani", "rahu", "ketu", "mangal"} and planet.ingress.leaves_iso:
            leaves = datetime.fromisoformat(planet.ingress.leaves_iso)
            days_away = (leaves - now_utc).total_seconds() / 86400.0
            if 0 <= days_away <= soon_threshold_days:
                highlights.append(
                    GocharHighlight(
                        type="sign_change",
                        planet_key=planet.key,
                        date=planet.ingress.leaves_date,
                        rashi_index=(planet.rashi_index + 1) % 12,
                    )
                )
    return highlights


# --------------------------------------------------------------------------- #
# Jupiter-Saturn double transit
# --------------------------------------------------------------------------- #
def _influence_signs(graha_sign: int, influence: dict[int, str]) -> set[int]:
    """The set of signs a graha occupies or aspects, given its sign + drishti map."""
    return {(graha_sign + offset) % 12 for offset in influence}


def _relation(graha_sign: int, target_sign: int, influence: dict[int, str]) -> str:
    """How a graha touches ``target_sign`` (``"occupies"`` / ``"aspect_N"`` / ``"none"``)."""
    return influence.get((target_sign - graha_sign) % 12, "none")


def _active_lord(timeline: object) -> str | None:
    """The active period's lord, translated to the gochar (Sanskrit) graha key."""
    if not isinstance(timeline, list):
        return None
    for period in timeline:
        if isinstance(period, dict) and period.get("active"):
            lord = period.get("lord_key")
            if not isinstance(lord, str):
                return None
            return _DASHA_LORD_TO_GOCHAR.get(lord, lord)
    return None


def _double_transit_tier(
    *,
    from_lagna: bool,
    from_moon: bool,
    karaka_hit: bool,
    dasha_linked: bool,
) -> str:
    both_frames = from_lagna and from_moon
    if both_frames and dasha_linked:
        return "event"
    if both_frames:
        return "strong"
    if (from_lagna or from_moon) and (dasha_linked or karaka_hit):
        return "building"
    if from_lagna or from_moon:
        return "mild"
    return "quiet"


def _build_double_transit(
    *,
    guru_sign: int,
    shani_sign: int,
    lagna_sign: int,
    moon_sign: int,
    natal_indices: dict[str, int],
    maha_lord: str | None,
    antar_lord: str | None,
) -> DoubleTransit:
    jupiter_signs = _influence_signs(guru_sign, _JUPITER_INFLUENCE)
    saturn_signs = _influence_signs(shani_sign, _SATURN_INFLUENCE)
    double_signs = jupiter_signs & saturn_signs
    ordered = sorted(double_signs)

    signs = [
        DoubleTransitSign(
            sign_index=sign,
            rashi=_rashi_name(sign),
            jupiter_relation=_relation(guru_sign, sign, _JUPITER_INFLUENCE),
            saturn_relation=_relation(shani_sign, sign, _SATURN_INFLUENCE),
            house_from_lagna=((sign - lagna_sign) % 12) + 1,
            house_from_moon=((sign - moon_sign) % 12) + 1,
        )
        for sign in ordered
    ]

    # Natal occupants of each sign, plus the signs each graha aspects natally —
    # the two positional legs of the dasha-connection (sambandha) check.
    occupants_by_sign: dict[int, set[str]] = {sign: set() for sign in range(12)}
    aspecting_by_sign: dict[int, set[str]] = {sign: set() for sign in range(12)}
    for key in _GRAHA_ORDER:
        natal_sign = natal_indices[key]
        occupants_by_sign[natal_sign].add(key)
        for offset in _ASPECT_OFFSETS[key]:
            aspecting_by_sign[(natal_sign + offset) % 12].add(key)
    dasha_lords = {lord for lord in (maha_lord, antar_lord) if lord}

    bhavas: list[DoubleTransitBhava] = []
    headline: list[int] = []
    event_windows: list[int] = []
    for house in range(1, 13):
        sign_from_lagna = (lagna_sign + house - 1) % 12
        sign_from_moon = (moon_sign + house - 1) % 12
        from_lagna = sign_from_lagna in double_signs
        from_moon = sign_from_moon in double_signs

        lord_key = _SIGN_LORDS[sign_from_lagna]
        lord_hit = natal_indices[lord_key] in double_signs
        karaka_key = _BHAVA_KARAKA[house]
        karaka_hit = natal_indices[karaka_key] in double_signs

        # Dasha is "connected" to the bhava when a running lord rules it, is its
        # karaka, sits in it, or aspects it natally — the four classical sambandha
        # types (lordship / karaka / occupancy / drishti).
        connectors = (
            {lord_key, karaka_key}
            | occupants_by_sign[sign_from_lagna]
            | aspecting_by_sign[sign_from_lagna]
        )
        dasha_linked = bool(dasha_lords & connectors)

        is_double = from_lagna and from_moon
        is_event = is_double and dasha_linked
        if is_double:
            headline.append(house)
        if is_event:
            event_windows.append(house)

        bhavas.append(
            DoubleTransitBhava(
                house=house,
                sign_index=sign_from_lagna,
                rashi=_rashi_name(sign_from_lagna),
                from_lagna=from_lagna,
                from_moon=from_moon,
                karaka_key=karaka_key,
                karaka_under_double_transit=karaka_hit,
                dasha_linked=dasha_linked,
                lord_key=lord_key,
                lord_under_double_transit=lord_hit,
                is_double_transit=is_double,
                is_event_window=is_event,
                tier=_double_transit_tier(
                    from_lagna=from_lagna,
                    from_moon=from_moon,
                    karaka_hit=karaka_hit,
                    dasha_linked=dasha_linked,
                ),
                # Weighted: the two frame legs are primary (2 each), the karaka
                # confirms (1), the dasha gate is decisive (2). The bhava lord is
                # informational and deliberately not counted.
                strength_score=(2 * int(from_lagna))
                + (2 * int(from_moon))
                + int(karaka_hit)
                + (2 * int(dasha_linked)),
                significations=_BHAVA_DT_SIGNIFICATIONS[house],
            )
        )

    return DoubleTransit(
        jupiter_sign_index=guru_sign,
        saturn_sign_index=shani_sign,
        double_transit_sign_indices=ordered,
        active=bool(ordered),
        maha_dasha_lord=maha_lord,
        antar_dasha_lord=antar_lord,
        headline_houses=headline,
        event_window_houses=event_windows,
        signs=signs,
        bhavas=bhavas,
    )


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _resolve_instant(as_of_date: str | None, tz: ZoneInfo) -> tuple[datetime, bool]:
    now_local = datetime.now(tz)
    if as_of_date is None:
        return now_local.replace(second=0, microsecond=0), True
    requested = datetime.strptime(as_of_date, "%Y-%m-%d").date()
    if requested == now_local.date():
        return now_local.replace(second=0, microsecond=0), True
    # A non-today day is read at local noon: stable, and the Moon's sign rarely
    # turns within the midday hours, so the headline reading is representative.
    noon = datetime(requested.year, requested.month, requested.day, 12, 0, tzinfo=tz)
    return noon, False


def _birth_event(*, date: str, time: str, place: PlaceResolution) -> BirthEvent:
    return BirthEvent(
        local_date=date,
        local_time=time,
        timezone=place.timezone,
        latitude=place.latitude,
        longitude=place.longitude,
        elevation_m=place.elevation_m,
        place_label=place.place_label,
    )


def _resolve(
    place_query: str | None,
    custom_place: CustomPlaceInput | None,
) -> PlaceResolution:
    if custom_place is not None:
        return custom_place.to_place_resolution()
    if place_query is None:
        raise ValueError("A place is required to compute a transit.")
    return resolve_place(place_query)


def _rashi_name(sign_index: int) -> LocalizedName:
    return LocalizedName(**_RASHI_BY_INDEX[sign_index % 12])


def _iso(jd: float | None, tz: ZoneInfo) -> str | None:
    if jd is None:
        return None
    return engine_gochar.jd_to_utc(jd).astimezone(tz).isoformat(timespec="minutes")


def _date(jd: float | None, tz: ZoneInfo) -> str | None:
    if jd is None:
        return None
    return engine_gochar.jd_to_utc(jd).astimezone(tz).strftime("%Y-%m-%d")


def _profile_as_dict(profile: CalculationProfile) -> dict[str, str]:
    return {
        "profile_id": profile.profile_id,
        "zodiac_system": profile.zodiac_system,
        "ayanamsha": profile.ayanamsha,
        "calculation_method": profile.calculation_method,
    }

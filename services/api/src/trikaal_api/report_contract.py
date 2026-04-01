from __future__ import annotations

from typing import Self

from pydantic import BaseModel, ConfigDict, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ProfileContract(StrictModel):
    profile_id: str
    zodiac_system: str
    ayanamsha: str
    calculation_method: str


class NormalizedInputContract(StrictModel):
    local_date: str
    local_time: str
    place_query: str


class ResolvedPlaceContract(StrictModel):
    place_label: str
    latitude: float
    longitude: float
    timezone: str
    elevation_m: float


class SnapshotMetaContract(StrictModel):
    status: str
    profile_id: str
    timezone: str
    utc_iso: str


class VaraContract(StrictModel):
    number: int
    name_vedic: str
    name_english: str


class TithiContract(StrictModel):
    number: int
    paksha: str
    paksha_english: str
    name_vedic: str
    name_english: str
    progress_percent: float


class NakshatraContract(StrictModel):
    number: int
    name_vedic: str
    name_english: str
    pada: int
    progress_percent: float


class YogaContract(StrictModel):
    number: int
    name_vedic: str
    name_english: str
    progress_percent: float


class KaranaContract(StrictModel):
    serial: int
    name_vedic: str
    name_english: str
    progress_percent: float


class SolarEventContract(StrictModel):
    utc_iso: str
    local_iso: str
    local_time: str


class PanchangaContract(StrictModel):
    vara: VaraContract
    tithi: TithiContract
    nakshatra: NakshatraContract
    yoga: YogaContract
    karana: KaranaContract
    sunrise: SolarEventContract
    sunset: SolarEventContract


class AstronomyContract(StrictModel):
    julian_day_utc: float
    drik_display_offset_deg: float
    drik_lagna_display_offset_deg: float

    sun_sidereal_deg: float
    sun_sidereal_deg_raw: float
    moon_sidereal_deg: float
    moon_sidereal_deg_raw: float
    mangal_sidereal_deg: float
    mangal_sidereal_deg_raw: float
    budha_sidereal_deg: float
    budha_sidereal_deg_raw: float
    guru_sidereal_deg: float
    guru_sidereal_deg_raw: float
    shukra_sidereal_deg: float
    shukra_sidereal_deg_raw: float
    shani_sidereal_deg: float
    shani_sidereal_deg_raw: float
    rahu_sidereal_deg: float
    rahu_sidereal_deg_raw: float
    ketu_sidereal_deg: float
    ketu_sidereal_deg_raw: float
    spashth_rahu_sidereal_deg: float
    spashth_rahu_sidereal_deg_raw: float
    spashth_ketu_sidereal_deg: float
    spashth_ketu_sidereal_deg_raw: float
    lagna_sidereal_deg: float
    lagna_sidereal_deg_raw: float


class VedicContract(StrictModel):
    sun_rashi: str
    sun_nakshatra: str
    sun_pada: int

    moon_rashi: str
    moon_nakshatra: str
    moon_pada: int

    lagna_rashi: str
    lagna_nakshatra: str
    lagna_pada: int

    mangal_rashi: str
    mangal_nakshatra: str
    mangal_pada: int

    budha_rashi: str
    budha_nakshatra: str
    budha_pada: int

    guru_rashi: str
    guru_nakshatra: str
    guru_pada: int

    shukra_rashi: str
    shukra_nakshatra: str
    shukra_pada: int

    shani_rashi: str
    shani_nakshatra: str
    shani_pada: int

    rahu_rashi: str
    rahu_nakshatra: str
    rahu_pada: int

    ketu_rashi: str
    ketu_nakshatra: str
    ketu_pada: int

    spashth_rahu_rashi: str
    spashth_rahu_nakshatra: str
    spashth_rahu_pada: int

    spashth_ketu_rashi: str
    spashth_ketu_nakshatra: str
    spashth_ketu_pada: int


class BhavaContract(StrictModel):
    lagna_house: int
    sun_house: int
    moon_house: int
    mangal_house: int
    budha_house: int
    guru_house: int
    shukra_house: int
    shani_house: int
    rahu_house: int
    ketu_house: int
    spashth_rahu_house: int
    spashth_ketu_house: int


class HouseContract(StrictModel):
    rashi: str
    occupants: list[str]


class DivisionContract(StrictModel):
    lagna_rashi: str
    houses: dict[str, HouseContract]

    @model_validator(mode="after")
    def validate_house_keys(self) -> Self:
        expected = {str(index) for index in range(1, 13)}
        actual = set(self.houses.keys())
        if actual != expected:
            missing = sorted(expected - actual)
            extra = sorted(actual - expected)
            raise ValueError(f"houses must contain keys 1..12 (missing={missing}, extra={extra})")
        return self


class VargaContract(StrictModel):
    d1: DivisionContract
    d9: DivisionContract


class GrahaEntryContract(StrictModel):
    key: str
    sidereal_deg: float
    sidereal_deg_raw: float
    speed_deg_per_day: float
    rashi: str
    nakshatra: str
    pada: int
    house: int
    d9_rashi: str
    d9_house: int
    retrograde: bool
    combust: bool


class GrahaTableContract(StrictModel):
    sun: GrahaEntryContract
    moon: GrahaEntryContract
    mangal: GrahaEntryContract
    budha: GrahaEntryContract
    guru: GrahaEntryContract
    shukra: GrahaEntryContract
    shani: GrahaEntryContract
    rahu: GrahaEntryContract
    ketu: GrahaEntryContract
    spashth_rahu: GrahaEntryContract
    spashth_ketu: GrahaEntryContract
    lagna: GrahaEntryContract


class SnapshotContract(StrictModel):
    meta: SnapshotMetaContract
    panchanga: PanchangaContract
    astronomy: AstronomyContract
    vedic: VedicContract
    bhava: BhavaContract
    varga: VargaContract
    graha_table: GrahaTableContract


class DashaPeriodContract(StrictModel):
    lord_key: str
    lord: str
    start: str
    end: str
    active: bool


class DashaContract(StrictModel):
    system: str
    as_of_iso: str
    birth_moon_nakshatra: str
    current_maha_dasha: str
    current_antar_dasha: str
    active_from: str
    active_until: str
    current_maha_start: str
    current_maha_end: str
    maha_timeline: list[DashaPeriodContract]
    antar_timeline_current_maha: list[DashaPeriodContract]

    @model_validator(mode="after")
    def validate_timeline_lengths(self) -> Self:
        if len(self.maha_timeline) != 9:
            raise ValueError("maha_timeline must contain 9 periods")
        if len(self.antar_timeline_current_maha) != 9:
            raise ValueError("antar_timeline_current_maha must contain 9 periods")
        return self


class LocalizedTextContract(StrictModel):
    english: str
    vedic: str


class InterpretationCardContract(StrictModel):
    card_id: str
    category: str
    confidence: str
    strength_score: float
    title: LocalizedTextContract
    summary: LocalizedTextContract
    impact: LocalizedTextContract
    evidence: list[LocalizedTextContract]

    @model_validator(mode="after")
    def validate_card(self) -> Self:
        allowed_categories = {"aspects", "yoga", "house_lord"}
        if self.category not in allowed_categories:
            raise ValueError(f"Unsupported interpretation category: {self.category}")
        allowed_confidence = {"high", "medium", "emerging"}
        if self.confidence not in allowed_confidence:
            raise ValueError(f"Unsupported interpretation confidence: {self.confidence}")
        if not (0.0 <= self.strength_score <= 1.0):
            raise ValueError("strength_score must be between 0 and 1")
        if not self.evidence:
            raise ValueError("evidence must contain at least one line")
        return self


class InterpretationsContract(StrictModel):
    version: str
    cards: list[InterpretationCardContract]


class DailyTransitCardContract(StrictModel):
    card_id: str
    transit_graha_key: str
    transit_house_from_lagna: int
    transit_rashi: str
    focus_tag: str
    title: LocalizedTextContract
    summary: LocalizedTextContract
    do_items: list[LocalizedTextContract]
    watch_items: list[LocalizedTextContract]

    @model_validator(mode="after")
    def validate_transit_card(self) -> Self:
        if not (1 <= self.transit_house_from_lagna <= 12):
            raise ValueError("transit_house_from_lagna must be between 1 and 12")
        if not self.do_items:
            raise ValueError("do_items must contain at least one line")
        if not self.watch_items:
            raise ValueError("watch_items must contain at least one line")
        return self


class DailyTransitBriefContract(StrictModel):
    version: str
    as_of_local_iso: str
    timezone: str
    cards: list[DailyTransitCardContract]

    @model_validator(mode="after")
    def validate_brief(self) -> Self:
        if not self.cards:
            raise ValueError("cards must contain at least one transit card")
        return self


class ComputeReportResponseContract(StrictModel):
    profile: ProfileContract
    normalized_input: NormalizedInputContract
    resolved_place: ResolvedPlaceContract
    snapshot: SnapshotContract
    dasha: DashaContract
    interpretations: InterpretationsContract
    daily_transit: DailyTransitBriefContract

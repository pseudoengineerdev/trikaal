from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class BirthEvent:
    local_date: str
    local_time: str
    timezone: str
    latitude: float
    longitude: float
    elevation_m: float
    place_label: str


@dataclass(frozen=True)
class CalculationProfile:
    profile_id: str = "vedic_lahiri_v1"
    zodiac_system: str = "sidereal"
    ayanamsha: str = "lahiri_chitrapaksha"
    calculation_method: str = "modern_ephemeris"


@dataclass(frozen=True)
class ChartSnapshot:
    birth_event: BirthEvent
    profile: CalculationProfile
    metadata: dict[str, str] = field(default_factory=dict)
    panchanga: dict[str, str] = field(default_factory=dict)
    grahas: dict[str, str] = field(default_factory=dict)
    lagna: dict[str, str] = field(default_factory=dict)

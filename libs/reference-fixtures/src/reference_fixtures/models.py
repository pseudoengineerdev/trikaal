from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class BirthInput(BaseModel):
    local_date: str
    local_time: str
    timezone: str
    latitude: float
    longitude: float
    elevation_m: float
    place_label: str


class ReferenceProfile(BaseModel):
    zodiac_system: str
    ayanamsha: str
    calculation_method: str


class ComparisonRules(BaseModel):
    exact_paths: list[str] = Field(default_factory=list)
    float_tolerance: float = 1e-6


class ReferenceFixture(BaseModel):
    fixture_id: str
    source: str
    captured_at_utc: str
    birth_input: BirthInput
    profile: ReferenceProfile
    expected_snapshot: dict[str, Any]
    comparison_rules: ComparisonRules = Field(default_factory=ComparisonRules)

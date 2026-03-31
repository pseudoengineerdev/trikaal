from __future__ import annotations

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from zoneinfo import ZoneInfo


@dataclass(frozen=True)
class PlaceResolution:
    place_label: str
    latitude: float
    longitude: float
    timezone: str
    elevation_m: float = 0.0


class PlaceNotFoundError(ValueError):
    pass


DATA_DIR = Path(__file__).resolve().parent / "data"
CATALOG_PATH = DATA_DIR / "place_catalog.json"


@dataclass(frozen=True)
class PlaceRecord:
    place_label: str
    latitude: float
    longitude: float
    timezone: str
    elevation_m: float
    aliases: tuple[str, ...]


def resolve_place(place_query: str) -> PlaceResolution:
    normalized = _normalize_key(place_query)
    resolved = _place_registry().get(normalized)
    if resolved is None:
        raise PlaceNotFoundError(f"Place not found in resolver registry: {place_query}")
    return resolved


def search_places(query: str, limit: int = 10) -> list[PlaceResolution]:
    normalized = _normalize_key(query)
    if not normalized:
        return []

    results: list[PlaceResolution] = []
    for record in _place_catalog():
        if any(normalized in alias for alias in record.aliases):
            results.append(
                PlaceResolution(
                    place_label=record.place_label,
                    latitude=record.latitude,
                    longitude=record.longitude,
                    timezone=record.timezone,
                    elevation_m=record.elevation_m,
                )
            )
        if len(results) >= limit:
            break

    return results


def _normalize_key(value: str) -> str:
    return " ".join(value.lower().replace(",", " ").split())


@lru_cache(maxsize=1)
def _place_catalog() -> tuple[PlaceRecord, ...]:
    raw_records = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    records = [PlaceRecord(**raw_record) for raw_record in raw_records]
    _validate_catalog(records)
    return tuple(records)


@lru_cache(maxsize=1)
def _place_registry() -> dict[str, PlaceResolution]:
    registry: dict[str, PlaceResolution] = {}
    for record in _place_catalog():
        resolved = PlaceResolution(
            place_label=record.place_label,
            latitude=record.latitude,
            longitude=record.longitude,
            timezone=record.timezone,
            elevation_m=record.elevation_m,
        )
        for alias in record.aliases:
            registry[_normalize_key(alias)] = resolved
    return registry


def _validate_catalog(records: list[PlaceRecord]) -> None:
    aliases_seen: set[str] = set()
    for record in records:
        if not record.aliases:
            raise ValueError(f"Place {record.place_label} must include at least one alias.")
        if record.latitude < -90.0 or record.latitude > 90.0:
            raise ValueError(f"Invalid latitude for {record.place_label}.")
        if record.longitude < -180.0 or record.longitude > 180.0:
            raise ValueError(f"Invalid longitude for {record.place_label}.")
        ZoneInfo(record.timezone)

        for alias in record.aliases:
            normalized = _normalize_key(alias)
            if not normalized:
                raise ValueError(f"Empty alias for {record.place_label}.")
            if normalized in aliases_seen:
                raise ValueError(f"Duplicate alias in catalog: {alias}")
            aliases_seen.add(normalized)

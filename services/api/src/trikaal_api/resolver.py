from __future__ import annotations

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from zoneinfo import ZoneInfo

import geonamescache


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
    population: int
    source_priority: int


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

    scored: list[tuple[int, PlaceRecord]] = []
    for record in _place_catalog():
        score = _score_match(record, normalized)
        if score is not None:
            scored.append((score, record))

    scored.sort(
        key=lambda item: (
            item[0],
            item[1].source_priority,
            item[1].population,
            item[1].place_label,
        ),
        reverse=True,
    )

    unique: list[PlaceResolution] = []
    seen: set[tuple[str, float, float, str]] = set()
    for _, record in scored:
        key = (
            record.place_label,
            record.latitude,
            record.longitude,
            record.timezone,
        )
        if key in seen:
            continue
        seen.add(key)
        unique.append(_as_resolution(record))
        if len(unique) >= limit:
            break

    return unique


def _score_match(record: PlaceRecord, query: str) -> int | None:
    if any(alias == query for alias in record.aliases):
        return 400
    if any(alias.startswith(query) for alias in record.aliases):
        return 250
    if any(query in alias for alias in record.aliases):
        return 100
    return None


def _as_resolution(record: PlaceRecord) -> PlaceResolution:
    return PlaceResolution(
        place_label=record.place_label,
        latitude=record.latitude,
        longitude=record.longitude,
        timezone=record.timezone,
        elevation_m=record.elevation_m,
    )


def _normalize_key(value: str) -> str:
    return " ".join(value.lower().replace(",", " ").split())


@lru_cache(maxsize=1)
def _place_catalog() -> tuple[PlaceRecord, ...]:
    records = _manual_place_catalog()
    records.extend(_global_place_catalog())
    _validate_catalog(records)
    return tuple(records)


def _manual_place_catalog() -> list[PlaceRecord]:
    raw_records = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    records: list[PlaceRecord] = []
    for raw_record in raw_records:
        aliases = tuple(raw_record["aliases"])
        records.append(
            PlaceRecord(
                place_label=raw_record["place_label"],
                latitude=float(raw_record["latitude"]),
                longitude=float(raw_record["longitude"]),
                timezone=raw_record["timezone"],
                elevation_m=float(raw_record.get("elevation_m", 0.0)),
                aliases=aliases,
                population=10_000_000_000,
                source_priority=2,
            )
        )
    return records


def _global_place_catalog() -> list[PlaceRecord]:
    geo = geonamescache.GeonamesCache()
    cities = geo.get_cities()
    countries = geo.get_countries()

    records: list[PlaceRecord] = []
    for city in cities.values():
        timezone = city.get("timezone")
        if not timezone:
            continue
        if not _is_supported_timezone(timezone):
            continue

        country_name = countries.get(city["countrycode"], {}).get("name", city["countrycode"])
        city_name = city["name"]
        place_label = f"{city_name}, {country_name}"
        aliases = _build_aliases(city_name, country_name, city.get("alternatenames") or [])
        records.append(
            PlaceRecord(
                place_label=place_label,
                latitude=float(city["latitude"]),
                longitude=float(city["longitude"]),
                timezone=timezone,
                elevation_m=0.0,
                aliases=aliases,
                population=int(city.get("population") or 0),
                source_priority=1,
            )
        )
    return records


def _build_aliases(city_name: str, country_name: str, alternates: list[str]) -> tuple[str, ...]:
    candidates = [city_name, f"{city_name} {country_name}", *alternates]
    seen: set[str] = set()
    aliases: list[str] = []
    for candidate in candidates:
        normalized = _normalize_key(candidate)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        aliases.append(normalized)
    return tuple(aliases)


@lru_cache(maxsize=1)
def _place_registry() -> dict[str, PlaceResolution]:
    registry: dict[str, tuple[int, int, PlaceResolution]] = {}
    for record in _place_catalog():
        resolved = _as_resolution(record)
        rank = (record.source_priority, record.population)
        for alias in record.aliases:
            existing = registry.get(alias)
            if existing is None or rank > (existing[0], existing[1]):
                registry[alias] = (rank[0], rank[1], resolved)
    return {alias: item[2] for alias, item in registry.items()}


def _validate_catalog(records: list[PlaceRecord]) -> None:
    for record in records:
        if not record.aliases:
            raise ValueError(f"Place {record.place_label} must include at least one alias.")
        if record.latitude < -90.0 or record.latitude > 90.0:
            raise ValueError(f"Invalid latitude for {record.place_label}.")
        if record.longitude < -180.0 or record.longitude > 180.0:
            raise ValueError(f"Invalid longitude for {record.place_label}.")
        if not _is_supported_timezone(record.timezone):
            raise ValueError(f"Unsupported timezone for {record.place_label}: {record.timezone}")


@lru_cache(maxsize=None)
def _is_supported_timezone(timezone: str) -> bool:
    try:
        ZoneInfo(timezone)
        return True
    except Exception:
        return False

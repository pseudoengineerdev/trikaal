from __future__ import annotations

import json
import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from zoneinfo import ZoneInfo

import geonamescache

from trikaal_api.geocoding import ExternalGeocoder, ExternalPlaceCandidate


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
DEFAULT_GEONAMES_MIN_CITY_POPULATION = 500
MAX_ALTERNATE_ALIASES_PER_CITY = 24


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
    if resolved is not None:
        return resolved

    fallback = _fallback_resolve(normalized)
    if fallback is not None:
        return fallback
    raise PlaceNotFoundError(f"Place not found in resolver registry: {place_query}")


def search_places(query: str, limit: int = 10) -> list[PlaceResolution]:
    normalized = _normalize_key(query)
    if not normalized:
        return []
    if limit <= 0:
        return []

    local_matches = _search_local_places(normalized, limit=limit)
    if _prefer_external_search():
        external_matches = list(_fallback_search(normalized, limit=limit))
        merged = _merge_unique_places([*external_matches, *local_matches], limit=limit)
        if merged:
            return merged
        return local_matches[:limit]

    if len(local_matches) >= limit:
        return local_matches[:limit]

    fallback_matches = _fallback_search(normalized, limit=limit - len(local_matches))
    merged = _merge_unique_places([*local_matches, *fallback_matches], limit=limit)
    return merged


def _search_local_places(query: str, limit: int) -> list[PlaceResolution]:
    scored: list[tuple[int, PlaceRecord]] = []
    for record in _place_catalog():
        score = _score_match(record, query)
        if score is not None:
            scored.append((score, record))

    scored.sort(
        key=lambda item: (
            item[1].source_priority,
            item[0],
            item[1].population,
            item[1].place_label,
        ),
        reverse=True,
    )

    results: list[PlaceResolution] = []
    seen: set[tuple[str, float, float, str]] = set()
    for _, record in scored:
        candidate = _as_resolution(record)
        dedupe_key = _place_key(candidate)
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)
        results.append(candidate)
        if len(results) >= limit:
            break
    return results


def _merge_unique_places(candidates: list[PlaceResolution], limit: int) -> list[PlaceResolution]:
    merged: list[PlaceResolution] = []
    seen: set[tuple[str, float, float, str]] = set()
    for candidate in candidates:
        key = _place_key(candidate)
        if key in seen:
            continue
        seen.add(key)
        merged.append(candidate)
        if len(merged) >= limit:
            break
    return merged


def _place_key(place: PlaceResolution) -> tuple[str, float, float, str]:
    return (
        _normalize_key(place.place_label),
        round(place.latitude, 5),
        round(place.longitude, 5),
        place.timezone,
    )


def _score_match(record: PlaceRecord, query: str) -> int | None:
    if any(alias == query for alias in record.aliases):
        return 500
    if any(alias.startswith(query) for alias in record.aliases):
        return 300
    if any(query in alias for alias in record.aliases):
        return 120
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
        aliases = tuple(_normalize_key(alias) for alias in raw_record["aliases"])
        records.append(
            PlaceRecord(
                place_label=raw_record["place_label"],
                latitude=float(raw_record["latitude"]),
                longitude=float(raw_record["longitude"]),
                timezone=raw_record["timezone"],
                elevation_m=float(raw_record.get("elevation_m", 0.0)),
                aliases=aliases,
                population=10_000_000_000,
                source_priority=3,
            )
        )
    return records


def _global_place_catalog() -> list[PlaceRecord]:
    geonames = geonamescache.GeonamesCache(min_city_population=_geonames_min_population())
    cities = geonames.get_cities()
    countries = geonames.get_countries()
    us_states = geonames.get_us_states()

    records: list[PlaceRecord] = []
    for city in cities.values():
        timezone = city.get("timezone")
        if not timezone or not _is_supported_timezone(timezone):
            continue

        country_code = city["countrycode"]
        country_name = countries.get(country_code, {}).get("name", country_code)
        city_name = city["name"]
        admin1_code = str(city.get("admin1code") or "").strip()
        state_name = _resolve_state_name(
            country_code=country_code,
            admin1_code=admin1_code,
            us_states=us_states,
        )
        place_label = _build_place_label(
            city_name=city_name,
            state_name=state_name,
            country_name=country_name,
        )
        aliases = _build_aliases(
            city_name=city_name,
            state_name=state_name,
            admin1_code=admin1_code,
            country_name=country_name,
            country_code=country_code,
            alternates=city.get("alternatenames") or [],
        )
        records.append(
            PlaceRecord(
                place_label=place_label,
                latitude=float(city["latitude"]),
                longitude=float(city["longitude"]),
                timezone=timezone,
                elevation_m=0.0,
                aliases=aliases,
                population=int(city.get("population") or 0),
                source_priority=2,
            )
        )
    return records


def _build_aliases(
    city_name: str,
    state_name: str | None,
    admin1_code: str,
    country_name: str,
    country_code: str,
    alternates: list[str],
) -> tuple[str, ...]:
    candidates = [
        city_name,
        f"{city_name} {country_name}",
        f"{city_name} {country_code}",
        f"{city_name} {admin1_code}",
        f"{city_name} {admin1_code} {country_name}",
        *alternates[:MAX_ALTERNATE_ALIASES_PER_CITY],
    ]
    if state_name:
        candidates.extend(
            [
                f"{city_name} {state_name}",
                f"{city_name} {state_name} {country_name}",
            ]
        )
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


@lru_cache(maxsize=1024)
def _fallback_resolve(normalized_query: str) -> PlaceResolution | None:
    if not _fallback_enabled():
        return None
    result = _external_geocoder().resolve_place(normalized_query)
    if result is None:
        return None
    return _external_to_place_resolution(result)


@lru_cache(maxsize=1024)
def _fallback_search(normalized_query: str, limit: int) -> tuple[PlaceResolution, ...]:
    if not _fallback_enabled():
        return ()
    if limit <= 0:
        return ()
    results = _external_geocoder().search_places(normalized_query, limit=limit)
    return tuple(_external_to_place_resolution(item) for item in results)


def _external_to_place_resolution(candidate: ExternalPlaceCandidate) -> PlaceResolution:
    return PlaceResolution(
        place_label=candidate.place_label,
        latitude=candidate.latitude,
        longitude=candidate.longitude,
        timezone=candidate.timezone,
        elevation_m=candidate.elevation_m,
    )


def _fallback_enabled() -> bool:
    value = os.getenv("TRIKAAL_ENABLE_FALLBACK_GEOCODING", "1").strip().lower()
    return value not in {"0", "false", "no", "off"}


def _prefer_external_search() -> bool:
    value = os.getenv("TRIKAAL_PREFER_EXTERNAL_SEARCH", "0").strip().lower()
    return value in {"1", "true", "yes", "on"}


@lru_cache(maxsize=1)
def _external_geocoder() -> ExternalGeocoder:
    return ExternalGeocoder()


def _geonames_min_population() -> int:
    raw_value = os.getenv(
        "TRIKAAL_GEONAMES_MIN_CITY_POPULATION",
        str(DEFAULT_GEONAMES_MIN_CITY_POPULATION),
    )
    try:
        value = int(raw_value)
    except ValueError:
        return DEFAULT_GEONAMES_MIN_CITY_POPULATION
    if value < 500:
        return 500
    return value


def _resolve_state_name(
    country_code: str,
    admin1_code: str,
    us_states: dict[str, dict[str, str]],
) -> str | None:
    if country_code == "US":
        return us_states.get(admin1_code, {}).get("name")
    return None


def _build_place_label(
    city_name: str,
    state_name: str | None,
    country_name: str,
) -> str:
    if state_name:
        return f"{city_name}, {state_name}, {country_name}"
    return f"{city_name}, {country_name}"


@lru_cache(maxsize=None)
def _is_supported_timezone(timezone: str) -> bool:
    try:
        ZoneInfo(timezone)
        return True
    except Exception:
        return False

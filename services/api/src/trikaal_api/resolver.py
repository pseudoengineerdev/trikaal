from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PlaceResolution:
    place_label: str
    latitude: float
    longitude: float
    timezone: str
    elevation_m: float = 0.0


class PlaceNotFoundError(ValueError):
    pass


_PLACE_REGISTRY = {
    "mumbai": PlaceResolution(
        place_label="Mumbai, India",
        latitude=19.0760,
        longitude=72.8777,
        timezone="Asia/Kolkata",
        elevation_m=14.0,
    ),
    "mumbai india": PlaceResolution(
        place_label="Mumbai, India",
        latitude=19.0760,
        longitude=72.8777,
        timezone="Asia/Kolkata",
        elevation_m=14.0,
    ),
    "bombay": PlaceResolution(
        place_label="Mumbai, India",
        latitude=19.0760,
        longitude=72.8777,
        timezone="Asia/Kolkata",
        elevation_m=14.0,
    ),
}


def resolve_place(place_query: str) -> PlaceResolution:
    normalized = " ".join(place_query.lower().replace(",", " ").split())
    resolved = _PLACE_REGISTRY.get(normalized)
    if resolved is None:
        raise PlaceNotFoundError(f"Place not found in resolver registry: {place_query}")
    return resolved

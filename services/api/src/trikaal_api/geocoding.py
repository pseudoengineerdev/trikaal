from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import httpx
from timezonefinder import TimezoneFinder


@dataclass(frozen=True)
class ExternalPlaceCandidate:
    place_label: str
    latitude: float
    longitude: float
    timezone: str
    elevation_m: float = 0.0


class ExternalGeocoder:
    def __init__(self, http_client: httpx.Client | None = None) -> None:
        self._user_agent = os.getenv(
            "TRIKAAL_GEOCODER_USER_AGENT",
            "Trikaal/1.0 (global city fallback geocoder)",
        )
        self._timeout_s = float(os.getenv("TRIKAAL_GEOCODER_TIMEOUT_SECONDS", "2.5"))
        self._http_client = http_client or httpx.Client(
            timeout=self._timeout_s,
            headers={"User-Agent": self._user_agent},
        )
        self._timezone_finder = TimezoneFinder()
        self._mapbox_token = os.getenv("TRIKAAL_MAPBOX_ACCESS_TOKEN", "").strip()
        self._google_api_key = os.getenv("TRIKAAL_GOOGLE_MAPS_API_KEY", "").strip()
        self._provider = os.getenv("TRIKAAL_GEOCODER_PROVIDER", "auto").strip().lower()

    def search_places(self, query: str, limit: int = 5) -> list[ExternalPlaceCandidate]:
        normalized = " ".join(query.split())
        if not normalized or limit <= 0:
            return []

        candidates: list[ExternalPlaceCandidate] = []
        for provider in self._provider_sequence():
            provider_candidates = self._search_with_provider(
                provider=provider,
                query=normalized,
                limit=limit,
            )
            if provider_candidates:
                candidates.extend(provider_candidates)
            if candidates:
                break

        return self._dedupe(candidates)[:limit]

    def resolve_place(self, query: str) -> ExternalPlaceCandidate | None:
        results = self.search_places(query, limit=1)
        if not results:
            return None
        return results[0]

    def _search_mapbox(self, query: str, limit: int) -> list[ExternalPlaceCandidate]:
        try:
            response = self._http_client.get(
                f"https://api.mapbox.com/geocoding/v5/mapbox.places/{query}.json",
                params={
                    "access_token": self._mapbox_token,
                    "limit": min(limit, 5),
                    "types": "place,locality",
                    "language": "en",
                },
            )
            response.raise_for_status()
            payload = response.json()
            features = payload.get("features") or []
        except Exception:
            return []

        candidates: list[ExternalPlaceCandidate] = []
        for feature in features:
            center = feature.get("center") or []
            if len(center) != 2:
                continue
            longitude = _safe_float(center[0])
            latitude = _safe_float(center[1])
            if latitude is None or longitude is None:
                continue
            timezone = self._timezone_for_coordinates(latitude=latitude, longitude=longitude)
            if timezone is None:
                continue
            label = str(feature.get("place_name") or feature.get("text") or query)
            candidates.append(
                ExternalPlaceCandidate(
                    place_label=label,
                    latitude=latitude,
                    longitude=longitude,
                    timezone=timezone,
                )
            )
        return candidates

    def _search_google(self, query: str, limit: int) -> list[ExternalPlaceCandidate]:
        try:
            response = self._http_client.get(
                "https://maps.googleapis.com/maps/api/geocode/json",
                params={
                    "address": query,
                    "key": self._google_api_key,
                },
            )
            response.raise_for_status()
            payload = response.json()
            results = payload.get("results") or []
        except Exception:
            return []

        candidates: list[ExternalPlaceCandidate] = []
        for item in results[:limit]:
            geometry = item.get("geometry") or {}
            location = geometry.get("location") or {}
            latitude = _safe_float(location.get("lat"))
            longitude = _safe_float(location.get("lng"))
            if latitude is None or longitude is None:
                continue
            timezone = self._timezone_for_coordinates(latitude=latitude, longitude=longitude)
            if timezone is None:
                continue
            label = str(item.get("formatted_address") or query)
            candidates.append(
                ExternalPlaceCandidate(
                    place_label=label,
                    latitude=latitude,
                    longitude=longitude,
                    timezone=timezone,
                )
            )
        return candidates

    def _search_nominatim(self, query: str, limit: int) -> list[ExternalPlaceCandidate]:
        params: dict[str, Any] = {
            "q": query,
            "format": "jsonv2",
            "addressdetails": 1,
            "limit": min(limit, 5),
        }
        email = os.getenv("TRIKAAL_NOMINATIM_EMAIL", "").strip()
        if email:
            params["email"] = email

        try:
            response = self._http_client.get(
                "https://nominatim.openstreetmap.org/search",
                params=params,
            )
            response.raise_for_status()
            rows = response.json()
        except Exception:
            return []

        if not isinstance(rows, list):
            return []

        candidates: list[ExternalPlaceCandidate] = []
        for row in rows:
            latitude = _safe_float(row.get("lat"))
            longitude = _safe_float(row.get("lon"))
            if latitude is None or longitude is None:
                continue
            timezone = self._timezone_for_coordinates(latitude=latitude, longitude=longitude)
            if timezone is None:
                continue
            label = _build_nominatim_label(row, query)
            candidates.append(
                ExternalPlaceCandidate(
                    place_label=label,
                    latitude=latitude,
                    longitude=longitude,
                    timezone=timezone,
                )
            )
        return candidates

    def _timezone_for_coordinates(self, latitude: float, longitude: float) -> str | None:
        try:
            timezone = self._timezone_finder.timezone_at(lat=latitude, lng=longitude)
        except Exception:
            return None
        if not timezone:
            return None
        return str(timezone)

    def _dedupe(self, candidates: list[ExternalPlaceCandidate]) -> list[ExternalPlaceCandidate]:
        unique: list[ExternalPlaceCandidate] = []
        seen: set[tuple[str, float, float, str]] = set()
        for candidate in candidates:
            key = (
                " ".join(candidate.place_label.lower().split()),
                round(candidate.latitude, 5),
                round(candidate.longitude, 5),
                candidate.timezone,
            )
            if key in seen:
                continue
            seen.add(key)
            unique.append(candidate)
        return unique

    def _provider_sequence(self) -> list[str]:
        if self._provider == "google":
            return ["google", "mapbox", "nominatim"]
        if self._provider == "mapbox":
            return ["mapbox", "google", "nominatim"]
        if self._provider == "nominatim":
            return ["nominatim", "google", "mapbox"]
        return ["google", "mapbox", "nominatim"]

    def _search_with_provider(
        self,
        provider: str,
        query: str,
        limit: int,
    ) -> list[ExternalPlaceCandidate]:
        if provider == "google":
            if not self._google_api_key:
                return []
            return self._search_google(query, limit=limit)
        if provider == "mapbox":
            if not self._mapbox_token:
                return []
            return self._search_mapbox(query, limit=limit)
        return self._search_nominatim(query, limit=limit)


def _build_nominatim_label(row: dict[str, Any], fallback: str) -> str:
    address = row.get("address")
    if not isinstance(address, dict):
        return str(row.get("display_name") or fallback)

    city = (
        address.get("city")
        or address.get("town")
        or address.get("village")
        or address.get("municipality")
        or address.get("county")
    )
    country = address.get("country")
    if city and country:
        return f"{city}, {country}"
    return str(row.get("display_name") or fallback)


def _safe_float(value: Any) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None

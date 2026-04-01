from __future__ import annotations

from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from trikaal_api.resolver import PlaceResolution


class CustomPlaceInput(BaseModel):
    place_label: str = Field(min_length=1)
    latitude: float = Field(ge=-90.0, le=90.0)
    longitude: float = Field(ge=-180.0, le=180.0)
    timezone: str = Field(min_length=1)
    elevation_m: float = 0.0

    def to_place_resolution(self) -> PlaceResolution:
        ZoneInfo(self.timezone)
        return PlaceResolution(
            place_label=self.place_label,
            latitude=self.latitude,
            longitude=self.longitude,
            timezone=self.timezone,
            elevation_m=self.elevation_m,
        )

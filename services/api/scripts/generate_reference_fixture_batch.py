from __future__ import annotations

import json
import html
import re
import subprocess
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import geonamescache

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
FIXTURE_DIR = WORKSPACE_ROOT / "libs" / "reference-fixtures" / "fixtures" / "reference"
ADMIN1_CODES_PATH = WORKSPACE_ROOT / "services" / "api" / "src" / "trikaal_api" / "data" / "admin1CodesASCII.txt"
OFFLINE_CAPTURE_DIR = Path("/tmp/reference_batch")

SIGN_ORDER = [
    "Mesh",
    "Vrish",
    "Mitu",
    "Kark",
    "Simh",
    "Kany",
    "Tula",
    "Vrsc",
    "Dhanu",
    "Maka",
    "Kumb",
    "Meen",
]
SIGN_NORMALIZATION = {
    "Mesh": "Mesh",
    "Vibh": "Vrish",
    "Vrish": "Vrish",
    "Mith": "Mitu",
    "Mitu": "Mitu",
    "Kark": "Kark",
    "Simh": "Simh",
    "Kany": "Kany",
    "Tula": "Tula",
    "Vish": "Vrsc",
    "Vrsc": "Vrsc",
    "Dhan": "Dhanu",
    "Dhanu": "Dhanu",
    "Makar": "Maka",
    "Maka": "Maka",
    "Kumb": "Kumb",
    "Meen": "Meen",
}
NAKSHATRA_NORMALIZATION = {
    "Purva Bhadrapada": "P Bhadrapada",
    "Uttara Bhadrapada": "U Bhadrapada",
    "Purva Phalguni": "P Phalguni",
    "Uttara Phalguni": "U Phalguni",
    "Purva Ashadha": "P Ashadha",
    "Uttara Ashadha": "U Ashadha",
    "Dhanishtha": "Dhanishta",
    "Mrigashira": "Mrigashirsha",
}

LONGITUDE_PATTERN = re.compile(
    r"(\d+)\s*°\s*([A-Za-z]+)\s*(\d+)\s*[′']\s*([0-9]+(?:\.[0-9]+)?)\s*[″\"]",
)
NAKSHATRA_PATTERN = re.compile(r"^\s*([A-Za-z ]+?),\s*(\d+)\b")
TIMEZONE_PATTERN = re.compile(r"dpEssential\.olson_timezone_\s*=\s*'([^']+)';")
CARD_SPLIT_MARKER = '<div class="dpPlanetCard dpFlexEqual"><div class="dpCardTitle">'
CARD_TITLE_PATTERN = re.compile(r"<div>([^<]+)</div>\s*<div class=\"dpCardSecondaryTitle\">")
CARD_FIELD_PATTERN = re.compile(
    r"<span class=\"dpTitle\">([^<]+)</span><span class=\"dpValue\">(.*?)</span>",
    re.S,
)


@dataclass(frozen=True)
class CaptureCase:
    geoname_id: int
    local_date: str
    local_time: str

    @property
    def reference_date(self) -> str:
        year, month, day = self.local_date.split("-")
        return f"{day}/{month}/{year}"

    @property
    def reference_time(self) -> str:
        return f"{self.local_time}:00"


CASES = [
    CaptureCase(5368361, "2021-03-14", "12:30"),  # Los Angeles DST spring day
    CaptureCase(5368361, "2021-11-07", "12:30"),  # Los Angeles DST fall day
    CaptureCase(6167865, "2020-03-08", "12:30"),  # Toronto DST spring day
    CaptureCase(6167865, "2020-11-01", "12:30"),  # Toronto DST fall day
    CaptureCase(2988507, "2019-03-31", "12:30"),  # Paris DST spring day
    CaptureCase(2988507, "2019-10-27", "12:30"),  # Paris DST fall day
    CaptureCase(2643743, "2018-03-25", "12:30"),  # London DST spring day
    CaptureCase(2643743, "2018-10-28", "12:30"),  # London DST fall day
    CaptureCase(2147714, "2022-04-03", "12:30"),  # Sydney DST fall day
    CaptureCase(2147714, "2022-10-02", "12:30"),  # Sydney DST spring day
    CaptureCase(2193733, "2023-04-02", "12:30"),  # Auckland DST fall day
    CaptureCase(2193733, "2023-09-24", "12:30"),  # Auckland DST spring day
    CaptureCase(3448439, "2018-11-04", "12:30"),  # Sao Paulo historical DST day
    CaptureCase(524901, "2011-03-27", "12:30"),  # Moscow DST policy shift period
]


def main() -> None:
    gc = geonamescache.GeonamesCache()
    cities = gc.get_cities()
    countries = gc.get_countries()
    admin1_names = load_admin1_name_map()
    captured_at_utc = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    generated = 0
    for case in CASES:
        city = cities.get(str(case.geoname_id))
        if city is None:
            raise ValueError(f"Unknown GeoNames ID: {case.geoname_id}")
        city_name = city["name"]
        page_html = load_reference_page_html(case=case, city_name=city_name)
        timezone_name = parse_timezone(page_html)
        parsed = parse_planetary_fields(page_html)

        country_code = city["countrycode"]
        country_name = countries.get(country_code, {}).get("name", country_code)
        admin1_code = str(city.get("admin1code") or "").strip()
        state_name = admin1_names.get(f"{country_code}.{admin1_code}") if admin1_code else None

        place_label = build_place_label(
            city_name=city_name,
            state_name=state_name,
            country_name=country_name,
        )
        fixture_id, fixture_path = build_fixture_identity(
            city_name=city_name,
            local_date=case.local_date,
            local_time=case.local_time,
        )
        payload = {
            "fixture_id": fixture_id,
            "source": "reference_panchang_search_capture",
            "captured_at_utc": captured_at_utc,
            "reference_status": "reference_captured",
            "birth_input": {
                "local_date": case.local_date,
                "local_time": case.local_time,
                "timezone": timezone_name,
                "latitude": float(city["latitude"]),
                "longitude": float(city["longitude"]),
                "elevation_m": 0.0,
                "place_label": place_label,
            },
            "profile": {
                "zodiac_system": "sidereal",
                "ayanamsha": "lahiri_chitrapaksha",
                "calculation_method": "modern_ephemeris",
            },
            "expected_snapshot": {
                "meta": {
                    "status": "computed",
                },
                "astronomy": {
                    "sun_sidereal_deg": parsed["sun_deg"],
                    "moon_sidereal_deg": parsed["moon_deg"],
                },
                "vedic": {
                    "sun_rashi": parsed["sun_rashi"],
                    "moon_rashi": parsed["moon_rashi"],
                    "lagna_rashi": parsed["lagna_rashi"],
                    "sun_nakshatra": parsed["sun_nakshatra"],
                    "sun_pada": parsed["sun_pada"],
                    "moon_nakshatra": parsed["moon_nakshatra"],
                    "moon_pada": parsed["moon_pada"],
                    "lagna_nakshatra": parsed["lagna_nakshatra"],
                    "lagna_pada": parsed["lagna_pada"],
                },
            },
            "comparison_rules": {
                "exact_paths": [
                    "meta.status",
                ],
                "float_tolerance": 0.03,
            },
        }

        fixture_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        generated += 1
        print(f"Generated: {fixture_path.relative_to(WORKSPACE_ROOT)} ({fixture_id})")

    print(f"\nDone. Generated {generated} fixture(s).")


def fetch_reference_page_html(case: CaptureCase) -> str:
    url = (
        "https://www.referencepanchang.com/planet/position/planetary-positions-sidereal.html"
        f"?geoname-id={case.geoname_id}&date={case.reference_date}&time={case.reference_time}&lang=en"
    )
    result = subprocess.run(
        [
            "curl",
            "-L",
            "-sS",
            url,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def load_reference_page_html(*, case: CaptureCase, city_name: str) -> str:
    capture_path = OFFLINE_CAPTURE_DIR / build_capture_file_name(
        city_name=city_name,
        local_date=case.local_date,
        local_time=case.local_time,
    )
    if capture_path.exists():
        return capture_path.read_text(encoding="utf-8", errors="ignore")
    return fetch_reference_page_html(case)


def parse_timezone(html: str) -> str:
    match = TIMEZONE_PATTERN.search(html)
    if not match:
        raise ValueError("Unable to parse timezone from Reference page source.")
    return match.group(1).strip()


def parse_planetary_fields(page_html: str) -> dict[str, object]:
    card_data: dict[str, dict[str, object]] = {}
    for section in page_html.split(CARD_SPLIT_MARKER)[1:]:
        title_match = CARD_TITLE_PATTERN.search(section)
        if not title_match:
            continue
        title = normalize_text(title_match.group(1))
        if title not in {"Sun", "Moon", "Ascendant (Asc)"}:
            continue

        fields = parse_card_fields(section)
        longitude_text = fields.get("Longitude")
        nakshatra_text = fields.get("Nakshatra")
        if longitude_text is None:
            raise ValueError(f'Unable to parse "Longitude" for card: {title}')
        if nakshatra_text is None:
            raise ValueError(f'Unable to parse "Nakshatra" for card: {title}')
        degree, rashi = parse_longitude(longitude_text)
        nakshatra, pada = parse_nakshatra(nakshatra_text)
        card_data[title] = {
            "degree": degree,
            "rashi": rashi,
            "nakshatra": nakshatra,
            "pada": pada,
        }

    required_titles = {"Sun", "Moon", "Ascendant (Asc)"}
    missing = required_titles - set(card_data.keys())
    if missing:
        raise ValueError(f"Unable to parse required planetary cards: {sorted(missing)}")

    return {
        "sun_deg": card_data["Sun"]["degree"],
        "sun_rashi": card_data["Sun"]["rashi"],
        "sun_nakshatra": card_data["Sun"]["nakshatra"],
        "sun_pada": card_data["Sun"]["pada"],
        "moon_deg": card_data["Moon"]["degree"],
        "moon_rashi": card_data["Moon"]["rashi"],
        "moon_nakshatra": card_data["Moon"]["nakshatra"],
        "moon_pada": card_data["Moon"]["pada"],
        "lagna_rashi": card_data["Ascendant (Asc)"]["rashi"],
        "lagna_nakshatra": card_data["Ascendant (Asc)"]["nakshatra"],
        "lagna_pada": card_data["Ascendant (Asc)"]["pada"],
    }


def parse_card_fields(section: str) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for match in CARD_FIELD_PATTERN.finditer(section):
        key = normalize_text(match.group(1))
        value = normalize_text(strip_tags(match.group(2)))
        parsed[key] = value
    return parsed


def parse_longitude(value: str) -> tuple[float, str]:
    match = LONGITUDE_PATTERN.search(value)
    if not match:
        raise ValueError(f"Unable to parse longitude: {value}")

    degree_in_sign = int(match.group(1))
    sign_token = match.group(2).strip()
    minute = int(match.group(3))
    second = float(match.group(4))
    rashi = SIGN_NORMALIZATION.get(sign_token)
    if rashi is None:
        raise ValueError(f"Unsupported rashi token: {sign_token}")
    sign_index = SIGN_ORDER.index(rashi)
    absolute = sign_index * 30.0 + degree_in_sign + minute / 60.0 + second / 3600.0
    return truncate_two_decimals(absolute), rashi


def parse_nakshatra(value: str) -> tuple[str, int]:
    match = NAKSHATRA_PATTERN.search(value)
    if not match:
        raise ValueError(f"Unable to parse nakshatra: {value}")
    raw_name = " ".join(match.group(1).split()).strip()
    normalized = NAKSHATRA_NORMALIZATION.get(raw_name, raw_name)
    pada = int(match.group(2))
    return normalized, pada


def truncate_two_decimals(value: float) -> float:
    return int(value * 100.0) / 100.0


def build_place_label(city_name: str, state_name: str | None, country_name: str) -> str:
    if state_name and state_name != country_name:
        return f"{city_name}, {state_name}, {country_name}"
    return f"{city_name}, {country_name}"


def build_fixture_identity(city_name: str, local_date: str, local_time: str) -> tuple[str, Path]:
    year, month, day = local_date.split("-")
    time_digits = local_time.replace(":", "")
    city_slug = normalize_slug(city_name)
    file_name = f"{local_date}_{city_slug}_{time_digits}.json"
    fixture_id = f"reference_{city_slug}_{year}_{month}_{day}_{time_digits}_v1"
    return fixture_id, FIXTURE_DIR / file_name


def build_capture_file_name(city_name: str, local_date: str, local_time: str) -> str:
    city_slug = normalize_slug(city_name)
    time_digits = local_time.replace(":", "")
    return f"{local_date}_{city_slug}_{time_digits}.html"


def normalize_slug(value: str) -> str:
    ascii_value = (
        unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    )
    slug = re.sub(r"[^a-z0-9]+", "_", ascii_value.lower())
    slug = slug.strip("_")
    slug = re.sub(r"_+", "_", slug)
    return slug


def strip_tags(value: str) -> str:
    return re.sub(r"<[^>]+>", " ", value)


def normalize_text(value: str) -> str:
    return " ".join(html.unescape(value).split())


def load_admin1_name_map() -> dict[str, str]:
    mapping: dict[str, str] = {}
    for line in ADMIN1_CODES_PATH.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        columns = line.split("\t")
        if len(columns) < 2:
            continue
        code = columns[0].strip()
        name = columns[1].strip()
        if code and name:
            mapping[code] = name
    return mapping


if __name__ == "__main__":
    main()

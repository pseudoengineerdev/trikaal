from vedic_engine import (
    BirthEvent,
    CalculationProfile,
    compute_chart_snapshot,
    compute_kundali_compatibility,
)


def _birth_event(
    *,
    local_date: str,
    local_time: str,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
    place_label: str,
) -> BirthEvent:
    return BirthEvent(
        local_date=local_date,
        local_time=local_time,
        timezone=timezone,
        latitude=latitude,
        longitude=longitude,
        elevation_m=elevation_m,
        place_label=place_label,
    )


def test_compatibility_returns_ashta_kuta_manglik_and_d1_d9_sections() -> None:
    profile = CalculationProfile()
    primary_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        profile=profile,
    )
    partner_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="2001-09-09",
            local_time="01:30",
            timezone="America/New_York",
            latitude=40.7128,
            longitude=-74.0060,
            elevation_m=10.0,
            place_label="New York, New York, United States",
        ),
        profile=profile,
    )

    result = compute_kundali_compatibility(
        boy_snapshot=primary_snapshot,
        girl_snapshot=partner_snapshot,
    )

    assert result["version"] == "v1"
    ashta = result["ashta_kuta"]
    assert ashta["total_score"] == 23.0
    assert ashta["max_score"] == 36.0
    assert ashta["classification"] == "Very Good"
    assert len(ashta["components"]) == 8
    assert [component["key"] for component in ashta["components"]] == [
        "varna",
        "vashya",
        "tara",
        "yoni",
        "graha_maitri",
        "gana",
        "bhakoot",
        "nadi",
    ]
    first_component = ashta["components"][0]
    assert "boy_value" in first_component
    assert "girl_value" in first_component
    assert "area_of_life" in first_component
    assert "description" in first_component
    assert result["manglik"]["pair_alignment"] == "Balanced"
    assert result["manglik"]["score"] == 8.0
    assert result["d1_d9"]["d1"]["lagna_distance"] == 4
    assert result["d1_d9"]["d9"]["mars_house_gap"] == 5
    assert result["summary"]["overall_band"] == "Very Good"
    assert result["summary"]["guna_score"] == 23.0


def test_compatibility_is_direction_sensitive_for_ashta_kuta_rules() -> None:
    profile = CalculationProfile()
    profile_a = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        profile=profile,
    )
    profile_b = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="2001-09-09",
            local_time="01:30",
            timezone="America/New_York",
            latitude=40.7128,
            longitude=-74.0060,
            elevation_m=10.0,
            place_label="New York, New York, United States",
        ),
        profile=profile,
    )

    a_as_boy = compute_kundali_compatibility(
        boy_snapshot=profile_a,
        girl_snapshot=profile_b,
    )
    b_as_boy = compute_kundali_compatibility(
        boy_snapshot=profile_b,
        girl_snapshot=profile_a,
    )

    score_a_as_boy = a_as_boy["ashta_kuta"]["total_score"]
    score_b_as_boy = b_as_boy["ashta_kuta"]["total_score"]
    assert score_a_as_boy == 23.0
    assert score_b_as_boy == 24.0


def test_reference_same_nakshatra_different_pada_override_matches_full_score_case() -> None:
    profile = CalculationProfile()
    boy_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.07,
            longitude=72.88,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=profile,
    )
    girl_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1993-02-22",
            local_time="17:35",
            timezone="America/Chicago",
            latitude=29.69,
            longitude=-95.21,
            elevation_m=12.0,
            place_label="Pasadena, United States",
        ),
        profile=profile,
    )

    result = compute_kundali_compatibility(
        boy_snapshot=boy_snapshot,
        girl_snapshot=girl_snapshot,
    )
    components = {component["key"]: component["score"] for component in result["ashta_kuta"]["components"]}

    assert boy_snapshot["panchanga"]["nakshatra"]["number"] == 25
    assert girl_snapshot["panchanga"]["nakshatra"]["number"] == 25
    assert boy_snapshot["vedic"]["moon_pada"] != girl_snapshot["vedic"]["moon_pada"]
    assert components["bhakoot"] == 7.0
    assert components["nadi"] == 8.0
    assert result["ashta_kuta"]["total_score"] == 36.0


def test_reference_same_nakshatra_same_pada_override_matches_zero_score_case() -> None:
    profile = CalculationProfile()
    boy_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.07,
            longitude=72.88,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=profile,
    )
    girl_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1993-02-22",
            local_time="05:35",
            timezone="America/Chicago",
            latitude=29.69,
            longitude=-95.21,
            elevation_m=12.0,
            place_label="Pasadena, United States",
        ),
        profile=profile,
    )

    result = compute_kundali_compatibility(
        boy_snapshot=boy_snapshot,
        girl_snapshot=girl_snapshot,
    )
    components = {component["key"]: component["score"] for component in result["ashta_kuta"]["components"]}

    assert boy_snapshot["panchanga"]["nakshatra"]["number"] == 25
    assert girl_snapshot["panchanga"]["nakshatra"]["number"] == 25
    assert boy_snapshot["vedic"]["moon_pada"] == girl_snapshot["vedic"]["moon_pada"]
    assert components["bhakoot"] == 0.0
    assert components["nadi"] == 0.0
    assert result["ashta_kuta"]["total_score"] == 21.0


def test_reference_parity_sahil_archita_case_matches_pdf_breakdown() -> None:
    profile = CalculationProfile()
    boy_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0728,
            longitude=72.8825,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        profile=profile,
    )
    girl_snapshot = compute_chart_snapshot(
        birth_event=_birth_event(
            local_date="1999-08-15",
            local_time="15:07",
            timezone="Asia/Kolkata",
            latitude=18.5194,
            longitude=73.8553,
            elevation_m=560.0,
            place_label="Pune, Maharashtra, India",
        ),
        profile=profile,
    )

    result = compute_kundali_compatibility(
        boy_snapshot=boy_snapshot,
        girl_snapshot=girl_snapshot,
    )
    components = {component["key"]: component["score"] for component in result["ashta_kuta"]["components"]}

    assert result["ashta_kuta"]["total_score"] == 13.0
    assert components == {
        "varna": 0.0,
        "vashya": 2.0,
        "tara": 1.5,
        "yoni": 1.0,
        "graha_maitri": 4.0,
        "gana": 5.0,
        "bhakoot": 0.0,
        "nadi": 0.0,
    }

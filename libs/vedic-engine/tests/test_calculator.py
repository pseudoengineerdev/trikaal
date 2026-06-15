from vedic_engine.calculator import compute_chart_snapshot
from vedic_engine.domain import BirthEvent, CalculationProfile


def test_calculator_returns_computed_snapshot_for_canonical_case() -> None:
    snapshot = compute_chart_snapshot(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=CalculationProfile(),
    )

    assert snapshot["meta"]["status"] == "computed"
    assert snapshot["meta"]["timezone"] == "Asia/Kolkata"
    assert snapshot["meta"]["utc_iso"] == "1999-07-04T06:52:00Z"
    assert snapshot["panchanga"]["vara"]["name_vedic"] == "Ravivara"
    assert snapshot["panchanga"]["vara"]["name_english"] == "Sunday"
    assert snapshot["panchanga"]["tithi"]["number"] == 21
    assert snapshot["panchanga"]["tithi"]["name_vedic"] == "Krishna Shashthi"
    assert snapshot["panchanga"]["tithi"]["name_english"] == "Waning Shashthi"
    assert snapshot["panchanga"]["nakshatra"]["name_vedic"] == "P Bhadrapada"
    assert snapshot["panchanga"]["nakshatra"]["pada"] == 1
    assert snapshot["panchanga"]["yoga"]["number"] == 3
    assert snapshot["panchanga"]["yoga"]["name_vedic"] == "Ayushman"
    assert snapshot["panchanga"]["karana"]["serial"] == 41
    assert snapshot["panchanga"]["karana"]["name_vedic"] == "Garija"
    # Hindu sunrise convention: solar disc center, no refraction.
    assert snapshot["panchanga"]["sunrise"]["local_time"] == "06:09"
    assert snapshot["panchanga"]["sunset"]["local_time"] == "19:16"
    assert isinstance(snapshot["astronomy"]["julian_day_utc"], float)
    assert isinstance(snapshot["astronomy"]["sun_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["moon_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["mangal_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["budha_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["guru_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["shukra_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["shani_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["rahu_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["ketu_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["spashth_rahu_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["spashth_ketu_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["lagna_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["sun_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["moon_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["mangal_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["budha_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["guru_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["shukra_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["shani_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["rahu_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["ketu_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["spashth_rahu_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["spashth_ketu_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["lagna_sidereal_deg_raw"], float)
    assert snapshot["astronomy"]["reference_display_offset_deg"] == 0.01
    assert snapshot["astronomy"]["reference_lagna_display_offset_deg"] == 0.182
    assert snapshot["astronomy"]["mangal_sidereal_deg"] == 185.85
    assert snapshot["astronomy"]["budha_sidereal_deg"] == 102.75
    assert snapshot["astronomy"]["guru_sidereal_deg"] == 7.04
    assert snapshot["astronomy"]["shukra_sidereal_deg"] == 120.92
    assert snapshot["astronomy"]["shani_sidereal_deg"] == 20.65
    assert snapshot["astronomy"]["rahu_sidereal_deg"] == 110.78
    assert snapshot["astronomy"]["ketu_sidereal_deg"] == 290.78
    assert snapshot["astronomy"]["spashth_rahu_sidereal_deg"] == 109.38
    assert snapshot["astronomy"]["spashth_ketu_sidereal_deg"] == 289.38
    assert snapshot["vedic"]["sun_rashi"] == "Mitu"
    assert snapshot["vedic"]["moon_rashi"] == "Kumb"
    assert snapshot["vedic"]["lagna_rashi"] == "Kany"
    assert snapshot["vedic"]["mangal_rashi"] == "Tula"
    assert snapshot["vedic"]["budha_rashi"] == "Kark"
    assert snapshot["vedic"]["guru_rashi"] == "Mesh"
    assert snapshot["vedic"]["shukra_rashi"] == "Simh"
    assert snapshot["vedic"]["shani_rashi"] == "Mesh"
    assert snapshot["vedic"]["rahu_rashi"] == "Kark"
    assert snapshot["vedic"]["ketu_rashi"] == "Maka"
    assert snapshot["vedic"]["spashth_rahu_rashi"] == "Kark"
    assert snapshot["vedic"]["spashth_ketu_rashi"] == "Maka"
    assert snapshot["vedic"]["sun_nakshatra"] == "Ardra"
    assert snapshot["vedic"]["sun_pada"] == 4
    assert snapshot["vedic"]["moon_nakshatra"] == "P Bhadrapada"
    assert snapshot["vedic"]["moon_pada"] == 1
    assert snapshot["vedic"]["lagna_nakshatra"] == "Hasta"
    assert snapshot["vedic"]["lagna_pada"] == 2
    assert snapshot["vedic"]["mangal_nakshatra"] == "Chitra"
    assert snapshot["vedic"]["mangal_pada"] == 4
    assert snapshot["vedic"]["budha_nakshatra"] == "Pushya"
    assert snapshot["vedic"]["budha_pada"] == 3
    assert snapshot["vedic"]["guru_nakshatra"] == "Ashwini"
    assert snapshot["vedic"]["guru_pada"] == 3
    assert snapshot["vedic"]["shukra_nakshatra"] == "Magha"
    assert snapshot["vedic"]["shukra_pada"] == 1
    assert snapshot["vedic"]["shani_nakshatra"] == "Bharani"
    assert snapshot["vedic"]["shani_pada"] == 3
    assert snapshot["vedic"]["rahu_nakshatra"] == "Ashlesha"
    assert snapshot["vedic"]["rahu_pada"] == 2
    assert snapshot["vedic"]["ketu_nakshatra"] == "Shravana"
    assert snapshot["vedic"]["ketu_pada"] == 4
    assert snapshot["vedic"]["spashth_rahu_nakshatra"] == "Ashlesha"
    assert snapshot["vedic"]["spashth_rahu_pada"] == 1
    assert snapshot["vedic"]["spashth_ketu_nakshatra"] == "Shravana"
    assert snapshot["vedic"]["spashth_ketu_pada"] == 3
    assert snapshot["bhava"]["lagna_house"] == 1
    assert snapshot["bhava"]["sun_house"] == 10
    assert snapshot["bhava"]["moon_house"] == 6
    assert snapshot["bhava"]["mangal_house"] == 2
    assert snapshot["bhava"]["budha_house"] == 11
    assert snapshot["bhava"]["guru_house"] == 8
    assert snapshot["bhava"]["shukra_house"] == 12
    assert snapshot["bhava"]["shani_house"] == 8
    assert snapshot["bhava"]["rahu_house"] == 11
    assert snapshot["bhava"]["ketu_house"] == 5
    assert snapshot["bhava"]["spashth_rahu_house"] == 11
    assert snapshot["bhava"]["spashth_ketu_house"] == 5
    assert snapshot["varga"]["d1"]["lagna_rashi"] == "Kany"
    assert snapshot["varga"]["d9"]["lagna_rashi"] == snapshot["graha_table"]["lagna"]["d9_rashi"]
    assert snapshot["varga"]["d10"]["lagna_rashi"] == "Kany"
    assert snapshot["varga"]["d60"]["lagna_rashi"] == "Dhanu"
    assert snapshot["varga"]["d1"]["graha_positions"]["sun"]["rashi"] == "Mitu"
    assert snapshot["varga"]["d1"]["graha_positions"]["sun"]["house"] == 10
    assert snapshot["varga"]["d1"]["graha_positions"]["sun"]["degree_in_sign"] == 18.0229
    assert snapshot["varga"]["d9"]["graha_positions"]["sun"]["rashi"] == snapshot["graha_table"]["sun"]["d9_rashi"]
    assert snapshot["varga"]["d10"]["graha_positions"]["lagna"]["rashi"] == "Kany"
    assert snapshot["varga"]["d60"]["graha_positions"]["lagna"]["rashi"] == "Dhanu"
    assert len([key for key in snapshot["varga"] if key.startswith("d")]) == 60
    assert len(snapshot["varga"]["d1"]["houses"]) == 12
    assert len(snapshot["varga"]["d9"]["houses"]) == 12
    assert len(snapshot["varga"]["d60"]["houses"]) == 12
    assert len(snapshot["varga"]["d1"]["graha_positions"]) == 12
    assert len(snapshot["varga"]["d9"]["graha_positions"]) == 12
    assert len(snapshot["varga"]["d60"]["graha_positions"]) == 12
    assert isinstance(snapshot["varga"]["d1"]["houses"]["1"]["occupants"], list)
    assert "lagna" in snapshot["varga"]["d1"]["houses"]["1"]["occupants"]
    assert snapshot["graha_table"]["sun"]["rashi"] == "Mitu"
    assert snapshot["graha_table"]["sun"]["house"] == 10
    assert snapshot["graha_table"]["sun"]["nakshatra"] == "Ardra"
    assert isinstance(snapshot["graha_table"]["sun"]["sidereal_deg"], float)
    assert isinstance(snapshot["graha_table"]["sun"]["retrograde"], bool)
    assert isinstance(snapshot["graha_table"]["sun"]["combust"], bool)
    assert isinstance(snapshot["graha_table"]["sun"]["d9_rashi"], str)
    assert isinstance(snapshot["graha_table"]["sun"]["d9_house"], int)


def test_calculator_vara_uses_sunrise_to_sunrise_day_for_pre_sunrise_birth() -> None:
    # The vara runs sunrise to sunrise, not midnight to midnight. This birth is
    # at 02:00 IST, before the 06:09 sunrise, so it belongs to the previous
    # day's vara: Shanivara (Saturday), not Ravivara (Sunday). The canonical
    # case above is the same date at 12:22 (post-sunrise) and stays Ravivara.
    snapshot = compute_chart_snapshot(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="02:00",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=CalculationProfile(),
    )

    # Sunrise is unchanged, confirming the birth is genuinely pre-sunrise.
    assert snapshot["panchanga"]["sunrise"]["local_time"] == "06:09"
    assert snapshot["panchanga"]["vara"]["number"] == 7
    assert snapshot["panchanga"]["vara"]["name_vedic"] == "Shanivara"
    assert snapshot["panchanga"]["vara"]["name_english"] == "Saturday"


def test_calculator_computes_for_non_canonical_case() -> None:
    snapshot = compute_chart_snapshot(
        birth_event=BirthEvent(
            local_date="2000-01-01",
            local_time="00:00",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=CalculationProfile(),
    )

    assert snapshot["meta"]["status"] == "computed"
    assert snapshot["meta"]["utc_iso"] == "1999-12-31T18:30:00Z"

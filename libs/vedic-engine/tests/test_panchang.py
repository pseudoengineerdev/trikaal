from __future__ import annotations

import pytest

from vedic_engine.panchang import compute_daily_panchang


VADODARA = {
    "timezone": "Asia/Kolkata",
    "latitude": 22.2994,
    "longitude": 73.2081,
    "elevation_m": 39.0,
}


@pytest.fixture(scope="module")
def friday_panchang() -> dict[str, object]:
    return compute_daily_panchang(target_date="2026-06-12", **VADODARA)


def test_panchang_payload_shape(friday_panchang: dict[str, object]) -> None:
    assert friday_panchang["panchang_profile_id"] == "vedic_daily_panchang_v1"
    assert friday_panchang["date"] == "2026-06-12"
    assert friday_panchang["weekday"]["name_vedic"] == "Shukravara"
    assert friday_panchang["weekday"]["name_english"] == "Friday"


def test_five_limbs_transition_times(friday_panchang: dict[str, object]) -> None:
    tithi = friday_panchang["tithi"]
    assert tithi[0]["name_vedic"] == "Krishna Dvadashi"
    assert tithi[0]["end"]["local_time"] == "19:37"
    assert tithi[1]["name_vedic"] == "Krishna Trayodashi"

    nakshatra = friday_panchang["nakshatra"]
    assert nakshatra[0]["name_vedic"] == "Ashwini"
    assert nakshatra[0]["is_ganda_moola"] is True
    assert nakshatra[0]["end"]["local_time"] == "06:29"
    assert nakshatra[1]["name_vedic"] == "Bharani"
    assert nakshatra[1]["end"]["local_iso"].startswith("2026-06-13T04:06")

    yoga = friday_panchang["yoga"]
    assert yoga[0]["name_vedic"] == "Atiganda"
    assert yoga[1]["name_vedic"] == "Sukarma"

    karana = friday_panchang["karana"]
    assert [entry["name_vedic"] for entry in karana[:3]] == [
        "Kaulava",
        "Taitila",
        "Garija",
    ]
    assert karana[0]["end"]["local_time"] == "09:11"


def test_lunar_month_and_samvat(friday_panchang: dict[str, object]) -> None:
    month = friday_panchang["lunar_month"]
    assert month["amanta"] == "Jyeshtha (Adhika)"
    assert month["purnimanta"] == "Jyeshtha (Adhika)"
    assert month["paksha"] == "Krishna"

    samvat = friday_panchang["samvat"]
    assert samvat["vikram"] == 2083
    assert samvat["vikram_samvatsara"] == "Siddharthi"
    assert samvat["shaka"] == 1948
    assert samvat["shaka_samvatsara"] == "Parabhava"
    assert samvat["kali"] == 5127


def test_samvat_before_chaitra_pratipada() -> None:
    payload = compute_daily_panchang(target_date="2026-01-15", **VADODARA)
    samvat = payload["samvat"]
    assert samvat["shaka"] == 1947
    assert samvat["vikram"] == 2082
    assert samvat["shaka_samvatsara"] == "Vishvavasu"


def test_rashi_and_ayana(friday_panchang: dict[str, object]) -> None:
    rashi = friday_panchang["rashi"]
    assert rashi["moon_rashi"] == "Mesha"
    assert rashi["sun_rashi"] == "Vrishabha"
    assert rashi["sun_nakshatra"]["name"] == "Mrigashirsha"

    ayana_ritu = friday_panchang["ayana_ritu"]
    assert ayana_ritu["ayana_sayana"] == "Uttarayana"
    assert ayana_ritu["ritu_nirayana"] == "Grishma"


def test_kalam_windows_follow_weekday_parts(friday_panchang: dict[str, object]) -> None:
    inauspicious = friday_panchang["inauspicious"]
    # Friday: Rahu 4th, Yamaganda 7th, Gulikai 2nd eighth-part of the day.
    assert inauspicious["rahu_kalam"]["start"]["local_time"] == "10:56"
    assert inauspicious["yamaganda"]["start"]["local_time"] == "15:57"
    assert inauspicious["gulikai_kalam"]["start"]["local_time"] == "07:36"


def test_varjyam_and_amrit_kalam_proportions(friday_panchang: dict[str, object]) -> None:
    # Bharani: varjyam from ghati 24, amrit kalam from ghati 48 of the span.
    varjyam = friday_panchang["inauspicious"]["varjyam"]
    assert len(varjyam) == 1
    assert varjyam[0]["start"]["local_time"] == "15:08"

    amrit = friday_panchang["auspicious"]["amrit_kalam"]
    assert len(amrit) == 1
    assert amrit[0]["start"]["local_time"] == "23:47"


def test_mula_varjyam_amrit_match_reference() -> None:
    # Mula nakshatra day at Vadodara. Published reference: Varjyam 10:07 AM,
    # Amrit Kalam 08:53 PM. These ghatis (Varjyam 20, Amrit 44) satisfy the
    # classical Amrit = Varjyam + 24 ghati relationship; a regression here
    # means the Mula table row drifted back to a non-conforming value.
    payload = compute_daily_panchang(target_date="2026-06-29", **VADODARA)
    varjyam = payload["inauspicious"]["varjyam"]
    amrit = payload["auspicious"]["amrit_kalam"]
    assert any(w["start"]["local_time"] == "10:08" for w in varjyam)
    assert any(w["start"]["local_time"] == "20:54" for w in amrit)


def test_dur_muhurtam_tables() -> None:
    # Saturday: 1st and 2nd day muhurtas.
    saturday = compute_daily_panchang(target_date="2026-06-13", **VADODARA)
    saturday_windows = saturday["inauspicious"]["dur_muhurtam"]
    assert len(saturday_windows) == 2
    assert (
        saturday_windows[0]["start"]["local_time"]
        == saturday["sun"]["sunrise"]["local_time"]
    )

    # Tuesday: one day window plus the 7th night muhurta.
    tuesday = compute_daily_panchang(target_date="2026-06-16", **VADODARA)
    tuesday_windows = tuesday["inauspicious"]["dur_muhurtam"]
    assert len(tuesday_windows) == 2
    assert tuesday_windows[1]["start"]["local_iso"].startswith("2026-06-16T23:34")


def test_abhijit_omitted_on_wednesday() -> None:
    wednesday = compute_daily_panchang(target_date="2026-06-17", **VADODARA)
    assert wednesday["weekday"]["name_english"] == "Wednesday"
    assert wednesday["auspicious"]["abhijit_muhurta"] is None
    friday = compute_daily_panchang(target_date="2026-06-12", **VADODARA)
    assert friday["auspicious"]["abhijit_muhurta"] is not None


def test_moon_events_use_panchang_day_window(friday_panchang: dict[str, object]) -> None:
    moonrise = friday_panchang["moon"]["moonrise"]
    moonset = friday_panchang["moon"]["moonset"]
    # Krishna paksha morning moon: rises after midnight on the next civil date.
    assert moonrise["local_iso"].startswith("2026-06-13T03:44")
    assert moonset["local_time"] == "16:23"


def test_hora_and_choghadiya_sequences(friday_panchang: dict[str, object]) -> None:
    hora = friday_panchang["advanced"]["hora_timeline"]
    assert len(hora) == 24
    assert hora[0]["lord_vedic"] == "Shukra"
    assert hora[0]["start"] == friday_panchang["sun"]["sunrise"]

    choghadiya = friday_panchang["advanced"]["choghadiya"]
    day_names = [slot["name"] for slot in choghadiya["day"]]
    assert day_names[0] == "Chara"
    assert day_names[7] == "Chara"
    assert len(choghadiya["night"]) == 8
    assert choghadiya["night"][0]["name"] == "Roga"


def test_advanced_static_rules(friday_panchang: dict[str, object]) -> None:
    advanced = friday_panchang["advanced"]
    assert advanced["disha_shoola"] == "West"
    # Moon in Mesha: chandrabalam favors houses {1,3,6,7,10,11} from each rashi.
    assert "Mesha" in advanced["chandrabalam"]
    assert "Vrishabha" not in advanced["chandrabalam"]
    # Ashwini at sunrise: its own tara (janma) is excluded.
    assert "Ashwini" not in advanced["tarabalam"]
    assert "Bharani" in advanced["tarabalam"]


def test_ganda_moola_window_reported(friday_panchang: dict[str, object]) -> None:
    ganda_moola = friday_panchang["inauspicious"]["ganda_moola"]
    assert len(ganda_moola) == 1
    assert ganda_moola[0]["nakshatra"] == "Ashwini"


def test_polar_fallback_keeps_five_limbs() -> None:
    payload = compute_daily_panchang(
        target_date="2026-06-12",
        timezone="Europe/Oslo",
        latitude=78.2232,
        longitude=15.6267,
        elevation_m=10.0,
    )
    assert payload["sun"]["sunrise"] is None
    assert payload["tithi"]
    assert payload["nakshatra"]
    assert payload["auspicious"] == {}
    assert payload["inauspicious"] == {}

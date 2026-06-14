from fastapi.testclient import TestClient

from trikaal_api.gochar import (
    _JUPITER_INFLUENCE,
    _SATURN_INFLUENCE,
    TransitComputeRequest,
    _active_lord,
    _build_double_transit,
    _dignity_for,
    _influence_signs,
    _phala,
    compute_transit,
)
from trikaal_api.main import app


def _request(**overrides) -> TransitComputeRequest:
    base = {
        "date_of_birth": "1990-08-20",
        "time_of_birth": "08:30",
        "place_of_birth": "Mumbai",
        "as_of_date": "2026-06-14",
    }
    base.update(overrides)
    return TransitComputeRequest(**base)


def test_compute_transit_shape() -> None:
    response = compute_transit(_request())

    assert len(response.planets) == 9
    keys = [planet.key for planet in response.planets]
    assert keys == [
        "sun",
        "moon",
        "mangal",
        "budha",
        "guru",
        "shukra",
        "shani",
        "rahu",
        "ketu",
    ]
    for planet in response.planets:
        assert 1 <= planet.house_from_moon <= 12
        assert 1 <= planet.house_from_lagna <= 12
        assert 0 <= planet.rashi_index <= 11
        assert planet.motion in {"direct", "retrograde", "stationary"}
        assert planet.ashtakavarga.sarva_bindus >= 0

    # Ashtakavarga invariants survive the round-trip into the response.
    assert sum(response.ashtakavarga.sarva) == 337
    assert response.as_of.date == "2026-06-14"


def test_moolatrikona_is_degree_aware() -> None:
    # Mars: Aries 0-12 deg = moolatrikona; beyond that (still Aries) = own sign.
    assert _dignity_for("mangal", 0, 5.0) == "moolatrikona"
    assert _dignity_for("mangal", 0, 25.0) == "own"
    assert _dignity_for("mangal", 7, 25.0) == "own"  # Scorpio is own at any degree
    # Sun: Leo 0-20 moolatrikona, 20-30 own.
    assert _dignity_for("sun", 4, 10.0) == "moolatrikona"
    assert _dignity_for("sun", 4, 25.0) == "own"
    # Whole-sign exaltation/debilitation are unaffected by degree.
    assert _dignity_for("guru", 3, 2.4) == "exalted"  # Cancer
    assert _dignity_for("shani", 0, 25.0) == "debilitated"  # Aries
    assert _dignity_for("budha", 2, 23.0) == "own"  # Gemini


def test_dignity_moon_mercury_whole_sign_exalted() -> None:
    # The Moon (exalt & moolatrikona both Taurus) and Mercury (both Virgo) read
    # "exalted" across the whole sign, by design — exaltation outranks the MT
    # band and is consistent with whole-sign exaltation for every other graha.
    # (Regression lock for the dignity-precedence boundary.)
    for degree in (0.0, 10.0, 20.0, 29.9):
        assert _dignity_for("moon", 1, degree) == "exalted"  # Taurus
    for degree in (5.0, 15.0, 17.0, 20.0, 25.0):
        assert _dignity_for("budha", 5, degree) == "exalted"  # Virgo


def test_nodes_have_no_bav_and_no_vedha() -> None:
    response = compute_transit(_request())
    by_key = {planet.key: planet for planet in response.planets}
    for node in ("rahu", "ketu"):
        assert by_key[node].ashtakavarga.bindus is None
        assert by_key[node].phala_from_moon.has_vedha_rule is False
        assert by_key[node].phala_from_moon.vedha_obstructed is False
        assert by_key[node].motion == "retrograde"


def test_vedha_obstruction_respects_exceptions() -> None:
    # Saturn favourable in the 11th from Moon is obstructed by a planet in the
    # 5th (its vedha house) — but NOT by the Sun (the Sun-Saturn exception).
    occupants = {house: [] for house in range(1, 13)}
    occupants[11] = ["shani"]
    occupants[5] = ["mangal"]
    blocked = _phala(key="shani", house_from_moon=11, occupants_by_house=occupants)
    assert blocked.favourable is True
    assert blocked.vedha_obstructed is True
    assert blocked.vedha_by == "mangal"

    occupants[5] = ["sun"]
    exempt = _phala(key="shani", house_from_moon=11, occupants_by_house=occupants)
    assert exempt.favourable is True
    assert exempt.vedha_obstructed is False
    assert exempt.vedha_by is None


def test_double_transit_intersection_relations_and_dasha_gate() -> None:
    # Jupiter in Cancer (sign 3) aspects Pisces by its 9th; Saturn in Pisces
    # (sign 11) occupies it -> Pisces is the sole double-transit sign.
    # With a Virgo (5) Lagna AND Moon, Pisces is the 7th from both -> a marriage
    # double transit; the 7th lord (Jupiter) and karaka (Venus) sit there too.
    # With the Jupiter Mahadasha running (connected to the 7th as its lord), the
    # dasha gate opens -> a full event window.
    natal = {
        "sun": 0,
        "moon": 5,
        "mangal": 0,
        "budha": 0,
        "guru": 11,
        "shukra": 11,
        "shani": 0,
        "rahu": 0,
        "ketu": 0,
        "lagna": 5,
    }
    dt = _build_double_transit(
        guru_sign=3,
        shani_sign=11,
        lagna_sign=5,
        moon_sign=5,
        natal_indices=natal,
        maha_lord="guru",
        antar_lord="moon",
    )

    assert dt.double_transit_sign_indices == [11]
    assert dt.active is True
    assert dt.maha_dasha_lord == "guru"
    for sign in dt.double_transit_sign_indices:
        assert sign in _influence_signs(3, _JUPITER_INFLUENCE)
        assert sign in _influence_signs(11, _SATURN_INFLUENCE)

    sign = dt.signs[0]
    assert sign.sign_index == 11
    assert sign.jupiter_relation == "aspect_9"
    assert sign.saturn_relation == "occupies"

    assert dt.headline_houses == [7]
    assert dt.event_window_houses == [7]
    h7 = next(b for b in dt.bhavas if b.house == 7)
    assert h7.is_double_transit is True
    assert h7.is_event_window is True
    assert h7.dasha_linked is True
    assert h7.tier == "event"
    assert h7.lord_key == "guru" and h7.lord_under_double_transit is True
    assert h7.karaka_key == "shukra" and h7.karaka_under_double_transit is True
    # Weighted: lagna2 + moon2 + karaka1 + dasha2 = 7 (lord is not scored).
    assert h7.strength_score == 7
    assert len(dt.bhavas) == 12


def test_active_lord_translates_dasha_keys_to_gochar() -> None:
    # The dasha engine names lords in English; they must be translated to the
    # gochar Sanskrit keys or the connection check silently never matches.
    assert _active_lord([{"active": True, "lord_key": "venus"}]) == "shukra"
    assert _active_lord([{"active": True, "lord_key": "jupiter"}]) == "guru"
    assert _active_lord([{"active": True, "lord_key": "mars"}]) == "mangal"
    assert _active_lord([{"active": True, "lord_key": "mercury"}]) == "budha"
    assert _active_lord([{"active": True, "lord_key": "saturn"}]) == "shani"
    # sun/moon/rahu/ketu share the same key in both vocabularies.
    assert _active_lord([{"active": True, "lord_key": "moon"}]) == "moon"
    assert _active_lord([{"active": False, "lord_key": "sun"}]) is None


def test_dasha_gate_links_through_full_pipeline_for_venus_jupiter_dasha() -> None:
    # Regression for the English/Sanskrit dasha-key mismatch: a Leo-Lagna chart
    # whose 5th lord (Jupiter) is the running antardasha must come out linked.
    # (DOB chosen so the full pipeline yields a Venus/Jupiter dasha in late 2026.)
    response = compute_transit(
        TransitComputeRequest(
            date_of_birth="2026-06-03",
            time_of_birth="12:53",
            place_of_birth="Mumbai",
            as_of_date="2026-11-01",
        )
    )
    dt = response.double_transit
    # Lords are reported in the gochar vocabulary, not the dasha engine's English.
    gochar_keys = {"sun", "moon", "mangal", "budha", "guru", "shukra", "shani", "rahu", "ketu"}
    assert dt.maha_dasha_lord in gochar_keys
    fifth = next((b for b in dt.bhavas if b.house == 5), None)
    assert fifth is not None
    if fifth.from_lagna or fifth.from_moon:
        # The 5th lord is Jupiter and the antardasha is Jupiter -> must be linked.
        assert fifth.dasha_linked is True
        assert fifth.tier in {"building", "strong", "event"}


def test_dasha_gate_opens_on_aspect_sambandha() -> None:
    # Same marriage double transit on the 7th (Pisces, sign 11). The running
    # Mahadasha lord is the Moon, in Virgo (sign 5): it neither rules, occupies,
    # nor is the karaka of the 7th — but it casts its 7th aspect onto Pisces.
    # The 4/4 sambandha rule (incl. drishti) must open the dasha gate.
    natal = {
        "sun": 0,
        "moon": 5,
        "mangal": 0,
        "budha": 0,
        "guru": 11,
        "shukra": 11,
        "shani": 0,
        "rahu": 0,
        "ketu": 0,
        "lagna": 5,
    }
    dt = _build_double_transit(
        guru_sign=3,
        shani_sign=11,
        lagna_sign=5,
        moon_sign=5,
        natal_indices=natal,
        maha_lord="moon",
        antar_lord="sun",
    )
    h7 = next(b for b in dt.bhavas if b.house == 7)
    assert h7.dasha_linked is True  # via the Moon's natal 7th aspect
    assert h7.is_event_window is True
    assert dt.event_window_houses == [7]


def test_double_transit_without_dasha_link_is_strong_not_event() -> None:
    # Same transit/chart, but neither running lord is connected to the 7th -> the
    # double transit is "strong" but holds short of a fructifying event window.
    natal = {
        "sun": 0,
        "moon": 5,
        "mangal": 0,
        "budha": 0,
        "guru": 11,
        "shukra": 11,
        "shani": 0,
        "rahu": 0,
        "ketu": 0,
        "lagna": 5,
    }
    dt = _build_double_transit(
        guru_sign=3,
        shani_sign=11,
        lagna_sign=5,
        moon_sign=5,
        natal_indices=natal,
        maha_lord="sun",
        antar_lord="mangal",
    )
    assert dt.headline_houses == [7]
    assert dt.event_window_houses == []
    h7 = next(b for b in dt.bhavas if b.house == 7)
    assert h7.is_double_transit is True
    assert h7.is_event_window is False
    assert h7.dasha_linked is False
    assert h7.tier == "strong"
    assert h7.strength_score == 5  # lagna2 + moon2 + karaka1, no dasha


def test_double_transit_present_in_response() -> None:
    response = compute_transit(_request())
    dt = response.double_transit
    assert len(dt.bhavas) == 12
    for sign in dt.double_transit_sign_indices:
        assert 0 <= sign <= 11
        # Consistency: every reported double sign is genuinely in both sets.
        assert sign in _influence_signs(dt.jupiter_sign_index, _JUPITER_INFLUENCE)
        assert sign in _influence_signs(dt.saturn_sign_index, _SATURN_INFLUENCE)
    # Event windows must be a subset of the both-frames strong transits.
    assert set(dt.event_window_houses).issubset(set(dt.headline_houses))
    for bhava in dt.bhavas:
        assert 0 <= bhava.strength_score <= 7
        assert bhava.tier in {"event", "strong", "building", "mild", "quiet"}


def test_dignity_highlights_only_for_slow_planets() -> None:
    # The Moon/Sun/Mercury/Venus change dignity too often to headline; only
    # Mars/Jupiter/Saturn dignity should appear in the highlights strip.
    response = compute_transit(_request())
    for highlight in response.highlights:
        if highlight.type in {"exalted", "debilitated"}:
            assert highlight.planet_key in {"mangal", "guru", "shani"}


def test_sade_sati_block_present() -> None:
    response = compute_transit(_request())
    assert response.saturn.status in {
        "sade_sati",
        "kantaka_dhaiya",
        "ashtama_dhaiya",
        "none",
    }
    assert 1 <= response.saturn.house_from_moon <= 12


def test_endpoint_returns_200() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/transit/compute",
        json={
            "date_of_birth": "1990-08-20",
            "time_of_birth": "08:30",
            "place_of_birth": "Mumbai",
            "as_of_date": "2026-06-14",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body["planets"]) == 9
    assert "saturn" in body
    assert "ashtakavarga" in body


def test_endpoint_unknown_place_404() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/transit/compute",
        json={
            "date_of_birth": "1990-08-20",
            "time_of_birth": "08:30",
            "place_of_birth": "Nowhere-Atlantis-XYZ",
        },
    )
    assert response.status_code == 404

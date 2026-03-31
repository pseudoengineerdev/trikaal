from reference_fixtures.comparator import compare_snapshots


def test_comparator_reports_numeric_mismatch_outside_tolerance() -> None:
    expected = {"grahas": {"sun_longitude": 79.123456}}
    actual = {"grahas": {"sun_longitude": 79.123556}}

    differences = compare_snapshots(
        expected_snapshot=expected,
        actual_snapshot=actual,
        float_tolerance=1e-6,
    )

    assert len(differences) == 1
    assert differences[0].path == "grahas.sun_longitude"
    assert differences[0].reason == "numeric_mismatch"


def test_comparator_allows_numeric_match_within_tolerance() -> None:
    expected = {"grahas": {"sun_longitude": 79.123456}}
    actual = {"grahas": {"sun_longitude": 79.1234564}}

    differences = compare_snapshots(
        expected_snapshot=expected,
        actual_snapshot=actual,
        float_tolerance=1e-5,
    )

    assert differences == []


def test_comparator_enforces_exact_path_comparison() -> None:
    expected = {"meta": {"status": "ok"}}
    actual = {"meta": {"status": "OK"}}

    differences = compare_snapshots(
        expected_snapshot=expected,
        actual_snapshot=actual,
        exact_paths=["meta.status"],
    )

    assert len(differences) == 1
    assert differences[0].path == "meta.status"
    assert differences[0].reason == "exact_mismatch"

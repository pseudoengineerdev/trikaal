from __future__ import annotations

import pytest


@pytest.fixture(autouse=True)
def disable_external_place_fallback(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("TRIKAAL_ENABLE_FALLBACK_GEOCODING", "0")

    from trikaal_api import resolver

    resolver._fallback_resolve.cache_clear()
    resolver._fallback_search.cache_clear()
    _clear_external_geocoder_cache(resolver)

    yield

    resolver._fallback_resolve.cache_clear()
    resolver._fallback_search.cache_clear()
    _clear_external_geocoder_cache(resolver)


def _clear_external_geocoder_cache(resolver_module) -> None:
    cache_clear = getattr(resolver_module._external_geocoder, "cache_clear", None)
    if callable(cache_clear):
        cache_clear()

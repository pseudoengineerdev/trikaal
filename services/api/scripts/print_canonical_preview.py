from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[3]
API_SRC = PROJECT_ROOT / "services" / "api" / "src"
if str(API_SRC) not in sys.path:
    sys.path.insert(0, str(API_SRC))

from trikaal_api.canonical import build_canonical_preview


def main() -> None:
    preview = build_canonical_preview()
    payload = preview.model_dump()
    snapshot = payload["computed_snapshot"]
    astronomy = snapshot.get("astronomy", {})

    output = {
        "fixture_id": payload["fixture_id"],
        "birth_input": payload["birth_input"],
        "profile": payload["profile"],
        "sun_sidereal_deg": astronomy.get("sun_sidereal_deg"),
        "moon_sidereal_deg": astronomy.get("moon_sidereal_deg"),
        "full_snapshot": snapshot,
    }
    print(json.dumps(output, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

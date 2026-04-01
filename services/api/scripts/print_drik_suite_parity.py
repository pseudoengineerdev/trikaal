from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[3]
API_SRC = PROJECT_ROOT / "services" / "api" / "src"
if str(API_SRC) not in sys.path:
    sys.path.insert(0, str(API_SRC))

from trikaal_api.parity import run_drik_parity_suite_check


def main() -> None:
    result = run_drik_parity_suite_check()
    print(json.dumps(result.model_dump(), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

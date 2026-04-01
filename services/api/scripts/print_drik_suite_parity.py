from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[3]
API_SRC = PROJECT_ROOT / "services" / "api" / "src"
if str(API_SRC) not in sys.path:
    sys.path.insert(0, str(API_SRC))

from trikaal_api.parity import run_drik_parity_suite_check  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--include-unverified",
        action="store_true",
        help="Include provisional engine-seed fixtures in the parity run.",
    )
    args = parser.parse_args()

    result = run_drik_parity_suite_check(include_unverified=args.include_unverified)
    print(json.dumps(result.model_dump(), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

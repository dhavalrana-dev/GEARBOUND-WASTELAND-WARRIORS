"""Copy runtime shared JSON into flutter/assets/shared (Flutter cannot bundle files
outside its package). Run after editing shared data; --check fails on drift.

Usage:
    python -I tools/build/sync_flutter_shared.py
    python -I tools/build/sync_flutter_shared.py --check
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHARED = ROOT / "shared"
TARGET = ROOT / "flutter" / "assets" / "shared"

# Runtime data only; schemas and test fixtures stay out of the app bundle.
RUNTIME_FILES = [
    "configs/gear_rules.json",
    "gears/starter_gears.json",
    "enemies/enemies.json",
    "economy/shop.json",
    "economy/currencies.json",
    "monetization/ad_policy.json",
    "waves/mission_001.json",
    "missions/campaign_route.json",
    "events/progression_rewards.json",
]


def main(argv: list[str]) -> int:
    check = "--check" in argv
    stale = []
    for rel in RUNTIME_FILES:
        source = (SHARED / rel).read_bytes()
        target = TARGET / rel
        if check:
            if not target.exists() or target.read_bytes() != source:
                stale.append(rel)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source)
        print("synced", rel)
    extra = sorted(
        str(p.relative_to(TARGET)).replace("\\", "/")
        for p in TARGET.rglob("*.json")
        if str(p.relative_to(TARGET)).replace("\\", "/") not in RUNTIME_FILES
    ) if TARGET.exists() else []
    if stale or extra:
        for rel in stale:
            print("STALE", rel)
        for rel in extra:
            print("UNEXPECTED", rel)
        return 1
    if check:
        print("flutter shared assets up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

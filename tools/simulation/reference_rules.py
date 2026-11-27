"""Reference implementation of Gearbound shared rules used to generate fixtures.

This script is the third, independent implementation of the shared
`xorshift32-v1` random algorithm, the gear shop roll, and wave expansion.
C# (Unity) and Dart (Flutter) each implement the same rules separately and
must reproduce the fixtures this script writes. It uses only the Python
standard library.

Usage:
    python -I tools/simulation/reference_rules.py           # rewrite fixtures
    python -I tools/simulation/reference_rules.py --check   # fail if stale
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHARED = ROOT / "shared"
MASK32 = 0xFFFFFFFF
ZERO_SEED_REPLACEMENT = 0x9E3779B9


class SeededRandom:
    """xorshift32-v1: shifts 13/17/5, zero seed replaced, one draw per call."""

    def __init__(self, seed: int) -> None:
        seed &= MASK32
        self.state = seed if seed != 0 else ZERO_SEED_REPLACEMENT

    def next_uint(self) -> int:
        x = self.state
        x ^= (x << 13) & MASK32
        x ^= x >> 17
        x ^= (x << 5) & MASK32
        self.state = x & MASK32
        return self.state

    def next_int(self, exclusive_max: int) -> int:
        if exclusive_max < 1 or exclusive_max > 0x7FFFFFFF:
            raise ValueError("exclusive_max must be in [1, 2^31-1]")
        return (self.next_uint() * exclusive_max) >> 32


def roll_shop(rng, catalog, config, unlocked, locked, board_has_guaranteed):
    n = config["offerCount"]
    weights = config["rarityWeights"]
    excluded = set(config["excludedCategories"])
    pool = sorted(
        (g for g in catalog
         if g["category"] not in excluded
         and (unlocked is None or g["id"] in unlocked)
         and weights.get(g["rarity"], 0) > 0),
        key=lambda g: g["id"].encode("utf-8"),
    )
    by_id = {g["id"]: g for g in catalog}
    locked = list(locked or [None] * n)
    offers = list(locked)

    for slot in range(n):
        if locked[slot] is not None:
            continue
        candidates = [g for g in pool if offers.count(g["id"]) < config["maxCopiesPerOffer"]]
        if not candidates:
            offers[slot] = None
            continue
        total = sum(weights[g["rarity"]] for g in candidates)
        r = rng.next_int(total)
        for g in candidates:
            r -= weights[g["rarity"]]
            if r < 0:
                offers[slot] = g["id"]
                break

    category = config.get("guaranteedCategory")
    if category and not board_has_guaranteed:
        present = any(o is not None and by_id[o]["category"] == category for o in offers)
        unlocked_slots = [i for i in range(n) if locked[i] is None]
        options = sorted((g for g in pool if g["category"] == category),
                         key=lambda g: (g["cost"], g["id"].encode("utf-8")))
        if not present and unlocked_slots and options:
            offers[unlocked_slots[-1]] = options[0]["id"]
    return offers


def reroll_cost(config, rerolls_taken):
    r = config["reroll"]
    return min(r["costCap"], r["baseCost"] + r["costStep"] * rerolls_taken)


def expand_wave(wave):
    spawns = []
    for group_index, group in enumerate(wave["groups"]):
        pattern = group["lanePattern"]
        for k in range(group["count"]):
            spawns.append((group["firstSpawnTick"] + k * group["intervalTicks"],
                           pattern[k % len(pattern)], group_index, k, group["enemyId"]))
    spawns.sort(key=lambda s: (s[0], s[1], s[2], s[3]))
    return [{"tick": s[0], "lane": s[1], "enemyId": s[4]} for s in spawns]


def load(rel):
    return json.loads((SHARED / rel).read_text(encoding="utf-8"))


def build_fixtures():
    rng_cases = []
    for seed in [1, 42, 0, 2463534242, 4294967295]:
        rng = SeededRandom(seed)
        rng_cases.append({"seed": seed, "nextUint": [rng.next_uint() for _ in range(8)]})
    rng = SeededRandom(42)
    bounds = [10, 100, 7, 1, 1000, 3, 2147483647, 25]
    int_case = {"seed": 42, "bounds": bounds, "results": [rng.next_int(b) for b in bounds]}
    random_fixture = {
        "schemaVersion": 1,
        "algorithm": "xorshift32-v1",
        "zeroSeedReplacement": ZERO_SEED_REPLACEMENT,
        "nextUintCases": rng_cases,
        "nextIntCase": int_case,
    }

    catalog = load("gears/starter_gears.json")["gears"]
    shop = load("economy/shop.json")
    shop_cases = []
    definitions = [
        ("all-unlocked-seed-1", 1, None, None, True, 4),
        ("all-unlocked-seed-12345", 12345, None, None, True, 4),
        ("zero-seed", 0, None, None, True, 2),
        ("guarantee-transmission", 7, None, None, False, 4),
        ("locked-first-slot", 99, None, ["turret.spark", None, None], True, 3),
        ("restricted-unlocks", 2024, ["drive.coupler", "unit.rivetguard"], None, False, 3),
    ]
    for case_id, seed, unlocked, locked, board_has, rolls in definitions:
        rng = SeededRandom(seed)
        results = [roll_shop(rng, catalog, shop, set(unlocked) if unlocked else None, locked, board_has)
                   for _ in range(rolls)]
        shop_cases.append({"id": case_id, "seed": seed, "unlocked": unlocked, "locked": locked,
                           "boardHasGuaranteedCategory": board_has, "expectedOffers": results})
    shop_fixture = {
        "schemaVersion": 1,
        "rerollCosts": [reroll_cost(shop, k) for k in range(7)],
        "cases": shop_cases,
    }

    mission = load("waves/mission_001.json")
    wave_fixture = {
        "schemaVersion": 1,
        "missionId": mission["missionId"],
        "waves": [{"id": w["id"], "spawns": expand_wave(w)} for w in mission["waves"]],
    }
    return {
        "test-fixtures/random_vectors.json": random_fixture,
        "test-fixtures/shop_cases.json": shop_fixture,
        "test-fixtures/mission_001_spawns.json": wave_fixture,
    }


def main(argv):
    check = "--check" in argv
    stale = []
    for rel, data in build_fixtures().items():
        text = json.dumps(data, indent=2) + "\n"
        path = SHARED / rel
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                stale.append(rel)
        else:
            path.write_text(text, encoding="utf-8", newline="\n")
            print("wrote", rel)
    if stale:
        print("STALE fixtures:", ", ".join(stale))
        return 1
    if check:
        print("fixtures up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

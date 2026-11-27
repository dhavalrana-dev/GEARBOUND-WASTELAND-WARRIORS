"""Validate Gearbound shared JSON data without third-party packages.

Checks schema versions, required fields, stable ID formats, uniqueness, and
cross-file references (waves -> enemies, shop rarities -> gear rarities).
It is a focused validator, not a full JSON Schema engine; the schema files in
shared/schemas remain the authoritative contract for editors and tools.

Usage: python -I tools/data-validation/validate_shared.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SHARED = Path(__file__).resolve().parents[2] / "shared"
ID_PATTERN = re.compile(r"^[a-z0-9]+([.-][a-z0-9]+)*$")
GEAR_CATEGORIES = {"power-core", "transmission", "booster", "infantry", "turret"}
PORTS = {"north", "east", "south", "west"}
errors: list[str] = []


def fail(where: str, message: str) -> None:
    errors.append(f"{where}: {message}")


def load(rel: str):
    path = SHARED / rel
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(rel, f"cannot read JSON ({exc})")
        return None
    if data.get("schemaVersion") != 1:
        fail(rel, "schemaVersion must be 1")
    return data


def require_int(where, obj, key, minimum=0):
    value = obj.get(key)
    if not isinstance(value, int) or isinstance(value, bool) or value < minimum:
        fail(where, f"'{key}' must be an integer >= {minimum}")


def unique_ids(rel, items):
    seen = set()
    for item in items:
        item_id = item.get("id")
        if not isinstance(item_id, str) or not ID_PATTERN.match(item_id):
            fail(rel, f"invalid id {item_id!r}")
        elif item_id in seen:
            fail(rel, f"duplicate id {item_id}")
        seen.add(item_id)
    return seen


def main() -> int:
    rules = load("configs/gear_rules.json")
    gears_doc = load("gears/starter_gears.json")
    enemies_doc = load("enemies/enemies.json")
    shop = load("economy/shop.json")
    mission = load("waves/mission_001.json")
    if None in (rules, gears_doc, enemies_doc, shop, mission):
        return report()

    if rules["simulation"].get("ticksPerSecond") != 30:
        fail("configs/gear_rules.json", "ticksPerSecond must be 30 per AGENTS.md")
    if rules["simulation"].get("randomAlgorithm") != "xorshift32-v1":
        fail("configs/gear_rules.json", "randomAlgorithm must be xorshift32-v1")
    net = rules["network"]
    if net["boosterBonusPercentCap"] < net["boosterBonusPercentEach"]:
        fail("configs/gear_rules.json", "booster cap is lower than a single booster")

    gears = gears_doc["gears"]
    unique_ids("gears/starter_gears.json", gears)
    rarities = set(shop["rarityWeights"])
    for gear in gears:
        where = f"gears/starter_gears.json[{gear.get('id')}]"
        if gear.get("category") not in GEAR_CATEGORIES:
            fail(where, f"unknown category {gear.get('category')!r}")
        if gear.get("rarity") not in rarities:
            fail(where, f"rarity {gear.get('rarity')!r} has no shop weight")
        if not set(gear.get("ports", [])) <= PORTS or len(set(gear.get("ports", []))) != len(gear.get("ports", [])):
            fail(where, "ports must be unique compass directions")
        require_int(where, gear, "tier", 1)
        require_int(where, gear, "cost")
        require_int(where, gear, "baseIntervalTicks")
        is_output = gear.get("category") in {"infantry", "turret"}
        if is_output and gear.get("baseIntervalTicks", 0) < 1:
            fail(where, "output gears need a positive baseIntervalTicks")
    cores = [g for g in gears if g.get("category") == "power-core"]
    if not cores:
        fail("gears/starter_gears.json", "at least one power core is required")
    if not any(g.get("category") == shop["guaranteedCategory"] for g in gears):
        fail("economy/shop.json", "guaranteedCategory has no gear in the catalog")

    enemy_ids = unique_ids("enemies/enemies.json", enemies_doc["enemies"])
    for enemy in enemies_doc["enemies"]:
        where = f"enemies/enemies.json[{enemy.get('id')}]"
        for key, minimum in (("health", 1), ("armor", 0), ("damage", 1), ("attackRangeMm", 0),
                             ("movementMmPerTick", 0), ("attackIntervalTicks", 1), ("rewardScrap", 0)):
            require_int(where, enemy, key, minimum)

    r = shop["reroll"]
    if r["costCap"] < r["baseCost"]:
        fail("economy/shop.json", "reroll costCap is below baseCost")
    if shop["offerCount"] < 1:
        fail("economy/shop.json", "offerCount must be positive")
    cheapest_useful = min((g["cost"] for g in gears if g["category"] in {"transmission", "infantry"}), default=None)
    if cheapest_useful is None or shop["startingScrap"] < cheapest_useful:
        fail("economy/shop.json", "startingScrap cannot buy any transmission or infantry gear")

    unique_ids("waves/mission_001.json", mission["waves"])
    for wave in mission["waves"]:
        where = f"waves/mission_001.json[{wave.get('id')}]"
        require_int(where, wave, "rewardScrap")
        if not wave.get("groups"):
            fail(where, "wave has no spawn groups")
        for group in wave.get("groups", []):
            if group.get("enemyId") not in enemy_ids:
                fail(where, f"enemyId {group.get('enemyId')!r} is not defined in enemies.json")
            require_int(where, group, "count", 1)
            require_int(where, group, "firstSpawnTick")
            require_int(where, group, "intervalTicks", 1)
            lanes = group.get("lanePattern", [])
            if not lanes or any(lane not in (0, 1, 2) for lane in lanes):
                fail(where, "lanePattern must contain lanes 0-2")

    rewards = load("events/progression_rewards.json")
    if rewards is not None:
        where = "events/progression_rewards.json"
        booster_ids = unique_ids(where, rewards["boosters"])

        def check_bundle(label, bundle):
            require_int(f"{where}[{label}]", bundle, "scrap")
            for booster_id, amount in bundle.get("boosters", {}).items():
                if booster_id not in booster_ids:
                    fail(where, f"{label} grants unknown booster {booster_id}")
                if not isinstance(amount, int) or amount < 1:
                    fail(where, f"{label} booster amounts must be positive integers")
            if bundle.get("scrap", 0) == 0 and not bundle.get("boosters"):
                fail(where, f"{label} grants nothing")

        streak = rewards["winStreak"]
        if sorted(streak["streakSoldierLaneOrder"]) != [0, 1, 2] or streak["maxLevel"] > 3:
            fail(where, "streak lanes must be a permutation of 0-2 and maxLevel <= 3")
        previous = 0
        for chest in rewards["starChests"]:
            if chest["stars"] <= previous:
                fail(where, "star chest thresholds must strictly increase")
            previous = chest["stars"]
            check_bundle(f"starChest {chest['stars']}", chest)
        if rewards["loginTrack"].get("missedDaysReset") is not False:
            fail(where, "loginTrack.missedDaysReset must stay false (no streak-loss pressure)")
        for index, day in enumerate(rewards["loginTrack"]["days"], 1):
            check_bundle(f"login day {index}", day)
        unique_ids(where, rewards["dailyContracts"])
        points = [tier["points"] for tier in rewards["weeklyEventTiers"]]
        if points != sorted(set(points)):
            fail(where, "weekly event tiers must have strictly increasing points")

    return report()


def report() -> int:
    if errors:
        for error in errors:
            print("ERROR", error)
        print(f"shared data validation FAILED with {len(errors)} error(s)")
        return 1
    print("shared data validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

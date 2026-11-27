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
    extra_missions = [load("waves/copperwash_01.json")]
    if None in (rules, gears_doc, enemies_doc, shop, mission):
        return report()

    if rules["simulation"].get("ticksPerSecond") != 30:
        fail("configs/gear_rules.json", "ticksPerSecond must be 30 per AGENTS.md")
    if rules["simulation"].get("randomAlgorithm") != "xorshift32-v1":
        fail("configs/gear_rules.json", "randomAlgorithm must be xorshift32-v1")
    net = rules["network"]
    if net["boosterBonusPercentCap"] < net["boosterBonusPercentEach"]:
        fail("configs/gear_rules.json", "booster cap is lower than a single booster")

    merge = rules.get("merge", {})
    pct = merge.get("intervalPercentByTier", [])
    if len(pct) != merge.get("maxTier") or not pct or pct[0] != 100 or any(not isinstance(v, int) or v < 1 for v in pct):
        fail("configs/gear_rules.json", "merge.intervalPercentByTier needs one positive entry per tier, starting at 100")
    workshop = rules.get("workshop", {})
    board = rules["board"]
    if len(workshop.get("outputLaneByRow", [])) != board["height"] or any(l not in (0, 1, 2) for l in workshop.get("outputLaneByRow", [])):
        fail("configs/gear_rules.json", "workshop.outputLaneByRow needs one lane (0-2) per board row")

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
    gear_ids = {g.get("id") for g in gears}
    starters = workshop.get("starterGears", [])
    cells = set()
    for starter in starters:
        if starter.get("definitionId") not in gear_ids:
            fail("configs/gear_rules.json", f"starter gear {starter.get('definitionId')!r} is not in the catalog")
        cell = (starter.get("x"), starter.get("y"))
        if cell in cells or not (0 <= cell[0] < board["width"] and 0 <= cell[1] < board["height"]):
            fail("configs/gear_rules.json", f"starter gear cell {cell} is invalid or duplicated")
        cells.add(cell)
    if not any(g.get("category") == "power-core" for g in gears if g.get("id") in {s.get("definitionId") for s in starters}):
        fail("configs/gear_rules.json", "starter gears must include a power core")
    for category in workshop.get("shopCategories", []):
        if category not in GEAR_CATEGORIES or category == "power-core":
            fail("configs/gear_rules.json", f"shop category {category!r} is unknown or not purchasable")
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

    for rel, doc in [("waves/mission_001.json", mission), ("waves/copperwash_01.json", extra_missions[0])]:
        if doc is None:
            continue
        unique_ids(rel, doc["waves"])
        for wave in doc["waves"]:
            where = f"{rel}[{wave.get('id')}]"
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

    route = load("missions/campaign_route.json")
    if route is not None:
        for node in route.get("nodes", []):
            where = f"missions/campaign_route.json[{node.get('id')}]"
            target = SHARED / node.get("mission", "")
            if not target.is_file():
                fail(where, f"mission file {node.get('mission')!r} does not exist")
                continue
            wave_ids = {w["id"] for w in json.loads(target.read_text(encoding="utf-8"))["waves"]}
            node_waves = node.get("waveIds")
            if not isinstance(node_waves, list) or not node_waves or len(set(node_waves)) != len(node_waves):
                fail(where, "waveIds must be a non-empty list of unique wave IDs")
            elif any(w not in wave_ids for w in node_waves):
                fail(where, f"waveIds {node_waves} not all found in {node.get('mission')}")

    currencies = load("economy/currencies.json")
    currencies_ids = [c.get("id") for c in currencies["currencies"]] if currencies else []
    if currencies is not None:
        ids = set()
        for currency in currencies["currencies"]:
            cid = currency.get("id")
            if not isinstance(cid, str) or not re.match(r"^[a-z][a-z0-9_]*$", cid) or cid in ids:
                fail("economy/currencies.json", f"invalid or duplicate currency id {cid!r}")
            ids.add(cid)
            require_int(f"economy/currencies.json[{cid}]", currency, "max", 1)
            if currency.get("scope") not in {"mission", "persistent", "event"}:
                fail("economy/currencies.json", f"{cid}: unknown scope")
        if not any(c.get("premium") for c in currencies["currencies"]):
            fail("economy/currencies.json", "expected one premium currency")
        if any(c.get("premium") and c.get("scope") != "persistent" for c in currencies["currencies"]):
            fail("economy/currencies.json", "premium currency must be persistent")

    ads = load("monetization/ad_policy.json")
    if ads is not None:
        inter = ads["interstitial"]
        forbidden = {"combat", "gear_placement", "tutorial", "startup", "purchase"} & set(inter["allowedContexts"])
        if forbidden:
            fail("monetization/ad_policy.json", f"interstitials may not run in {sorted(forbidden)}")
        for key in ("adFreeFirstMissions", "minMissionsBetween", "minSecondsBetween", "maxPerSession", "suppressSecondsAfterRewarded"):
            require_int("monetization/ad_policy.json[interstitial]", inter, key)
        if ads.get("rewardedInterstitial", {}).get("enabled"):
            fail("monetization/ad_policy.json", "rewarded interstitials must stay disabled until policy review")
        seen = set()
        for placement in ads["rewardedPlacements"]:
            pid = placement.get("id", "")
            if pid in seen or not pid.startswith("rewarded."):
                fail("monetization/ad_policy.json", f"invalid or duplicate placement {pid!r}")
            seen.add(pid)
            for key in ("dailyCap", "perMissionCap", "cooldownSeconds"):
                require_int(f"monetization/ad_policy.json[{pid}]", placement, key)
            if "alloy" in json.dumps(placement.get("reward", {})):
                fail("monetization/ad_policy.json", f"{pid}: ad rewards may not grant premium currency")

    manifest = load("art/asset_manifest.json")
    if manifest is not None:
        where = "art/asset_manifest.json"
        statuses = ["planned", "concept", "approved_concept", "source_ready", "rigged", "animated",
                    "runtime_integrated", "qa_passed", "approved"]
        known_owners = ({g["id"] for g in gears} | enemy_ids | set(currencies_ids)
                        | {"hero.rivet", "fortress.wayfarer", "region.copperwash", "project", "board", "ui", "vfx",
                           "route", "rewards", "audio", "store", "booster.vanguard",
                           "event.scrapstorm", "event.gear_frenzy", "event.engineering_trials"})
        seen_assets = set()
        for asset in manifest["assets"]:
            aid = asset.get("assetId")
            if not isinstance(aid, str) or not re.match(r"^[a-z0-9]+(_[a-z0-9]+)*$", aid) or aid in seen_assets:
                fail(where, f"invalid or duplicate assetId {aid!r}")
            seen_assets.add(aid)
            owner = asset.get("logicalOwnerId", "")
            if owner not in known_owners and not owner.startswith("gearbound."):
                fail(where, f"{aid}: logicalOwnerId {owner!r} is not a known data ID or provisional owner")
            status = asset.get("status")
            if status not in statuses:
                fail(where, f"{aid}: unknown status {status!r}")
            elif statuses.index(status) >= statuses.index("approved_concept"):
                if not asset.get("reviewer") or not asset.get("acceptanceEvidence"):
                    fail(where, f"{aid}: status {status} needs a reviewer and acceptance evidence")
                if asset.get("license") in ("", "pending") or asset.get("provenance") in ("", "none"):
                    fail(where, f"{aid}: status {status} needs a license and provenance")
            if status in ("runtime_integrated", "qa_passed", "approved") and not asset.get("runtimePaths"):
                fail(where, f"{aid}: status {status} needs runtime paths")
            if not str(asset.get("sourcePath", "")).startswith("assets-source/"):
                fail(where, f"{aid}: sourcePath must live under assets-source/")

    heroes = load("heroes/heroes.json")
    if heroes is not None:
        where = "heroes/heroes.json"
        unique_ids(where, heroes.get("heroes", []))
        for hero in heroes.get("heroes", []):
            hw = f"{where}[{hero.get('id')}]"
            for key, minimum in (("health", 1), ("armor", 0), ("damage", 1), ("attackRangeMm", 0),
                                 ("movementMmPerTick", 0), ("attackIntervalTicks", 1)):
                require_int(hw, hero, key, minimum)
            special = hero.get("special")
            if not isinstance(special, dict):
                fail(hw, "special is required")
                continue
            for key, minimum in (("spMax", 1), ("spPerHit", 1), ("damage", 1), ("radiusMm", 0)):
                require_int(f"{hw}.special", special, key, minimum)
            if isinstance(special.get("spPerHit"), int) and isinstance(special.get("spMax"), int)                     and special["spPerHit"] > special["spMax"]:
                fail(hw, "special.spPerHit cannot exceed spMax (the special would charge on one hit)")

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

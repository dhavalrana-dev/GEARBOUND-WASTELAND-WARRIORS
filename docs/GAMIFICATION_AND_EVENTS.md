# Gamification, events and tasks

Gearbound borrows the *structure* that keeps casual level-map games engaging (a route map, star ratings, short daily goals, a weekly score chase, win-streak bonuses, milestone chests, a login track and earned pre-level boosters). It does not copy any game's names, art, currencies or reward tables. Every system below is original, works offline, and is earned only through play.

Tuning lives in [`shared/events/progression_rewards.json`](../shared/events/progression_rewards.json). The Dart constants in `flutter/lib/progression/rewards.dart` and `campaign_progress.dart` are checked against that file by `flutter/test/progression/rewards_test.dart`, and `tools/data-validation/validate_shared.py` validates the file itself.

## Systems

| System | Player-facing rule | Anti-abuse / fairness rule | Status |
|---|---|---|---|
| Wasteland Route | 12 nodes across three chapters; every clear unlocks the next node. | Replays cannot re-earn first-clear scrap. | Implemented (Flutter) |
| Star rating | 3★ at ≥75 fortress health, 2★ at ≥40, 1★ for any clear. Best result is kept. | Stars never gate unlocks. | Implemented (Flutter) |
| Daily contracts | Three small goals (clear a route, power 4 gears in one setup, shift Rivet 3 times). Reset at local midnight. | Each pays once per day; the setup goal measures one setup, not accumulated sessions. | Implemented (Flutter) |
| Scrapstorm weekly event | Weekly score = sum of each node's best stars this week; three fixed reward tiers. | Only the weekly best per node counts; tiers claim once; resets Monday. | Implemented (Flutter) |
| Overclock Streak | Each consecutive victory adds one free soldier at wave start (lanes 1, 0, 2), up to 3. | A defeat resets the streak, and so does abandoning a mission after its first wave started (pause menu or system Back), so quitting cannot protect a streak. Leaving before wave 1 costs nothing. | Implemented (Flutter) |
| Star chests | Every 6 total stars opens a chest with fixed, visible contents (scrap + Vanguard Drops). | Contents are never random; each chest opens once. | Implemented (Flutter) |
| Supply Log | 7-day login track; one claim per local day, then loops. | Missed days pause the track; they never reset it. | Implemented (Flutter) |
| Vanguard Drop booster | Optional pre-wave booster: one Rivetguard soldier in each lane. | Earned only, never sold; stack cap 9; consumed when the wave starts. | Implemented (Flutter) |

## Principles

- No paid random rewards or energy/lives timers. Monetization follows the revised policy in `AGENTS.md`: optional rewarded ads add to the normal reward and never replace it, interstitials appear only at transitions, and purchases have fixed contents.
- Every reward is paid through the wallet ledger with an idempotency key (`docs/REWARD_TRANSACTION_SYSTEM.md`).
- Missing a day must never cost progress already earned.
- Boosters help but never replace the gear machine. At most 2 opening soldiers per lane, under the per-lane unit cap of 4.
- Local device dates are used, with a monotonic guard against rolling the clock back. Forward jumps cannot be detected offline, so server time must come before any "global" event or valuable time-gated reward.

## Planned next (not implemented)

- Achievement track (chapter clears, merges, perfect defenses) with cosmetic rewards.
- Rotating weekly event rule sets (e.g. "boosters capped at 10%", "runners only").
- A second earned booster that acts on the gear board (e.g. a free reroll) once the shop UI exists in Flutter.
- C# port of the meta-progression model so Unity reaches parity (tracked in `CROSS_ENGINE_PARITY.md`).
- Human playtest of streak and chest pacing; current values are first-pass tuning.

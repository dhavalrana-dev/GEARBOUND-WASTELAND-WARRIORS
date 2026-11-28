# Gearbound contributor guide

## Project direction
- Working title: **GEARBOUND: Wasteland Warriors**. Build an original game; references inform broad mechanics and presentation only.
- Unity 6.3 LTS is the reference runtime. Shared, versioned JSON is authoritative for tunable rules. Keep simulation code engine-independent where practical.
- Ship a validated vertical slice before widening content. Record real implementation and verification status in `docs/DEVELOPMENT_STATUS.md`.
- Track phase progress in `.kiro/specs/gearbound-production/tasks.md` (Kiro spec: `requirements.md`, `design.md`, `tasks.md`; steering in `.kiro/steering/`). Tick a box only when its evidence is recorded, then refresh the table with `python -I tools/build/phase_progress.py`.

## Repository rules
- Keep source art under `assets-source/`; runtime exports under each engine's asset folder.
- Never use proprietary reference assets. Offline campaign play must never require a network connection.
- Use stable IDs, seeded randomness, fixed integer ticks (30 Hz), and explicit event order for gameplay.
- Never mark unexecuted builds, tests, or device profiles as passed. Do not claim performance targets without measurements.
- Add packages only when their use is justified and compatible with the installed Unity/Flutter SDK.

## Initial simulation contract
- Board is 5x5; connections are orthogonal and require reciprocal ports.
- A single power core drives a connected component. A component touching multiple cores or containing an odd-parity gear loop is conflicted and inactive.
- A gear's rotation alternates across each physical mesh edge. Gameplay uses graph rules, not rigid-body physics.
- Booster modifiers are additive, capped by shared config. Output clocks are fixed-tick and unit caps are explicit.

## Monetization and rewards policy (revised 2026-11-27)
- Approved: optional rewarded ads, interstitial ads at natural transitions, and fixed-content in-app purchases (premium Alloy, No Ads, bundles, cosmetics). See `docs/MONETIZATION_STRATEGY.md`.
- Forbidden: paid random rewards (loot boxes), ads during combat, gear placement, tutorials or purchases, ads at app startup, misleading purchase or reward screens, and difficulty spikes designed to push spending.
- Interstitial rules live in `shared/monetization/ad_policy.json` and must pass `shared/test-fixtures/ad_policy_cases.json`. The first three missions are ad-free, and a failed or missing ad never blocks progress.
- The normal reward is always granted without watching an ad. Ad rewards add to it and are paid exactly once, through the wallet ledger.
- Every balance change goes through the wallet ledger (`flutter/lib/economy/wallet.dart`, `unity/Assets/Game/Economy/Wallet.cs`) with an idempotency key. UI code never mutates balances.
- Premium currency (`alloy`) and entitlements are granted only from verified purchases or server-verified rewards. Never mark mock ad or purchase providers as live, and never commit ad unit IDs, store keys or backend secrets.
- Monetization never changes deterministic combat. Combat boosters enter the simulation only as explicit, validated mission-start commands.

## Working commands
- Unity editor: `C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor\Unity.exe`
- Run Unity EditMode tests from PowerShell with `-batchmode -nographics -projectPath unity -runTests -testPlatform EditMode -testResults artifacts/unity-editmode.xml -logFile artifacts/unity-test.log`.
- Flutter/Dart toolchain is expected at `E:\flutter\bin`; record command failures instead of inferring SDK compatibility.
- Shared data checks: `python -I tools/data-validation/validate_shared.py`, `python -I tools/simulation/reference_rules.py --check`, `python -I tools/build/sync_flutter_shared.py --check`, `tools/simulation/generate_combat_traces.ps1 -Check`, `python -I tools/build/phase_progress.py --check`, and from `flutter/`: `dart run tool/workshop_cases.dart --check` and `dart run tool/baseline_check.dart` (also compile it with `dart compile exe` to check AOT).
- `.gitattributes` pins JSON, Dart, C#, Python and Markdown to LF; byte-for-byte fixture checks depend on it.

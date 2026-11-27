# Gearbound contributor guide

## Project direction
- Working title: **GEARBOUND: Wasteland Warriors**. Build an original game; references inform broad mechanics and presentation only.
- Unity 6.3 LTS is the reference runtime. Shared, versioned JSON is authoritative for tunable rules. Keep simulation code engine-independent where practical.
- Ship a validated vertical slice before widening content. Record real implementation and verification status in `docs/DEVELOPMENT_STATUS.md`.

## Repository rules
- Keep source art under `assets-source/`; runtime exports under each engine's asset folder.
- Avoid paid random rewards, mandatory online play, forced combat ads, and proprietary reference assets.
- Use stable IDs, seeded randomness, fixed integer ticks (30 Hz), and explicit event order for gameplay.
- Never mark unexecuted builds, tests, or device profiles as passed. Do not claim performance targets without measurements.
- Add packages only when their use is justified and compatible with the installed Unity/Flutter SDK.

## Initial simulation contract
- Board is 5x5; connections are orthogonal and require reciprocal ports.
- A single power core drives a connected component. A component touching multiple cores or containing an odd-parity gear loop is conflicted and inactive.
- A gear's rotation alternates across each physical mesh edge. Gameplay uses graph rules, not rigid-body physics.
- Booster modifiers are additive, capped by shared config. Output clocks are fixed-tick and unit caps are explicit.

## Working commands
- Unity editor: `C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor\Unity.exe`
- Run Unity EditMode tests from PowerShell with `-batchmode -nographics -projectPath unity -runTests -testPlatform EditMode -testResults artifacts/unity-editmode.xml -logFile artifacts/unity-test.log`.
- Flutter/Dart toolchain is expected at `E:\flutter\bin`; record command failures instead of inferring SDK compatibility.

# GEARBOUND: Wasteland Warriors

**Build the machine. Command the battle.**

An original mobile mechanical strategy and action game. Players wire a compact gear network to power soldiers, defenses, and battlefield support, then steer Rivet through short lane-based encounters.

## Project status

Early playable prototype with placeholder graphics.

- **Shared rules, both engines:** the mechanical network, lane combat with multi-wave missions, hero special, boss telegraphs, turret projectiles, the seeded shop and workshop rules, and an idempotent wallet ledger. Cross-engine fixtures and seven combat traces prove Unity and Flutter agree.
- **Flutter/Flame client:** a 12-node campaign route loading shared mission data, the workshop (shop, drag and drop, merge, undo), stars, daily contracts, a weekly offline event, streaks, chests and boosters, pause and checkpoints.
- **Not yet:** production art, a Unity playable client, multi-wave tuning for nodes 2–12, a physical-phone test and performance numbers (Android builds run on the emulator so far), and any ad or purchase SDK. Ad placement rules are built and tested only. See the [phase checklist](.kiro/specs/gearbound-production/tasks.md), [development status](docs/DEVELOPMENT_STATUS.md), [phase roadmap](docs/PHASE_ROADMAP.md), and [backlog](docs/TASK_BACKLOG.md).

## Structure

- `shared/`: schemas, balancing configuration, and cross-engine fixtures.
- `unity/`: Unity 6.3 reference implementation.
- `flutter/`: Flutter/Flame workshop and Dart mechanical-network implementation.
- `docs/`: design, technical decisions, reference analysis, risks, and production tracking.
- `assets-source/`: original source art and asset inventory.
- `.kiro/`: Kiro steering files and the production spec (`requirements.md`, `design.md`, phase-wise `tasks.md`).

## First prototype rules

The 5x5 board uses orthogonal, reciprocal gear ports. A single core powers a component. A component with multiple cores or an odd rotational loop becomes safely inactive. Boosters add at most 30% total speed. The simulation runs at 30 fixed ticks per second.

## Open in Unity

Open `unity/` with Unity 6.3 LTS or newer compatible Unity 6 LTS. Unity currently holds the engine-independent rules (`Assets/Game/Core`, `Economy`, `Workshop`) and their EditMode tests; there is no playable scene yet (GB-046).

## Flutter checks

From `flutter/`, run `flutter pub get`, `flutter analyze`, and `flutter test`. Flame 1.38.2 is the resolved renderer dependency. Shared-data checks are listed in `AGENTS.md`.

To review the game on a Windows PC, turn on Windows Developer Mode and run `flutter run -d windows` from `flutter/` (debug build only). Android builds use the Android Studio SDK (`flutter build apk --debug`, or `flutter run` with the Pixel 10 Pro XL emulator running); see `docs/TOOLCHAIN_REPORT.md`.

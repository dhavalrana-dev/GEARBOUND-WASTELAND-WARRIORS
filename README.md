# GEARBOUND: Wasteland Warriors

**Build the machine. Command the battle.**

An original mobile mechanical strategy and action game. Players wire a compact gear network to power soldiers, defenses, and battlefield support, then steer Rivet through short lane-based encounters.

## Project status

Early playable prototype. The Unity core and Flutter/Flame client include the mechanical network, lane combat, a campaign route, local stars, daily contracts, and a weekly offline event. Encounter variety, production art, and mobile packaging remain in progress. See [development status](docs/DEVELOPMENT_STATUS.md), [phase roadmap](docs/PHASE_ROADMAP.md), and [backlog](docs/TASK_BACKLOG.md).

## Structure

- `shared/`: schemas, balancing configuration, and cross-engine fixtures.
- `unity/`: Unity 6.3 reference implementation.
- `flutter/`: Flutter/Flame workshop and Dart mechanical-network implementation.
- `docs/`: design, technical decisions, reference analysis, risks, and production tracking.
- `assets-source/`: original source art and asset inventory.

## First prototype rules

The 5x5 board uses orthogonal, reciprocal gear ports. A single core powers a component. A component with multiple cores or an odd rotational loop becomes safely inactive. Boosters add at most 30% total speed. Simulation is planned at 30 fixed ticks per second.

## Open in Unity

Open `unity/` with Unity 6.3 LTS or newer compatible Unity 6 LTS. No custom art has been produced yet; presentation work follows the mechanical and combat validation milestone.

## Flutter checks

From `flutter/`, run `flutter pub get`, `flutter analyze`, and `flutter test`. Flame 1.38.2 is the resolved renderer dependency. The Android build currently requires the local Android NDK license to be accepted; the project has not accepted it automatically.

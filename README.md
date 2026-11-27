# GEARBOUND: Wasteland Warriors

**Build the machine. Command the battle.**

An original mobile mechanical strategy and action game. Players wire a compact gear network to power soldiers, defenses, and battlefield support, then steer Rivet through short lane-based encounters.

## Project status

Preproduction and mechanical prototype. This repository began empty. The initial implementation establishes shared rules and the Unity reference project; it is not yet a complete or playable vertical slice. See [development status](docs/DEVELOPMENT_STATUS.md) and [backlog](docs/TASK_BACKLOG.md).

## Structure

- `shared/`: schemas, balancing configuration, and cross-engine fixtures.
- `unity/`: Unity 6.3 reference implementation.
- `flutter/`: reserved for the Flame parity implementation after shared rules validate.
- `docs/`: design, technical decisions, reference analysis, risks, and production tracking.
- `assets-source/`: original source art and asset inventory.

## First prototype rules

The 5x5 board uses orthogonal, reciprocal gear ports. A single core powers a component. A component with multiple cores or an odd rotational loop becomes safely inactive. Boosters add at most 30% total speed. Simulation is planned at 30 fixed ticks per second.

## Open in Unity

Open `unity/` with Unity 6.3 LTS or newer compatible Unity 6 LTS. No custom art has been produced yet; presentation work follows the mechanical and combat validation milestone.

# Flutter and Flame architecture

## Toolchain
- Flutter 3.47.7 stable, Dart 3.13.5.
- Flame 1.38.2 (`^1.38.2`), resolved and locked in `flutter/pubspec.lock`.
- Flame's documented `FlameGame`, `World`, `CameraComponent`, and `GameWidget` lifecycle is used; Flutter owns responsive panels and Flame owns the board/battlefield canvas.

## Code boundaries
- `lib/mechanical/gear_network.dart`: plain Dart board, placement, merge, connectivity graph, rotational parity, booster cap and output interval calculation.
- `lib/game/gearbound_game.dart`: Flame rendering of the mechanical board and three-lane battlefield. It recalculates its composition when the canvas changes size.
- `lib/app/gearbound_app.dart`: orientation-aware Flutter workshop controls and status panels.
- `test/mechanical/gear_network_test.dart`: rule checks corresponding to the Unity mechanical checks.

## Current limitation
The screen is a mechanical/battlefield presentation prototype. Combat simulation, hero controls, gear-to-combat output, save data, and mission progression are not implemented yet. Android compilation reaches Gradle but cannot proceed until the installed NDK license is accepted. See `DEVELOPMENT_STATUS.md`.

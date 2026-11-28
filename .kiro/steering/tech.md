---
inclusion: always
---

# Tech stack and commands

## Engines
- **Unity 6.3 LTS** (6000.3.27f1) is the reference runtime. Rules live in presentation-free assemblies: `Gearbound.Core`, `Gearbound.Economy`, `Gearbound.Workshop`.
- **Flutter 3.47.7 / Dart 3.13.5 with Flame 1.38.2** is the playable client today. Toolchain at `E:\flutter\bin`.
- Both engines implement the same rules from **shared, versioned JSON** in `shared/`. Shared fixtures prove they agree.

## Determinism contract
- 30 fixed integer ticks per second; stable IDs; ties broken by ID; explicit event order.
- Randomness only through `xorshift32-v1` (`SeededRandom`); derive seeds from small integers with `mixSeed32`.
- Combat traces hash every tick with FNV-1a; a checkpoint every 30 ticks locates divergence.
- C# Core must also compile under Unity's bundled Mono `mcs` (no C# 8 switch expressions, nullable tuple casts or tuple `==`).

## Commands
- Flutter (from `flutter/`): `flutter pub get`, `flutter analyze`, `flutter test`.
- Review build on Windows: `flutter run -d windows` (needs Windows Developer Mode; debug only).
- Unity EditMode (PowerShell): `"C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor\Unity.exe" -batchmode -nographics -projectPath unity -runTests -testPlatform EditMode -testResults artifacts/unity-editmode.xml -logFile artifacts/unity-test.log` (Unity resolves the relative `-testResults` path inside `unity/`, so the report lands in `unity/artifacts/unity-editmode.xml`)
- Unity Android baseline: `-batchmode -nographics -quit -projectPath unity -buildTarget Android -executeMethod Gearbound.Baseline.Editor.AndroidBaselineBuild.Build -logFile artifacts/unity-android-build.log`, then install `unity/Builds/android/gearbound-unity-baseline.apk` and read `adb logcat -s Unity` (see `docs/TOOLCHAIN_REPORT.md`)
- Shared data checks:
  - `python -I tools/data-validation/validate_shared.py`
  - `python -I tools/simulation/reference_rules.py --check`
  - `python -I tools/build/sync_flutter_shared.py --check` (run without `--check` after any shared edit)
  - `tools/simulation/generate_combat_traces.ps1 -Check`
  - from `flutter/`: `dart run tool/workshop_cases.dart --check`
  - from `flutter/`: `dart run tool/baseline_check.dart`; for AOT, `dart compile exe tool/baseline_check.dart -o build/baseline_check.exe` and run it
  - The validator also enforces every `shared/schemas/*.json` against its data file; a new data file needs a schema entry in `SCHEMA_FOR`
  - `python -I tools/build/phase_progress.py --check` (this checklist's progress table)

## Constraints
- Add packages only when justified and compatible with the installed SDKs.
- `.gitattributes` pins JSON, Dart, C#, Python and Markdown to LF; byte-for-byte checks depend on it.
- Never regenerate a fixture to hide a behavior change; intentional changes are reviewed and recorded.
- Android SDK: the owner's Android Studio SDK at `F:\Android\Sdk` (licenses accepted by the owner; never accept licenses for them). Emulator: Pixel 10 Pro XL AVD (`flutter emulators --launch Pixel_10_Pro_XL`).
- Device baseline: `dart run tool/baseline_check.dart --write-device-fixtures`, then `flutter test integration_test/baseline_device_test.dart -d emulator-5554`, and for AOT `flutter drive --profile --driver test_driver/integration_test.dart --target integration_test/baseline_device_test.dart -d emulator-5554`.
- `android/gradle.properties` keeps `kotlin.incremental=false` (the pub cache on C: and the project on F: break Kotlin's incremental caches).
- Commits use the repo-local primary email; stage by path; never stage `Reference APK/`.

# Risk register

| ID | Risk | Impact | Mitigation | Status |
|---|---|---|---|---|
| R-01 | Scope spans two complete engines and a large commercial content target | High | Validate one Unity vertical slice before porting or content expansion | Active |
| R-02 | Reference visuals and interaction details are not yet hands-on verified | Medium | Capture authorized gameplay observations before finalizing art/UI; v3 references are used for broad principles only (`REFERENCE_GAME_ANALYSIS.md`) | Active |
| R-03 | Flutter/Dart launcher fails to report version in this shell | Medium | Diagnose executable/shell invocation before creating Flame project | Closed: analyze and test run normally (2026-11-27) |
| R-04 | Unity project can import but mobile packages/device builds may be unavailable | High | Verify editor modules and target builds at GB-012 | Mitigated 2026-11-28: the Unity IL2CPP Android baseline APK builds and passes on the emulator; physical phone pending |
| R-05 | Graph cycles can create contradictory mesh rotation parity | Medium | Explicit odd-cycle jam rule and deterministic fixtures | Mitigated in design |
| R-06 | Device clock manipulation of daily/weekly rewards | Medium | Monotonic guard against rollback; server time before valuable rewards | Partly mitigated (forward jumps undetectable offline) |
| R-07 | Local save is editable, so premium state could be forged | High | Ledger rejects unverified premium grants; server-side verification before IAP | Open until Phase H |
| R-08 | Ad or store policy violations (placement, consent, children's rules) | High | Policy engine + fixtures; UMP; audience decision; store review | Open |
| R-09 | Line-ending drift breaking byte-for-byte checks | Medium | `.gitattributes` LF pinning | Mitigated |
| R-10 | Inconsistent AI-generated artwork | High | Approve masters first (ART-01/02); manifest records with reviewer and evidence enforced by the validator | Open |
| R-11 | Prototype canvas graphics persist into release | High | Production vertical slice is gate G3; manifest shows real art status | Open |
| R-12 | Rig anatomy errors (mirrored far limbs, joint gaps) | Medium | `CHARACTER_RIGGING_GUIDE.md` rules; turnaround and near/far sheet before parts; extreme-pose QA at ART-03 | Open |
| R-13 | Android build blocked: no user-profile SDK, NDK version mismatch, licenses not accepted | High | TOOLCHAIN_REPORT.md option A (separate SDK, user accepts licenses) | Mitigated 2026-11-28: the owner's SDK at `F:\Android\Sdk` builds and runs on the emulator; `cmdline-tools` and a physical phone still missing |
| R-14 | Two engines double the art integration cost | High | One shared manifest and metadata; one visual slice before parity work | Open |
| R-15 | xorshift32 first outputs are low-entropy for small seeds, biasing seeded content | Medium | Derive seeds with `mixSeed32`; any new seeded system must use it | Mitigated in both engines (Unity `SeededRandom.MixSeed32`, shared vectors in `workshop_cases.json`, GB-049) |
| R-16 | Combat difficulty is bursty (lanes hold or collapse), making star tuning coarse | Medium | Probe-based tuning per node; telegraphed boss attacks add a player-skill lever; consider knockback or armor variety | Open (partly addressed by GB-058; GB-024 probes show the middle lane is held by the starter build, so side lanes carry all pressure) |
| R-17 | Visual ambition (2.5D depth, diorama atmosphere, effects) outgrows mobile budgets | High | Painted or baked identity, quality tiers, budgets in `VISUAL_PERFORMANCE_BUDGET.md`, a first device reading at ART-B before production scales | Open |
| R-18 | The skeletal animation chosen for Unity cannot be reproduced in Flutter | High | Rigid-part rigs from shared metadata by default; decision at ART-03 with a Flutter prototype (`RENDERING_ARCHITECTURE.md` §4) | Open |
| R-19 | Art drifts toward a reference game's recognizable look (silhouettes, UI frames, chests, map style) | High | Originality review at every gate (`ASSET_VALIDATION_GUIDE.md` §8); distinctive markers in `REFERENCE_GAME_ANALYSIS.md`; no reference images as generator inputs | Open |
| R-20 | Generated art carries unclear commercial rights or missing provenance | High | Provenance and license required from `concept` onward; tool terms confirmed before `approved_concept`; the validator blocks approval without them | Open |
| R-21 | Producing art before the benchmark is approved wastes production effort | Medium | Execution order in `ART_DIRECTION.md` §7; GB-063 gates Phase 05 | Open |

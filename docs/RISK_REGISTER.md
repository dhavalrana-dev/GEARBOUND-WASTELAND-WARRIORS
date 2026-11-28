# Risk register

| ID | Risk | Impact | Mitigation | Status |
|---|---|---|---|---|
| R-01 | Scope spans two complete engines and a large commercial content target | High | Validate one Unity vertical slice before porting or content expansion | Active |
| R-02 | Reference visuals and interaction details are not yet hands-on verified | Medium | Capture authorized gameplay observations before finalizing art/UI | Active |
| R-03 | Flutter/Dart launcher fails to report version in this shell | Medium | Diagnose executable/shell invocation before creating Flame project | Closed: analyze and test run normally (2026-11-27) |
| R-04 | Unity project can import but mobile packages/device builds may be unavailable | High | Verify editor modules and target builds at GB-012 | Active (EditMode runs in batch mode; no Unity build attempted) |
| R-05 | Graph cycles can create contradictory mesh rotation parity | Medium | Explicit odd-cycle jam rule and deterministic fixtures | Mitigated in design |
| R-06 | Device clock manipulation of daily/weekly rewards | Medium | Monotonic guard against rollback; server time before valuable rewards | Partly mitigated (forward jumps undetectable offline) |
| R-07 | Local save is editable, so premium state could be forged | High | Ledger rejects unverified premium grants; server-side verification before IAP | Open until Phase H |
| R-08 | Ad or store policy violations (placement, consent, children's rules) | High | Policy engine + fixtures; UMP; audience decision; store review | Open |
| R-09 | Line-ending drift breaking byte-for-byte checks | Medium | `.gitattributes` LF pinning | Mitigated |
| R-10 | Inconsistent AI-generated artwork | High | Approve masters first (ART-01/02); manifest records with reviewer and evidence enforced by the validator | Open |
| R-11 | Prototype canvas graphics persist into release | High | Production vertical slice is gate G3; manifest shows real art status | Open |
| R-12 | Rig anatomy errors (mirrored far limbs, joint gaps) | Medium | ART_DIRECTION §10–12 rules; extreme-pose QA at ART-03 | Open |
| R-13 | Android build blocked: no user-profile SDK, NDK version mismatch, licenses not accepted | High | TOOLCHAIN_REPORT.md option A (separate SDK, user accepts licenses) | Mitigated 2026-11-28: the owner's SDK at `F:\Android\Sdk` builds and runs on the emulator; `cmdline-tools` and a physical phone still missing |
| R-14 | Two engines double the art integration cost | High | One shared manifest and metadata; one visual slice before parity work | Open |
| R-15 | xorshift32 first outputs are low-entropy for small seeds, biasing seeded content | Medium | Derive seeds with `mixSeed32`; any new seeded system must use it | Mitigated in both engines (Unity `SeededRandom.MixSeed32`, shared vectors in `workshop_cases.json`, GB-049) |
| R-16 | Combat difficulty is bursty (lanes hold or collapse), making star tuning coarse | Medium | Probe-based tuning per node; telegraphed boss attacks add a player-skill lever; consider knockback or armor variety | Open (partly addressed by GB-058; GB-024 probes show the middle lane is held by the starter build, so side lanes carry all pressure) |

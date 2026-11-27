# Risk register

| ID | Risk | Impact | Mitigation | Status |
|---|---|---|---|---|
| R-01 | Scope spans two complete engines and a large commercial content target | High | Validate one Unity vertical slice before porting or content expansion | Active |
| R-02 | Reference visuals and interaction details are not yet hands-on verified | Medium | Capture authorized gameplay observations before finalizing art/UI | Active |
| R-03 | Flutter/Dart launcher fails to report version in this shell | Medium | Diagnose executable/shell invocation before creating Flame project | Closed: analyze and test run normally (2026-11-27) |
| R-04 | Unity project can import but mobile packages/device builds may be unavailable | High | Verify editor modules and target builds at GB-012 | Active |
| R-05 | Graph cycles can create contradictory mesh rotation parity | Medium | Explicit odd-cycle jam rule and deterministic fixtures | Mitigated in design |
| R-06 | Device clock manipulation of daily/weekly rewards | Medium | Monotonic guard against rollback; server time before valuable rewards | Partly mitigated (forward jumps undetectable offline) |
| R-07 | Local save is editable, so premium state could be forged | High | Ledger rejects unverified premium grants; server-side verification before IAP | Open until Phase H |
| R-08 | Ad or store policy violations (placement, consent, children's rules) | High | Policy engine + fixtures; UMP; audience decision; store review | Open |
| R-09 | Line-ending drift breaking byte-for-byte checks | Medium | `.gitattributes` LF pinning | Mitigated |

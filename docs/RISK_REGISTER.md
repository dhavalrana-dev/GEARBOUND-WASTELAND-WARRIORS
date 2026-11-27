# Risk register

| ID | Risk | Impact | Mitigation | Status |
|---|---|---|---|---|
| R-01 | Scope spans two complete engines and a large commercial content target | High | Validate one Unity vertical slice before porting or content expansion | Active |
| R-02 | Reference visuals and interaction details are not yet hands-on verified | Medium | Capture authorized gameplay observations before finalizing art/UI | Active |
| R-03 | Flutter/Dart launcher fails to report version in this shell | Medium | Diagnose executable/shell invocation before creating Flame project | Active |
| R-04 | Unity project can import but mobile packages/device builds may be unavailable | High | Verify editor modules and target builds at GB-012 | Active |
| R-05 | Graph cycles can create contradictory mesh rotation parity | Medium | Explicit odd-cycle jam rule and deterministic fixtures | Mitigated in design |

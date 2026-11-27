# Cross-engine parity contract

Shared JSON files under `shared/` are the source of truth for board dimensions, tick rate, booster caps, gear IDs, and authored wave schedules. Both implementations must load the same `schemaVersion`, process integer ticks at 30 Hz, and use the same stable identifiers.

Initial fixtures cover: connected output, disconnect after transmission removal, tier merge, capped booster output, and consistent even-loop parity. A 5×5 orthogonal grid is bipartite, so odd loops cannot be authored until a non-grid link is introduced; if that changes, the jam rule remains in force.

Unity currently has the first implementation. The Dart/Flame implementation is not yet scaffolded because the local Flutter and Dart version commands did not return; verify the installed SDK before adding dependencies. Do not claim parity until both runners emit comparable states for the same fixture inputs.

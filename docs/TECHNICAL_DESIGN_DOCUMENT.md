# Technical design document

## Runtime boundaries
Shared JSON defines tunable content. Engine-independent simulation owns board occupancy, connectivity, output clocks, combat state, wave progression, IDs, and seeded randomness. Unity presentation owns input mapping, view animation, audio, effects, and responsive composition. Flame will reproduce the same fixtures after rules stabilize.

## Time and ordering
- Target simulation: 30 integer ticks per second; rendering is independent.
- Each tick processes, in order: scheduled spawns → player commands → movement → target selection → attacks/projectiles → damage/status → deaths/rewards → gear outputs → mission conditions.
- Use integer health and damage; round modifiers once, downward, after multiplication. Stable entity IDs break ties.
- RNG uses a versioned shared xorshift32 contract. Do not consume random values for presentation.

## Coordinate model
- Board cells use integer `(x,y)` with origin at upper left; orthogonal cardinal adjacency only.
- Battlefield uses `lane ∈ {0,1,2}` and integer horizontal position in millimeters relative to the fortress. Right is positive toward enemies. Screen projection is presentation-only; lane changes preserve horizontal position.

## Power network
See `MECHANICAL_ENGINE.md`. Recompute the whole small 5×5 graph after each edit; correctness is preferred to premature incremental caching. Outputs take effect on the next simulation tick.

## Persistence and data
Shared data schemas are versioned. Save only stable IDs, board layout, mission state, resource totals, RNG state, and tick number. Migrations are pure functions and save writes use temporary-file replacement.

## Engine decision
Unity 6.3 LTS is installed and selected as the first reference implementation. URP/Input System are deferred until the core board/combat slice and package compatibility are confirmed. Flutter parity is a later dependent milestone because SDK command behavior currently prevents version verification.

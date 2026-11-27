# Mechanical engine

## Board and ports
The MVP board is 5×5 with one cell per gear. Each gear declares cardinal ports in local orientation. Rotation is quarter-turn clockwise; a board edge exists only when both neighboring cells expose reciprocal ports. Diagonals never transmit.

## Recalculation
1. Validate each gear ID, cell bounds, unique occupancy, orientation, and core count (exactly one for a mission).
2. Build reciprocal-port edges in stable cell order: row, column, then north/east/south/west.
3. Traverse each connected component. A component without a core is unpowered.
4. Breadth-first assign rotation parity from the core (`core=0`, every meshed neighbor toggles parity). Revisiting a node with a different expected parity marks the component jammed; no component outputs run.
5. A second core in the same component marks it conflicted and inactive. Different components cannot share a core; only the unique core component powers. Because orthogonal grid graphs are bipartite, an odd-length mesh loop cannot occur on the MVP board; odd-parity detection remains defensive for future portal/non-grid links.
6. Booster contributions add 10 percentage points per booster to compatible outputs, capped at +30%. Effective interval is `ceil(baseTicks * 100 / (100 + bonusPct))`, bounded to at least 1 tick.
7. Publish a complete immutable result; outputs observe it on the next simulation tick.

## Loop policy and merge
Even-parity loops are valid. Odd-parity loops jam if introduced by a future non-grid connector. Merge consumes two gears with the same definition, kind, and tier (cores are excluded) and places the result in the lower row-major cell if its one-cell footprint remains valid. The configured next-tier output interval is supplied from content data, not an exponential formula. Any edit causes a full deterministic rebuild.

## Starter fixture
Core at (1,2), transmission gears at (2,2) and (3,2), infantry output at (4,2). This tests a connected production chain. A disconnected output remains visible but inactive.

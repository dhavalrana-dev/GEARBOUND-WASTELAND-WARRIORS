# Flutter and Flame architecture

Updated 2026-11-27 to match the code on `feature/workshop-shop-ui`.

## Toolchain
- Flutter 3.47.7 stable, Dart 3.13.5.
- Flame 1.38.2 and `shared_preferences` 2.5.x. Versions are locked in `flutter/pubspec.lock`; no other runtime packages.
- Flutter owns screens and panels. Flame owns the board and battlefield canvas, including board taps.

## Module layout (`flutter/lib`)

| Folder | Responsibility | Engine-independent? |
|---|---|---|
| `mechanical/` | Board, placement, merge, connectivity graph, rotation parity, output clocks | Yes |
| `combat/` | Lane combat simulation, battle session | Yes |
| `core/` | `SeededRandom` (`xorshift32-v1`) | Yes |
| `data/` | Shared JSON loaders and rules (`shared_rules.dart`); runtime asset bundle (`shared_content.dart`) | Rules yes; content loading uses Flutter assets |
| `economy/` | Wallet ledger, currencies | Yes |
| `progression/` | Campaign progress, rewards, encounters, save store | Yes, except `campaign_store.dart` (SharedPreferences) |
| `services/ads/` | Ad policy, provider interface, mock provider, rewarded controller | Yes (no SDK) |
| `simulation/` | Cross-engine combat trace runner | Yes |
| `features/campaign/` | Campaign hub: route map, events, contracts, rewards card | Flutter UI |
| `features/workshop/` | Workshop screen and `WorkshopController` (shop, placement, merge, sell, battle scrap) | Controller yes; screen is Flutter UI |
| `game/` | Flame rendering and board tap mapping | Flame |
| `design_system/` | Color tokens: prototype palette plus the specification palette | Flutter |
| `app/` | App shell; re-exports the screens | Flutter |

## Workshop flow
1. `WorkshopController` places the starter gears from `gear_rules.json` `workshop.starterGears` and grants `shop.startingScrap` battle scrap through a mission-scoped wallet that is never saved. It then rolls seeded offers from the categories in `workshop.shopCategories`.
2. **Buy** spends battle scrap and puts the gear in hand. **Cancel** refunds it in full. **Tapping an empty cell** places the gear, and the board row sets its lane (`workshop.outputLaneByRow`).
3. **Tapping a gear** selects it. Tapping an identical gear of the same tier merges the two into the top-left cell, with the interval set by `merge.intervalPercentByTier`. **Sell** refunds `sellRefundPercent` of every tier-1 copy merged into the gear.
4. **Drag-and-drop** (`WorkshopBoardView` with `DragCallbacks`): drag the gear in hand onto a cell to place it, or drag a placed gear to move it (free; its lane follows the new row) or onto an identical gear to merge. The target cell is tinted from `WorkshopController.previewAt`, which runs the network on a copy of the board. The core can't be dragged or dropped onto.
5. **Undo** reverts place, move, merge and sell, last in first out, from board snapshots. Undoing a sale charges the refund back through the ledger and is refused if that scrap has been spent. Buys (use Cancel) and rerolls are deliberately not undoable.
6. **Start wave** locks the controller, refunding any gear still in hand and clearing undo. After that, board taps and drags are ignored.
7. **Intermission** (multi-wave missions): when a non-final wave is cleared, `BattleSession` enters `intermission`. Gear soldiers withdraw; the hero returns to the fortress line; fortress damage stays. The screen calls `WorkshopController.beginIntermission`, which pays the wave reward once per wave number through the ledger, resets the reroll price, rolls fresh offers and unlocks editing. **Start wave** then begins the next wave. The Vanguard booster and streak soldiers apply only to wave 1.
8. **Seeds**: the workshop seeds its shop RNG with `mixSeed32(seed)` (murmur3 fmix32) to avoid xorshift32's low-entropy first outputs for small seeds.
9. **Lifecycle** (`GearboundGame.setSimulationPaused`, screen `AppLifecycleListener`):
   - The gameplay pause freezes the simulation while the battlefield still renders.
   - When the app is hidden during combat it pauses, and only the player resumes.
   - Once a mission has started, system Back opens the pause menu. Abandoning asks for confirmation and resets the Overclock Streak.
   - Simulation catch-up is capped at 0.25 s per frame.
   - The game widget has a `GlobalKey`, so rotation moves it between layouts instead of rebuilding it. This matters because Flame reports widget disposal as an app pause.
10. **Checkpoints** (`MissionSnapshot`):
   - **When:** saved when each wave starts and at each intermission; cleared on victory, defeat or abandon.
   - **Resume after a kill:** an intermission checkpoint resumes into the rebuild phase. A mid-wave kill restarts that wave, paused, with the board locked and wave-1 opening soldiers redeployed.
   - **What's restored:** `WorkshopController.restore` rebuilds the mission wallet (claim keys included), offers, reroll count and RNG state.
   - **Checks:** `BattleSession.restoreCheckpoint` only applies to a fresh session and rejects values that don't fit the mission.

## Layout
- **Portrait:** the battlefield and board get 11/20 of the height; status, shop, loadout and actions scroll in the remaining 9/20.
- **Landscape:** the canvas fills the left side; a 300-pixel scrollable control column sits on the right.
- Widget tests check for no overflow on phone landscape (2400×1080), a small portrait phone (720×1520) and tablet landscape (2732×2048).

## Not yet built
- A gear details sheet, and rotation (not needed until gears with partial ports exist).
- Multi-wave missions with inter-wave preparation (GB-025).
- Production art, animation and audio.
- Turret, mortar and other output behaviors; the shop sells only gears whose behavior is implemented.
- Real ad or purchase SDKs.

Android compilation is still blocked on the NDK license; see `DEVELOPMENT_STATUS.md`.

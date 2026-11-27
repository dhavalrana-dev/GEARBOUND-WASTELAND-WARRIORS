# Save format and migration

Implementation: `flutter/lib/progression/campaign_progress.dart` (`CampaignProgress.fromJson`, `_fromLegacy`) and `flutter/lib/progression/campaign_store.dart`. Fixtures: `shared/test-fixtures/save_migration_cases.json`. Tests: `flutter/test/progression/save_migration_test.dart`.

## Versions

| Version | Shape | Where |
|---|---|---|
| 1 | Flat map, no `saveVersion`: scrap, stars, contracts, weekly event | key `gearbound.campaign.v1` |
| 2 | v1 plus streak, boosters, star chests, Supply Log (`saveVersion: 2`) | key `gearbound.campaign.v1` |
| 3 | Sections `campaign`, `periods`, `wallet` (ledger), `clock` | keys `gearbound.save.primary` and `gearbound.save.backup`, each holding `{sequence, save}` |

## v1/v2 → v3

- `scrap` becomes `workshop_scrap` through a ledger entry `migration:v<N>:workshop_scrap`. Today's scrap is only ever earned (first clears, contracts, events) and never spent, so it is permanent earned currency, not battle currency.
- Known boosters become ledger balances through `migration:v<N>:boosters`. Stacks are clamped, and unknown booster IDs are dropped.
- **Pre-ledger claims are marked as processed.** Claimed contracts, event tiers, star chests, first clears and past Supply Log steps get their keys marked processed, so nothing already paid can be paid again after migration.
- Hostile values are sanitized: negative numbers become 0, stars are kept in 1–3, and the streak is capped at 3.
- The legacy key is left untouched as a read-only fallback.

## Store behavior

- **Write order:** each save writes the backup slot, then the primary slot, with an increasing `sequence`. Saves are queued, so overlapping saves cannot interleave.
- **Load:** decode both slots and keep the valid one with the higher sequence. If neither is valid, fall back to the legacy key; if that fails too, start fresh. Unreadable slots are reported in `CampaignStore.corruptSlots`.
- **Newer builds:** a save with a newer `saveVersion` is never overwritten. The store sets `persistenceBlocked` and saving becomes a no-op, so a downgrade cannot destroy data.

## Clock rollback

`CampaignProgress` stores the latest device time it has seen (`clock.lastObservedUtc`). Any earlier reading is replaced by that time, so moving the device clock backwards cannot reopen the Supply Log or reset daily contracts. `clockRollbackDetected` is set whenever this happens.

**Limitation:** moving the clock *forwards* cannot be detected offline. Trusted server time is required before online events or valuable time-gated rewards (Phase H).

## Mission checkpoint (separate slot)

`CampaignStore.missionKey` (`gearbound.mission.active`) holds at most one `MissionSnapshot` (schema 1, `flutter/lib/features/workshop/mission_snapshot.dart`). It's separate from the progression save, so a broken checkpoint can never damage campaign progress. An empty or unreadable value means "no checkpoint". Snapshots are taken only at wave boundaries. Their resume rules are described in `FLUTTER_ARCHITECTURE.md`.

## Not yet done

- Cloud save and conflict resolution (Phase H).
- Separate storage for purchase entitlements (Phase G), and a settings store.

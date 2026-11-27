# Reward transaction system

Every change to a player balance goes through one wallet ledger. Implementations:

- Dart: `flutter/lib/economy/wallet.dart`
- C#: `unity/Assets/Game/Economy/Wallet.cs`

Both replay `shared/test-fixtures/reward_transaction_cases.json`.

## Assets

- **Currencies** come from `shared/economy/currencies.json`: `battle_scrap`, `workshop_scrap`, `alloy` (premium), `blueprints`, `event_tokens` and `xp`. Each has a maximum balance; a result above it is **rejected**.
- **Boosters** come from `shared/events/progression_rewards.json`. Each has a stack cap; a result above it is **clamped**, and the ledger entry records the amount actually applied.

## Request → result

A request carries:
- `idempotencyKey`, `type` (grant, spend, purchase, ad_reward, refund, migration) and `source`
- an optional `referenceId`
- `verification`: local or verified
- `deltas`: asset and signed amount pairs

The wallet checks the request in this fixed order. Every engine must report the same reason.

1. **Duplicate:** the key was already processed. Status `duplicate`; nothing changes.
2. **Invalid:** an empty key, no deltas, an amount of 0, an unknown asset, or the same asset twice.
3. **Unverified premium:** a positive premium delta without `verification: verified`.
4. **Insufficient:** any resulting balance would be below 0.
5. **Overflow:** a currency would exceed its maximum.

Rejections are all-or-nothing and **do not** consume the key, so a corrected retry can succeed. An applied request writes one ledger entry per delta, with these fields: transaction ID, idempotency key, profile ID, asset, applied amount, type, source, reference ID, verification and UTC time.

The save keeps the latest 500 ledger entries. Balances and processed keys are kept in full, so trimming the ledger can never re-enable a duplicate claim.

## Idempotency keys in use

| Claim | Key |
|---|---|
| First clear | `first_clear:<levelId>` |
| Daily contract | `contract:<dayKey>:<contractId>` |
| Scrapstorm tier | `scrapstorm:<weekKey>:<points>` |
| Star chest | `star_chest:<stars>` |
| Supply Log | `supply_log:<step>` |
| Booster use | `booster_use:<attemptKey>:<boosterId>` |
| Rewarded ad | `ad_reward:<placementId>:<offerId>` |
| Save migration | `migration:v<N>:workshop_scrap`, `migration:v<N>:boosters` |

## Limits of the local ledger

The local wallet lives in `SharedPreferences`, which a determined user can edit. It is fine for earned currency. **Premium balances and entitlements must also be verified server-side** before real purchases are enabled (Phase H). The local rule that rejects unverified premium grants stops accidental UI grants; it is not anti-tamper protection.

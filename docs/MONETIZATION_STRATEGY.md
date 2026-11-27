# Monetization strategy

Approved model (2026-11-27): optional **rewarded ads**, **interstitials at natural transitions**, and **fixed-content in-app purchases**. The policy rules are in `AGENTS.md`. This document records the design and what is actually built.

## Status

| Piece | Status |
|---|---|
| Ad placement policy (interstitial + rewarded eligibility) | **Built.** Dart `lib/services/ads/ad_policy.dart` and C# `Game/Economy/AdPolicy.cs`, both checked against `ad_policy_cases.json`. |
| Rewarded flow controller (grant once, failure-safe) | **Built (Dart)** against `MockAdProvider`; `lib/services/ads/ad_provider.dart`. |
| Real ad SDK (`google_mobile_ads`, Google Mobile Ads Unity plugin) | **Not integrated.** Needs SDK compatibility checks, AdMob app and ad unit IDs, and consent (UMP). |
| Consent (Google UMP) | Not started. Ads must stay off without it. |
| `shared/monetization/ad_policy.json` `enabled` | **false**. The kill switch stays off until a real provider and consent flow ship. |
| In-app purchases, entitlements, No Ads | Not started (Phase G). Requires server verification first (Phase H). |
| Victory "double reward" and other ad UI | Not built. No ad buttons are shown until a provider exists (no dead buttons). |

## Interstitial rules (initial, remotely tunable later)

Interstitials are allowed only in the `mission_complete_transition` context: after rewards have been saved, before returning to the route. They are never shown during combat, gear placement, tutorials, purchases or startup, and never with the No Ads entitlement or without consent. Further limits:

- The first 3 missions are ad-free.
- At least 2 missions and at least 180 seconds between interstitials.
- At most 4 per session.
- Suppressed for 120 seconds after a rewarded ad.

The rules are checked in a fixed order, so both engines report the same reason. A failed or unavailable ad simply lets the player continue.

## Rewarded placements (initial)

| Placement | Reward | Cap |
|---|---|---|
| `rewarded.daily_supply` | 10 Workshop Scrap | 3 per day |
| `rewarded.victory_double` | Doubles mission scrap | Once per mission |
| `rewarded.prep_vanguard` | 1 Vanguard Drop | 3 per day, once per mission |
| `rewarded.shop_reroll` | 1 free reroll | Once per mission |
| `rewarded.emergency_continue` | Continue once | Once per mission |

Ad rewards can never grant premium currency; both the ledger and the validator enforce this. The controller grants only after the provider's earned callback. It ignores duplicate callbacks, and an early dismissal, no fill or SDK failure grants nothing. The grant's ledger key is `ad_reward:<placement>:<offerId>`.

## In-app purchases (planned)

Product IDs are reserved, and prices are planning values only. The app must display the store's localized price and never a hard-coded one. Every product has fixed contents; there are no paid random boxes.

`gearbound.no_ads`, `gearbound.starter_bundle`, `gearbound.alloy.100/350/800/1800`, `gearbound.boosters.small`, `gearbound.skin.rivet_01`, `gearbound.fortress.skin_01`, `gearbound.season.01`.

No Ads disables interstitials only; opt-in rewarded ads stay available. This must be stated before purchase.

## Blockers needing the project owner

- AdMob account, app IDs and ad unit IDs (development uses Google's public test IDs only).
- Google Play Console and App Store Connect products, with sandbox testers.
- A backend for purchase verification and premium balances (Firebase was evaluated in the spec; nothing is provisioned).
- Target-audience and age-rating decisions, which determine ad personalization and consent behavior.
- The Android NDK license acceptance needed for device builds.

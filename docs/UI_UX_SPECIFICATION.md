# UI/UX specification

**Version:** 2.0 (2026-11-28). It expands the three-paragraph v1 note, keeping all of it, and absorbs art direction v2 §20–23.
**Status:**
- The interaction rules in §2–3 describe the current Flutter prototype and stay binding.
- The visual system in §4 onward is **proposed**; no final UI art exists.
- The prototype uses Flutter Material widgets styled by `flutter/lib/design_system/tokens.dart`. That is a scaffold, not the final look.

**Related:** `VISUAL_STYLE_BIBLE.md`, `ANIMATION_SPECIFICATION.md` §6, `MONETIZATION_STRATEGY.md`, `GAMIFICATION_AND_EVENTS.md`, `RENDERING_ARCHITECTURE.md` §6.

## 1. Principles

- The board and its powered/unpowered state stay visible together with the combat consequences.
- Large touch targets, short labels, high-contrast costs and clear scrap totals.
- **Text and icon redundancy for every state**: color is never the only signal.
- A **premium mechanical comic** look: illustrated industrial panels, angular frames, tactile buttons, mechanical gear slots, bold readable type and recognizable illustrated icons. **No standard Material Design styling in the final game.**
- **The same components in Unity and Flutter**, built from one token set (`shared/art/ui_tokens.json`, planned) and one painted kit.
- **No misleading interaction patterns** (§7).

## 2. Layout

| Orientation | Layout |
|---|---|
| Portrait | Status strip at the top, the three-lane battlefield above, hero controls at the midline, the construction board below, and a shop that collapses during battle. Reference shares: status 6%, battlefield 40%, hero controls 8%, board 29%, shop and actions 17% |
| Landscape | Board and shop in the left third (34%), battlefield and controls in the right two-thirds, with a shared resource and wave strip on top |
| Tablet | Larger panel spacing and targets, never more gameplay capacity |

- Respect safe areas and cutouts.
- Preserve logical state on orientation changes.
- Test compact (360 dp), tall, tablet and foldable viewports by size, not by device model.

*Current prototype:* the canvas takes 11/20 of the height and the controls scroll (`FLUTTER_ARCHITECTURE.md`).

## 3. Interactions

**Preparation:**
- Tap a card to buy; drag the ghost to a highlighted cell; tap a placed gear to select it.
- **Hold** an offer with the lock toggle beside its card (free). A held offer shows a lock icon and the HELD label, survives rerolls and the next wave's shop, and is released by buying it or tapping the toggle again. With every offer held, Reroll is disabled and the hint says to release one.
- A merge preview appears over a compatible occupied cell; undo restores the prior board snapshot.
- Errors explain the bounds, occupancy, cost or connection constraint.
- *Rotation and a conflict explanation are deferred (task 2.10) until gears with partial ports exist.*

**Combat HUD:** fortress health, wave, battle scrap, gear output status, lane buttons, attack, and the hero's SP and special.

**During combat** the board refuses edits; the board shows its locked state and stays visible.

## 4. Component kit (premium mechanical comic)

| Family | Variants | Notes |
|---|---|---|
| Panels | Primary, secondary, card, modal, HUD strip | Chamfered painted steel with brass corner plates and rivets. Nine-slice: corners never stretch |
| Buttons | Primary, secondary, destructive, disabled, selected, pressed, loading, **rewarded-ad**, **purchase** | Tactile bevel; the pressed state drops the bevel by 2–3 px; 48 dp minimum target |
| Gear slots | Empty, hover/valid, invalid, powered, locked, selected | Recessed sockets that match the board art (`VISUAL_STYLE_BIBLE.md` §12) |
| Cards | Shop offer, event, contract, product, reward | A header art area, an empty title plate, and stat and price rows filled at runtime |
| Resource pills | One per currency | Icon + tabular number; the amount animates on ledger changes only |
| Bars | Health, SP, wave progress, event track, streak | Brass casing; the fill color carries meaning and is paired with an icon or label |
| Badges | Tier, cost, new, locked, completed, stars | A shape and a number, never color alone |
| Banners | Event, wave, victory/defeat | Modular art; the text stays dynamic |
| Chests | Small and medium crates, reinforced, star milestone, blueprint, alloy | Closed, anticipation and open states (`ANIMATION_SPECIFICATION.md` §6) |
| Icons | Functional (30–50), currencies (6) | Illustrated, with silhouette-tested outlines; 48–96 px runtime |
| Map nodes | Locked, available, selected, completed, 1–3 stars, hard, boss, event | The hit area is separate from the decorative art |

**Typography:**
- A bold industrial or comic display face and a highly legible sans for body text.
- Tabular numerals for prices, health, currency and timers.
- Commercially licensed, ready for localization, and scaled with the OS text size up to 130% without clipping.

**Text is never baked into art:** titles, prices, dates, timers, descriptions and quantities stay in the UI.

## 5. Screens

| Screen | Key content |
|---|---|
| Campaign route (Wasteland Route) | An illustrated region map; a winding road; nodes with stars; landmarks and boss monuments; reward checkpoints; a moving fortress marker; the Resume/Abandon card for an interrupted mission |
| Workshop and battle | Board, shop (three offers, reroll, lock, sell, undo), battlefield, HUD, hero controls, pause menu |
| Wave intermission | Wave reward, fresh offers, board unlocked, a clear "next wave" action |
| Victory, defeat and result | Stars, normal reward, optional rewarded-ad bonus (§7), first-clear rewards, return |
| Contracts | Daily and weekly lists, progress bars, claim buttons, reset timers |
| Events | Event card, track, milestones, tokens, expired state |
| Supply Depot (shop) | The proposed name for the store screen: alloy bundles, No Ads, starter and booster bundles, cosmetics. Prices come from the store, localized |
| Collections | Gear collection, hero mastery, achievements (when implemented) |
| Settings | Audio, quality tier, reduced motion, text size, privacy and consent options |

## 6. Gamification visual systems

Every system uses **modular templates**:
- a reusable frame, an illustrated emblem and a motif;
- dynamic title, dates, timers, objectives and reward quantities, rendered by code;
- per-event art limited to the emblem, banner background, card header, track background, milestone marker, completion badge, token icon, and locked/expired treatment.

| System | Implemented? | Visual template |
|---|---|---|
| Wasteland Route | Yes (12 nodes) | Map region tiles, landmarks, node states, road, fortress marker |
| Daily contracts | Yes | Contract card with a clipboard and stamp motif; progress bar; claim |
| Weekly contracts | Planned (GB-032) | Same card family, with a weekly ribbon and a completion chest |
| Scrapstorm | Yes (weekly best score) | Dust storm, flying scrap, gold and copper; event card and track |
| Gear Frenzy | Planned (Phase 09) | Interlocking rotating gears, orange and energy yellow |
| Engineering Trials | Planned (Phase 09) | Blueprint grid, diagrams, cobalt and cyan |
| Overclock Streak | Yes | A pressure-gauge needle climbing with the streak; resets shown plainly |
| Supply Log | Yes | A logbook with stamped pages; each claim stamps a page |
| Star chests | Yes | Star milestone chest on the route; closed, anticipation and open |
| Achievements | Planned (GB-023) | Riveted medal plates; locked plates as embossed outlines |
| Booster inventory | Yes (Vanguard Drop) | Crate slots with a count badge; the mission-start choice is explicit |
| Hero mastery | Planned | A mastery dial around the hero portrait; tiers as brass pips |
| Gear collection | Planned | A catalogue drawer of gear plates; uncollected gears as silhouettes |
| Seasonal events | Planned (Phase 09) | The same event template with a season motif layer |
| Supply Depot | Planned (Phases 11/13) | Clear product cards (§7) |

## 7. Monetization visual states (policy-bound)

These follow `AGENTS.md` and `MONETIZATION_STRATEGY.md`.

**Rewarded-ad action:**
- A distinct button family with an ad icon, the exact added reward and a "Watch ad" verb.
- The **normal reward action always sits beside it**, equally readable and at least as large.
- **States:** available, loading, unavailable ("No ad available right now"; the normal reward is still claimable), verifying (pending), granted, already claimed.

**Purchase action:**
- A distinct button family showing the store-localized price from the store, and exactly what the product contains (fixed content).
- **States:** available, pending, purchased or owned, restore, refunded or revoked (the entitlement removed, with an explanation).

**No Ads:** the product card states plainly that it removes interstitials only; rewarded ads stay optional.

**Forbidden:**
- fake close buttons, countdowns that pressure, or a disguised ad button;
- default-selected purchases, or prices shown as currency-like icons;
- loot-box visuals for paid content;
- ads during combat, placement, tutorials or purchases, or at startup;
- reward screens that hide the free option.

## 8. Accessibility

- Color is never the only signal: every state pairs color with an icon, shape, label or motion.
- Contrast: body text at least 4.5:1; large text and UI glyphs at least 3:1.
- Touch targets of 48 dp minimum, with 8 dp between targets.
- Reduced motion (`ANIMATION_SPECIFICATION.md` §8) and quality tiers are separate settings.
- The game is playable without sound; every audio cue has a visual counterpart.
- Text scales to 130% without clipping or losing state.

## 9. Cross-engine consistency

Unity (UI Toolkit or uGUI, chosen at GB-046) and Flutter widgets use:
- the same tokens: colors, the type scale, spacing, the chamfer size and button states;
- the same nine-slice kit images;
- the same icon set;
- the same layout proportions.

The internals may differ, but the screenshots of the benchmark screens must match in structure and states (`RENDERING_ARCHITECTURE.md` §7).

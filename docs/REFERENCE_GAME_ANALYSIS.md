# Reference game analysis

Research captured 2026-11-27. This is a desk study of official store descriptions and public product pages, not a hands-on build review. No screenshots have been copied into the repository.

## Gear Fight!

Sources: [Google Play listing](https://play.google.com/store/apps/details?id=com.EternalStudio.GearFight), [App Store listing](https://apps.apple.com/in/app/gear-fight/id6738430824), [user-provided gameplay video](https://www.youtube.com/watch?v=kywMFtloNjc).

The store copy describes placing gears, testing a factory against enemy waves, choosing ranged or brute-force army compositions, and managing a budget. These claims verify the high-level build-budget-army loop, but do not establish every interaction in the specification (for example, exact merge and reroll rules); those require direct gameplay capture before detailed imitation is considered.

**Design conclusions:** Make each purchase visibly compete with other uses of scrap. Tie powered output to a legible board connection. Offer distinct frontline and ranged responses. Keep the production phase short and immediately show the battlefield consequence.

## The Last Friend

Sources: [official website](https://thelastfriend.net/), [Steam product page](https://store.steampowered.com/app/944430/The_Last_Friend/), [IndieCade page](https://www.indiecade.com/2018-games/the-last-friend/).

Steam positions the game as a combination of action, strategy, beat-'em-up combat, tower defense, enemies and bosses. Its page describes deployable defensive options alongside direct fighting, with varied wasteland settings and a colorful, comedic tone. The requested side-view multi-lane composition and precise controls still need hands-on visual reference capture.

**Design conclusions:** Keep hero movement and machine defense legible in one camera frame. Separate hostile entrances, friendly deployment and structures by depth/lane. Telegraph enemy intent and keep silhouettes readable at phone scale. Use original angular silhouettes, expressive proportions, and an optimistic industrial palette.

## Originality and capture plan

Gearbound borrows broad genre patterns only. It will use an original rolling fortress called the Wayfarer, original crew/factions, original art, and a power graph where connectivity, rotational parity and booster caps directly gate battlefield output. No reference characters, branding, levels, UI art, audio, or code are included.

Before finalizing presentation, capture authorized in-game screenshots or use official promotional material with attribution and document observations for: placement feedback, phase transitions, lane visibility, attack readability, shop density, boss telegraphs, and mobile touch targets. Asset extraction and redistribution are out of scope.

> **Section references:** the 2026-11-27 sections below cite art direction **v2** section numbers. Since v3 (2026-11-28) those rules live in the specifications listed in `ART_DIRECTION.md` §4.

## Package analysis (local reference copies, 2026-11-27)

The project owner placed reference packages in `Reference APK/`. That folder is gitignored and never committed. This analysis used only package manifests, native library and managed assembly *names*, folder names, file-type counts, and the engine version header. **No code was decompiled, and no assets, data or text were copied into Gearbound.**

### Gear Fight! (`com.EternalStudio.GearFight` 6.27.0, Android min SDK 26, target 36)

| Area | Observation | Implication for Gearbound |
|---|---|---|
| Engine | Unity **6000.3.5f2** (Unity 6.3), IL2CPP, Burst, URP **2D**, Swappy frame pacing | Confirms our Unity 6.3 LTS choice and a 2D URP pipeline for the reference client |
| Animation and rendering | Unity 2D Animation + **2D IK** (skeletal sprites), SpriteShape, Cinemachine, Timeline, DOTween, Text Animator, UIEffect/UIParticle, Cartoon FX Remaster, All In 1 Sprite Shader | Skeletal 2D characters at mobile scale are proven in this genre. Our art plan (ART_DIRECTION §10–13) fits Unity 2D Animation. Flutter still needs a separate runtime decision (GB-045). |
| Publishing stack | Voodoo SDK (VoodooSauce, **VoodooTune** remote A/B config, Voodoo IAP, AgeGate), AppLovin **MAX** mediation, Adjust attribution, GameAnalytics, Firebase (Analytics, Crashlytics, Messaging), AppHarbr ad-quality filtering | Hypercasual publishers tune economy and ads remotely through A/B tests. Our versioned shared JSON plus a future remote-config layer (Phase 12) is the right shape. |
| Ads | Networks bundled under MAX: Moloco, Pangle, Mintegral, DT/Fyber, Meta Audience Network, PubMatic, Unity Ads, AudioMob (audio ads), adjoe (offerwall); Google UMP consent | A large mediation stack brings heavy SDK weight (16 dex files) and compliance work. Start with one mediation provider and a small network set (GB-034). Keep consent first. |
| Feel and platform | Nice Vibrations haptics, Play Games v2, Play Age Signals, in-app update | Add haptics to the game-feel budget, and plan an age gate with the audience decision (MONETIZATION_STRATEGY). |
| Tooling | Odin, NaughtyAttributes, SRDebugger, Easy Save, UniTask + Addressables, a Unity MCP package | An in-game debug console and async asset loading are worth adopting in the Unity client (GB-046). |

### Candy Crush Saga (`com.king.candycrushsaga` 1.341.2.1, min SDK 24, target 37)

| Area | Observation | Implication for Gearbound |
|---|---|---|
| Engine | Proprietary native engine (a single `libcandycrushsaga.so`); about 149 MB of assets | Not comparable technically; the useful signal is content organization |
| Data-driven content | 4,356 XML and 1,109 JSON files against 643 images; level, widget, GUI, quest and board systems as separate modules | Validates shared, versioned data with validators, at a much larger scale |
| **Live content packs** | Features ship as separately updatable packs: `ota-` packs (dynamic difficulty v6, first-attempt challenge, seasonal map skin) and feature modules (season pass and revamp, quests, chests, prize draw, sale, vanity items) | Build the Phase 09 event engine around **versioned content packs** with their own config and art, not code per event. Seasonal map skins are a cheap, high-value LiveOps asset. |
| Competitive and social | Episode race, weekly race, marathon leagues, short leaderboard tiers, expeditions, partner events, Facebook social | These need a backend and real players (Phase 12, P3). Do not fake them (PHASE_ROADMAP Phase 09 rule). |
| Streaks and modes | `onfire` (streak state), time pressure, tap-them-all, merge minigame, **treasure defense** | The Overclock Streak matches the pattern. Timed or rule-twist modes map to Engineering Trials and Overclock Challenge. |
| Ad placements | Separate packs for pre-level, end-of-game, out-of-lives, map balloon, arcade, rewarded-ad tiering | Gearbound equivalents already in the policy: pre-mission Vanguard (pre-level) and victory double (end-of-game). We have no lives system, so there's no out-of-lives placement. A map balloon is an optional future rewarded placement. |
| CRM | Braze in-app messaging, plus a large `performance_messaging` pack | Server-driven in-app messages are a LiveOps tool; Phase 12 or later. |

### Dynamic difficulty: policy note

Candy Crush ships dynamic-difficulty packs. If Gearbound ever adapts difficulty, it must:
- use only gameplay signals (failures, time in mission), never spending or ad behavior;
- never raise difficulty to push purchases (AGENTS.md);
- be documented and covered by tests.

No dynamic difficulty is planned at present.

### The Last Friend

The copy in `Reference APK/The.Last.Friend*` is an unauthorized redistribution of a commercial Steam game: it includes a "STEAMUNLOCKED" link and a run instruction file. **It was not opened, run or analyzed**, and nothing from it may be used. Use a legitimately purchased Steam copy, the official website and press kit, or public trailers for visual reference. The recommendation is to delete this copy.

## Gameplay and UI/UX visual study (2026-11-27)

**Sources:**
- **Gear Fight!:** the public Google Play listing (description, 8 store screenshots, top reviews).
- **The Last Friend:** the official Steam page (description, tags, official screenshots).
- **Candy Crush Saga:** six UI texture atlases from the owner's extracted package, converted to temporary previews *outside* the repository.

**What was not done:** no game was installed or run (the Android build path is blocked, GB-038), no image was copied into Gearbound, and the pirated The Last Friend copy was not used. Gameplay observations come from screenshots and store text. **They still need confirmation from hands-on play** before exact rules are designed.

### Gear Fight!: gameplay (observed from store media)

| Observation | Gearbound status and decision |
|---|---|
| Portrait layout: a ~5×4 board of **touching gears** at the top, the shop of **3 offers** (nut currency, prices 12–40) with **reroll (5)** and a large green **FIGHT** button beneath | Matches our loop. Our 5×5 board, 3 offers, reroll and Start Wave are already in place. Consider a single prominent fight button with the reroll beside it. |
| Gear kinds: **number gears** (1, 2, 4, 8, apparently power or merge values), a **1.5× multiplier** gear, **unit gears showing a character portrait and spawn rate ("0.45/s")** | **Adopt:** show each output gear's rate on the gear itself; we already compute it for the status line. Numeric tier badges are clearer than our "T2". |
| **Ice blocks occupy cells** as obstacles | Locked or blocked cells are in the spec (§7, future boards). Useful for later nodes and Engineering Trials. |
| During battle the **board stays visible above a single horizontal lane**: a crowd of units on the left fights a boss with a health bar and portrait on the right | Our portrait layout already keeps the board and battlefield together. Our 3 lanes plus a hero add depth Gear Fight doesn't have. |
| Meta: an **8-card deck** (troops, skills, gears) with in-mission cost, level, power and rarity, a **total power** score, a **collection of 63** with Upgrade and Add | **Gap:** the spec's "select equipment loadout" step. The shop should draw from a player-chosen loadout (new task GB-054). Avoid making "total power" the main gate, to keep the strategy-first promise. |
| Store text: 500+ levels, 50+ gears, archers, brutes, elites, boss mode; tags Merge, Offline | Scope reference only; our MVP targets are in the roadmap. |
| **Top reviews:** "an ad every wave or every other wave with 12 waves per level", unskippable ads up to a minute; steep enemy scaling forcing level repeats ("grinding"). The developer replied that it is rebalancing ad frequency. | **Strong validation of our policy:** interstitials only after a *completed mission*, never between waves, with a 3-mission grace period and spacing rules (`ad_policy.json`). Difficulty must come from composition, not stat inflation (roadmap Phase 07.5). |

**Visual style:** saturated cartoon "chibi" heads on brightly colored gear rings, with thick outlines and flat colors. Readable at phone size, but generic. **Gearbound deliberately differs:** angular comic anatomy and industrial materials (ART_DIRECTION §2).

### The Last Friend: gameplay and presentation (official screenshots)

| Observation | Gearbound status and decision |
|---|---|
| **Landscape, elevated side view.** An upgradable **RV fortress** sits at the left edge with its health ("RV 490/500") in the top-left HUD | Same composition as our fortress-left layout. Put the fortress health bar in the top-left status strip (ART_DIRECTION §6). |
| **Defenses are placed on blue deployment pads** in front of the RV: turrets plus shield barricades | Our gear board plays this role. A visible link from each gear to its battlefield output would bridge the two halves (spec §4); consider a small lane marker on output gears. |
| The **hero brawls mid-field.** Bottom-center hero portrait with **HP and SP (special) bars** | Our hero has lane commands only. An **SP-driven special** fits Phase 03.2 hero abilities (new task GB-055). |
| HUD: a **"My Team" portrait strip** (dog companions as abilities), a currency counter, and an **objective panel** ("Defend the raft", "Reach the end of the elevator") | Mission **objectives beyond "survive"** are a cheap variety lever for route nodes (GB-051). An objective panel belongs in the HUD spec. |
| Combat on **one deep ground band**: characters at different depths, enemies leaping in from the right, varied biomes (industrial, jungle) | We use 3 discrete lanes for gear-to-lane readability. Keep that, but render them as one continuous ground band with depth sorting (ART_DIRECTION §5). |
| **Art:** angular, flat cel-shaded figures without heavy outlines; a teal, pink and orange palette; clean shapes | The reference quality bar for ART-01. Our palette and outline rules stay original. |

### Candy Crush Saga: UI system (texture atlases)

- **Buttons:**
  - Glossy circular buttons with **one white glyph**, color-coded by function: red for close, back and info; blue for sound, settings and skip; green to confirm; yellow for help.
  - Large pastel rounded-square panels, ribbon banners and cloud headers.
- **A consistent status iconography:** stars, hearts (lives), a **flaming skull for "super hard" levels**, flames for streaks, keys and keyholes for unlocks.
- **Packing:** atlases are packed **per screen or feature** (main menu, in-level HUD, LiveOps, onboarding), so each screen loads only its own art.
- **Characters** are cut into parts for skeletal animation (Spine), the same separated-part approach as our art direction.

**Adopt for Gearbound (with our own industrial style):**
1. **One button family**, color-coded by function and always paired with an icon and label (not color alone; accessibility).
2. **A fixed status icon set:** hard or boss node, streak, locked, reward.
3. **Per-feature atlases:** board, HUD, map, events, shop. These map onto the `atlasGroup` field in `shared/art/asset_manifest.json`.

### New backlog items from this study
- **GB-054 (P1):** loadout and deck selection before a mission. The shop draws from the chosen loadout, and unlocks expand options without raising raw power.
- **GB-055 (P1):** a hero special ability charged by an SP bar (Phase 03.2), entering the simulation as a validated command.
- **GB-056 (P2):** spawn-rate and tier numbers on output gears, plus a lane marker linking each output gear to its lane.
- **GB-057 (P2):** mission objective types beyond survival (protect, escort, reach), shown in an objective panel.

## Visual direction v3 references (2026-11-28)

The v3 direction (`ART_DIRECTION.md`, Tactile Industrial Comic 2.5D) adds three references and reframes the earlier three.

**How this was gathered:** general design knowledge of widely published games. No new store pages were fetched, no game was installed, and no image was collected or stored. Each entry names the **principle** Gearbound takes and the **line it must not cross**. Hands-on capture, if the owner wants it, uses legitimately owned copies or official press material only.

| Reference | Principle Gearbound takes | Must not cross |
|---|---|---|
| Gear Fight! | Gear placement, power and merge feedback; numbers on output gears (adopted, GB-056); a short build phase that cuts straight to the consequence | Its chibi characters, gear ring art and UI layout |
| The Last Friend | Character energy and an elevated side view with a fortress on the left; hero and defenses in one frame | Its characters, RV, companions, palette and HUD art |
| SteamWorld Build / Dig | Machines with personality; industrial worlds told through structures and equipment; tactile mechanical detail on every surface | Its robot characters, Western-steampunk iconography and any specific building or tool design |
| Clash Royale | A miniature diorama battlefield that reads instantly on a phone; chunky, toy-like objects with clear silhouettes; satisfying button and chest feedback | Its arena layouts, towers, card frames, chest designs, fonts and character styles |
| Hades | Illustrated, high-quality interface and character portraits; dramatic but legible effects; one coherent painted identity across every screen | Its ink-heavy portrait style, mythology motifs, boon UI and fonts |
| Candy Crush Saga | Route map progression, event presentation, reward chests, daily goals; per-feature atlases; content packs for LiveOps | Its candy visuals, glossy button family, map art and characters |

**Distinctive markers that keep Gearbound original:**
- **Tactility through gears.** The player's own machine is the hero object, drawn as weighty layered metal.
- **The copper-and-teal Wayfarer crew** against crimson scrap raiders, in a sunlit industrial pass.
- **Angular comic anatomy** with designed cel shadows leaning cobalt.
- **A chamfered, riveted steel-and-brass UI**, never glossy or rounded.
- **A three-lane miniature diorama** with a visible board-to-lane link.

**Originality review:** `ASSET_VALIDATION_GUIDE.md` §8 checks every gate's output against this table.

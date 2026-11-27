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

# Gearbound phased roadmap

This roadmap is the delivery order for the game. Each phase ends in a playable, reviewable build before the team widens scope. The progression and event loop takes broad inspiration from level-map puzzle games; Gearbound keeps its own mechanical combat, world, art, and reward economy.

## Phase 0 — Production foundation

**Status: implemented; verification is partial.**

- Establish Unity as the reference runtime and keep the Dart prototype aligned through shared rules and fixtures.
- Implement the five-by-five reciprocal-port gear network, deterministic merging, output timing, and three-lane combat.
- Keep simulation on fixed integer ticks, document balance assumptions, and test core systems independently.

**Exit evidence:** Unity project verification and C# smoke checks pass; Flutter analysis and gameplay tests pass. Unity Test Framework and mobile packaging still need a working build path.

## Phase 1 — One complete route slice

**Status: in progress; the first campaign shell is implemented.**

- Campaign hub with a readable, unlockable wasteland route.
- Battle prep, gear-powered units, hero lane commands, victory/defeat, and a return to the route.
- Best-of-three star rating, first-clear scrap, and locally saved campaign progress.
- Daily contracts and a weekly score event with earn-only scrap tiers.
- Author distinct spawn scripts for the first five route nodes, including a boss encounter; balance them through playtesting before multiplying content.

**Exit criteria:** finish and replay the first five nodes; prove save and unlock behavior across app restarts; verify all rewards can be earned without a network connection; complete an Android build and a human playthrough on a phone.

## Phase 2 — Campaign content and challenge

**Status: planned.**

- Add authored enemy roles, bosses, environmental hazards, and level-specific goals.
- Add optional objectives that can change star outcomes without making completion feel mandatory.
- Expand the gear catalog and teach each mechanic through short, readable route challenges.
- Tune difficulty from play sessions and telemetry gathered only with clear player consent.

**Exit criteria:** a complete chapter with distinct encounters, tested difficulty progression, and no progression soft locks.

## Phase 3 — Event calendar and long-term goals

**Status: partly prototyped offline; service-backed operations are planned.**

- Keep the weekly local event playable offline with fixed, transparent rewards.
- Add rotating event rule sets and chapter-length achievement tracks after core content is stable.
- Only add server calendars, leaderboards, or shared competition if they materially improve the solo game and have a clear privacy and support plan.

**Exit criteria:** event state handles week boundaries, clock changes, interrupted sessions, and repeat clears without duplicate rewards or paid advantage.

## Phase 4 — Production polish and release readiness

**Status: planned.**

- Produce original characters, gear, environments, audio, animation, onboarding, and accessibility options.
- Complete Unity/Dart parity fixtures and device performance checks.
- Add save migration, crash recovery, localization, store metadata, and platform compliance review.

**Exit criteria:** release-candidate build passes platform validation and a structured external playtest.

## Reward and event principles

- Scrap and event tiers are earned through play. No paid random rewards, forced timers, or pay-to-win boosts.
- Daily contracts and weekly scoring are additive goals; they never block campaign progress.
- Stars reward skill and preparedness, while every completed level unlocks the next route node.
- The current prototype uses local device dates and saves. Do not advertise a real-time global event until server scheduling and clock-abuse handling exist.

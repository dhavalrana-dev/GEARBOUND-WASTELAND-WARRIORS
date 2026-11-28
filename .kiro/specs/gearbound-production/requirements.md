# Requirements Document

## Introduction

GEARBOUND: Wasteland Warriors is built in 19 phases (00–18, `docs/PHASE_ROADMAP.md`). Each requirement below is one phase's exit criteria, written in EARS form. `tasks.md` links every task to these numbers. Requirement *N* belongs to Phase *N*.

## Requirements

### Requirement 0: Repository and simulation foundation

**User Story:** As the developer, I want a deterministic shared rules core, so that both engines produce the same game.

#### Acceptance Criteria
1. THE simulation SHALL run at 30 fixed integer ticks per second with stable IDs and ID-ordered tie breaks.
2. WHEN a component touches more than one core or contains an odd-parity gear loop, THE network SHALL mark it conflicted or jammed and inactive.
3. THE shared JSON SHALL be versioned, schema-described and checked by the validator.
4. WHEN the same scenario runs in Unity and Flutter, THE combat traces SHALL match tick for tick.

### Requirement 1: Toolchain and build readiness

**User Story:** As the developer, I want working builds on real targets, so that the game can be tested on devices.

#### Acceptance Criteria
1. THE Flutter project SHALL build a debug APK that launches on an Android device or emulator.
2. THE Unity project SHALL open without compilation errors and run its EditMode tests.
3. WHEN a license must be accepted, THE agent SHALL leave the acceptance to the owner.
4. THE build steps and blockers SHALL be recorded in `docs/TOOLCHAIN_REPORT.md`.

### Requirement 2: Complete mechanical workshop

**User Story:** As a player, I want to buy, place, move, merge and sell gears, so that I can build the machine I plan.

#### Acceptance Criteria
1. WHEN the player buys, places, merges, sells or undoes, THE power state SHALL update immediately.
2. THE costs SHALL go through the ledger, and an invalid action SHALL change nothing.
3. WHILE a wave is in combat, THE board SHALL refuse edits.
4. THE workshop rules SHALL match in both engines through a shared fixture.

### Requirement 3: Combat and multi-wave mission flow

**User Story:** As a player, I want missions of several waves with rebuilds between them, so that gear strategy develops during a mission.

#### Acceptance Criteria
1. THE player SHALL be able to complete a 3–5-wave mission, changing gears between waves.
2. WHEN the hero acts, THE action SHALL enter the simulation as a validated command.
3. THE rewards SHALL be paid once, and mission state SHALL survive rotation, backgrounding and an app kill.
4. THE existing fixtures SHALL keep passing.

### Requirement 4: Visual preproduction

**User Story:** As the owner, I want one approved visual direction, so that production art is coherent.

#### Acceptance Criteria
1. THE ART-01 style direction and ART-02 Rivet master SHALL be approved by the owner.
2. THE identity, proportions, camera and lighting SHALL be locked and documented.
3. THE project SHALL contain no proprietary reference assets.

### Requirement 5: Production vertical slice

**User Story:** As a player, I want one complete, good-looking mission, so that the game's quality is proven before content expands.

#### Acceptance Criteria
1. THE ART-03, ART-04 and relevant ART-05 gates SHALL pass.
2. THE gear visuals SHALL match the simulation state.
3. THE player SHALL play a full mission from preparation to reward with production art.

### Requirement 6: Unity and Flutter playable parity

**User Story:** As the developer, I want both clients playable, so that Unity stays the reference runtime.

#### Acceptance Criteria
1. WHEN the same mission is played in Unity and Flutter, THE simulation outcomes SHALL be equivalent.
2. THE clients SHALL work in portrait and landscape with a consistent visual identity.

### Requirement 7: Campaign content

**User Story:** As a player, I want a campaign where each mission asks for a different plan, so that progress stays interesting.

#### Acceptance Criteria
1. THE route SHALL load every node from shared mission data.
2. EVERY normal mission SHALL have a path that needs no purchase.
3. THE progress, stars and first-clear rewards SHALL survive a restart and follow the rules.
4. THE missions SHALL need distinct strategies.

### Requirement 8: Expanded gamification

**User Story:** As a player, I want daily and weekly goals and collections, so that I have reasons to return.

#### Acceptance Criteria
1. THE resets SHALL be documented, and no reward SHALL be claimable twice.
2. WHEN a day is missed, THE player SHALL lose nothing already earned.
3. THE tasks SHALL be filtered by what is unlocked and SHALL require no paid action.

### Requirement 9: LiveOps and rotating events

**User Story:** As a player, I want rotating events, so that the game changes over time.

#### Acceptance Criteria
1. THE events SHALL follow a documented lifecycle and survive restarts.
2. WHEN an event expires, THE game SHALL pay nothing more for it.
3. THE device clock SHALL NOT authorize server-backed rewards.

### Requirement 10: Economy and persistence hardening

**User Story:** As a player, I want my progress and currency safe, so that nothing is lost or duplicated.

#### Acceptance Criteria
1. WHEN a transaction is interrupted, THE wallet SHALL stay consistent.
2. THE game SHALL never overwrite a newer save.
3. THE UI SHALL never grant premium currency.

### Requirement 11: Advertising integration

**User Story:** As a player, I want optional ads that never block me, so that ads feel fair.

#### Acceptance Criteria
1. THE ad rewards SHALL be paid exactly once, and a failed ad SHALL never block progress.
2. THE game SHALL never show ads during combat or placement.
3. THE consent SHALL be collected before ads, and production ads SHALL stay off until release approval.

### Requirement 12: Backend and cloud services

**User Story:** As a player, I want cloud save and verified rewards, so that my account is portable and fair.

#### Acceptance Criteria
1. WHEN a call is unauthorized, THE backend SHALL refuse it.
2. THE backend SHALL deduplicate repeated requests and resolve cloud save conflicts.
3. THE offline campaign SHALL keep working.

### Requirement 13: In-app purchases

**User Story:** As a player, I want clear fixed-content purchases, so that I know exactly what I buy.

#### Acceptance Criteria
1. WHEN a sandbox purchase succeeds, THE game SHALL grant it exactly once after verification.
2. THE pending, refund, revoke and restore paths SHALL be verified.
3. THE prices SHALL be localized, and No Ads SHALL disable interstitials only.

### Requirement 14: Audio, onboarding and accessibility

**User Story:** As a new player, I want to learn the game without help, so that I keep playing.

#### Acceptance Criteria
1. THE new players SHALL finish onboarding unaided.
2. THE audio SHALL survive ads and lifecycle changes, and the game SHALL be playable without sound.
3. THE state SHALL never be shown by color alone.

### Requirement 15: Performance and QA

**User Story:** As a player, I want smooth play on my phone, so that the game feels good.

#### Acceptance Criteria
1. THE performance targets SHALL be measured on real devices before they are claimed.
2. THE release SHALL have no critical gameplay, save-loss or duplicate-payment defects.

### Requirement 16: Closed testing and soft launch

**User Story:** As the owner, I want real player feedback, so that tuning is based on evidence.

#### Acceptance Criteria
1. THE game SHALL be fun without purchases, and players SHALL understand building.
2. THE critical crashes and save bugs SHALL be resolved before launch.

### Requirement 17: Commercial release

**User Story:** As the owner, I want a store-ready release, so that the game can launch.

#### Acceptance Criteria
1. THE release candidate SHALL pass store validation with no critical defects.
2. THE production features SHALL be enabled only through reviewed configuration.

### Requirement 18: Post-launch operations

**User Story:** As the owner, I want steady operations, so that the game grows safely.

#### Acceptance Criteria
1. THE stability, economy and events SHALL be monitored.
2. THE social systems SHALL be added only with demonstrated demand.

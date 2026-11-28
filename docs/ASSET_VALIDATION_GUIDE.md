# Asset validation guide

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §26 (lifecycle) and §32 (QA).
**The rule:** generating an image does not complete an asset. An asset is **production-ready** only when its manifest record reaches `approved`, after passing **visual, technical and in-engine** validation. All three need recorded evidence, and the project owner reviews them.

## 1. Status lifecycle (`shared/art/asset_manifest.json`)

| Status | Meaning | Required evidence |
|---|---|---|
| `planned` | In the inventory, nothing produced | — |
| `concept` | A concept or working file exists | Source path, provenance |
| `approved_concept` | The owner approved the design | Reviewer, acceptance evidence, license, provenance (validator-enforced) |
| `source_ready` | Final layered source exists | Source file; visual check (§3) |
| `rigged` | Characters only: skeleton assembled | Extreme-pose test (§4) |
| `animated` | Clips authored and events aligned | Animation preview, timing check (§5) |
| `runtime_integrated` | Exported and used in an engine | Runtime paths (validator-enforced), in-engine capture |
| `qa_passed` | Technical and in-engine checks pass in **both** engines where used | §6 and §7 evidence |
| `approved` | The owner signed off in the benchmark or production context | Reviewer, final evidence |

`tools/data-validation/validate_shared.py` enforces the license, provenance, reviewer, evidence and runtime-path rules, and that every `logicalOwnerId` is real.

## 2. Gate map

| Gate | Records it moves | Approver |
|---|---|---|
| ART-01 Visual direction | `style_*` (mood board, reference board, palette, material library, character/environment/UI style, compositions) → `approved_concept` | Owner |
| ART-02 Rivet master | `chr_rivet_concept_*` → `approved_concept` | Owner |
| ART-B Visual benchmark | The benchmark set (`ASSET_INVENTORY.md` ("Visual benchmark set")) → `runtime_integrated` in Flutter at least, reviewed in portrait and landscape | Owner |
| ART-03 Rig and animation | Rivet parts, rig and clips → `animated` | Owner after the extreme-pose test |
| ART-04 Mechanical and environment | Gears, board, Copperwash, fortress, units → `qa_passed` | Owner |
| ART-05 UI and engagement | UI kit, map, events, rewards, shop → `qa_passed` | Owner |
| ART-06 Cross-engine | The slice in Unity and Flutter, with paired captures and profiling → `approved` | Owner |

## 3. Visual check (every asset)

**Reject on any of:**
- Transparency errors: edge halos, matte fringes, stray pixels, semi-transparent holes.
- Lighting not from the upper left, or shading that breaks `VISUAL_STYLE_BIBLE.md` §5.
- A perspective that does not match the elevated side view, or proportions outside the character's guide.
- Outline weights outside the spec, or blurry, doubled or resampled-looking lines.
- Colors outside the approved ramps, or functional colors used decoratively.
- A silhouette that is not identifiable as a solid black fill at gameplay size.
- Any resemblance to reference-game characters, UI, logos or environments (§8).
- Text baked into art.

## 4. Character and rig checks

- **Near/far:** every far limb is its own drawing with correct surfaces and shading. No mirrored duplicates.
- **Joints:** hidden overlap exists under every joint. There is no gap in the extreme poses (`CHARACTER_RIGGING_GUIDE.md` §8).
- **Pivots:** pivots sit at anatomical joint centers, and the weapon stays in its socket through every clip.
- **Draw order:** it matches the default, plus the keyed overrides only.
- **Identity:** it matches the approved master in every view and frame.

## 5. Animation checks

- **Timing:** it matches `ANIMATION_SPECIFICATION.md`. Telegraph clips last exactly the simulation wind-up.
- **Events:** frame events line up with the simulation events (impact on the damage tick, within one rendered frame).
- **Motion:** feet do not slide (stride matched to speed), the anticipation is readable, and the clip plays correctly in reduced-motion mode.

## 6. In-engine check (both engines where the asset is used)

- **Capture the scene:** the asset in the benchmark scene, at gameplay scale.
- **Orientations and sizes:** portrait 1080 × 1920 and landscape 1920 × 1080, plus a compact phone (360 dp wide) and a tablet.
- **Readability:**
  - The 3:1 actor-to-lane contrast is sampled.
  - Telegraphs and projectiles stay visible under the effects and the foreground.
  - Gear states can be told apart without color.
- **Correctness:** the draw order is right in all three lanes, and the lane scale and shadows match the projection contract.
- **Paired captures:** Unity and Flutter at the same simulation tick of the scripted benchmark mission, compared side by side.

## 7. Technical check

- **Exports:** the runtime dimensions, trim offsets, pivots, atlas group, color space and draw order are recorded in the manifest. The texture size matches `VISUAL_PERFORMANCE_BUDGET.md`.
- **Engine load:** the asset loads in each engine with no warnings, and nothing is decoded during combat.
- **Performance:** only with a device capture (device, build mode, tier, numbers). An emulator or a desktop capture is never performance evidence.

## 8. Provenance and licensing

Every record carries a `license` and a `provenance`, filled in from the `concept` status onward:
- **The tool or artist:** the generator or artist, the model or version where the tool has one, and the date.
- **The inputs:** the prompt or brief, plus the IDs of the reference assets used. Those must be our own approved assets, never reference-game images.
- **The edits:** the post-processing steps.

**Prompts** are stored next to the source under `assets-source/**/prompts/`, with a revision number.

**Licenses:**
- **Generated output:** confirm the tool's terms allow commercial use before an asset passes `approved_concept`.
- **Fonts:** commercial game or app licenses, with the license file stored.
- **Third-party textures, brushes or fonts:** recorded, with the license file kept in `assets-source/licenses/`.

**Originality review at each gate.** Compare against the reference games in `REFERENCE_GAME_ANALYSIS.md`. Reject any near-copy of a character, silhouette, UI frame, icon, map layout or logo, even an unintentional one.

## 9. Evidence storage

Review captures go under `artifacts/art-review/<gate>/` locally, which is not committed. Each approval is recorded in the manifest (`reviewer`, `acceptanceEvidence`, with a short description and a capture file name) and in the `DEVELOPMENT_STATUS.md` ledger. Committed approved previews, if any, go under `assets-source/**/review/` at reduced resolution.

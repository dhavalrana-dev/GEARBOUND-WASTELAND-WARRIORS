# Visual performance budget

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §31.
**Status: every number here is a target, not a measurement.** Nothing has been measured on a phone. The emulator results from sessions 18 and 20 are functional checks, not performance evidence. A target becomes a claim only with a recorded device capture (`ASSET_VALIDATION_GUIDE.md` §7).

## 1. Frame rate

| Target | Value |
|---|---|
| Primary | 60 FPS (16.6 ms per frame) on representative mid-range devices during combat with the benchmark scene |
| Fallback | A stable 30 FPS (33.3 ms) with frame pacing (no alternating 16/50 ms frames) when the device cannot hold 60 |
| Simulation | Fixed 30 Hz in every mode; the render rate never changes gameplay |
| Loading | Mission start to first combat frame within 3 s on the reference mid-range device (target) |

## 2. Reference device classes

The classes are defined by capability, not by brand. The exact models are chosen when devices are available (Phase 15).

| Class | Approximate capability | Purpose |
|---|---|---|
| Low | 3 GB RAM, an older 8-core ARM64 SoC with an entry-level GPU, 720p | Must hold a stable 30 FPS at Low quality |
| Mid (reference) | 4–6 GB RAM, a recent mid-range SoC, 1080p | Must hold 60 FPS at Medium quality |
| High | 8 GB+ RAM, flagship GPU, 1440p | High quality; thermal behavior over 10 minutes |
| Tablet | 1600p+ | Layout and memory at larger render targets |

## 3. Budgets per frame during combat (Medium quality)

| Area | Budget | Notes |
|---|---|---|
| GPU texture memory | ≤ 160 MB loaded during a mission | Characters, gears, one region, UI, VFX |
| Atlas page size | 2048² typical; 4096² only with a measured reason | ASTC (or ETC2 as a fallback) on Android, chosen after visual tests |
| Draw calls or batches (Unity) | ≤ 120 | Atlases per layer group |
| Overdraw | ≤ 2.5× average across the battlefield | Foreground and atmosphere are the risk |
| Live particles | ≤ 150 (Medium), ≤ 60 (Low) | Pooled emitters |
| Live projectiles | ≤ 24 | Already capped by the simulation |
| Active characters | ≤ 40 | 12 friendly (4 per lane) + enemies + hero |
| Managed allocations | 0 bytes per frame in steady combat (Unity GC); no per-frame object churn in Dart hot paths | Pools and reused lists |
| Render-side CPU | ≤ 6 ms at Medium on the mid device | Leaves room for the simulation, UI and the OS |

## 4. Quality tiers

| Tier | Contents |
|---|---|
| Low | Fewer particles, no ambient environment animation except gears, simple shadow ellipses, no 2D lights, half-rate background animation, 30 FPS cap |
| Medium | Standard art, particles and small camera effects; 60 FPS target |
| High | Extra atmosphere layers and optional 2D lights, within measured budgets |

- **Gameplay rules and readability are identical at every tier.** Telegraphs, gear states and projectiles are never reduced.
- **Effects are configurable** in settings. **Reduced motion** (`ANIMATION_SPECIFICATION.md` §8) is a separate switch from quality.
- **Default tier:** chosen from a short startup benchmark or a device class table (decided at Phase 15). The player can always override it.

## 5. Asset rules that protect the budget

- Never load full master canvases or unused layers at runtime.
- Trim transparent space, and keep pivots in metadata.
- Tile large surfaces (ground, sky) instead of using full-screen textures.
- Decode no textures during combat; preload per mission.
- No full-screen post-processing in the identity.
- One region's environment loaded at a time.

## 6. Measurement plan (Phase 15, GB-012)

**Unity:**
- Profiler (CPU, GPU, memory) and Frame Debugger on the device.
- Memory Profiler snapshots at the mission start and the boss phase.

**Flutter:**
- A profile build with `flutter run --profile` and DevTools (frame chart, raster and UI threads, memory).
- Builds with `--trace-skia` or Impeller tracing as needed.

**Both:**
- A scripted benchmark mission: the same seed and the same hero commands, so captures are comparable across engines and builds.
- Record the device, OS version, quality tier, build mode, the 1% low FPS, average frame time, texture memory and thermal state after 10 minutes, in `DEVELOPMENT_STATUS.md` and the device matrix.

# Game design document (vertical-slice target)

## Pillars
1. **Build a machine that matters:** every powered gear has a battlefield output.
2. **Read the battle at a glance:** three lanes, clear approach direction, distinct silhouettes, explicit telegraphs.
3. **Make active play amplify planning:** Rivet can interrupt threats and protect a strong build without replacing it.
4. **Short, generous sessions:** a mission target of 3–7 minutes, with saving at wave boundaries.

## Premise
An ancient energy lattice has gone feral. Engineer-fighter Rivet and the Wayfarer crew restore broken links between settlements while outsmarting the machine factions that now guard them. The tone is adventurous, humorous, and colorful.

## Mission loop
Workshop → select Rivet/loadout/route → inspect threat → buy/place/connect/merge → launch wave → automate gear output while steering hero → collect scrap → inter-wave reconfigure → boss/final wave → rewards/save/workshop. The first playable target is three waves, one boss, one environment.

## Campaign and replay layer
- Route nodes unlock in order. Cleared nodes can be replayed; the map stores the best result, up to three stars.
- Star count currently reflects fortress health at victory. Later authored levels may add optional objectives, but a first clear always advances the route.
- First clears award scrap. Daily contracts cover a clear, a powered setup, and hero lane commands; each pays once per local day.
- Scrapstorm is a weekly, offline score track. It counts each level's best star result once per week and pays fixed scrap tiers.
- Progress is saved locally. Daily and weekly rewards are earn-only and do not gate campaign access.
- Event operations, server dates, and leaderboards are outside the prototype until the solo campaign is stable.

## Prototype slice
- 5×5 grid, one core, orthogonal ports, three lanes, one hero, one infantry output, one turret, one booster, three enemy patterns, fortress health and a three-wave script.
- Board preparation and battle are distinct phases. Only small hero controls remain during battle; board edits wait until intermission.
- Production is capped at four friendly units per lane. Excess output waits on a single queued spawn clock.
- Rivet's MVP controls: move, lane shift, quick melee, heavy melee, dash. Assisted basic attacks share damage, range, and cooldown rules.

## First session targets
First purchase or placement within 10 seconds; prep phase 15–30 seconds; wave 20–60 seconds. Initial tuning assumptions are hypotheses until tested with players.

## Not in the first slice
Multiple heroes, monetization, online services, broad unlock tree, procedural campaign, and a full twelve-gear catalog. They follow proof of the core loop.

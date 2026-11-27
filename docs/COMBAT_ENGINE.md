# Combat engine (initial contract)

Positions use lane 0–2 and integer millimeters; enemies approach from the right. Each entity has stable ID, health, armor, range, attack interval, cooldown, and one of `Idle`, `Moving`, `AcquiringTarget`, `Attacking`, `Recovering`, `Stunned`, `KnockedBack`, `Dying`, `Dead`.

Damage formula: `max(1, floor((rawDamage - armor) * (100 - clamp(reductionPct, 0, 80)) / 100))`. A shield absorbs damage before health. Critical chance and status rolls use the shared seeded RNG. Simultaneous damage is applied by target ID then attacker ID; deaths resolve after all hits in the tick. Only one pending unit spawn per output may queue; unit capacity is four per lane. Fortress reaching zero loses; all scheduled enemies defeated wins. Hero incapacitation starts a recovery timer and does not end a mission.

These are prototype rules to implement and validate. Boss patterns and full status-effect stacking remain backlog work.

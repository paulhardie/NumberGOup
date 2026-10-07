# True top-down: the Number at the bottom, numbers falling from the top (D167)

**Status (7 October 2026): criteria written before anything is built or measured.** The owner chose "Do true top down" after the invaders view (D166) showed the round battle drawn on a portrait screen. This page holds the rule, the pass criteria and, once measured, the results.

## 1. The rule

`top_down` is a run option, recorded in a run's tuning only while on, so a round run, saved or replayed, plays as it always did.

- **Enemies fall straight down in columns** across a field `Guesses.TOP_DOWN_WIDTH_M` wide (60 m), centred on the Number. A spawn's column comes from the same draw that gave its direction in the round battle (straight up is the middle), so the same seed sends the same enemies at the same moments.
- **Distance is height.** Everything that used an enemy's distance keeps doing so: walking in, arriving, Range (now a height), knockback (now upward), the Wall, targeting the nearest. An enemy reaching the bottom hits the Number from its column.
- **Positions are true:** an enemy stands at (its column, minus its height), so shots fly to it in straight lines, bounces jump between true neighbours, and Protector shields, land mines and orbs act where things really are. Orbs still circle the Number and catch what their circle crosses; land mines are laid above it; a Scatter splits sideways.
- **The game's rules otherwise unchanged.** The Settings switch starts the next run top-down, and the battle screen draws it with the Number at the bottom (D166's layout). The round battle stays the default until the owner decides.

## 2. Pass criteria (top-down against round, both under the game's rules, the bots' usual buying)

Measured with `tools/topdown_trial.py`; every configuration is reported.

- **T1, the first minutes:** a fresh tower that buys nothing dies on every seed by wave 5 and inside 180 game seconds (The Tower's "you die immediately", the harness's design expectation).
- **T2, Workshop cells:** for each cell (10,000 and 100,000 Coins, each spent core, turtle and blender), the median wave reached top-down is within 20% of the round battle's.
- **T3, careers:** for the core (50 runs) and grow (70 runs) careers, the first run reaching wave 30 top-down is within 25% of the round battle's (both never reaching it passes; one only fails).

Reported beside the criteria, never one of them: how kills split between shots, bounces, orbs, Thorns and mines; how much of the Number Ranged, basic and boss enemies take; and the Coins a run earns.

**Why these:** the change is meant to alter how the battle looks and reads, not how hard Tier 1 is. The bands are wide enough for the geometry's honest effects (enemies three times denser across 60 m than round a 30 m ring, so bounces find neighbours and Protectors cover more) and narrow enough to catch a broken defence or a runaway build.

## 3. Results

Not yet measured.

# True top-down: the Number at the bottom, numbers falling from the top (D167)

**Status (7 October 2026): built as a run option and measured: all three criteria pass (section 3). Not yet the game's rule; the owner decides after playing it.** The owner chose "Do true top down" after the invaders view (D166) showed the round battle drawn on a portrait screen. This page holds the rule, the pass criteria and, once measured, the results.

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
- **T4, where the geometry differs most (added 7 October, before measuring, after T1 to T3 passed without reaching these):** orbs, bounce shots, land mines and Protectors act on true positions, and enemies stand three times closer together top-down. For each cell where they work, the median wave reached top-down is within 20% of the round battle's: 1,000,000 Coins spent as `blender_orbs` (every orb first), `multishot` (Multishot and Bounce Shot), `spread` (every group, land mines included) and `turtle` (Thorns), 6 seeds each; and Tier 2 and Tier 3 with every Workshop row at level 20 (Protectors and elites, orbs, bounces and mines together), 6 seeds, 30 game minutes each. How each cell's damage splits between shots, orbs, bounces, Thorns and mines is reported beside it.

Reported beside the criteria, never one of them: how kills split between shots, bounces, orbs, Thorns and mines; how much of the Number Ranged, basic and boss enemies take; and the Coins a run earns.

**Why these:** the change is meant to alter how the battle looks and reads, not how hard Tier 1 is. The bands are wide enough for the geometry's honest effects (enemies three times denser across 60 m than round a 30 m ring, so bounces find neighbours and Protectors cover more) and narrow enough to catch a broken defence or a runaway build.

## 3. Results (7 October 2026): PASS on all three

Measured with `python3 tools/topdown_trial.py` (criteria committed first, unchanged; every run checked to have played the battle it was meant to, from its recorded tuning).

| Criterion | Reading | Verdict |
|---|---|---|
| T1, the first minutes | 20 of 20 fresh towers dead by wave 5 inside 180 s | PASS |
| T2, Workshop cells (median wave, top-down / round) | 10K core 31 / 31, turtle 41 / 41, blender 31 / 31; 100K core 51 / 51, turtle 83 / 83, blender 50 / 50 | PASS |
| T3, careers (first run reaching wave 30) | core 35 / 33, grow 47 / 43 | PASS |

**Reported beside the criteria:** losses split almost exactly as in the round battle (Ranged 56% against 57% at 10K core; Thorns 46% of a 100K turtle's damage against 45%), and a run's Coins are the same within 1% to 2% in every cell.

**What it means:** top-down changes how the battle looks and reads, not how hard Tier 1 is. Range, contact, knockback and targeting all follow distance, which is now height, so the waves a build reaches are the same.

**Not measured:** no trial cell opens orbs, bounce shots, land mines or meets a Protector (they open above these budgets or later in Tier 1), so where the geometry differs most (enemies three times denser across 60 m than round a 30 m ring) is unmeasured. The land-mine height rule (mines laid no lower than enemies stop, from the independent review) came after the measurement; no measured cell lays mines. A player, a phone and Tier 2 and 3 are not checked.

## 4. How it looks (7 October 2026)

Drawing only; the battle is unchanged.

- **An enemy that hits shows its health**, counting down as it is shot, with the hit it will land small under it ("−2"), and nothing there when the defences would take that hit whole. A Divider keeps its ÷, a Lock its = and a Vampire its drain, since those are what they do. The round battle still shows the hit, as D102 has it.
- **A faint line across the field where enemies stop,** broken where the Number stands, so an enemy reaching the bottom at an edge reads as having arrived.
- **A melee hit flashes a line** in the enemy's colour from where it stands to the top of the Number, for a quarter of a second.


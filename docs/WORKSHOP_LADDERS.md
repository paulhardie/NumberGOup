# Workshop ladders: ranks, cost curves and stat curves

**Status:** The [Tower-matched review](#tower-matched-review--23-september-2026) is accepted and built as [D047](DECISIONS.md#d047--deep-workshop-ladders-on-the-towers-shape-and-150-hours-to-max); see [As built](#as-built--d047). The original proposal from [The short version](#the-short-version) on (5,000 / 1,000-rank classes, tier bands, rank conversion) is superseded and kept as the record. It answers the owner's request to look at every Workshop row, put them in JSON and tables, and decide how deep the ladders go (The Tower runs its core rows to about 5,000 levels) and how cost and stats climb.
**Data:**
- [`data/workshop/current.json`](../data/workshop/current.json) and [`current.md`](../data/workshop/current.md): every current Workshop row, Lab line and Card, generated from the live game by [`tools/export_workshop.gd`](../tools/export_workshop.gd).
- [`data/workshop/proposed_spec.json`](../data/workshop/proposed_spec.json): the proposal as an editable spec.
- [`data/workshop/proposed.json`](../data/workshop/proposed.json) and [`proposed.md`](../data/workshop/proposed.md): every rank of every proposed row, generated from that spec by [`tools/workshop_ladders.py`](../tools/workshop_ladders.py).

**Depends on:** [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md) for the 28 rows and [`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md) for the ten-tier ladder that sets the income these prices are matched to.

## Tower-matched review — 23 September 2026

**Status:** review on owner direction ("roughly match the Tower's equivalent levels for each stat and check their individual scales and gates so we can establish how powerful a player who maxes the workbench out is"). It revises the proposal below. Accepted with every recommendation and a 150-hour target (D047), and built.

**Sources:** The Tower's level counts, values and prices come from the unofficial community [TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) workshop table (release 0.11.0, 13 September 2026); community data, not developer data. Our side comes from `data/workshop/upgrades.json` and the balance simulator.

### How The Tower builds its Workshop

- **Four rows go deep and carry all the scaling:** Damage (6,000 levels), Health (6,000), Health Regen (6,000) and Defense Absolute (5,000). Their values grow steeply, faster than the level: Damage is ×67,480 from level 100 to level 6,000, Defense Absolute ×78,930, Health ×310,500.
- **Every other row is capped at 75–300 levels** and costs 1–20 million Coins to max, against about 800 trillion for Damage. The capped rows are finished early; the deep rows are the whole long game.
- **Price rises faster than power.** Damage's per-level price rises from 30 Coins to 5.1 trillion (×1.7 × 10^11) while its value rises ×2.4 × 10^7.
- **Every level is on sale from the start.** No row's levels are opened by tier; the price is the only gate on depth, and the one-time unlock gates ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#how-the-tower-prices-its-gates)) are the only gate on breadth.

### Every row against its Tower twin

| Our row | Tower twin | Tower: levels, value at max | Ours today | This proposal (below) | Recommended |
| --- | --- | --- | --- | --- | --- |
| Tap Damage | Damage | 6,000, 3 → 71 million | 100, +6 | 5,000, +916 | **6,000**, Tower-shaped: +405,000 |
| Damage per Second | Damage | 6,000 | 100, +7.5 | 5,000, +1,367 | **6,000**, Tower-shaped: +506,000 |
| Damage Multiplier | — (Tower's Damage curve compounds itself) | — | 60, ×1.52 | 5,000, ×80 | **60, ×1.52** (one deep damage source, as The Tower) |
| Tick Speed | Attack Speed | 99, ×5.95 | 100, ×2.49 | 100, ×2.49 | **100, ×5.95** (the tick loop allows 80 a second) |
| Double Tick | Multishot Chance | 99, 49.5% | 60, 24% | 60, 24% | **125, 50%** |
| Burst | Rapid Fire | 85, 34% | 6 | 6 | 6 (Frenzy replaces it later) |
| Crit Chance | Critical Chance | 79, 80% | 100, 25% | 100, 25% | **80, 80%** (1% a rank; the engine clamps at 80%) |
| Crit Damage | Critical Factor | 150, ×16.2 | 60, ×5 | 1,000, ×52 | **150, ×16.2** |
| Crit Chain | Super Crit (nearest) | 100–120 | 60 | 60 | 60 |
| Auto Crank | — | — | 50, +5 | 50 | 50 |
| Boss Damage | — | — | 100, ×2 | 1,000, ×11 | **100, ×2** (every Tier 1 wall is a boss; a deep row would outgrow Defense) |
| Armor | Defense % | 99, 49.5% | 100, 40% | 100, 40% | **125, 50%** |
| Guard | Defense Absolute | 5,000, 0 → 80 million | 100, +100 × tier | 5,000, 494 × tier | **5,000**, Tower-shaped: +7.9 million × tier |
| Leech | Lifesteal | 80, 4.46% | 100, 25% (bosses only) | 100 | 100, 25% (a different job) |
| Thorns | Thorn Damage | 99, 99% | 100, 50% | 100 | **200, 100%** |
| Cushion | Health | 6,000, ×310,500 | 50, +500 × tier | 1,000, +10,000 × tier | **150, +1,500 × tier** (Number is health and refills from output; a deep Cushion only pads the first waves, measured: no change in waves reached) |
| Brace Cost | — | — | 60, 15% | 60 | 60 |
| Second Wind | Death Defy | 75, 30% | 50, 25% | 50 | **60, 30%** |
| Discount | — (Labs) | — | 60, 15% | 60 | 60 |
| Coin Bonus | Coins / Kill Bonus | 149, ×2.49 | 100, ×1.5 | 100 | **300, ×2.5** |
| Knowledge Bonus | — | — | 50, +50% | 50 | 50 |

Where we part from The Tower, and why: the Multiplier stays shallow so one row (Tap and Damage per Second) carries damage, as Damage does there; Cushion stays shallow because The Tower's Health is its survival and ours is the Number; Boss Damage has no twin and stays at ×2.

**Tower-shaped** means ranks 1–100 stay exactly as today (so every owned rank keeps its value and no rank conversion is needed), and ranks 101–6,000 follow The Tower's curve from its level 100: ×5 by 250, ×20 by 500, ×76 by 1,000, ×2,223 by 3,000, ×67,480 by 6,000.

### How powerful a maxed Workshop is

Every row at its ladder's maximum, with no Labs, Cards or run ranks, two taps a second (`run_balance.sh` with `-- --maxed-workshop`, profile `tax-foundation-v10`, seed 7):

| Ladder | Damage a second | Tier 1 | Tier 2 | Tier 3 | Coins from that Tier 1 run |
| --- | ---: | --- | --- | --- | ---: |
| Today | 48 | wave 120 | wave 54 | wave 40 | 7,083 |
| This proposal (5,000 / 1,000) | 274,890 | wave 677 | wave 511 | wave 455 | 250,438 |
| Tower-matched | 4.6 million | wave 830 | wave 660 | wave 608 | 695,302 |
| **Recommended** | 4.6 million | **wave 830** | **wave 660** | **wave 608** | 695,062 |

- **Damage buys depth slowly.** The Tower-matched build has 17× the proposal's damage and reaches 150 waves further, because Tier 1's Wave HP multiplies by roughly 6–8 every 100 waves from wave 500.
- **Wave 5,000 is out of reach of any Workshop.** Its Wave HP is about 10^40; the recommended maxed Workshop handles about 10^11. Labs, Cards and run ranks would have to supply the other 10^29. With the 5,000-wave milestones (D043), either the curve eases past some depth or wave 5,000 stays a milestone no one reaches; that is its own decision.
- **Higher tiers cost a maxed build about 170 waves (Tier 2, ×20 pressure) and 220 (Tier 3, ×60).**

### The decisions, revised

1. **Depth: which rows go deep.** Recommended: Tap Damage and Damage per Second to 6,000 and Guard to 5,000, as The Tower's Damage and Defense Absolute; everything else capped at the counts in the table. (The proposal below also deepened the Multiplier, Crit Damage, Boss Damage and Cushion.)
2. **How depth is opened.** Recommended: **drop tier bands**; every rank is on sale from the start and its price is the gate, as in The Tower. The bands assumed ten tiers; with three, a Tier 1 player would stop at 500 ranks. Coin gates already stop a new player getting everything at once.
3. **Price, and how long maxing takes.** Recommended: price rises faster than power, as The Tower's does, anchored to what a run at that depth pays (a maxed Tier 1 run pays about 700,000 Coins). The number to choose is how many hours of play it takes to max the Workshop; the career simulator then sets the curve to hit it.
4. **Stat shapes.** Recommended: ranks 1–100 unchanged, then The Tower's growth for the deep rows (Guard grows too, rather than the proposal's shrinking steps; the 10% Hit floor keeps Hits real); straight steps to the new caps for the rest.
5. **Rank conversion.** Recommended: **none needed.** The deep rows keep today's values for ranks 1–100; Armor, Double Tick, Thorns, Second Wind and Coin Bonus keep their step and simply gain ranks. Tick Speed, Crit Chance and Crit Damage need a bigger step per rank to reach The Tower's maximums, so ranks already owned there get stronger, never weaker. Raising `max_rank` changes no saved key, so it is not a schema bump by itself.
6. **Breakthroughs.** The proposal's finding assumed its ten-tier climb; recommended to leave it with the tier proposal rather than decide it here.
7. **`data/workshop/` as the single source.** Done: the Workshop loads from `data/workshop/upgrades.json` (PR #40).
8. **New: the depth a maxed Workshop should reach**, and what happens past it (above).

### As built — D047

- **Ladders:** as recommended in the table above. Tap Damage and Damage per Second run to 6,000 ranks on the Damage depth curve, Guard to 5,000 on Defense Absolute's; ranks 1–100 keep their old values. The curves live in `data/workshop/upgrades.json` as `depth_curve` anchors (rank: multiple of the rank-100 value), interpolated in log space.
- **Price:** ranks 1–100 keep their old prices. Past rank 100 each deep-row rank costs 1.0007× the last, and each extended capped row 1.02× the last (`deep_cost_growth`). The whole Workshop costs 34.6 million Coins: Attack 18.5 million, Defense 13.9 million, Utility 2.3 million. Tap Damage's last rank costs 5,372 Coins and Damage per Second's 7,195; Cushion's last is the dearest at 103,919.
- **Hours to max:** the career simulator's focused player (`--spend focused --careers today_rig --runs 600 --run-cap-minutes 180`, buying run Upgrades, seed 7) maxes the Workshop on run 120, **147.9 hours**. The other growths measured: 1.0006 took 115.2 h, 1.00065 134.9 h, 1.0008 188.9 h, and 1.001 had not maxed by 217 h.
- **Maxed reach:** Tier 1 wave 830, Tier 2 660, Tier 3 608 (`-- --maxed-workshop`), as the review predicted.
- **Early pacing moved.** Tick Speed, Crit Chance and Crit Damage now take bigger steps per rank, and Tap Damage and Damage per Second keep selling past 100, so the same Coins buy more: the focused player reaches wave 100 in 1.4 hours instead of 2.8, and a rank-100 Attack build reaches wave 200 instead of 100 (balance target 5 no longer holds). The first run is unchanged.
- **Research Focus is lopsided.** Its 25% off a category was balanced on equal category totals (WORKSHOP_DESIGN step 4a); Attack now costs eight times Utility, so focusing Utility saves little. Open.
- **Save V9:** raising a max rank changes no key, but a V8 build would clamp ranks past 100, so saves move to V9 and older builds refuse them (D028).

## The short version

- **Three kinds of ladder.**
  - **Core: 5,000 ranks.** Tap Damage, Damage per Second, Damage Multiplier and Guard.
  - **Long: 1,000 ranks.** Crit Damage, Boss Damage and Cushion.
  - **Capped: 100 ranks or fewer.** Every percentage row, and the stats the engine has to limit.
- **Each tier unlocked opens one band** of every core and long row (500 and 100 ranks). The Workshop literally grows as you climb, and there's always something to buy.
- **One smooth price curve per kind of ladder, no cliffs.** Prices rise 3.07× a band, the same rate the career model says income rises per tier. So filling every band costs about **55% of what a player earns in that tier**, at every tier. First ranks cost 2–10 Coins.
- **Stats climb in four shapes.**
  - Damage rows add a little more per rank as they go.
  - The Multiplier compounds.
  - Guard adds a little less per band.
  - Everything capped rises in straight steps to its ceiling.
- **Band 1 is worth the same as today's maxed Workshop (×1.02)**, so Tier 1 plays as it does now. By band 10 the three damage rows give about 8,000× today's.
- **Nobody loses anything.** Every owned rank converts to the first new rank worth at least as much.
- **Finding: at this strength the Workshop carries enough of the climb that Breakthroughs aren't needed for pacing.** In the career model, ten tiers take about 72 hours with the ladders and no Breakthroughs, and 25 hours with them.
- **Finding: Lab research is unreachable past about rank 20.** Maxing Damage Research would cost 1.9 trillion Coins and take about 425 years.

## How The Tower's core rows map

The Tower's reference ladders are Damage, Health, Regen and Defense Absolute, at thousands of levels each. Number Go Up borrows the *depth*, not the rows, because its Number is its health.

| The Tower | Number Go Up | Ladder | Why |
| --- | --- | --- | --- |
| Damage | Damage per Second, Tap Damage, Damage Multiplier | Core, 5,000 | Damage carries the whole climb, split into the base and the multiplier |
| Health | *No direct twin.* The Number is health; Cushion is only its starting value | Cushion: long, 1,000 | Output refills the Number every second, so a deep starting buffer matters far less than a deep health bar does in The Tower |
| Regen | *No direct twin.* All output is Number (D037); Bounty is the closest | Bounty: capped | A deep regen row would just be a second damage row |
| Defense Absolute | Guard | Core, 5,000 | The flat-reduction twin; see [its curve](#guard-adds-less-each-band) |

## The three kinds of ladder

| Kind | Ranks | Bands | Price growth per rank | Price at rank 1 | Rows |
| --- | ---: | --- | --- | ---: | --- |
| Core | 5,000 | 10 × 500, band *n* opens with Tier *n* | ×1.002245 (×3.07 a band) | 2–4 Coins | Tap Damage, Damage per Second, Damage Multiplier, Guard |
| Long | 1,000 | 10 × 100, band *n* opens with Tier *n* | ×1.01128 (×3.07 a band) | 4–10 Coins | Crit Damage, Boss Damage, Cushion |
| Capped | 6–100 | none | as today, 1.04–1.09 | as today | Tick Speed, Double Tick, Burst, Crit Chance, Crit Chain, Auto Tap, Finisher, Streak, Armor, Leech, Thorns, Payback, Brace Cost, Second Wind, Bounty, Interest, Boost Discount, Free Boost, Discount, Coin Bonus, Knowledge Bonus |

Why some rows **must** stay capped:

- **Tick Speed:** the tick loop runs at most 20 ticks per 0.25-second frame, so tick rate can't grow without limit.
- **Crit Chance:** clamped at 80% in `GameState`.
- **Percentage rows:** they already have combined ceilings that keep runs ending (D023, and the table in [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#ceilings-that-keep-runs-ending)).
- **Coin Bonus and Knowledge Bonus:** Coins buy everything else, so an uncapped Coin multiplier compounds with every band and runs away.

## The cost curve

One exponential per kind of ladder, and its growth is the whole design: **a band costs 3.07× the one before, because a tier pays about 3.07× the one before** (`tools/career_model.py`, proposal scenario: 25,000 Coins earned during Tier 1, 611 million during Tier 10).

A core row, Damage per Second:

| Rank | 1 | 100 | 500 (end of band 1) | 1,000 (band 2) | 2,500 (band 5) | 5,000 (band 10) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| This rank costs | 2 | 3 | 7 | 19 | 544 | 147,757 |
| Coins to get here | 2 | 299 | 2,109 | 8,016 | 242,783 | 65,965,360 |

All banded rows together, against income:

| Tier | Band Coins, every core and long row | Coins earned while playing that tier | Share |
| ---: | ---: | ---: | ---: |
| 1 | 15,013 | 25,000 | 60% |
| 2 | 43,530 | 76,750 | 57% |
| 5 | 1,225,965 | 2,220,719 | 55% |
| 10 | 333,488,679 | 605,599,333 | 55% |

The other ~45% goes on capped rows (all 21 together cost about 139,000 Coins, so they're bought out during Tiers 1–3) and on Labs and slack.

**Why no cliffs.** The tier unlock is already the gate: a band simply isn't for sale until its tier is open. A price jump on top would double-gate the same moment.

Alternatives considered:
- **Polynomial prices** go cheap late and run away.
- **Steeper exponentials** turn the last ranks of each band into walls.
- **Hand-placed cliffs**, the owner's earlier Tower reference, surprise players without adding a decision.

## The stat curves

### Damage rows add a little more per rank

Tap Damage and Damage per Second add a small step each rank, and the step grows 1.6× a band. Early ranks are tiny, as in The Tower, so the unit a player feels is a Workshop visit bought with MAX, not a single rank.

| Rank | 500 | 1,000 | 1,500 | 2,500 | 5,000 |
| --- | --- | --- | --- | --- | --- |
| Damage per Second | +7.5 (today's max) | +19.6 | +38.9 | +119 | +1,367 |
| Tap Damage | +6.0 (today's max) | +14.1 | +27.0 | +80.7 | +916 |

### The Multiplier compounds

Damage Multiplier multiplies by 1.55 every 500 ranks: ×1.55 at the end of band 1 (today's max is ×1.52), ×2.40, ×3.72, then ×8.95 at 2,500 and **×80 at 5,000**.

### Guard adds less each band

Guard takes a flat amount off every Hit, priced in the tier's Hits like Cushion. Its step *shrinks* 0.85× a band, so it approaches a ceiling. The reason is that the Hit curve inside every tier is the same shape (from about 12 at wave 1 to about 12,000 at the wave 100 boss, times the tier), so a Guard that kept growing would eventually make the first 75 waves of every tier hitless.

| Rank | 500 | 1,000 | 2,500 | 5,000 |
| --- | --- | --- | --- | --- |
| Guard (× the tier's Hit pressure) | 92 | 171 | 342 | 494 |

At its cap, Guard floors each tier's Hits (to 10% of their size) up to about wave 40 of that tier, then fades while Armor carries on. That's the "Guard carries the early game, Armor the late game" split in [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md).

### Long rows rise in straight steps

| Row | Per rank | Rank 100 | Rank 500 | Rank 1,000 | Coins to max |
| --- | --- | --- | --- | --- | ---: |
| Crit Damage | +0.05× | ×7 | ×27 | ×52 | 39.6 M |
| Boss Damage | +1% | ×2 (today's max) | ×6 | ×11 | 26.4 M |
| Cushion | +10 × the tier's Hits | +1,000 | +5,000 | +10,000 | 65.9 M |

## The climb

Every banded row filled to that tier's band, at two taps a second, from the three damage rows alone (before crits, ticks, Boost, Insight, Labs or Cards):

| Tier | Core ranks open | Damage/sec row | Tap row | Multiplier | Damage a second | Against today's max | Guard |
| ---: | ---: | --- | --- | --- | ---: | ---: | ---: |
| 1 | 500 | +7.5 | +6.0 | ×1.55 | 32 | ×1.0 | 92 |
| 2 | 1,000 | +19.6 | +14.1 | ×2.40 | 117 | ×3.8 | 171 |
| 3 | 1,500 | +38.9 | +27.0 | ×3.72 | 350 | ×11 | 237 |
| 5 | 2,500 | +119 | +80.7 | ×8.95 | 2,517 | ×81 | 342 |
| 7 | 3,500 | +324 | +218 | ×21.5 | 16,367 | ×525 | 418 |
| 10 | 5,000 | +1,367 | +916 | ×80.0 | 256,171 | ×8,216 | 494 |

That is about ×3.7 in Tier 2's band, easing to ×2.5 a band by the late tiers. With the tier proposal's ×10 Wave HP per tier, the rest comes from Knowledge and Insight (about ×3 a tier), crits and Boss Damage, and the percentage Boosts inside a run.

**What it does to pacing** (career model; its absolute hours still use the pre-D037 wave rule, so read the shape):

| | Tier 1 | Tier 5 | Tier 10 | Each tier vs the one before |
| --- | ---: | ---: | ---: | ---: |
| Tier proposal as merged (Workshop about ×2 a tier) | 3.2 h | 19.5 h | 72.7 h | 1.30× |
| These ladders, with ×1.4 Breakthroughs | 3.2 h | 13.1 h | 25.4 h | 1.04× |
| These ladders, with ×1.2 Breakthroughs | 3.2 h | 16.2 h | 39.7 h | 1.13× |
| **These ladders, no Breakthroughs** | 3.2 h | 20.7 h | 71.9 h | **1.24×** |

The ladders make the Workshop strong enough that Breakthroughs aren't needed to pace the climb, which fits the owner's "keep it simple". **Recommendation: drop Breakthroughs from the pacing plan.** Keep the reserved name for a later fun layer if one earns its place.

## Keeping owned ranks

Where a row's ladder changes shape, each owned rank converts to the first new rank worth at least as much. The conversion is by value, not by Coins, so nobody loses anything.

| Row | Owned today | New rank | Worth |
| --- | ---: | ---: | --- |
| Damage per Second | 100 (max) | 499 | +7.5 |
| Tap Damage | 100 (max) | 497 | +6.0 |
| Damage Multiplier | 60 (max) | 479 | ×1.52 |
| Crit Damage, Boss Damage, Cushion | any | same rank | unchanged: their steps don't change |

The full table, including partial ranks, is in [`proposed.md`](../data/workshop/proposed.md#keeping-owned-ranks). This is a save migration (new rank values under the same ids), so it's a schema bump under D028 with old-save fixtures.

## Labs: a finding, not yet a proposal

The export shows Lab research growing 1.55× in time and 1.7× in Coins *per rank*:

| Line | Rank 10 | First rank over a day | First rank over a week | To max |
| --- | --- | ---: | ---: | --- |
| Damage Research (40 ranks) | 2.6 h, 94,871 Coins | 16 | 20 | 1.9 trillion Coins, about 425 years |
| Lab Speed (20 ranks) | 1.3 h, 99,180 Coins | 18 | — | 80 million Coins, 9 days |

So every Lab line is effectively capped near rank 20, and ranks 21–40 exist only on paper. The natural fix is the same shape as the Workshop: gentle time growth that tops out around a day per rank, and ranks opened by tier bands rather than by ever-longer clocks. That needs its own pass alongside the Gem economy (D027, D029).

## Decisions this needs

1. **Ladder depth:** Core 5,000 / Long 1,000 / Capped, with these rows in each.
2. **Tier bands:** each tier unlocked opens one band of every core and long row.
3. **The cost rule:** one exponential per kind, a band costing about what the tier earns ×0.55, no cliffs.
4. **The stat shapes:** growing steps for damage, compounding for the Multiplier, shrinking steps for Guard, straight steps for everything else.
5. **Rank conversion** for Tap Damage, Damage per Second and Damage Multiplier, with a save migration.
6. **Drop Breakthroughs from the pacing plan** (supersedes part of the tier proposal).
7. **Make `data/workshop/` the Workshop's single source.** Today the rows are constructor calls in `GameState._make_definitions()`. Balancing thousands of ranks by editing code is error-prone, and two copies would break "one clear authority per concept". Recommendation: the game loads its catalogue from JSON, `tools/workshop_ladders.py` retires, and a test checks the loader against the sampled tables in `proposed.json`.

## Build order

| Step | What | Why here | Risk |
| --- | --- | --- | --- |
| 1 | The Workshop loads its rows from `data/workshop/`, reproducing today's ladders exactly | One authority before any number changes; proves the loader against `current.json` | Medium: purchase path and catalogue |
| 2 | A GDScript career simulator on the real game (the tier proposal's step 0) | These hour figures come from a model still using the pre-D037 wave rule | Low: a tool |
| 3 | Core and long ladders with bands and the rank conversion | The climb itself | High: economy and save migration |
| 4 | Guard and the other new rows, one at a time ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md) order) | Each measured on its own | High: economy |
| 5 | Labs on the same band shape | Currently unreachable past rank 20 | High: economy and saves |

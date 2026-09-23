# Workshop ladders: ranks, cost curves and stat curves

**Status:** Proposed, 23 September 2026. Nothing here is accepted or built; the game still uses its current ladders. It answers the owner's request to look at every Workshop row, put them in JSON and tables, and decide how deep the ladders go (The Tower runs its core rows to about 5,000 levels) and how cost and stats climb.
**Data:**
- [`data/workshop/current.json`](../data/workshop/current.json) and [`current.md`](../data/workshop/current.md): every current Workshop row, Lab line and Card, generated from the live game by [`tools/export_workshop.gd`](../tools/export_workshop.gd).
- [`data/workshop/proposed_spec.json`](../data/workshop/proposed_spec.json): the proposal as an editable spec.
- [`data/workshop/proposed.json`](../data/workshop/proposed.json) and [`proposed.md`](../data/workshop/proposed.md): every rank of every proposed row, generated from that spec by [`tools/workshop_ladders.py`](../tools/workshop_ladders.py).

**Depends on:** [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md) for the 28 rows and [`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md) for the ten-tier ladder that sets the income these prices are matched to.

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

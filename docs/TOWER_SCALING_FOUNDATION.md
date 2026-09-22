# Tower scaling research and Number Go Up foundation

Status: researched and implemented as foundation profile `tax-foundation-v1`, then retuned to `tax-foundation-v2` for D012, 21 September 2026.

## Implemented foundation

The first complete slice now includes:

- absolute Liability and Collection encounters;
- original wave curves with milestone growth and separate boss multipliers;
- Tiers 1–3 with 1×/20×/60× pressure and 1×/1.8×/2.6× rewards;
- Tier 1's 20-wave onboarding grace, with immediate pressure in Tiers 2–3;
- per-tier wave records, milestones at 10/25/50/100, and wave-100 tier unlocks;
- deterministic run seeds and exact RNG/encounter restoration in save V4;
- V1, V2 and V3 migration;
- a shared ordered rule-modifier pipeline;
- retreat-as-reset and active-run offline freezing, removing pause-and-grow;
- a permanent Coin-funded Workshop whose ranks form every run's baseline;
- Tier selection and live Liability/Collection presentation in the Number screen.

Later-system hooks exist, but Perks, configurable card loadouts, Laws/Violations content, Modules, events and tournaments remain deliberately outside this slice.

## Executive conclusion

The Tower does not make its waves difficult with one percentage-of-player-resources curve. It has two independently scaled enemy requirements:

- health, which the player's damage must overcome;
- attack, which the player's health and mitigation must survive.

Its campaign tier is then an explicit multiplier layer on top of the wave curves. Tier 2 is 20 times Tier 1 for both displayed base health and displayed base damage. Rewards rise much less: the Tier 2 base coin multiplier is 1.8 times Tier 1. Later tier jumps are deliberately irregular rather than a single exponential.

Number Go Up should borrow that separation, not copy The Tower's whole formula. A tax wave should have:

- `liability` — the tax's health, depleted by the player's production;
- `collection` — the tax's attack, deducted as an absolute `ScientificNumber` from Number;
- `reward` — independently scaled Coins or run progress;
- a versioned tier definition and a versioned wave-scaling profile.

**Recommended foundation decision: replace the current percentage-of-current-Number tax with an absolute two-stat Tax Encounter before tuning any tiers.** A percentage tax makes a weak and a strong build lose the same fraction of Number, so production growth does not meaningfully extend survival. Tuning its constants cannot fix that structural problem.

## Baseline audited before implementation

The pre-migration Godot slice had a useful base:

- `ScientificNumber` supports addition, subtraction, multiplication, logarithms, powers and comparison without ordinary-float overflow;
- a four-bay Number-funded, run-scoped Workshop, automation, offline generation, Prestige, Knowledge and permanent Insight;
- a wave-tax prototype with a 15-second clock, 20 free waves, every tenth wave as a boss, Coins, Brace and permanent tax resistance;
- save migration and an economy test suite.

The old tax started at 1.5% of current Number, grew by 1.12 per taxed wave and was multiplied by 1.5 on boss waves. It was intentionally allowed to reach 100%, when it forced death.

That prototype had four foundation gaps which the implemented slice now addresses:

1. Tax is proportional to current Number, so two builds with wildly different production lose the same percentage on the same wave.
2. `end_run()` stops tax while Number production and offline production continue, then resumes the same wave. This creates a pause-and-grow exploit.
3. There is one global `highest_wave`, but no selected tier, per-tier records, tier unlocks, tier reward multiplier, active encounter, or versioned balance profile.
4. `GameState` owns economy, combat, run lifecycle, persistence and balance constants. More systems added directly there will become difficult to reason about and test.

The recoverable pre-migration baseline is commit `5e4b499` (`Initial commit: Number Go Up idle game with wave-tax run/death loop`).

## Best available public formula/data sources

### 1. TheTowerSDK — strongest current source

[TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) is the most useful public source found. It exposes typed data, save parsing and game-mechanics calculations. The important files are:

- [wave base health and damage scaler](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/waves/base-empirical-scaling.ts);
- [tier pressure, coin reward and scaling profiles](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/waves/scaling-regression-profile.ts);
- [enemy wave stats](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/enemies/wave-stats.ts);
- [enemy-type health and damage multipliers](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/enemies/type-mults.ts).

The wave scaler's own documentation says its current health/damage chain was checked on 18 August 2026 for exact equality across 21 tiers, 34 waves and 8 contexts. That exactness statement applies to this base wave scaler, not automatically to every mechanic in the pre-1.0 SDK. Pin a commit or package version before using it as a regression reference.

### 2. Tower Idle Toolkit — useful predecessor

[tower-idle-toolkit](https://github.com/tower-idle-toolkit/tower-idle-toolkit) established the earlier structure used by the SDK. Its [calculator site](https://tower-idle-toolkit.github.io/tower-idle-toolkit/) remains useful for cross-checking historical values, but the newer SDK is the better implementation reference.

### 3. Enemy Stats calculator — useful visual cross-check

[The Tower Enemy Stats](https://tower-enemy-stats.netlify.app/) is a user-facing calculator for unmodified base enemy stats. The site currently points users toward [My Tower](https://mytower.app/) as its successor. Representative displayed values are:

| Wave | T1 attack | T1 health | T2 attack | T2 health |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 1.18 | 2.35 | 23.52 | 47 |
| 100 | 402.95 | 4.36K | 8.06K | 87.29K |
| 1,000 | 482.95K | 742.10M | 9.66M | 14.84B |
| 4,500 | 1.70B | 30.62Q | 33.98B | 612.38Q |

Display rounding aside, Tier 2 is 20 times Tier 1 on both axes at those waves.

### 4. Fandom wiki — system map, not formula authority

The supplied [The Tower wiki](https://the-tower-idle-tower-defense.fandom.com/wiki/The_Tower_-_Idle_Tower_Defense_Wiki) is most useful for understanding system roles, unlock order and player-facing terminology. Some indexed tier pages lag the current game, so do not treat the wiki as the formula source of truth.

Relevant system pages include [Tiers](https://the-tower-idle-tower-defense.fandom.com/wiki/Tiers), [Milestones](https://the-tower-idle-tower-defense.fandom.com/wiki/Milestones), [Workshop](https://the-tower-idle-tower-defense.fandom.com/wiki/Workshop), [Laboratory](https://the-tower-idle-tower-defense.fandom.com/wiki/Laboratory), [Cards](https://the-tower-idle-tower-defense.fandom.com/wiki/Cards), [Modules](https://the-tower-idle-tower-defense.fandom.com/wiki/Modules), [Perks](https://the-tower-idle-tower-defense.fandom.com/wiki/Perks), [Ultimate Weapons](https://the-tower-idle-tower-defense.fandom.com/wiki/Ultimate_Weapons), [Relics](https://the-tower-idle-tower-defense.fandom.com/wiki/Relics), [Events](https://the-tower-idle-tower-defense.fandom.com/wiki/Events) and [Tournaments](https://the-tower-idle-tower-defense.fandom.com/wiki/Tournaments).

## What The Tower's curve actually looks like

At a structural level, base enemy health is:

```text
floor(
  health_body(wave)
  × health_milestone_envelope(wave)
  × health_compound_growth(wave)
  × tier_pressure[tier]
  × context_modifiers
)
```

The early health body is approximately:

```text
0.05 × wave^2.13 + 0.8 × wave + 1.5
```

The envelope adds step terms at milestone intervals, and the compound chain applies additional powers at intervals such as 30, 60, 72, 83, 94, 100, 107, 200, 400, 900 and 1,024 waves. The source contains float-precise constants.

Damage is a separate calculation and never reads health. Its early body is approximately:

```text
0.021 × wave^2.007 + 0.16 × wave + 1.07
```

It has its own milestone chain and tier attenuation/branch behaviour. Enemy-type multipliers are applied after base wave stats; for example, the public SDK data gives Boss a 20-times health multiplier and 1-times damage, Tank 5-times health and 0.5-times damage, and Ray 1-times health and 2-times damage.

The reusable lesson is the architecture:

```text
wave body × milestone steps × compound growth × explicit tier table × modifiers
```

The exact Tower constants should remain research evidence, not become Number Go Up's identity.

## Campaign tier reference

The SDK's current campaign tables expose the following pressure and coin-reward multipliers. This table is a calibration reference, not a recommendation to ship all 24 tiers now.

| Tier | Pressure | Coin reward |
| ---: | ---: | ---: |
| 1 | 1 | 1.0 |
| 2 | 20 | 1.8 |
| 3 | 60 | 2.6 |
| 4 | 120 | 3.4 |
| 5 | 240 | 4.2 |
| 6 | 480 | 5.0 |
| 7 | 960 | 5.8 |
| 8 | 1,920 | 6.6 |
| 9 | 5,760 | 7.5 |
| 10 | 40,320 | 8.7 |
| 11 | 2,620,800 | 10.3 |
| 12 | 1,572,480,000 | 12.2 |
| 13 | 786,239,979,520 | 14.7 |
| 14 | 235,870,007,328,768 | 17.6 |
| 15 | about 7.0762e16 | 21.3 |
| 16 | about 3.5381e18 | 25.2 |
| 17 | about 1.0614e20 | 29.1 |
| 18 | about 2.6536e21 | 33.0 |
| 19 | about 3.4496e24 | 40.0 |
| 20 | about 4.1396e27 | 48.0 |
| 21 | about 4.9675e30 | 60.0 |
| 22 | about 5.9610e33 | 72.0 |
| 23 | about 7.1532e36 | 86.0 |
| 24 | about 8.5838e39 | 103.0 |

**Recommended tier decision: lock Tier 2 at 20-times Tier 1 liability and 20-times Tier 1 collection, with a much smaller reward step near 1.8-times.** This produces the intended intimidating jump without making Tier 2 automatically better farming. Note that 20-times both axes is not a mathematically defined “400-times difficulty”; the axes challenge different parts of the build.

For the first implementation, author only Tiers 1–3 and keep every later row out of the save/UI. A sensible research-shaped starting point is:

| Tier | Liability multiplier | Collection multiplier | Reward multiplier | Unlock |
| ---: | ---: | ---: | ---: | --- |
| 1 | 1 | 1 | 1.0 | default |
| 2 | 20 | 20 | 1.8 | clear Tier 1 wave 100 |
| 3 | 60 | 60 | 2.6 | clear Tier 2 wave 100 |

These are starting calibration values, not a promise that the final curve will feel good with Number Go Up's production model.

## Recommended Tax Encounter model

### Player-facing loop

1. A wave starts with an amount of Tax Liability and a Collection value.
2. Every unit produced still increases Number and also deals one unit of compliance damage to Liability. A later stat may change this ratio. *Superseded by [D012](DECISIONS.md): output applies to Liability first and only the overflow becomes Number; see [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).*
3. A wave has a minimum 15-second window, preserving the existing pacing.
4. If Liability reaches zero within the window, the wave clears at the boundary without a collection hit.
5. If Liability remains at the boundary, Tax collects its absolute Collection value from Number. The wave stays active for another collection interval.
6. Number at zero is death. Cleared Liability advances to the next wave and grants the wave reward.
7. Boss waves multiply liability, collection and reward independently.

This creates the equivalent of The Tower's two checks:

- production/compliance must beat liability;
- Number buffer and mitigation must survive collection.

It also keeps the core fantasy coherent: making Number go up is both offence and survival.

### Formula shape

Number Go Up should use its own simpler and inspectable curve:

```text
base_liability(w) = liability_body(w)
                    × product(liability_milestone_bumps(w))

base_collection(w) = collection_body(w)
                     × product(collection_milestone_bumps(w))

max_liability(t, w) = base_liability(w)
                      × tier[t].liability_multiplier
                      × active_rule_modifiers

collection(t, w) = base_collection(w)
                   × tier[t].collection_multiplier
                   × active_rule_modifiers

reward(t, w) = base_reward(w)
               × tier[t].reward_multiplier
               × active_reward_modifiers
```

Use explicit checkpoint multipliers for intentional difficulty beats instead of hiding all growth in one exponent. Evaluate and store large results as `ScientificNumber`, or calculate in log space and convert once; do not let balance formulas overflow ordinary floats.

### Implemented balance snapshot

The committed profile evaluator currently produces:

| Tier | Wave | Liability | Collection | Wave reward |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 21 | 238 | 156 | 14 |
| 1 | 50 boss | 5,276 | 1,493 | 163 |
| 1 | 100 boss | 55,475 | 12,251 | 325 |
| 2 | 21 | 4,764 | 3,121 | 25 |
| 2 | 100 boss | 1.11M | 245,016 | 585 |
| 3 | 21 | 14,293 | 9,364 | 35 |
| 3 | 100 boss | 3.33M | 735,049 | 845 |

These are `tax-foundation-v2` values: v1's Liability and Collection halved and pressured rewards ×0.65, retuned for D012. Before-and-after measurements are in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).

The deterministic first-run baseline in `tools/balance_simulator.gd` taps twice per second and buys the first affordable permanent Workshop upgrade in the standard order. With seed 7 it currently dies at Tier 1 wave 21 after 360 seconds with 48 Coins, enough to fund the first two Workshop ranks. The same tool's build matrix measures progressed builds on Tiers 1 and 2. This is a reproducible calibration baseline, not a claim that the balance is final.

### Data contracts to create before content

```text
BalanceProfile
  id
  schema_version
  liability_curve
  collection_curve
  reward_curve
  boss_profile
  tier_definitions[]

TierDefinition
  id
  liability_multiplier: ScientificNumber
  collection_multiplier: ScientificNumber
  reward_multiplier
  unlock_rule
  battle_conditions[]

TaxEncounter
  tier_id
  wave
  max_liability: ScientificNumber
  remaining_liability: ScientificNumber
  collection: ScientificNumber
  collection_interval
  elapsed
  phase

RunState
  status
  selected_tier
  wave
  active_encounter
  run_rewards
  deterministic_seed
  balance_profile_id

TierRecord
  tier_id
  highest_wave
  best_time
  milestones_claimed[]
```

Keep the formulas and tables in data/resources rather than as constants in `GameState`. An encounter service should resolve Tax; a run service should own start, retreat, death and rewards; `GameState` should coordinate them.

## Decisions that must be locked before implementation

### 1. Run exit, pause and offline behaviour

**Recommended decision: Tax runs cannot be paused while the same Number keeps growing. Leaving a run must either end it and bank the permitted rewards, or freeze the entire run state including production. Offline generation should not be injected into an active frozen run.**

A clean first rule is:

- voluntary retreat resets the run and banks earned Coins but gives reduced or no Knowledge;
- death resets the run and banks Coins plus earned Knowledge;
- app suspension freezes the active run exactly, with no active-run offline production;
- there is no Number production outside a run; the between-run state is for permanent progression choices.

### 2. Workshop permanence

The Tower's Workshop is a permanent baseline, while its in-run cash upgrades reset. Number Go Up now follows that boundary: the four Workshop bays use Coins between runs, their ranks survive every run ending, and every attempt starts from those upgraded production stats. Number exists only during an active run.

The former Autopilot/Priority Buffer cards conflicted with this boundary because they bought Workshop ranks during play. Their saved IDs are retained for migration, but their gameplay roles are now permanent Auto Crank production and Starting Reserve baseline. A later temporary in-run upgrade layer must have a distinct name, currency and reset contract.

### 3. Forced death and voluntary Prestige

**Recommended decision: Tax death and voluntary Prestige may share reset machinery, but they must have distinct reward policies and summaries.** A player-controlled reset should not become identical to losing, and loss should never destroy already-earned permanent currency.

### 4. Randomness and reproducibility

Run seeds and RNG state are persisted in save V4, so a saved active encounter resumes with identical random outcomes; fresh runs still seed from the clock.

**Decision: a run seed and all encounter-relevant random state are persisted before Perks, Cards, battle conditions or random offers are added.** That keeps saves reproducible and balance failures debuggable.

### 5. Rules and modifier stacking

**Recommended decision: all Laws, Violations, challenges, perks and tier battle conditions must enter through one ordered modifier pipeline.** Define additive, multiplicative and cap stages once. Do not implement each system as a special case inside `GameState`.

## Which Tower-like systems belong where

| Tower layer | Its job | Number Go Up interpretation | Timing |
| --- | --- | --- | --- |
| Waves, enemy health/damage | Core run pressure | Tax Liability and Collection | Foundation now |
| Tiers | Difficulty/reward choice | Explicit Tax tiers and records | Foundation now |
| Milestones | Unlock spine | Per-tier wave rewards and feature gates | Foundation now |
| Workshop | Permanent baseline | Permanent Coin-funded baseline, upgraded between runs | Implemented |
| Laboratory | Slow permanent research | Knowledge/Insight and later timed Research | Schema/hooks now, content later |
| Perks | Run-only choices | Breakthroughs or temporary tax deals | After Tiers 1–3 work |
| Cards/loadouts | Limited configurable power | Protocol/Routine loadout, preferably deterministic initially | After core balance |
| Battle conditions | Rule variations | Laws, Violations and challenges via modifier pipeline | Hooks now, content later |
| Modules | Random equipment with effects | Optional late equipment layer | Defer |
| Ultimate Weapons | Rare major build systems | Optional capstone automations | Defer |
| Relics/Bots | More permanent multipliers | Optional collection/meta bonuses | Defer |
| Events/Dailies/Tournaments | Retention/live operations | Only after the core run is fun and stable | Do not foundation-build yet |

The Tower also has many currencies for these layers: cash, coins, gems, stones, medals, keys and module shards. Number Go Up should not import that currency count. Number, Coins and Knowledge are sufficient for the first tiered version.

## Implementation sequence

1. Kept baseline commit `5e4b499` as the pre-migration reference and updated the README.
2. Added `TaxBalanceProfile`, three `TierDefinition` records and per-tier records.
3. Implemented balance evaluation in log space before conversion to `ScientificNumber`.
4. Added the modifier pipeline and stacking-order tests.
5. Implemented `TaxEncounter` separately from `GameState`.
6. Added explicit active/outside run state, distinct retreat/death outcomes and resumable active encounters.
7. Replaced pause-and-grow with retreat-as-reset, exact active-run freezing and no between-run Number generation.
8. Added tier selection, Tier 1–3 unlocks and milestones.
9. Converted Workshop ranks into permanent, between-run Coin purchases and made every run start from that baseline.
10. Added save V4 and V1/V2/V3 migration while preserving Workshop ranks and declared permanent progress.
11. Deferred temporary in-run upgrades, perks, challenge/Law content and loadouts until the three-tier balance is playtested.

## Balance and regression gates

Before calling the foundation locked, automated tests should prove:

- golden liability, collection and reward values at waves 1, 20, 21, 50 and 100 for Tiers 1–3;
- Tier 2 is exactly 20 times Tier 1 on liability and collection at every checked wave;
- curves are monotonic except for explicitly documented mechanics;
- all calculated values remain finite and non-negative at very high waves;
- a stronger production build survives or clears farther than a weaker one;
- spending Number can create a real survival trade-off;
- boss multipliers and modifier stacking apply once and in the documented order;
- retreat, death, app suspension and offline return cannot pause Tax while growing the same run;
- a saved active encounter resumes identically, including RNG outcomes;
- per-tier records and milestones cannot be claimed twice;
- migration preserves Coins, Knowledge, Insights and other declared permanent progress;
- a headless balance simulator can print time-to-clear, hits-survived, expected death wave and reward rate for representative builds.

## Source and originality boundary

The Tower data is useful for validating the desired shape: two combat axes, explicit tier cliffs, milestone growth and smaller reward multipliers. Number Go Up should author its own coefficients, labels, pacing and system content. If wiki text or tables are copied rather than summarized, comply with Fandom's attribution and CC BY-SA terms. TheTowerSDK is MIT-licensed, but its reverse-engineered values should still be treated as a version-sensitive research reference rather than copied wholesale into the shipped game.

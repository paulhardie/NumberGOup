# Tower scaling research and Number Go Up foundation

Status: researched and implemented as foundation profile `tax-foundation-v1`, retuned to `tax-foundation-v2` for D012, `tax-foundation-v3` for Tier 1's opening (D034), and `tax-foundation-v4` for lower warm-up Wave HP and idle-safe Hit growth (D036), 22 September 2026. The encounter rules changed with D037 (the Number always rises; missed waves move on; bosses stay) under `tax-foundation-v5`, with the curves unchanged. D040 (`tax-foundation-v7`) replaced Tier 1's warm-up with one curve from wave 1 and made each Hit a share of its wave's HP.

**Reading guide (23 September 2026):** This page retains the research and implementation history. Its “baseline audited”, “recommended” and “implementation sequence” sections are historical, not pending instructions. For a dated comparison of Tower scaling with the current game, source confidence and closeness ratings, use the scaling chapter in [`TOWER_SYSTEMS_REFERENCE.md`](TOWER_SYSTEMS_REFERENCE.md). The live Number Go Up formula authority is [`TaxBalanceProfile`](../src/tax_balance_profile.gd), with encounter resolution in [`GameState`](../src/game_state.gd). Tower SDK formulas and tier tables here are unofficial, version-sensitive research evidence: its [documented parity check](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/waves/base-empirical-scaling.ts) covered 21 tiers in August 2026, while the [developer's v28.3 notes](https://www.techtreegames.com/post/v28-3-patch-notes) added Tiers 22–24. Do not treat the early-body examples or full table below as independently verified v29 constants. The live Wave HP body uses the same written polynomial terms as the early SDK example below, with a ×4 scale; the provenance of those terms needs review under D009 before claiming independent coefficients.

## Implemented foundation

The first complete slice now includes:

- absolute Liability and Collection encounters;
- original wave curves with milestone growth and separate boss multipliers;
- Tiers 1–3 with 1×/20×/60× pressure and 1×/1.8×/2.6× rewards;
- Tier 1's 20-wave onboarding warm-up (a ramp from small waves since D033, originally a grace with no pressure), with immediate pressure in Tiers 2–3; *replaced by one curve from wave 1 in D040 (`tax-foundation-v7`), with Hits a share of their wave's HP;*
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

### 1. TheTowerSDK — strongest public reconstruction reviewed

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

## Tier 1, wave by wave, against ours — 24 September 2026

Computed from TheTowerSDK 0.11.0 (npm, released 13 September 2026): `computeWaveBaseHealthRaw` and `computeWaveBaseDamage` for a basic enemy (the game floors health; wave 1's 2.35 shows as 2), and `killsPerWaveFromSpawnContext` for enemies per wave, with no Wave Accelerator and no Enemy Balance. The enemy counts are the SDK's spawn model, not a counted run. "Our" columns are today's profile (`tax-foundation-v11`): wave HP and Hit shared evenly across the wave's members. The ratio columns (an enemy's health divided by its damage) are the scale-free comparison: they don't depend on how big the player's numbers are.

| Wave | Tower enemy HP | Tower enemy damage | Tower HP ÷ damage | Tower enemies | Tower wave HP (all enemies) | Our enemy HP | Our enemy Hit | Our HP ÷ Hit | Our enemies | Our wave HP |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 2.35 | 1 | 2.4 | 3.3 | 7.6 | 3.1 | 0.84 | 3.7 | 3 | 9.4 |
| 10 | 18 | 4 | 4.6 | 3.3 | 60 | 23 | 9.2 | 2.5 | 3 | 70 |
| 20 | 59 | 13 | 4.6 | 3.3 | 193 | 55 | 26 | 2.1 | 4 | 219 |
| 30 | 143 | 28 | 5.1 | 3.3 | 466 | 96 | 49 | 2.0 | 5 | 481 |
| 50 | 477 | 81 | 5.9 | 3.3 | 1,552 | 251 | 136 | 1.9 | 7 | 1,759 |
| 75 | 1,546 | 197 | 7.8 | 6.5 | 10,051 | 507 | 281 | 1.8 | 9 | 4,562 |
| 100 | 4,365 | 402 | 10.9 | 9.8 | 42,556 | 1,541 | 865 | 1.8 | 12 | 18,492 |
| 150 | 17,185 | 1,103 | 15.6 | 16.3 | 279,262 | 4,686 | 2,649 | 1.8 | 16 | 74,969 |
| 200 | 54,839 | 2,423 | 22.6 | 22.8 | 1.25e6 | 18,024 | 10,197 | 1.8 | 20 | 360,471 |
| 300 | 323,610 | 7,737 | 41.8 | 32.5 | 1.05e7 | 196,475 | 110,827 | 1.8 | 20 | 3.93e6 |
| 500 | 4.53e6 | 38,941 | 116 | 58.5 | 2.65e8 | 1.25e7 | 7.02e6 | 1.8 | 20 | 2.51e8 |
| 1,000 | 7.42e8 | 482,947 | 1,537 | 120 | 8.92e10 | 1.20e11 | 6.61e10 | 1.8 | 20 | 2.40e12 |

Other Tier 1 facts from the same source: a boss comes every 10 waves with 20 times a basic enemy's health and **the same damage as a basic**; a wave's combat lasts 26 seconds with about 8.7 seconds between waves; the mix is 91% basic and 3% each fast, tank and ranged at every wave; tank is 5× health and half damage, and ray is double damage. The SDK has no enemy attack interval.

**What a fresh Tower save starts with** (owner's new save, 24 September 2026): Damage 3, Attack Speed 1.00, Critical Chance 1%, Critical Factor ×1.20, Health 5 and Health Regen 0/sec. Damage, Attack Speed, Health and Health Regen cost 30 Coins a rank and the two crit rows 50. Range unlocks for 50 Coins and the next Defense set for 75. So a wave-1 enemy dies to one shot and takes five hits to kill the tower. The owner sees basic enemies pay $1 Cash and no Coins, with Coins coming from fast enemies and tougher. The SDK's coin model instead pays every kill `wave × type weight` (basic 1, fast and ranged 2, tank 4). Take the owner's play as the evidence for the current game.

**What the owner's game shows (24 September 2026, Tier 1, a new save), which outranks the SDK where they differ:**

- **Wave 22 Wave Info:** basic Health 63.11 and Attack 15.90; tank 315.56 (5×) and boss 1.26K (20×), both at the same 15.90 Attack; mix 85% basic, 7% fast, 6% tank, 2% ranged; Wave Timer 26 s, Wave Cooldown 9 s; Active Enemies 16 (spawn rate 15). The SDK matches the Attack (its 15 is 15.90 floored) and the multipliers, but its health is about 10% higher (69.64), its mix is 91/3/3/3, and its model counts about 3 enemies a wave. **The Tower sends far more enemies per wave than the SDK's model says,** which makes its wave totals several times the table above.
- **Battle report at wave 22:** 12 m 33 s game time (about 34 s a wave), 7 m 49 s real time at ×1.5 speed, 1.46K Coins (11.25K an hour), and 16.94K damage, all from projectiles.
- **Wave 21, mid-run build:** Damage 93, Health 118, Health Regen 1.29/s, Defense 2%, **Defense Absolute 19.76 against an enemy Attack of 14.75**, and Thorn 4%. The owner: "def absolute on tier 1 is the first 'yeah, I've stopped dying quickly' moment". Flat defence taken off each enemy's hit outgrows early enemy damage, so the swarm stops hurting and the danger moves to reaching the next wall.

**Enemy types and Coins (owner's reference table, 24 September 2026, attributed to Tower Hub):** base Coins per kill are basic 0, fast 2, ranged 3, tank 4, boss 5 and protector 1; basic enemies pay Coins only through the Critical Coin card or coin masteries. That matches the owner's play (basics pay $1 Cash and no Coins). The SDK instead gives basic 1 and ranged 2. **The table's health multipliers are contradicted by the owner's wave 22 screen and the SDK,** which agree on fast 1×, ranged 1×, tank 5× and protector 0.6×, where the table says 0.5×, 0.5×, 4× and about 2×; use the screen. Bosses come every 10 waves, don't die on impact, and resist one-shot effects; protectors project a damage-reduction aura and cancel instant kills. Ranged, vampire and ray enemies attack from outside the tower (projectile, draining beam, charged burst). Every enemy's repeated hits heat up by 4% compounding (SDK `ENEMY_HEAT_UP_MULTIPLIER_PER_HIT`).

**What this says about our curve:**

1. **Wave HP matches through about wave 60, then falls behind, then overshoots.** Our LIABILITY_SCALE of 4 stands in for The Tower's three to four enemies, so the opening matches. The Tower then adds enemies faster than we do and multiplies its HP by them, where we divide ours: its wave holds 2.3 times our HP at wave 100 and 3.5 times at 200. From about wave 500 our milestone chain (×1.08 every 10 waves compounding) passes its compound chain, and at wave 1,000 we are 27 times higher.
2. **Our enemies hit far harder than The Tower's, relative to their health, and the gap widens.** The Tower's enemies get tankier relative to their damage every wave (health ÷ damage goes from 2.4 at wave 1 to 11 at 100, 42 at 300 and over 1,500 at 1,000), so its long run is a damage wall. Ours holds at 1.8 from wave 60 onwards, so Defense demand keeps pace with Attack demand forever. At wave 100 our enemy has about a third of a Tower enemy's health and twice its damage; at 200, a third and four times.
3. **Our bosses hit like a whole wave.** A Tower boss is a wall of health that hits like one basic. Ours carries three times the wave's HP and 1.5 times its whole Hit, which is about 18 enemies' worth of Hit at wave 100.
4. **The pile makes point 2 matter more.** Since D058, enemies at the Number keep hitting, and they land most of the damage from mid builds on (the [Workshop audit](WORKSHOP_EXPANSION.md#workshop-audit-against-groups-and-the-pile--proposed-24-september-2026)). A Hit curve on The Tower's shape would shrink each pile hit rather than the pile itself.

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
2. Every unit produced still increases Number and also deals one unit of compliance damage to Liability. A later stat may change this ratio. *Superseded by [D012](DECISIONS.md) (output applied to Liability first), then restored by [D037](DECISIONS.md) (23 September 2026); see [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).*
3. A wave has a minimum 15-second window, preserving the existing pacing. *Since D037 a beaten wave gives way after a 2.5-second beat; 15 seconds is the time allowed to clear it.*
4. If Liability reaches zero within the window, the wave clears at the boundary without a collection hit.
5. If Liability remains at the boundary, Tax collects its absolute Collection value from Number. The wave stays active for another collection interval. *Since D037 only bosses stay; an ordinary wave hits once and moves on, paying Coins for the share cleared.*
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
| 1 | 21 | 238 | 113 | 14 |
| 1 | 50 boss | 5,276 | 1,583 | 163 |
| 1 | 100 boss | 55,475 | 16,643 | 325 |
| 2 | 21 | 4,764 | 2,267 | 25 |
| 2 | 100 boss | 1.11M | 332,852 | 585 |
| 3 | 21 | 14,293 | 6,801 | 35 |
| 3 | 100 boss | 3.33M | 998,556 | 845 |

These are `tax-foundation-v7` values (D040). Liability keeps the v2 curve (v1 halved for D012) and now applies from wave 1 on every tier. Collection is no longer a separate curve: a Hit is a share of its wave's HP, 20% at wave 1 rising to 60% by wave 30, ×1.5 on bosses. Tier 1's warm-up and its wave 21–25 Hit ramp are gone. `run_balance.sh` prints the Tier 1 curve at sample waves. Before-and-after measurements are in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).

The deterministic first-run baseline in `tools/balance_simulator.gd` taps twice per second and buys permanent Workshop upgrades in its standard order after the run. With seed 7 it dies at the Tier 1 wave 20 boss after 338 seconds with 106 Coins (D040). The simulator's build matrix also compares two fixed builds bought from the former 48-Coin opening budget; those rows remain a D035 pricing comparison, not the current first-run spend. This is a reproducible calibration baseline, not a claim that the balance is final.

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

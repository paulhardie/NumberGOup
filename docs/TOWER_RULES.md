# The Tower's run rules, checked

**Status:** research, 28 September 2026, done at the owner's request before 1.1: "find all the relevant information we need for the game… we don't start 1.1 until everything else that needs built is built" (D116). The same day, D115 (#104) built the Protector, the elites, coin decay, ageing enemies, the tier speed-up, the boss cap and Wave Info; the marks below include it. This page holds what The Tower does in a run, how sure we are, and where our game differs. Its last section is the build list that stands between us and 1.1.

**How to read it.** Each rule is marked:
- **Built**: our game already does it.
- **Gap**: The Tower does it and we don't. It's on the build list.
- **Ours**: we differ on purpose (a recorded decision), or a guess still stands.
- **Unknown**: no source settles it; the owner's screen would.

## Sources, and how far to trust them

| Source | What it is | Trust |
|---|---|---|
| **SDK**: [TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) `main` at `da19fef` (0.11.0, 13 September 2026), MIT | Game mechanics mapped from the game's own code (v28.3–v29): method names, constants and field layouts. Its knowledge notes say which claims come from the code, a save, the wiki or players | Highest where it cites the game's code. It has **no real data for spawn rates below wave 1,000** (it draws a line to 37), and it can't see values the game keeps in its scene files (the base fast and ranged chances) |
| **Wiki**: [the community wiki](https://the-tower-idle-tower-defense.fandom.com/), read through its API on 28 September 2026 | Player-maintained rules and tables: enemies, milestones, labs, cards, tiers | Good for tables and unlock waves; can lag the game |
| **Patch notes**: the developer's, as the SDK collected them | When rules changed | High, for what changed and roughly when |
| **The owner's screens** (24–28 September) | Wave Info and battle reports from a new save | Highest, where they exist. They outrank the SDK (REBUILD_SPEC rule 1) |

## 1. Waves and spawning

| Rule | The Tower | Us | Mark |
|---|---|---|---|
| Wave timing | 26 s of spawning, then a cooldown of about 9 s (the SDK's 8.7 s; the wiki and the owner's screen say 9). Cash / Wave pays after the cooldown | Same, from the SDK | Built |
| What a wave fixes when it starts | Health, attack, rewards, spawn chances and when any special spawn lands are all set once as a wave starts, not per enemy (SDK, `NewWave`) | Same: `_schedule_wave` rolls the wave, and enemies take the wave's level | Built |
| Spawn rolls | Every 0.125 s of the spawning window the game rolls against the wave's spawn rate (0–100), plus a double-spawn chance of 5 + tier ÷ 2.85 | Same (D113, D114) | Built |
| **Enemies per successful roll** | The SDK reads the game's code as three spawn sites per roll: one enemy for sure, a second 80% of the time, and a third only under a battle condition. That makes **about 1.86 enemies per successful roll** | About 1.06 per roll (D114), because the owner's wave-22 battle report dealt about as much damage as that many enemies hold. The SDK's reading would need nearly twice the damage | **Conflict.** D114 stands until a wave's enemies are counted in the game |
| **Spawn rate below wave 1,000** | The only reading is the owner's: 15 at wave 22. Patch notes say the rate "grows" in steps (tournaments above wave 50; every tier above wave 3,000). From 1,000: the SDK's chart, 37 up to 56 at 6,500 | Our 5 at wave 1, straight lines to 15 at 22 and 37 at 1,000 | **Unknown.** The biggest open wave number |
| **Type mix by wave** | The game rewrites the tank and protector chances every wave, and the base fast and ranged chances live in its scene files, so the SDK can't recover them. Evidence the mix grows with the wave: the SDK's wave-1 panel shows about 3/3/3, the owner's wave 22 shows 7/6/2, and a measured Tier 21 round (waves 600–4,875) killed about 20% basic, 28% fast, 27% tank and 25% ranged. The wiki: "the spawn rates and chance for non-basic enemies increase with each wave" | The owner's wave-22 mix (85/7/6/2) at every wave | **Gap and unknown.** Early waves get too many specials and later waves far too few. Needs Wave Info readings |
| Enemy caps | 150 on the field: 120 normal, 20 elite and 10 boss. Protectors at most 10; each elite type at most 8 | Same (D115) | Built |
| Boss waves | Every 10th wave, one boss (more from Tier 14). Tier 7+ bosses land at a random 5–75% of the wave; Tiers 1–6 at a fixed moment the sources don't give | A boss at the start of the wave | Built; the timing is **unknown** |
| Wave skip, Wave Accelerator, Intro Sprint | Cards and labs. A wave skip can't skip a boss wave | — | Later (1.1+) |

## 2. Enemies

### Stats by wave

| Rule | The Tower | Us | Mark |
|---|---|---|---|
| Health and attack curves | Separate curves for health and attack. The SDK claims exact equality with the game's constants across 21 tiers | The SDK's curves; attack unrounded (it matches the owner's screens exactly); health × 0.9953 per wave, fitted to the owner's screens up to wave 22 | Built. **The health drift is unexplained**: the SDK claims to be exact, yet it runs 10% high at wave 22. A reading at wave 30 or 50 tells us whether the drift keeps going |
| Heat-up | **Settled: each hit an enemy lands makes its next hit ×1.04**, compounding. The game's `Enemy$$Attack` does damage × 1.04^attacks (SDK, from the code; the wiki and FAQ agree). Hits on the Wall count too | Same, from the generated data (D116) | Built. The "per wave survived" research was wrong |
| Boss health past wave 100 | 20× a basic's. The SDK names a step (×1.2 from wave 100, and more later) and flags the boss for it, but its own Wave Info never applies it; it's most likely the Boss's Ultimate battle condition (Tier 20+), not a base rule | 20× at every wave | Built. A reading of a wave-100 boss would confirm it |
| Enemy speed | Rises from wave 100 (+0.03% a wave), with steps at 141 (×1.129) and 678 (×1.324), capped at 12×. Each tier also multiplies speed by its spawn weight (×1.04 in Tier 2, ×1.08 in Tier 3) | Same (D115) | Built |
| Enemy mass | Each enemy's mass grows 4% for every wave it stays alive (patch notes, August 2025), so knockback weakens against old enemies. Separately, the wave's base mass grows only above wave 4,000 | Same (D115) | Built |
| Coin decay | An enemy alive for more than three waves pays half its Coins (wiki; the SDK's kill payout has a `LivedWavesCoins` factor) | Same (D115) | Built |
| Speed and mass by type | Fast ×2.3, tank and boss ×0.34, ranged ×0.56 speed; mass basic 21.2, tank 102.7, boss 261.9 (SDK Wave Info) | Same | Built |

### Enemy types

| Type | The Tower | When it appears | Us |
|---|---|---|---|
| Basic | 1× health, 1× attack, 0 Coins | Always | Built |
| Fast | 1× health, 1× attack, ×2.3 speed, 2 Coins | Always | Built |
| Tank | 5× health, ½ attack, 4 Coins | Always | Built |
| Ranged | 1×, 1×, 2 Coins. Fires projectiles from range (patch notes added a visible shooting line); its projectiles don't hit Protectors. A lab (Tier 13) shortens its range | Always | Built, but its hits land instantly and its hit rate is our guess |
| Boss | 20× health (growing past wave 100, above), 1× attack, ×0.34 speed, 5 Coins. Immune to orbs, shockwave, Death Ray and Black Hole; **knockback does move it**, reduced by its mass. Takes half of Thorns | Every 10th wave | Built, except its growth past wave 100 |
| Protector | 0.6× health, basic attack, 3 Coins. Enemies in its radius take 60% less damage (×0.6, set as the wave starts, not stacking), can't be killed instantly by orbs or Death Ray, and take 60% less Thorns. Its spawn chance steps up at waves 80, 160, 320 and 751, with a counter between spawns | **Tier 2 and up only** (the SDK returns 0 in Tier 1), from wave 80 | Built (D115) |
| Vampire (elite) | 2× health. Drains 2% of the tower's max health a second, which no perk or defence changes, and switches off regen and lifesteal while it drains (not Wall regen). High knockback resistance. 4 Coins | Elite, from Tier 1 wave 500 (below) | Built (D115) |
| Ray (elite) | 1× health. Charges for 30 s, then fires for 2× a basic's attack. Immune to knockback. 4 Coins | Elite, as above | Built (D115); truly immune to Knockback since D117 |
| Scatter (elite) | 2× health, half attack. Splits in two when killed, four times over, each child with half the health; the children don't count towards the elite cap. High knockback resistance. 4 Coins | Elite, as above | Built (D115) |
| Saboteur, Commander, Overcharge (fleets) | 20× health; they disable Ultimate Weapons, buff nearby enemies, and fire returning shots that hit harder each time. Immune to orbs, shockwave and knockback; take 85% less Thorns | Tier 14+, and **Tier 1 only from wave 15,000** (past our data) | Out of reach; not needed |

**Elites in Tier 1.** Elites are immune to orbs, shockwave, Death Ray and Black Hole, and drop Elite Cells, a currency we don't have. Each wave has a chance of an elite, of one of the three types, which rises with the wave. In Tier 1 it's 0.33% from wave 500, 1.33% from 1,000, 3% from 1,500, 5.3% from 2,000, 8.3% from 3,000, 12% from 4,000, 16.3% from 5,000, 21.3% from 6,000, 27% from 7,000 and 33% from 8,000; a second elite a wave only from 8,000. Each tier after starts them 10% sooner (the wiki's table, which the SDK reproduces from two rules).

**Built in D115.** A maxed Workshop still never dies against them (D115's measurements); they matter to a realistic Workshop deep in Tier 1.

## 3. The tower and its defences

| Rule | The Tower | Us | Mark |
|---|---|---|---|
| Firing | Shots come from a timer that fires every 1 ÷ attack speed seconds and keeps the leftover; a long frame fires several at once (at most 1,000). Crit is rolled when a shot leaves; bounces are chosen where it hits | Same shape | Built |
| **Shot speed** | Attack speed also speeds up how fast shots travel, until the Light Speed Shots lab (Tier 7) makes them instant | A fixed 80 m/s | **Gap**, but no source says how much faster, so it waits for a reading or a chosen guess |
| Targeting | Nearest by default. Target Priority (a lab from Tier 4) can pick a type | Nearest | Built |
| Defense % and Absolute | % first (capped at 98% from every source), then Absolute, down to zero | Same | Built |
| Thorns | A share of the attacker's max health on every hit, **ranged hits included**, even when the hit does no damage. Half on bosses. Doesn't trigger lifesteal. Capped at 99% | Same | Built |
| Lifesteal and regen | Heal up to max health only; **only Recovery Packages go past it** | Past Health on purpose: regen up to the run's best, lifesteal in full (D083, D111) | Ours |
| Knockback | Pushes away from the tower, never towards it. Force over mass, no documented unit; since v24 it's an impulse the enemy carries rather than a jump | A jump of force × 5 m over the mass ratio | Built as a guess |
| Orbs | At least 60 m out; they move further out as Range grows, but less than one-for-one (at most 4 from the Workshop). Instantly kill everything but bosses, elites and Protector-shielded enemies. Speed is in turns a minute | Same (D108) | Built, elites and Protector shields included (D115) |
| Shockwave | Every Frequency seconds (floor 7 s from every source) pushes enemies away; never bosses or elites. The SDK has a pulse-damage formula (Workshop damage plus a level term), so it may also deal damage | Pushes enemies within Range, never bosses or elites; no damage | Built; its reach and any damage are **unknown** |
| Land mines | The wiki says enemies "drop" them by Land Mine Chance. Damage is Land Mine Damage × Damage × (1 + crit factor × crit chance) × (1 + super crit mult × super crit chance × crit chance), so the average crit is built in. A mine explodes by itself after a set time (the Land Mine Decay lab lengthens it) | The same damage (D116); a volley lays one in range, and mines never expire | Built for damage; how they're laid and their lifetime are **unknown** |
| Death Defy | A killing hit may be ignored, by chance. It's first in the order of things that save the tower | Same | Built |
| **The Wall** | Stops enemies until it falls; doesn't stop them while rebuilding. **While the Wall stands, the tower takes no damage from anything but Vampires** (patch notes, December 2025). **Rebuilding pushes every enemy out from the tower.** Rebuild floor 150 s from every source. Wall Regen, Thorns, Invincibility and Fortification are labs (Tier 8+) | Same (D116) | Built |
| Recovery Packages | By chance each wave, a package spawns and heals a share of max health at once, up to Max Recovery × Health; packages don't reach bosses | At the wave's end | Built; the timing is **unknown** |
| Free Upgrades | A chance each wave for each tab; never a maxed row. Over 100% gives a chance of a second | Same (it can't pass 49.5% yet) | Built |
| Enemy Level Skip | Deterministic since V26: its share of waves, evenly spread | Same | Built |
| Interest | (Cash + Cash / Wave × Cash Bonus) × Interest, up to $50 until the Max Interest lab | Same | Built |
| Hard caps | Defense % 98%, Thorns 99%, Wall Rebuild 150 s, Shockwave 7 s; game speed ×6.25 at most | Only the Workshop's own maximums matter yet | Built for now |

## 4. Economy

| Rule | The Tower | Us | Mark |
|---|---|---|---|
| **Cash per kill** | $1, plus $1 every 10 waves **up to wave 200, then $1 every 20 waves** ($21 at 200, $24 at 260). Then × Cash Bonus × Golden Tower × Enemy Balance (SDK's kill chain) | The same by wave (D116), times a type weight (fast and ranged 2, tank 5, boss 20; D071) | Built by wave. The type weights aren't confirmed by any source: **unknown** |
| Cash and tiers | No source says whether a tier multiplies Cash | Not multiplied (D071 assumed it would be) | **Unknown** |
| Coins per kill | By type: fast 2, ranged 2, tank 4, boss 5, protector 3, elites 4; basics pay nothing without a card. Times Coins / Kill Bonus × the tier bonus × every other bonus, all multiplied together, and ×0.5 for an enemy alive more than 3 waves | Flat by type × Coins / Kill × tier (D074); no decay | Built |
| Coins / Wave | A flat 1–150 a wave, × the tier bonus | Same | Built |
| Other Coin sources | Daily Missions, and wave milestones (below) | Our Number milestones (D107) | **Gap** (milestones); Missions is open decision 9 |
| **Gems** | Cards (20 each), card slots (50 to 10,000), lab slots (100 to 3,000), rushing labs and Modules. Free sources: milestones (**235 Gems across Tier 1's milestones**), floating gems in a run (2 each, at most 10 a run, about every 400–500 waves and never more than once in 15 minutes), plus ads, daily gifts, missions and events, which we don't have | None | Comes with 1.1. **Without ads or a store, a player earns very few Gems**, which 1.1's design has to answer |

## 5. Progression

**Tier 1's milestones: The Tower's unlock order.** Reaching a wave in a tier pays once (the free track; the paid one is left out):

| Tier 1 wave | Reward | Tier 2 wave | Reward |
|---|---|---|---|
| 10 | 10 Coins | 10 | 250 Coins |
| 20 | 10 Gems (the first card) | 20 | Buy Multiplier |
| 30 | **Labs** (the first lab slot is free; labs open with Game Speed, Starting Cash, Max Interest and others) | 30 | Range lab |
| 40 | 150 Coins | 40–60 | Workshop Attack, Defense and Utility Discount labs |
| 50 | 15 Gems | 80 | Interest and Max Interest labs |
| 60, 70 | Tournaments, Events | 90 | Modules |
| 80 | 1,500 Coins | 100 | Tier 3 |
| 90 | 20 Gems | 150 | Unlock Perks |
| 100 | **Tier 2** | 250 | First Perk Choice |
| 150 | Lab Speed lab | | |
| 200, 300, 500+ | 20–30 Gems each | | |
| 250 | More Round Stats | | |

- **Tiers:** the next opens at wave 100 of the one before (300 from Tier 16). Coin bonus by tier: 1.0, 1.8, 2.6, 3.4, 4.2, 5.0, 5.8, 6.6, 7.5, 8.7, 10.3, 12.2, 14.7, rising to 103 at Tier 24 (the table in [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md#campaign-tier-reference)). Tier battle conditions start at Tier 14.
- **Labs:** up to five slots (the first free at Tier 1 wave 30, then 100, 400, 1,400 and 3,000 Gems). Each research costs Coins and real time, and runs while the game is closed. Rushing costs Gems.
- **Cards:** 20 Gems a pull (80% common, 17% rare, 3% epic), seven levels by duplicates, and slots bought with Gems. Some cards open only at milestones.
- **Perks:** chosen during a run every 200 waves, once the Tier 2 wave-150 milestone and its lab are done.
- **Game speed:** a Lab from Tier 1 wave 30, ×2.0 to ×5.0 over seven levels; the stated ×5 plays like about ×4. What a fresh save allows before that isn't recorded (the owner's report was at ×1.5 on a paid account).
- **Buy Multiplier:** The Tower opens it at Tier 2 wave 20; we have had it from the start (D076).

## 6. Readings the owner can take in The Tower

Each replaces a guess or settles a conflict above. Wave Info (tap the wave counter) shows most of them.

1. **Spawn rate at waves 1, 50 and 100.** Replaces our straight lines.
2. **The spawn chances (the type mix) at waves 1, 50 and 100.** Settles whether and how the mix grows.
3. **A basic enemy's health at wave 30 or 50.** Says whether the health drift keeps going.
4. **How many enemies one wave sends** (count wave 1, or read kills off a battle report). Settles 1.06 against 1.86 enemies a roll.
5. **The Cash a boss, a fast and a tank enemy pay** (the floating number on a kill). Settles D071's type weights.
6. **A boss's health on Wave Info at wave 100.** 20× a basic's confirms the SDK's step isn't a base rule.
7. **When in the wave a Tier 1 boss appears.**
8. **The game-speed choices a fresh save has.**

## 7. Before 1.1: the build list

In order. Economy and enemy changes go through QUALITY_GATES' high-risk gate (the owner hasn't approved the lighter process), so each is its own change with fixtures, measurements and a review.

| # | What | Why | Size |
|---|---|---|---|
| 1 | ~~**Correct the rules we have**~~: **done** (D116): Cash per kill slowing past wave 200; the Wall shielding the Number from everything but Vampires, and pushing enemies out when it rebuilds; average crit in land-mine damage; heat-up in the generated data | Known Tower rules we got wrong | Done |
| 2 | **Take the readings in section 6** (owner) | Replaces the biggest guesses (spawn rate, mix, health drift, enemies per roll) before tuning anything on top of them | The owner's time |
| 3 | **Apply the readings:** spawn rate, a type mix that changes by wave, and the health drift. This is the importer and data, then re-measuring the benchmarks | The wave engine's two big unknowns | Medium |
| 4 | ~~**Factor enemy behaviour out of `BattleSim`**~~: **done** (D117): `enemy_kinds.gd` says what each kind is, `battle_spawns.gd` which enemies each wave sends | The next enemy lands in its own place | Done |
| 5 | **A single place where stat effects stack.** The Tower's stats are products of layers, for example Damage = Workshop × Lab × Card × (1 + relics) × …, and Attack Speed = (Workshop × Lab × Card + module) × Enhancement | Cards (1.1) and Labs (1.2) both need it, and building it first keeps them from each inventing one | Medium |
| 6 | **Wave milestones per tier:** claimed once, paying The Tower's Coins now and its Gems when they exist, and holding the unlock spine (Labs at Tier 1 wave 30, Tier 2 at wave 100) | 1.1 and 1.2 open from it; our Number milestones (D107) sit beside it | Medium; **a decision** |

Done already, by D115: elites in Tier 1 from wave 500, the Protector, coin decay, ageing enemies, the tier speed-up, the boss cap, and Wave Info.

**Not before 1.1** (their own versions): tier selection and opening Tier 2 (1.4); game speed as a Lab and a clock that runs while the game is closed (1.2); Perks (after Tier 2); fleets (Tier 14, and Tier 1 wave 15,000); tier battle conditions (Tier 14); Modules, Bots, Guardians, Relics, the Vault, Enhancements, Tournaments, Events and Guilds.

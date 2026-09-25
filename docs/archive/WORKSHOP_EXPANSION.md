# Workshop expansion

**Superseded by [D068](../DECISIONS.md#d068--the-towers-workshop-in-full-around-the-number) (25 September 2026):** the Workshop is now The Tower's own rows, prices and unlocks, so the rows, gates and ladders proposed here no longer apply. Kept as history.

**Status:** Proposed, 23 September 2026. The [Tower parity plan and coin gates](#tower-parity-plan-and-coin-gates--proposed-23-september-2026) below is the newer proposal and says which of the earlier rows survive. Step 1 (the core rules, with Leech and Thorns) is accepted and built as [D037](../DECISIONS.md) and [D038](../DECISIONS.md); everything else here is still proposed. It follows the owner's direction that the Workshop should be fleshed out rather than cut, and that the difficulty curve should be solved by investment in it. Each row below needs its decision recorded in [`DECISIONS.md`](../DECISIONS.md) before it is built.
**Scope:** the permanent Workshop's Attack, Defense and Utility rows: what each existing row does under the proposed core rules, eight new rows, and how the Workshop keeps scaling across tiers. Ultimates stay as [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md#ultimates--rare-powerful-earned) describes them.
**Ladders:** rank depth, cost curves and stat curves for every row, with JSON and tables, are in [`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md).
**Depends on:** the core-rule change below, which is itself proposed. [`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md) covers the tier ladder and the percentage Boosts (the Rig) this document assumes.

## Workshop audit against groups and the pile — proposed, 24 September 2026

**Status:** proposed; **superseded in part by D063** (24 September 2026). The owner's standing rule is now "if in doubt, copy the way the tower does it", so the invented set below (Burst splash, Multishot to a second enemy) should give way to The Tower's own group rows (Multishot targets, Bounce Shot, Orbs, Knockback) once enemies can be held back; the Boss Damage and Leech fix is built in D063. The measurements still stand. This is the first step of the owner's priority: redo the Workshop for fighting multiple enemies before any more balance work. It audits every row as the game plays now (D057–D059: damage strikes only the front enemy, damage beyond its HP is lost, and from wave 31 survivors stay and carry into the next wave), then proposes the smallest set of changes. It supersedes nothing below; the older proposals remain candidates.

### What the measurements say

A throwaway probe (deleted afterwards) played six seeds per build at two taps a second with no run Upgrades, recording each run's end wave, where each Hit came from, and how much damage came off enemies compared with what was fired. The candidate changes were then built as switches in a scratch copy of the game and measured the same way. Its baselines run slightly below the handover's six-seed table (fresh 20 against 22, mid 50 against 56, rank-100 Attack 156 against 158) because of an unexplained difference in method, so compare figures only within this section.

1. **The pile is what ends runs.** From the mid build onwards, 64–77% of all the Hit that lands comes from enemies at the Number hitting again, not from first contact. A rank-100 Attack build dies at wave 156 with about 35 enemies at the Number.
2. **Wasted overkill doesn't matter.** Overkill loses 1.5% of damage to wave 30, 4.5% at mid, 9.5% at rank-100 Attack and 30% with every Attack ladder maxed. But letting every point of excess carry on to the next enemy moves the end wave by at most one (mid 50 → 50, rank-100 Attack 155.8 → 156.7, full Attack ladders 709.3 → 709.8). The waste happens on waves the build already crushes.
3. **So splitting the same damage across enemies changes nothing.** Against the pile, only damage that grows with the number of enemies helps. Attack Speed against Damage, and "hits two" against "hits one twice", are still the same purchase until enemy types exist (D056 step 3).
4. **Today, exactly one row grows with the pile: Thorns, and it dominates.** At rank-100 Attack, Thorns at 50% adds 23 waves and at 100% adds 34, and the pile at death falls from 35 to none. Maxed Armor adds 4. With every Attack ladder maxed, Thorns adds 53 waves and Armor 10. In a maxed Workshop, Thorns deals about twice as much damage as every shot and tap together.

| Row worth at rank-100 Attack (wave 156) | End wave |
| --- | --- |
| without Crit Chain | 120 (−36) |
| without Multishot | 148 (−8) |
| without Burst | 150 (−6) |
| without Boss Damage | 152 (−4) |
| plus Leech maxed | 157 (+1) |
| plus Armor at rank 100 | 160 (+4) |
| plus Thorns at 50% | 179 (+23) |
| plus Thorns at 100% | 190 (+34) |

### Every row, against one enemy, a group and a boss

| Row | What it does now against groups | Verdict |
| --- | --- | --- |
| Tap Damage, Damage, Auto Crank, Damage Multiplier | Front enemy only. Neutral: the same total damage whichever enemy takes it | Keep. The single-target backbone |
| Attack Speed | The same purchase as Damage; smaller shots waste less overkill, worth under a wave | Keep. Its own job arrives with enemy types (swarms), not a row change |
| Multishot | Fires two visible shots, but both land on the front enemy as one doubled amount | **Change:** the second shot strikes the next enemy in line. Measured neutral, so it's a readability change: the player sees Multishot hit two enemies |
| Burst | Every Nth shot doubles, on the front enemy | **Change:** Burst's shot also strikes every other enemy at the Number. This gives Attack a pile answer |
| Crit Chance, Crit Damage | Front enemy; neutral | Keep |
| Crit Chain | Neutral against groups, but by far the strongest Attack row (36 waves) | Keep; flagged as a balance outlier. Rebuilding it as "a crit's overkill carries on" was tested and loses the 36 waves for nothing |
| Boss Damage | Also boosts damage to the pile carried into a boss wave, which is worth about 2.6 of its 4 waves | **Fix:** only against the boss itself |
| Armor | Takes a share off every Hit, the pile's included | Keep; now weak beside Thorns |
| Guard | Taken off the whole wave's Hit, then shared, so the pile pays what one enemy would | Keep |
| Thorns | Returns part of every Hit to the front enemy, so it grows with the pile | **Retune** (decision below); it's the Defense pile answer, but too strong |
| Leech | Boss-only, worth about a wave; also leaks onto the pile in boss waves | **Fix** the leak alongside Boss Damage. Extending it to every enemy at the Number measured +0.2 waves, so it needs a new job, which isn't part of this set |
| Cushion, Second Wind, Brace Cost | Don't depend on groups; Brace already blocks the pile's Hits | Keep |
| Discount, Coin Bonus, Knowledge Bonus | Don't depend on groups | Keep |

**Run Upgrades** sell the same 21 rows at twice a Workshop rank's worth (D044), so every change above carries into the run automatically. Burst's run ranks count one for one. One consequence: 100 run ranks of Thorns reach its 100% ceiling, so buying Thorns mid-run is probably the strongest run play, yet both simulators buy it nearly last, and the career figures likely understate what an informed player reaches.

### The proposed set

| # | Change | Measured (end wave) | Risk |
| --- | --- | --- | --- |
| 1 | **Burst splashes the pile:** every Nth shot still hits double, and also strikes every other enemy at the Number for the shot's plain amount. Opening members never stay, so to wave 30 it plays as today | rank-100 Attack 156 → 175 (pile at death 35 → 12); full Attack ladders 709 → 737; with Thorns at 100%, 190 → 196 | High: economy. It needs a splash-share dial and tuning, because Burst's six ranks cost about 2,000 Coins in total |
| 2 | **Multishot's second shot strikes the next enemy in line**, the same enemy against a boss alone | 156 → 156, 709 → 710 | Medium: presentation, with no balance effect |
| 3 | **Boss Damage and Leech apply only to the boss,** not the pile in front of it | 156 → 153, 709 → 708 | Medium: a small nerf that fixes the rows' own wording |
| 4 | **Thorns retuned** once 1 is measured; see the decision below | At 50%: +23 waves against 100%'s +34 | High: economy, and it weakens ranks the owner already holds |

All four keep every row's id, ranks, caps and prices, so no save shape changes and there is no save V11. Owned ranks keep their count; only what a rank does changes (the descriptions in `data/workshop/upgrades.json` with it). Splash damage, like Thorns, would come off enemies without adding Number.

Not in this set, and why:

- **Anything that holds enemies back before they reach the Number** (slow, knockback). It's The Tower's main Defense answer to crowds, but it needs a movable arrival time, a new encounter primitive: a real foundation gap for D056 step 4, not a row change.
- **A new job for Leech.** Nothing cheap tested well.
- **Pay for beating the pile.** A carried enemy beaten later pays nothing, because its wave already paid for the share cleared when it passed. It's an economy rule, not a row, so it needs its own decision.

### Decisions this needs

1. **Accept the set's direction:** Burst as Attack's pile answer, Multishot hitting a second enemy, and Boss Damage and Leech fixed to the boss. *Recommended:* yes. It's the smallest change that gives Attack a group job, and the only one that measured a real gain.
2. **How strong should Thorns be?** *Recommended:* build 1 first, then set Thorns and Burst's splash together so neither alone beats Armor plus the other. A starting point is Thorns' ceiling halved to 50%. The trade-off is that the owner's Thorns ranks lose half their effect.
3. **Balance target 5** (the cheapest build reaching wave 100 needs Defense) already fails since D047, and Burst's splash strengthens Attack-only builds further. Restate it with the redesign's measurements rather than tune the waves for it.

## Tower parity plan and coin gates — proposed, 23 September 2026

**Status:** proposed on owner direction, 23 September 2026: carry The Tower's Workshop over as far as it makes sense, and "hide some behind coin gates similar to the tower … so players don't get everything immediately at the start." Nothing here is accepted or built. "The Rig" below means run Upgrades (D045), whose ranks now stop at a row's max rank and are worth two Workshop ranks (D044). Each gate, row and foundation piece needs its decision in [`DECISIONS.md`](../DECISIONS.md) first. Where this plan overlaps the earlier 28-row plan below, this plan is the newer proposal; the [reconciliation](#how-this-meets-the-earlier-proposals) says which earlier rows survive.

**Sources:** The Tower's 48 Workshop rows (17 Attack, 18 Defense, 13 Utility) and their ranges come from the unofficial community [TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) workshop table (release 0.11.0, 13 September 2026). Death Defy's place in Defense and the unlock prices quoted below come from the community wikis ([Fandom](https://the-tower-idle-tower-defense.fandom.com/wiki/Workshop_Upgrades), [Game Vault](https://the-tower-idle-tower-defense.game-vault.net/wiki/Workshop)). These are community reconstructions, not developer data. Every number in this plan is ours (D009), not copied.

### The idea in one paragraph

A wave has no enemies on screen, so every "spatial" Tower row is translated through two readings the game already supports: **the Hit timer is distance** (the wave walks in and lands its Hit when it arrives) and **the waves behind this one form a queue** (a proposed new primitive: the next two or three waves' HP shown as small numbers behind the big one). Each Workshop tab starts with a few free rows. The rest open one at a time through **coin gates**: a one-time Coin payment that unlocks the next mechanic in that tab, in a fixed order. A fresh save opens with 9 rows (today 5, with the other 16 opening by Workshop level); a fully unlocked Workshop has 49, against The Tower's 48.

### How coin gates work

- **What The Tower does.** Its first rows in each tab are free; from there each new mechanic is a one-time Coin unlock that needs the previous one. The wikis give Attack as Multishot 400 Coins, Rapid Fire 1,500, Bounce Shot 10,000, Super Critical 100 million, and Death Defy at 1.5 million after the Land Mine rows. Crit Chance and Crit Factor are free there, and they are free here too.
- **One ladder per tab, in a fixed order.** Only the next gate in each tab shows, as a locked card with its price (`UNLOCK FRENZY · 2,500 COINS`). Later gates show as locked without a name, so the tab promises more without listing it.
- **A gate is a choice, not a toll.** After the first run a player can afford one first gate in one tab, or a handful of ranks. Opening a mechanic and deepening one compete for the same Coins.
- **Fixed prices.** Gates ignore Discount and Research Focus, so the ladder reads the same for everyone and a discount never reorders it.
- **Replaces the Workshop-level row gates.** `workshop_level_required` stops gating rows, so there is one rule for "why can't I buy this". The Workshop level stays: Labs and Research Focus still open by it.
- **The Rig sells only unlocked rows,** as The Tower's in-run upgrades do. This narrows D042's "all 21 rows in the Rig" to "every unlocked row", so it needs recording against D042. It also narrows what a fresh run can buy: 9 rows instead of 21. Measured with the career simulator (40 runs from a fresh save), the first ladder below made early progress without run ranks about twice as slow as today; see [the gate prices](#the-gate-ladder-measured).
- **Saves.** Unlocks are permanent and saved as `workshop_unlocks`, a new field, so under D028 it is save schema V9. That is the same bump the Cash fields owe. Migration unlocks every row an old save holds ranks in or whose old Workshop-level gate it already meets, so no player loses a row they had.

**The gate ladder**, the same in every tab (starting proposal; the first three gates raised from 60, 150 and 400 after the [measurement below](#the-gate-ladder-measured)):

| Gate | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Coins | 100 | 250 | 500 | 1,000 | 2,500 | 6,000 | 15,000 | 35,000 | 80,000 | 180,000 | 400,000 |

Sized against measured Coins per run (profile `tax-foundation-v8`, seed 7, two taps a second, hoarding / playing the Rig): fresh 86 / 232, early 382 / 683, mid 1,154 / 1,659, max Attack 3,808 / 5,875, everything maxed 7,760 / 13,675. So the first gate is about one first run; gate 3 is an early run; gate 5 is about one strong run; gates 8 and later exceed today's whole Workshop (about 140,000 Coins to max) and are sized for the deeper economy the [ladders](WORKSHOP_LADDERS.md) and higher tiers bring. Tune with the simulator; revisit the top of the ladder when the ladders land.

#### The gate ladder, measured

Measured on 23 September 2026 with `tools/career_simulator.gd`: 40 runs from a fresh save, Tier 1, two taps a second, seed 7 + run, on balance profile `tax-foundation-v9` (run ranks capped and worth 2, D044). The simulated player buys every affordable next gate, cheapest first, keeps back the next gate when one run pays for it, and spends the rest on ranks in turn. Gates for rows that don't exist yet are skipped, which flatters the gated careers slightly.

| Ladder (first gates) | Wave 30, no run Upgrades | Wave 100, no run Upgrades | Wave 100, buying run Upgrades |
| --- | --- | --- | --- |
| Today, no gates | run 4 (0.5 h) | run 33 (7.6 h) | run 20 (5.0 h) |
| First proposal: 60, 150, 400, … | run 9 (1.0 h) | run 40 (8.7 h) | run 26 (6.3 h) |
| Gentle: 25, 75, 200, … | run 9 (1.0 h) | not in 40 runs | run 25 (6.0 h) |
| **Now proposed: 100, 250, 500, then as before** | **run 6 (0.7 h)** | **run 37 (8.2 h)** | **run 26 (6.1 h)** |

**The lever is how many gates a player buys early, not what each costs.** The first real wall is the wave 20 boss, and passing it takes Damage ranks: today's player has about 70 Workshop ranks by run 3 and clears it. Cheap gates let the gated player spend its first 250 Coins opening six rows that do not help at wave 20 (Crit at rank 0, Thorns, Coin Bonus), so its ranks lag two or three runs behind. A dearer first gate opens fewer rows early and leaves those Coins in ranks. The new ladder is the starting proposal (`--ladder plan` in the simulator): gates cost about half an hour at the start and 8% of the time to wave 100 without run Upgrades, or 22% with them, because locked rows are locked for run Upgrades too. Players who unlock less greedily than the simulated one will lose less.

*Re-measured after D046 (Hit scale 1.7), new ladder:* without run Upgrades, wave 30 on run 8 against today's run 5, and wave 100 not reached within 40 runs against today's run 34 (7.3 h); buying run Upgrades, wave 100 on run 28 (6.2 h) against today's run 22 (5.2 h). The harder Hit widens what gates cost a player who never buys run Upgrades.

#### A focused player, and Crit free

The career simulator's first player spreads Coins evenly across every open row. `--spend focused` adds a second: between runs it buys the cheapest rank in its focus tab first (Attack, or Defense after a run that did not beat its best wave), opens its focus tab's next gate as soon as it can and another tab's only at twice the price. Measured on 23 September 2026 (profile `tax-foundation-v10`, 40 runs from a fresh save, two taps a second), with Crit free in the plan as the owner directed:

| Layout | Focused, no run Upgrades | Focused, buying run Upgrades | Even, no run Upgrades | Even, buying run Upgrades |
| --- | --- | --- | --- | --- |
| No gates (today) | wave 100 in 5.0 h (run 22) | 2.8 h (run 12) | 7.3 h (run 34) | 5.2 h (run 22) |
| **The plan, Crit free** | **7.2 h (run 34)** | **4.0 h (run 17)** | 8.2 h (run 40) | 5.7 h (run 26) |
| The Tower's shape (`--layout tower`) | 9.2 h (run 40) | 3.9 h (run 17) | not reached in 40 runs | 6.9 h (run 30) |

- **How a player spends matters more than how the gates are laid out:** the focused player reaches wave 100 in about half the even player's time under every layout.
- **The plan with Crit free is the better layout.** It matches the Tower shape for a player buying run Upgrades and is two hours faster for one who does not, because it opens Boss Damage second (every Tier 1 wall is a boss) where the Tower shape puts it at 2,500 Coins. Freeing Crit also helped the even player (wave 100 in 8.2 hours instead of not at all within 40 runs).
- **Gates cost a focused player about 40% more time to wave 100** (4.0 against 2.8 hours buying run Upgrades, 7.2 against 5.0 without). That is the slowdown the gates are for; whether 40% is the right amount is the owner's call.
- **Tier 1 is short for a focused player:** wave 100, and so Tier 2, in about three to seven hours. The Workshop's rows stop at 50–100 ranks; the deep ladders in [`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md) are proposed, not built.

#### How The Tower prices its gates

From the community wikis ([Fandom](https://the-tower-idle-tower-defense.fandom.com/wiki/Workshop_Upgrades), [Game Vault](https://the-tower-idle-tower-defense.game-vault.net/wiki/Workshop)); community data, not developer data, and prices can change between versions:

| Tab | Free from the start | Gates, in order (Coins) |
| --- | --- | --- |
| Attack | Damage, Attack Speed, Crit Chance, Crit Factor, Range, Damage / Meter | Multishot 400 · Rapid Fire 1,500 · Bounce Shot 10,000 · Super Crit 100 million · Rend Armor 500 billion |
| Defense | Health, Health Regen, Defense %, Defense Absolute | Thorns 500 · Lifesteal 2,000 · Knockback 5,000 · Orbs 15,000 · Shockwave 100,000 · Land Mines 400,000 · Death Defy 1.5 million · Wall 500 million |
| Utility | Cash Bonus, Cash / Wave, Coins / Kill Bonus, Coins / Wave | Free Upgrades 800 · Interest 5,000 · Recovery Packages 1.5 million · Enemy Level Skip 1 billion |

Its rules, read from that table:

1. **Core stats are never gated.** 14 of 48 rows are free, and every gate opens a new mechanic.
2. **The tabs open at different prices** (Attack 400, Defense 500, Utility 800), so there is never a three-way tie for the first unlock.
3. **A cheap band, then a cliff.** Inside each tab's early band each gate costs 2.5–7× the last; then the price jumps 300–10,000× to a gate that belongs to a much later economy. Defense has the longest cheap band (seven gates to 1.5 million), Utility the shortest (two).
4. **Chance-and-strength pairs open together** (Multishot Chance and Targets, Land Mine Chance, Damage and Radius).

*Measured with the career simulator (`--layout tower`):* The Tower's shape for our existing rows, its prices divided by 4 so its first Attack gate is one of our first runs, our own rows in the slot nearest their job, and its end-game gates past Tier 1's economy. Without run Upgrades: wave 30 on run 8 and wave 100 not reached within 40 runs, the same as the current plan. Buying run Upgrades: wave 100 on run 30 (6.9 h), against 6.2 for the current plan and 5.2 with no gates. Two things cost it time. Every Tier 1 wall is a boss wave, so Boss Damage, which The Tower has no row for, matters from the first run, and the Tower slot puts it at 2,500. And with ten rows free, the simulated player's even spread puts its first runs' Coins into Cushion and Crit rather than damage; a player who focuses would lose less, so this part is the simulator's assumption rather than a finding.



### Attack

*Since D054 the rows written here as Damage per Second, Tick Speed and Double Tick are called Damage, Attack Speed and Multishot. Multishot is today's Double Tick shown as two shots; the Volley proposal below would still replace it.*

Free at the start: **Tap Damage, Damage per Second, Tick Speed, Crit Chance, Crit Damage.** Crit is free, as in The Tower (owner direction, 23 September 2026).

| Gate | Opens | Tower row(s) | What it does here | Needs |
| --- | --- | --- | --- | --- |
| 1 | Damage Multiplier | Damage (its scaling) | As today | — |
| 2 | Boss Damage | — (ours) | As today | — |
| 3 | Auto Crank | — (ours) | As today; its Auto Tap job is still open | — |
| 4 | **Early Strike** | Damage / Meter | Bonus damage for every second left on the Hit timer: a wave hit while still far away takes more. Shown as a shrinking multiplier (`×1.3 EARLY`) | Pipeline |
| 5 | **Frenzy Chance, Frenzy Duration** | Rapid Fire Chance, Duration | Chance per tick to tick 4× faster for a few seconds, with a countdown on the ring. **Replaces Burst** | Pipeline |
| 6 | Double Tick → **Volley Chance, Volley Depth** | Multishot Chance, Targets | Double Tick as today until the queue exists; then a tick has a chance to also strike the queued waves, Depth setting how far down | Queue |
| 7 | Crit Chain | — (ours) | As today | — |
| 8 | **Reach** | Range | During the 2.5 seconds a beaten wave stays on screen, output already strikes the next wave; today it only adds Number | Queue |
| 9 | **Super Crit Chance, Super Crit Damage** | Super Crit Chance, Mult | A crit has a chance to multiply again, in its own colour (`SUPER ×13`) | Pipeline |
| 10 | **Rend Chance, Rend Strength** | Rend Armor Chance, Mult | Chance per tick to add a stack of "takes more damage" to the current wave, up to a cap; stacks clear with the wave. A boss-fight stat, shown as `REND ×1.8` | Pipeline |

Not taken: **Bounce Shot** (Chance, Targets, Range). Its job, overkill carrying into the next wave, is the "overkill carry-over" [already considered and not proposed](#considered-and-not-proposed): contested waves end with almost no overkill, and an outclassed wave's overkill buys nothing because the next wave waits out its 2.5 seconds anyway. Volley covers "hit more than one wave".

19 rows when complete (today 11); Burst and Double Tick are replaced.

### Defense

Free at the start: **Armor, Guard.**

| Gate | Opens | Tower row(s) | What it does here | Needs |
| --- | --- | --- | --- | --- |
| 1 | Thorns | Thorn Damage | As today | — |
| 2 | Cushion | Health | As today | — |
| 3 | Leech | Lifesteal | As today | — |
| 4 | Brace Cost | — (ours) | As today | — |
| 5 | **Wall Health, Wall Rebuild** | Wall Health, Rebuild | A rechargeable shield around the ring that takes Hits before Number does, sized in the tier's Hits like Cushion; once broken it rebuilds after a delay | Pipeline, saved run state |
| 6 | Second Wind | — (Death Defy's cousin) | As today | — |
| 7 | **Knockback Chance, Knockback Force** | Knockback Chance, Force | Chance per tick to push the wave back, adding seconds to its Hit timer, capped per wave; the ring visibly jumps back | Movable timer |
| 8 | **Orbs, Orb Speed** | Orbs, Orb Speed | Dots circle the ring; each pass takes a share of the approaching wave's max HP, less on bosses. The Defense stat that keeps scaling with depth | Pipeline |
| 9 | **Shockwave Size, Shockwave Frequency** | Shockwave Size, Frequency | Once the wave is within Size seconds of its Hit, a pulse every Frequency seconds strikes it and pushes it back a little | Movable timer |
| 10 | **Mine Chance, Mine Damage** (+ **Mine Blast**) | Land Mine Chance, Damage, Radius | Chance per tick to lay a mine; mines go off when the next wave arrives, turning output made after a clear into damage (`3 MINES READY`). Mine Blast lets them hit queued waves too | Pipeline; Blast needs the queue |
| 11 | **Defy** | Death Defy | After Second Wind's one guaranteed rescue, a chance that a later killing Hit leaves you alive | Pipeline |

Not taken: **Health Regen** as "Mend" (win back part of the Number lost since your peak). Supply Drop in Utility does the same job actively and visibly; two ways to restore Number is one too many. **Health** is Cushion, since Number is our health and has no maximum.

19 rows when complete (today 7).

### Utility

Free at the start: **Cash per Wave, Cash Bonus.**

| Gate | Opens | Tower row(s) | What it does here | Needs |
| --- | --- | --- | --- | --- |
| — (free) | **Cash per Wave** | Cash / Wave | Raises the Cash a beaten wave pays (today a fixed 10 + 5 × the wave) | — |
| — (free) | **Cash Bonus** | Cash Bonus | Multiplies all Cash. D042 names this row as its revisit trigger | — |
| 1 | Coin Bonus | Coins / Kill Bonus | As today | — |
| 2 | Discount | — (ours) | As today; since D042 it also lowers Rig prices | — |
| 3 | **Interest** | Interest / Wave | Each beaten wave pays a share of your unspent Cash, capped in seconds of income. It brings back the spend-or-save choice D042 took out of the Rig | Pipeline |
| 4 | **Supply Chance, Supply Size** | Package Chance, Recovery Amount, Max Recovery | After a wave, a glowing number sometimes floats onto the stage; tap it to collect Number. At most a few wait uncollected (a fixed cap standing in for Max Recovery), so idle play can't bank them | Saved run state |
| 5 | Knowledge Bonus | — (ours) | As today | — |
| 6 | **Free Upgrade** | Free Attack / Defense / Utility Upgrade | Chance a Rig purchase costs nothing (`FREE`). One row for all three tabs. A chance rather than the earlier "every Nth" Free Boost: the run's saved random state keeps it reproducible (law 6) | Pipeline |
| 7 | **Stall HP** | Enemy Health Level Skip | Chance the next wave's HP stays at this wave's level (`HP STALLED`) | Difficulty counter |
| 8 | **Stall Hit** | Enemy Attack Level Skip | The same for the Hit | Difficulty counter |

Not taken: **Coins / Wave**. Waves already pay Coins by wave number, Coin Bonus already lifts them, and Coins per minute (balance target 2) is already above target.

11 rows when complete (today 3).

### Foundation pieces this plan needs

| Piece | What it is | Rows that need it | Risk |
| --- | --- | --- | --- |
| Coin gates | One-time unlocks, `workshop_unlocks`, save V9, the Rig selling only unlocked rows | Every gated row | High: saves and economy |
| Ordered player-stat pipeline | Player stats pass through the same ordered stages (flat, percentage, multiplier, caps) the enemy side already uses, replacing the Burst and Crit Chain special cases | Almost every new row | Medium–high: touches every stat |
| Movable Hit timer | Defense may add seconds to a wave's timer, capped per wave. It changes D037's fixed 15-second boundary, so it needs its own decision | Knockback, Shockwave | High: the wave rule |
| Wave queue | The next two or three waves exist, show their HP, and can take damage early; saved with the encounter | Volley, Reach, Mine Blast | High: encounter state, saves |
| Difficulty counter | Wave HP and Hit each have a level that usually rises with the wave but can stall; Coins, milestones and records still follow the wave number. The enemy-growth candidate in [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md) needs the same counter | Stall HP, Stall Hit | High: encounter state, saves, every balance measurement |

### Proposal: a wave becomes a group — 24 September 2026

**Status:** **accepted in principle (D056, 24 September 2026):** "Yeah multiple enemies is the play … That change alone gives us MASSIVE options for gameplay, progression, upgrade ideas, workshop". Not built. The owner also dropped the earlier "after slowing bosses" ordering by choosing now; the build plan is below.

**The idea.** Since D050–D051 a wave is one number falling to the Number over its 15-second clock. A group splits that wave into a few numbers: the same wave, the same totals, arriving one after another. It is what gives area damage, chains, targeting and slowing something to choose between; with one enemy, "hits several" and "hits one hard" are the same upgrade.

**The rules it would need:**

1. **Same totals.** A wave's HP and Hit divide across its members (2–5, growing slowly with wave and tier). Keeping the totals is what keeps today's HP and Hit curves, the balance targets and the 150-hour calibration roughly valid.
2. **Staggered arrival inside the clock.** Members arrive through the 15 seconds, the last at 15, each landing its share of the Hit. A member beaten before it arrives lands nothing, so D037's "beat it before it hits" holds per member.
3. **Damage goes to the front member first** (the one nearest contact). Single-target damage then overkills and wastes some, which is the gap area damage fills.
4. **Bosses stay single.** They are the fight that stays (D037, D051). Escorts could come later.
5. **Guard is the trap.** Guard takes a flat amount off every Hit, so splitting one 4,000 Hit into four 1,000 Hits would let an 800 Guard take 80% instead of 20%. Options: (a) Guard applies to the group's combined Hit and each member's share of it is taken off pro rata; (b) Guard is divided by the number of members. **Recommended: (a)**, because a group then costs a player exactly what the single wave did, and Guard keeps meaning what it says.
6. **Coins for the share cleared** (D037) become the sum of the members beaten or damaged.
7. **Owner direction (24 September 2026):** bosses cannot be pushed back by any force, only slowed. Knockback (build step 4) would act on ordinary members only.

**What it needs:** the wave's position as a rule first; encounter state becomes a list of members (a new save version); member placement and arrival order from the wave number rather than the run's random stream, so a saved run resumes identically; the balance and career simulators taught front-first targeting and staggered Hits, then every balance target re-measured.

**How it meets the wave queue** (the table above): the queue lets the *next* waves be damaged early; a group splits the *current* one. They can share one primitive, an encounter that holds several bodies, which is the reason to decide them together.

**How The Tower ramps (researched 24 September 2026)**, from TheTowerSDK's v29 reconstruction (unofficial, version-sensitive; [`TOWER_SCALING_FOUNDATION.md`](../TOWER_SCALING_FOUNDATION.md) sets the source rules):

| Wave | Enemies per wave (Tier 1) | What changes |
| --- | --- | --- |
| 1–27 | about 4 | Basic enemies at base speed. Each has the wave's full HP and damage, and the tower's range kills them before they arrive |
| 100 | about 12 | Speed is flat to wave 100, then grows 0.03% a wave, with steps at 141, 678 and 3,500 |
| 500 | about 70 | |
| 1,000 | about 140 | Past 1,000 the count grows slowly (37 → 56 spawn attempts by wave 6,500) |

- **Enemies trickle in** across a 26-second wave (one spawn roll every 0.125 s), then a cooldown of 9 s at most (4 s with Wave Accelerator). The wave number moves on with the clock whether or not enemies are dead.
- **Tier 1's mix** is about 91% Basic and 3% each Fast (2.1× speed, same HP), Tank (5× HP, half damage, a third of the speed) and Ranged (attacks from range). Higher tiers weight the specials up. Bosses have 20× HP.
- **Why the first waves are free:** four slow, weak enemies against a tower that out-ranges them. The player banks Cash untouched and spends it before the pressure starts, which is the opening the owner asked for.
- **What we should not copy:** a Tower enemy carries the wave's whole HP, so the count multiplies the total. Ours keeps the totals (rule 1), so the count divides it. The shape of the ramp is what transfers, not the numbers.

**The build, in order** (each step its own decision, measured before the next):

1. **The group engine** (high risk: encounter, saves, balance). **Built as D057 (24 September 2026)**; members now stay at the Number and keep hitting, and survivors carry into the next wave (D058). A wave is 3 members at wave 1, rising towards 12 at wave 100 on The Tower's shape, capped at about 20 on screen, with bosses single. Members arrive through the clock (the last at 15 s) and take damage front-first, and overkill is wasted. Guard applies to the combined Hit (rule 5). This needs save V10, with an old save's active wave becoming one member, and both simulators taught the stagger. Expect the balance to move: early members land before 15 s, and overkill costs damage. Re-measure every target and retune the curves until a no-upgrade Tier 1 run still clears its first few waves unhit.
2. **The arena** (low–medium risk). Several numbers on screen, motes to the front member, a pop per member, and the Hit's working per landing.
3. **Enemy types** (medium risk). Fast and Tank join partway through Tier 1, Ranged later. This is what splits Damage from Attack Speed: swarms reward speed, tanks reward damage.
4. **The Damage/Attack Speed rebalance and taps as shots** (high risk: economy), then **the new rows** groups make possible: spread, bounce, area, targeting and slowing.

**Open questions:** how many members per wave and tier; the arrival pattern (even, bunched, random from the wave number); whether a tap can pick its target or always strikes the front; how the Hit's working at contact (D052) reads for a member's share.

### How this meets the earlier proposals

| Earlier proposal | Now |
| --- | --- |
| Interest (on Number) | Kept, **on Cash** (Utility gate 3) |
| Free Boost ("every Nth") | Becomes **Free Upgrade**, a chance (Utility gate 6) |
| Boost Discount | **Dropped:** D042 already makes Discount lower Rig prices |
| Bounty, Finisher, Streak, Payback | Still candidates outside The Tower's set. Each takes a gate slot only if chosen; Bounty overlaps Supply Drop and Finisher overlaps Early Strike, so those two most need a reason to exist |
| Auto Crank → Auto Tap | Still open; Auto Crank keeps Attack gate 4 either way |
| Tier bands, the category rebalance | Unchanged, and still later |

### Risks

- **Cash rows strengthen run Upgrades.** D044 capped run ranks and set their worth at 2 after they had outgrown the Workshop; Cash per Wave, Cash Bonus and Free Upgrade make them cheaper again, so each needs the career simulator run before and after.
- **Attack-side damage rows push balance target 5** (wave 100 needs Defense). Early Strike, Frenzy, Super Crit and Rend all strengthen Attack-only builds; Orbs and Mines put damage in the Defense tab. Each needs the target re-measured.
- **Gating existing rows changes existing progression.** Damage Multiplier is free today and becomes gate 2; Crit opens at Workshop level 30 today and becomes gate 1. Migration keeps every row a save already uses, but the measured early and mid builds need re-running under the gates.
- **Replacing Burst and Double Tick** touches owned ranks. Each replacement needs a decision: carry ranks across to the new row, or refund their Coins.

### Decisions this plan needs

1. **Coin gates**: the model (one-time unlock per mechanic, in a fixed order per tab), the ladder, the starter rows, replacing Workshop-level row gates, and the Rig selling only unlocked rows (a narrowing of D042).
2. **Save V9** for Cash and unlocks together, with the migration above.
3. **Each new mechanic,** separately, as for the earlier rows.
4. **The three primitives**: the movable Hit timer, the wave queue and the difficulty counter.
5. **Burst → Frenzy and Double Tick → Volley**: carry ranks across or refund.
6. **A wave becomes a group** (proposed above): same totals, staggered arrival, front-first damage, and Guard on the group's combined Hit.

### Build order

| Step | What | Why here | Risk |
| --- | --- | --- | --- |
| 0 | Rig strength re-sweep (owner decision pending) | Every Cash row and the gates change the Rig | High: economy |
| 1 | Coin gates and save V9 | Shapes what every later row costs to reach, cuts the fresh-run Rig, and carries the Cash fields' overdue bump | High: saves, economy |
| 2 | Ordered player-stat pipeline | Almost every new row stacks through it | Medium–high |
| 3 | Rows needing only the pipeline: Early Strike, Frenzy, Super Crit, Rend, Wall, Orbs, Mines, Defy, Cash per Wave, Cash Bonus, Interest, Supply Drop, Free Upgrade | No new encounter primitive; each lands and is measured on its own | Medium–high each |
| 4 | Movable Hit timer, then Knockback and Shockwave | One wave-rule decision unlocks both | High |
| 5 | Wave queue, then Volley, Reach and Mine Blast | The biggest new primitive | High |
| 6 | Difficulty counter, then Stall HP and Stall Hit | The biggest single lever on depth, so last and most carefully measured | High |

## The short version

The Workshop grows from 20 rows to 28. Nothing is removed: three rows get new jobs so they still mean something under the new rules, and every rank a player owns keeps counting.

| Category | Rows today | Proposed | New | Given a new job |
| --- | --- | --- | --- | --- |
| Attack | 11 | 13 | Finisher, Streak | Auto Crank becomes **Auto Tap** |
| Defense | 6 | 8 | Guard, Payback | Siphon becomes **Leech**, Recoil becomes **Thorns** |
| Utility | 3 | 7 | Bounty, Interest, Boost Discount, Free Boost | — |

The two biggest gaps this fills:

- **Defense has no forgiveness early.** Today's only opening Defense row is Armor, a percentage, which barely dents small Hits. **Guard**, a flat reduction on every Hit priced in the tier's Hits, is the early-game safety net.
- **Utility is empty until Workshop level 60.** All three Utility rows open there, so a new player's Utility tab is blank for hours. **Bounty** opens at level 0 and **Boost Discount** at 12.

## The rules these rows are designed for

A row only has a job relative to the rules. These are the proposed core rules from the 23 September discussion. The first is the owner's stated direction; the rest are proposals that come with it.

1. **Everything you make is Number.** Taps and the machine add to it every second, all the time. *(Replaces D012.)*
2. **Each wave sets an amount to clear in 15 seconds.** The same damage counts towards the wave while it grows your Number.
3. **Clear it:** Coins, no Hit, and the next wave comes straight in, after at least 2–3 seconds.
4. **Miss an ordinary wave:** it hits your Number once and moves on, paying Coins for the share you cleared.
5. **Bosses (every 10th wave) stay until beaten** and hit every 15 seconds. They are the fights.
6. **The run ends** when a Hit takes your Number to zero (Second Wind aside).

Rule 5 matters most here: Thorns, Leech and Payback are boss-fight stats. **If bosses move on like ordinary waves, those three need rethinking.**

## Principles for every row

1. **One job, one sentence, no overlap.** If two rows can be described the same way, one of them is a trap. This rules out, for example, "gain X% of a Hit back as Number" on its own: that is exactly Armor.
2. **The first rank visibly moves a result** in the simulator (balance target 6). A rank nobody can feel is a wasted purchase.
3. **Cheap first ranks.** Every row's first rank costs a handful of Coins (2–8), so every new row is worth trying the moment it opens, even though more rows share the same Coins.
4. **A readable failure points at a row.** "The wave wasn't cleared" points at Attack. "Lost to the Hit" points at Defense. "The run went fine but progress is slow" points at Utility. Every run-over message should have at least two rows that answer it.
5. **No row can make a run endless.** Every percentage row has a ceiling, and the combined ceilings are set on purpose ([Ceilings](#ceilings-that-keep-runs-ending)).
6. **No new buttons on the run screen** (pillar 1). Every row is passive or automatic. Anything that needs pressing belongs to Ultimates.
7. **Saves are a contract.** Row ids never change, owned ranks always count, and a row whose job changes is a recorded decision, never a silent retune.

## What each category is for

- **Attack: "Clear the wave in time."** Buy it when waves slip past the timer. Under the new rules, Attack also makes Number faster, because all damage is Number.
- **Defense: "Survive the misses and win the boss fights."** Buy it when a Hit ends the run, or a boss grinds you down.
- **Utility: "Get more out of every run."** More Number to spend on Boosts during a run, more Coins and Knowledge after it. It never adds damage or protection directly; it pays for them.

## Existing rows under the new rules

| Row | Category | Keep or change | Why |
| --- | --- | --- | --- |
| Tap Damage | Attack | Keep | |
| Damage per Second | Attack | Keep | |
| Damage Multiplier | Attack | Keep, **gets tier bands** | The main compounding row; carries damage across tiers |
| Tick Speed | Attack | Keep, **gets tier bands** | |
| Double Tick | Attack | Keep | |
| Burst | Attack | Keep | |
| Crit Chance | Attack | Keep | |
| Crit Damage | Attack | Keep, **gets tier bands** | |
| Crit Chain | Attack | Keep | Its card reads as a rank; give it a declared value to display |
| Auto Crank | Attack | **New job: Auto Tap** | Today it's "+0.1 damage per second", the same job as Damage per Second |
| Boss Damage | Attack | Keep, **gets tier bands** | More valuable now that bosses stay and fight |
| Armor | Defense | Keep | Percentage off every Hit; the late-game half of the Guard–Armor pair |
| Siphon | Defense | **New job: Leech** | Under rule 1 all damage is already Number, so today's effect does nothing |
| Recoil | Defense | **New job: Thorns** | Same idea, retargeted so it works when an ordinary wave moves on |
| Cushion | Defense | Keep | Already priced in the tier's Hits |
| Brace Cost | Defense | Keep | Brace blocks the next miss or boss Hit |
| Second Wind | Defense | Keep | |
| Discount | Utility | Keep | |
| Coin Bonus | Utility | Keep, **gets tier bands** | Also lifts the partial Coins from a missed wave |
| Knowledge Bonus | Utility | Keep | Price looks high: 20,519 Coins for 50 ranks, the dearest row in the Workshop, with Coin Bonus close behind. Review in the category rebalance |

### Auto Tap (was Auto Crank)

**The machine taps for you.** Each rank adds 0.05 automatic taps a second, up to 2.5 a second at 50 ranks. Auto taps use Tap Damage, crit and everything else a real tap uses.

- **Buy when** you play idle but your Tap Damage ranks sit unused.
- **Why:** today Tap Damage is worthless to an idle player and Auto Crank duplicates Damage per Second. This gives each a distinct reason to exist and makes the game properly playable idle, which the vision's automation line asks for: *remove decisions already solved*. Tapping was never a decision.
- **Opens at** Workshop level 12 (was 60), so idle players meet it in the first hour.
- **Owned ranks** carry over as Auto Tap ranks. At its cap with Tap Damage maxed, Auto Tap is worth about 15 damage a second, against Auto Crank's 5, so the row gets stronger: **re-measure target 5** (the Attack/Defense balance).

### Leech (was Siphon)

**Feed on the boss.** While a boss stands, X% of the damage you deal to it is added to your Number a second time. Each rank adds 0.25%, to 25% at 100 ranks.

- **Buy when** boss fights drain you faster than you can finish them.
- **Why:** it keeps Siphon's spirit, where damage dealt to a wave you're stuck on feeds your Number, and points it at the one kind of wave that now stays.

### Thorns (was Recoil)

**Hits hurt the attacker.** X% of every Hit you take is dealt as damage to the wave in front of you: the boss that hit you, or, if an ordinary wave has just moved on, the wave that replaces it. Each rank adds 0.5%, to 50% at 100 ranks (combined ceiling 100%).

- **Buy when** you win boss fights but take too many Hits doing it.
- **Why:** it's the boss thorns you described, and today's Recoil almost exactly. The only change is where the damage lands when an ordinary wave has already gone.

## New rows

Starting values, to be tuned by the simulator. Prices sit alongside today's rows: 100-rank rows start at about 3–4 Coins and total about 5,500; 60-rank rows start at about 6 and total about 4,800.

### Attack

#### Finisher

**Near misses become clears.** A wave with less than X% of its amount left breaks at once. Each rank adds 0.25%, to 15% at 60 ranks. Bosses included.

- **Buy when** the run-over screen keeps showing waves you almost cleared.
- **Why:** under rule 4 a near miss costs a Hit *and* part of that wave's Coins. Finisher turns "so close" into a clear, which is exactly the forgiving feel the game is missing. It does not add Number, so it is distinct from a damage row.
- **Opens at** level 30. **Ceiling:** 15%. At 25% or more, every wave would effectively have a quarter less to clear.

#### Streak

**Clean runs snowball.** Each wave you clear in a row adds X% damage, up to 20 waves; a Hit resets the streak. Each rank adds 0.05% per wave, so 60 ranks give +3% per wave and +60% on a full streak.

- **Buy when** you clear the early waves easily but stall in the middle.
- **Why:** it rewards playing well rather than just being strong, and it combines well with Rule 3: the fast early waves build a streak you carry into the hard ones. The dormant momentum code in `GameState` (`momentum_stacks`, which no row currently grants) is the natural place to start, counting waves rather than ticks.
- **Opens at** level 12. The streak is run state, so it is saved with the active run (a schema bump; see [Saves](#saves)).

### Defense

#### Guard

**Every Hit is smaller by a flat amount.** Each rank takes 1 × the tier's Hit pressure off every Hit, to 100 at 100 ranks on Tier 1 (2,000 on a 20× tier). A Hit never drops below 10% of its size after Guard and Armor together.

- **Buy when** early Hits keep chipping away at a run you should be winning.
- **Why:** it's The Tower's Defense Absolute. A flat reduction is huge against small Hits and fades against big ones, which is exactly the forgiveness the opening needs. At its cap it takes Tier 1's early Hits down to their 10% floor and still cuts the wave 25 Hit (208) by half. Against the wave 50 boss (1,493) it is a small extra, and Armor takes over: **Guard carries the early game and Armor the late game.** Pricing it in the tier's Hits, as Cushion already is, keeps it useful at the start of every tier.
- **Opens at** level 0, next to Armor. **Order:** Guard applies before Armor's percentage, following the modifier pipeline's flat → percentage order.
- **Watch-out:** a Guard-invested player can survive the whole warm-up while idle. That is investment rather than "doing nothing", so the invariant that an idle *fresh* run must not collect every warm-up reward still holds.

#### Payback

**Win the fight, get it back.** When you beat a boss, you regain X% of the Number its Hits took during that fight. Each rank adds 1%, to 50% at 50 ranks.

- **Buy when** you beat bosses but come out of the fight too weak for the waves after.
- **Why:** this is your "boss hits you and you gain Number back" idea, with the twist that keeps it from simply being Armor: the refund only comes if you *win*, so it rewards finishing the fight rather than soaking Hits.
- **Opens at** level 30. It needs the fight's landed Hits kept with the active run (see [Saves](#saves)).

### Utility

#### Bounty

**Every clear pays out.** Beating a wave adds X% of its amount to your Number in one lump. Each rank adds 0.5%, to 50% at 100 ranks.

- **Buy when** you want more Number for Boosts.
- **Why:** it makes every clear feel like a payout, which is the "burst on break" feeling Gemini described, delivered by the rules rather than by an animation, and it scales with the wave, so it never goes stale. It also gives a new player a Utility row on day one.
- **Opens at** level 0.

#### Interest

**Held Number grows.** Each wave you clear adds X% of your current Number, capped at 30 seconds of your income per wave. Each rank adds 0.02%, to 1% at 50 ranks.

- **Buy when** you hold a big Number and want it to work.
- **Why:** it creates the one tension the run is missing: every Boost you buy is Number that stops earning interest. It's the in-run interest The Tower uses, and the cap stops a huge hoard from compounding into a runaway.
- **Opens at** level 30.

#### Boost Discount

**Boosts cost X% less.** Each rank takes 0.25% off every Boost price, to 15% at 60 ranks.

- **Buy when** you spend on Boosts every run.
- **Why:** it's the bridge between the two lenses: permanent Coins that make the in-run layer cheaper. It answers "upgrades cost too much for what I earn" directly, for players who want that.
- **Opens at** level 12.

#### Free Boost

**Every Nth Boost is free.** Six ranks move N from every 12th Boost to every 6th, the way Burst works.

- **Buy when** you buy many Boosts per run.
- **Why:** the Rig's design already reserves a Free Upgrade row; this is its permanent form. It is deterministic ("every Nth"), not a roll, so saved runs stay reproducible.
- **Opens at** level 60.

## Scaling across tiers: what stops the Workshop running out

Breadth gives players choices; the long difficulty curve needs rows that **keep scaling**. Today every row maxes out, and all of Attack together is worth ×68 damage, enough for Tier 1 and part of Tier 2.

- **Tier bands.** Each tier unlocked opens one more band of ranks on the multiplying rows: Damage Multiplier, Tick Speed, Crit Damage, Boss Damage and Coin Bonus. A band adds ranks beyond today's caps, which stay a contract. Beyond those caps, damage should grow with about the square root of Coins spent, and each band should cost about four times the one before. The full reasoning is in [`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md#5-workshop-bands-each-tier-opens-more-workshop).
- **Flat rows are priced in the tier's Hits.** Guard and Cushion scale with the tier automatically, so the start of every tier gets the same forgiveness.
- **Percentage rows stay capped.** Armor, Leech, Thorns, Payback, Finisher, Streak, Bounty, Interest, Boost Discount, Crit Chance and Double Tick are worth the same at every tier, which is exactly why they need ceilings rather than bands.

## Ceilings that keep runs ending

| Effect | Workshop cap | Combined ceiling (Workshop + Boosts + Labs + Cards) |
| --- | --- | --- |
| Armor + Guard | Armor 40%; Guard 100 × the tier's Hits | A Hit keeps at least 10% of its size |
| Leech | 25% | 50% |
| Thorns | 50% | 100% |
| Payback | 50% | 50% |
| Finisher | 15% | 15% |
| Streak | +60% at 20 waves | +60% |
| Interest | 1% a wave | 30 seconds of income a wave |
| Boost Discount | 15% | 50% |

## Category balance

Research Focus discounts one category by 25%, so the categories must be worth about the same in Coins to max (WORKSHOP_DESIGN's step-4a rule). Today: Attack 46,590, Defense 41,070, Utility 46,503. With the new rows at starting prices, before bands:

| Category | Rows | Coins to max (estimate) |
| --- | --- | --- |
| Attack | 13 | about 56,000 |
| Defense | 8 | about 50,000 |
| Utility | 7 | about 63,000 |

That's a 27% spread, against today's 13%. **Target: within 15%**, reached by reviewing Knowledge Bonus (20,519 Coins for 50 ranks) and Coin Bonus (20,498), and by pricing Guard and Payback in the upper half of Defense's range.

## Considered, and not proposed

- **Hits that take a percentage of your Number.** That was the prototype's tax, and D001 retired it because weak and strong builds lost the same share. Hits stay absolute; Armor is the percentage *reduction*.
- **Refund X% of every Hit as Number, instantly.** Mathematically identical to Armor. Payback is the version with its own job.
- **A cap on how much one Hit can take** ("never more than half your Number"). It makes runs endless, because Number never reaches zero.
- **First Strike** (every wave starts X% cleared). Same job as Finisher; Finisher reads better.
- **Head Start** (begin runs at a later wave). With rule 3 the early waves take seconds each, so there's little to skip, and skipping risks milestone claims.
- **Overkill carry-over.** With damage arriving continuously, very little ever carries over; it would be a row nobody could feel.
- **Bounce Shot as Ricochet, Health Regen as Mend, and Coins / Wave** (from The Tower survey). Ricochet is overkill carry-over again; Mend duplicates Supply Drop; Coins / Wave duplicates the wave's own Coins and Coin Bonus. See the [Tower parity plan](#tower-parity-plan-and-coin-gates--proposed-23-september-2026).

## Saves

- Repurposed rows keep their ids (`automation_core`, `siphon`, `recoil`) and their owned ranks. Only their effect changes, which is a recorded decision per row.
- New rows are new ids in the existing `purchased` ranks; that needs no schema change by itself.
- Streak's current streak and Payback's landed-Hits tally are run state. They join the active-run block, which is a schema bump under D028, and a saved run must resume with both exactly as they were (invariant: a saved encounter resumes identically).

## Decisions this needs

1. **The core rules** (rules 1–6 above), and in particular **bosses stay and fight**, which Thorns, Leech and Payback depend on.
2. **The three new jobs:** Auto Crank → Auto Tap, Siphon → Leech, Recoil → Thorns. Owned ranks carry over; only their effects change.
3. **Each new row,** separately: Guard, Payback, Finisher, Streak, Bounty, Interest, Boost Discount, Free Boost.
4. **Tier bands** on the five multiplying rows (shared with the tier proposal's decision 5).
5. **The category rebalance** to within 15%.

## Build order

Each step lands on its own and is measured by "does its first rank move a result" before the next.

| Step | What | Why here | Risk |
| --- | --- | --- | --- |
| 1 | The core rules, with Leech and Thorns replacing Siphon and Recoil in the same change | Those two rows break the moment rule 1 lands, so they change together | High: economy, encounter, saves |
| 2 | Guard | The biggest forgiveness gain for the least code: one flat modifier through the pipeline | Medium–high: economy |
| 3 | Auto Tap | Makes idle play work; changes an owned row | Medium–high: economy |
| 4 | Bounty and Finisher | The "clears feel good" pair; no new saved state | Medium–high: economy |
| 5 | Streak and Payback | Both need run state saved | High: saves |
| 6 | Interest, Boost Discount and Free Boost | Need the percentage Boosts from the tier proposal in place | Medium–high: economy |
| 7 | Tier bands and the category rebalance | Only matter once Tier 2+ is reachable in normal play | High: economy |

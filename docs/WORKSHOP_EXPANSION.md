# Workshop expansion

**Status:** Proposed, 23 September 2026. Step 1 (the core rules, with Leech and Thorns) is accepted and built as [D037](DECISIONS.md) and [D038](DECISIONS.md); everything else here is still proposed. It follows the owner's direction that the Workshop should be fleshed out rather than cut, and that the difficulty curve should be solved by investment in it. Each row below needs its decision recorded in [`DECISIONS.md`](DECISIONS.md) before it is built.
**Scope:** the permanent Workshop's Attack, Defense and Utility rows: what each existing row does under the proposed core rules, eight new rows, and how the Workshop keeps scaling across tiers. Ultimates stay as [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md#ultimates--rare-powerful-earned) describes them.
**Depends on:** the core-rule change below, which is itself proposed. [`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md) covers the tier ladder and the percentage Boosts (the Rig) this document assumes.

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

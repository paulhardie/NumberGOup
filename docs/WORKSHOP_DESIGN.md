# Workshop design

**Status:** Accepted direction. Steps 1 (the wave rule and its retune), 3 (the four categories) and 3b (the deepened ladders) implemented 21–22 September 2026; later steps not yet.
**Decisions:** [D012](DECISIONS.md) (output beats the wave before it becomes Number), [D013](DECISIONS.md) (four categories), [D014](DECISIONS.md) (player vocabulary), [D015](DECISIONS.md) (the Rig: the same four categories inside a run), [D016](DECISIONS.md) (the bottom bar carries what is actionable now), [D018](DECISIONS.md) (multi-buy and the reference layout) and [D019](DECISIONS.md) (deep rank ladders).
**Owns:** the wave rule as the player should understand it, the four categories in both lenses — permanent in the Workshop, run-only in the Rig — and every stat's reason to exist, what the player sees, the build strategies this supports, the balance targets the retune must hit, and the implementation order.

This document uses the accepted player vocabulary (Wave HP, Hit, Armor). [Vocabulary](#vocabulary-d014) maps every term to its code name.

## The wave, in one paragraph

Each wave has **HP** (the ring) and a **Hit**. Everything you produce, taps and ticks alike, is **damage**, and it goes into the wave first. Beat the wave before its 15-second timer runs out and it never hits you; for the rest of that timer your output overflows into your Number. If the timer runs out with the wave still standing, it **hits** your Number, keeps the HP it has left, and the timer starts again. It hits every 15 seconds until you beat it. If a hit takes your Number to zero, the run ends.

That gives each half of the stat catalogue one plain job:

- **Attack** decides whether you beat a wave inside one timer.
- **Defense** decides how many hits you can take while you grind down a wave you couldn't.

The Number only rises while you are ahead, so a player can read their situation from the centre of the ring without opening a menu.

## Why the rule changed (D012)

Before D012, every unit of output counted twice: it raised Number *and* damaged the wave. So production quietly healed the player while they were stuck. Hits were background drag rather than events. A max-Attack Tier 1 run soaked 102 hits across 46 minutes and kept going. Attack was doing Defense's job, which left vision pillar 2 ("one build cannot trivially solve both") with nothing to stand on, and the Number rose whether the player was winning or losing.

Under D012, output that damages the wave does not also become Number. A hit is a real event, Defense has a job no Attack stat does, and the Number becomes an honest scoreboard.

**What D012 does not do by itself is make Defense an equal axis.** With today's curves, Attack is still the main wall. Two further things finish the job: Defense stats built for the new rule (below), and curve tuning that makes the hit, not the HP, the check that decides some fights. Bosses and higher tiers are the natural places for that.

### Measured impact

Method: a scratch copy of the current build with the rule change behind a switch, representative play at 2 taps per second, seed 7. This matches `run_balance.sh`. Workshop ranks were set directly. It is reproducible from this description and was not committed.

| Tier 1 build | Before D012 | After D012 |
| --- | --- | --- |
| Fresh first run | wave 21, 48 Coins | wave 21, 48 Coins |
| Mid Attack (Output bay maxed, Tick Wheel 3) | wave 46 | wave 38 |
| Max Attack | wave 85, 46 min, 4,708 Coins | wave 70, 27 min, 2,953 Coins |
| Max Attack + Armor 40% | wave 100 | wave 75 |

Defense stats after D012, added to Max Attack (baseline wave 70):

| Added | Wave reached |
| --- | --- |
| Armor 40% | 75 |
| Siphon 10% | 70 |
| Siphon 25% | 72 |
| Recoil 25% | 71 |
| Recoil 50% | 75 |
| Armor 40% + Siphon 25% | 80 |
| Siphon 25% + Recoil 50% | 80 |

Tier 2: mid Attack dies at wave 3 (was 8), but mid can't have unlocked Tier 2. Max Attack + Armor 40%, the build that reaches Tier 1 wave 100, survives to wave 18 (was 28). Tier 2 has no warm-up, so the first hit lands at wave 1 on an empty Number.

What this says:

- The first run and its Coins are unchanged, so D010's onboarding holds.
- Defense stats are small alone and stack together. Defense works as a build, not a single number.
- Siphon at 10% changes nothing, which makes it a trap rank at that size.
- On these (v1) curves, Tier 1 wave 100 moves out of reach at the same investment. The retune below restores it.

### After the v2 retune (step 1, as implemented)

Wave HP and hits are both halved, which keeps the hit-to-HP ratio, and pressured wave Coins are ×0.65. Warm-up Coins and milestone bonuses are unchanged. Lowering the hit alone could not restore wave 100: at 70% smaller hits the same build stalled at wave 92 and soaked 147 hits, undoing the point of D012. Restoring depth then made runs so much shorter that Coins per minute rose 40–60%, hence the reward trim. `run_balance.sh` reproduces every row below.

| Build | Before D012 (v1) | After D012 + v2 |
| --- | --- | --- |
| Fresh first run | wave 21, 48 Coins | wave 21, 48 Coins |
| Early (Hand Press 2, Desk Dynamo 2) | wave 25, 12.1 Coins/min | wave 29, 14.5 Coins/min |
| Mid | wave 46, 45.8 Coins/min | wave 50, 44.7 Coins/min |
| Max Attack | wave 85, 101.2 Coins/min | wave 90, 94.5 Coins/min |
| Max Attack + Armor 40% | wave 100 in 73 min, 194 hits, 88.0 Coins/min | wave 100 in 45 min, 82 hits, 92.9 Coins/min |
| Max Attack + Armor 40%, Tier 2 | wave 28, 50.5 Coins/min | wave 26, 60.3 Coins/min |

Armor 40% is worth +10 waves on Max Attack (+15 before D012, +5 on v1 curves). Knowledge per run is a little lower at the top (2 against 3) because runs are shorter; per minute it holds. Peak Number runs lower (128K against 241K at the top build), but the 110,000 dock unlock is still reached by Max Attack.

## Vocabulary (D014)

Player-facing words move away from tax and collection phrasing. The UI string pass is step 2; so far only the run screen's rate line uses the new words (`16 DAMAGE / sec` while a wave stands). Code names and save keys stay as they are. Renaming a save key needs a migration under the save contract, and renaming classes is a separate mechanical change.

| Player sees today | Player sees after step 2 | Code name (unchanged) | Plain meaning |
| --- | --- | --- | --- |
| Tax encounter | Wave | `TaxEncounter` | One 15-second fight |
| Liability | Wave HP, shown as the ring | `liability`, `remaining_liability` | How much damage beats this wave |
| Compliance | Damage | `apply_compliance()` | What your taps and ticks do to the wave |
| Liability cleared | Beaten | `is_cleared()` | The wave is done and can't hit you |
| Collection, Tax collected | Hit | `collection` | What the wave takes from your Number when its timer runs out |
| Grace wave · nothing due | Warm-up wave | `is_pressured_wave() == false` | No HP, no hit; everything banks |
| Brace | Brace (keep) | `braced` | Spend 30% of your Number to block the next hit |
| Armor (was Shield Matrix) | Armor | `tax_resistance` Workshop rank | Every hit is permanently smaller |
| Number, Coins, Knowledge, Retreat | Keep | — | — |
| — | The Rig, and `THIS RUN ONLY` on its panel | new (D015) | What you build inside one run, bought with Number |

Player-facing text never calls the Number "health". It says "If a hit takes your Number to zero, the run ends." That keeps one HP on screen, not two.

## The four categories (D013)

**Implemented (step 3).** Each category opens with the problem it solves, in the player's words, and every stat has a "buy this when" line, so a player can map any failure to a fix. Stats use plain names in the style of The Tower. The flavour names (Hand Press, Desk Dynamo) open each row's description, and upgrade ids are unchanged, so no save lost a rank.

### Attack — "Beat waves before they hit"

**Buy Attack when** the ring isn't closing before the timer runs out.

| Stat | Does | Source |
| --- | --- | --- |
| Tap Damage | More damage per tap | `stronger_tap` |
| Damage per Second | More base damage every second | `generator`, `automation_core` |
| Damage Multiplier | All damage ×1.15 per rank | `generator_two` |
| Tick Speed | Ticks come faster | `faster_cadence` |
| Double Tick | Chance a tick counts twice | `faster_echo` |
| Burst | Every Nth tick counts double | `burst_relay` |
| Crit Chance | More critical hits | `more_critical` |
| Crit Damage | Bigger critical hits | `magnitude_coil` |
| Crit Chain | Each crit strengthens the next | `chain_reaction` |
| Boss Damage | More damage against boss waves, ×2 at its cap | 100 ranks |

Attack is today's Output, Speed and Chance bays, nearly unchanged. Boss Damage is the one new stat (step 4b): a targeted choice for players whose runs end on bosses, and worth +6 waves on its own at the cap.

### Defense — "Survive the hits"

**Buy Defense when** a wave outlasts its timer and the hits drain your Number. That happens most often on bosses, and from wave 1 on Tier 2 and above.

**Implemented (step 4a, D020).** Six rows, 460 ranks, 60,008 Coins to max — within one Coin of Attack's total, which is what makes a Defense Research Focus a real choice rather than a consolation.

| Stat | Does | Ranks | At its cap |
| --- | --- | --- | --- |
| Armor | Every hit is X% smaller | 100 | hits 40% smaller |
| Siphon | X% of the damage you deal still reaches your Number | 100 | 25% of damage dealt |
| Recoil | X% of every hit you take is dealt back to the wave | 100 | half of every hit |
| Cushion | Start every run with X Number, scaled by the tier | 50 | 500 × the tier's pressure |
| Brace Cost | Brace costs less than 30% of your Number | 60 | 15%, its floor |
| Second Wind | Once per run, a hit that would end the run leaves you X% of your peak Number this run instead | 50 | a quarter of the peak |

Each works on a different part of being stuck:

- Armor shrinks each hit.
- Siphon refills you between hits.
- Recoil turns being hit into progress on the wave.
- Cushion gives you an opening buffer.
- Brace Cost improves the manual block.
- Second Wind forgives one mistake.

That spread is what makes Defense a build rather than one number.

### What step 3 changed, and what it deliberately did not

Retiring the bays moved nothing: every row's own `workshop_level_required` already equalled its bay's gate, so each row still opens at the same Workshop level (0, 2, 5 or 8). `run_balance.sh` reproduces every baseline row above unchanged, first run through Tier 2.

Four consequences are real and were accepted:

- **Armor is an ordinary Workshop rank now**, so it counts toward the Workshop level. A save with Armor ranks reaches later rows and Research Focus slightly sooner. Never later, so no progress regresses.
- **Armor is now discounted** by Discount and by a Defense Research Focus, and its cost rounds with the shared ceiling rather than its own `round()`. Over all ten ranks that is 5 Coins more in total: 2,728 against 2,723.
- **A Logic-shaped Research Focus loses part of its reach.** Logic's three rows split across Attack, Defense and Utility, so no mapping can keep all three; a migrated Logic focus becomes Utility and keeps the Discount row. Output, Speed and Chance all become Attack and keep everything they had.
- **Defense is open from the start, not gated on the first hit.** The requirement below assumed Defense was all new content, but Armor moves in and is available from wave 1 today. Gating it would take away access a player already has. Revisit when step 4 gives Defense rows a player cannot yet use.

### Deep ladders (step 3b, D019)

Multi-buy made the Workshop's real shortness visible: 51 ranks across 13 rows, which `MAX` collapsed into about thirteen presses. The reference's ladders run to hundreds of levels per stat. Step 3b rebuilds every ladder to that shape.

**The rule: multiply the cap, divide the step, keep the cap's value.** Each row's rank cap rose by roughly 20×, and its per-rank effect fell by the same factor, so the value at maximum rank is exactly what the three-to-ten-rank ladder reached. Cost growth flattens from 1.55–2.00 to 1.038–1.078, and each row's Coins-to-max is designed rather than inherited, which also retires two distortions: Cushion was 30% of the Workshop's price for a stat that does nothing on Tier 1, and Tap Damage was 0.2% of it for a stat used all game.

| | Before | After |
| --- | --- | --- |
| Coin-funded rows | 13 | 13 |
| Total ranks | 51 | **906** |
| Coins to max everything | 85,635 | **86,007** |
| Cost growth per rank | 1.55 – 2.00 | 1.038 – 1.078 |
| Tap Damage: ranks / Coins | 5 / 147 | 100 / 3,005 |
| Cushion: share of the Workshop | 30% | 12% |

Two rows could not simply be scaled. **Burst** sets a tick interval, so it has as many useful ranks as there are integers between 12 and its floor of 6: it runs 6 ranks, one tick shorter each, reaching the same floor. **Crit Chain** and Burst carry no declared effect, so their cards show a rank rather than a value; their coefficients moved in `GameState` alongside the rest.

Category gates move with the ranks, chosen to hold the old **Coin** pacing rather than the old rank counts: 0 / 12 / 30 / 60 in place of 0 / 2 / 5 / 8, and Research Focus at 120 in place of 12. Reaching the second shelf cost 45 Coins before and costs about 45 now.

**Measured: every baseline row below reproduces exactly** — the same wave, minutes, hits and Coins for the first run and all five build-matrix rows. Peak Number differs by under 0.1%, which is float residue in the per-rank multipliers (1.00701257 to the 60th against 1.15 cubed), not a balance change. A test asserts every cap still lands on its old value, so a future rank-count change that moves one is a failure rather than a silent retune.

What this does not do is lengthen the grind: the Workshop costs what it always did, and the same build still reaches Tier 1 wave 100 in 45 minutes. It buys decisions, not hours. Making the Workshop *longer* as well as deeper is a separate dial — the per-row Coin targets in `_make_definitions` — and a separate decision.

**Research Focus was lopsided until step 4a**, when Attack held ten rows against Defense's two and Utility's one. The fix was not a per-category discount scale but **balancing the categories by Coin cost rather than row count**: a 25% discount is worth a quarter of what the category costs, so Defense's six rows now total 60,008 Coins against Attack's 60,009 and the two focuses are worth the same. Step 4b closed it. The Workshop now holds **20 rows, 1,466 ranks and 196,006 Coins**, split Attack 68,008 / Defense 60,008 / Utility 67,990 — within 12%, so a Research Focus is a genuine three-way choice. The growth from 86,007 is new content rather than repricing: every row that existed before step 4 still costs what it did.

Cushion does nothing on Tier 1, because warm-up waves bank at least 600 Number before the first hit, even for a fresh player. On Tier 2 and above, the first hit lands at wave 1. That is deliberate: Cushion is the first stat whose value depends on which tier you play, and it is now priced in that tier's hits — its face value times the tier's pressure multiplier — rather than in absolute Number. Measured, that is exactly the intended shape: **+0 waves on Tier 1 and +2 on Tier 2.**

### What Defense is worth (step 4a, measured)

`run_balance.sh`, each stat at its cap on top of the maxed Attack build, seed 7, two taps a second.

These are the step 4b numbers, with Boss Damage in the maxed Attack build.

| Tier 1 build | Wave | Minutes | Hits | Coins | Coins/min |
| --- | --- | --- | --- | --- | --- |
| attack max | 96 | 38.8 | 60 | 3,950 | 101.9 |
| + Armor | **100** | 44.3 | 78 | 4,203 | 95.0 |
| + Siphon | **100** | 43.3 | 74 | 4,203 | 97.2 |
| + Recoil | **100** | 38.8 | 56 | 4,203 | 108.5 |
| + Cushion | 96 | 38.8 | 60 | 3,950 | 101.9 |
| + Second Wind | 99 | 41.8 | 68 | 4,139 | 99.1 |
| + all six Defense | **110** | 53.0 | 102 | 5,143 | 97.0 |
| + all three Utility | 96 | 38.8 | 60 | **5,896** | **152.2** |
| everything maxed | **110** | 53.0 | 102 | 7,683 | 145.0 |
| Defense alone, no Attack | 25 | 9.8 | 14 | 87 | 8.9 |

| Tier 2 build | Wave |
| --- | --- |
| attack max | 25 |
| + Armor | 28 |
| + Cushion | 26 |
| + all six Defense | 37 |

Armor, Siphon and Recoil all reach wave 100 and get there differently: Armor soaks 78 hits over 44 minutes, Recoil turns the hits into progress and finishes in 39 with 56. Recoil costs 14,004 Coins against Armor's 7,999, so Armor stays the cheapest route to 100 and Recoil is the faster one. That is Defense as a build rather than one number, which is what the category was for.

Utility behaves exactly as the category promised: **it never wins a wave** — the same 96 with and without it — and it pays 49% more Coins and a Knowledge for doing so.

### Utility — "Get more from every run"

**Buy Utility when** you survive comfortably but progress between runs feels slow.

**Implemented (step 4b, D021)**, apart from Auto-Brace.

| Stat | Does | Ranks | At its cap |
| --- | --- | --- | --- |
| Coin Bonus | +X% Coins from every wave beaten | 100 | half again |
| Knowledge Bonus | +X% Knowledge when a run ends | 50 | half again |
| Discount | Workshop costs X% lower | 60 | 15% off |
| Auto-Brace (later) | Braces for you when the next hit would take more than X% of your Number | — | waits until Brace is a solved decision |

Coin Bonus is **floored, not rounded**, per wave: "+50% Coins" that sometimes pays +100% reads as a bug. Coins are whole, so a one-Coin grace wave carries no percentage at all, which costs nothing real — the row opens at Workshop level 60, far past the waves that pay one Coin.

Utility never wins a wave. It is the shelf for farming, and it is where automation arrives, following the vision: automation removes decisions the player has already solved.

### Ultimates — "Rare, powerful, earned"

There is one Ultimate per milestone. The first time you reach wave 10, 25, 50 or 100 on any tier, that Ultimate unlocks permanently. Each fires on its own when ready, so the run screen gains no buttons (pillar 1). Each has three upgrade lines: strength, duration and cooldown.

| Unlocks at | Ultimate | Does | Serves |
| --- | --- | --- | --- |
| Wave 10 | Surge | All damage ×N for X seconds | Attack |
| Wave 25 | Bulwark | Blocks the next hit completely | Defense |
| Wave 50 | Breach | Instantly deals X% of the wave's max HP | Attack, as a boss-breaker |
| Wave 100 | Windfall | Coins from waves beaten in the next X seconds ×N | Utility |

Wave 10 falls inside Tier 1's warm-up, so every player meets their first Ultimate safely.

Rejected: *Stop the Clock* (pause the wave timer). It breaks the vision's anti-goal "no pausing an active run while Number keeps growing, in any form".

## The Rig — the same four categories inside a run (D015)

**Status:** Designed, not implemented. The four categories in the run and Number as their price are both owner-confirmed (21 September 2026); the cost coefficients below remain this document's recommendation until the simulator tunes them.

A run contains one decision today: Brace, at a flat 30%. Everything else the player does between starting a run and dying is tapping. That is the friction this section answers, and it is the reason the four categories belong on the run screen and not only in the Workshop.

The Rig is what you build inside a single run. Same four categories, same stat catalogue, three differences:

| | Workshop | Rig |
| --- | --- | --- |
| Spends | Coins | Number |
| Bought | Between runs | During a run |
| Lasts | Every later run | This run only |
| Lives | The Workshop screen | The run screen's bottom bar |

One catalogue, two price tags. A player learns "Tap Damage" once and meets it twice: as a permanent floor raised with Coins, and as a rank bought with Number while a wave is standing.

### Why Number is the right cost

Pillar 3 and architectural law 4 require a temporary layer to carry a distinct name and resource. Number already **is** the run-only resource: it exists only during a run and resets at every ending (D004, D008). Spending it adds no fourth currency (pillar 4), and Brace already sets the precedent at 30%.

It also produces the decision D012 was reaching for. Under D012 the Number rises only while you are ahead of the wave. The Rig is how being ahead compounds: beat waves cleanly, bank the overflow, convert it into the damage that beats the next one cleanly. **Every Rig purchase is also a cut to the buffer that absorbs the next hit**, so Attack and Defense compete for one pool inside the run rather than only in a shopping trip before it. That is pillar 2 as a moment-to-moment choice.

The cost of that is real: a player can spend themselves to death. The panel therefore prices every row against the incoming hit — `LEAVES 400 · HITS FOR 900` in the warning colour — and sells it anyway if they tap. A warning, not a block. The game's job is to make the number visible before it kills you, not to refuse the decision.

### What it costs

A flat Number price cannot work across tiers, because Tier 2 Number is twenty times Tier 1's from wave 1. Rig prices are quoted against the wave instead of in absolutes:

```
cost(rank)   = k × reference_hp × growth ^ rank
reference_hp = max(current wave HP, the tier's first pressured wave HP)
```

One rank costs roughly what one wave is worth, which is a price a player can feel without reading a table, and it scales with tier and depth with no per-tier data. The floor stops Tier 1's warm-up waves, which have no HP, from making the whole panel free.

**These coefficients are proposals, not measurements.** They are starting points for `tools/balance_simulator.gd` to tune:

| Category | k | growth |
| --- | --- | --- |
| Attack | 0.5–1.5 | 1.7 |
| Defense | 1.0 | 1.6 |
| Utility | 2.0 | 1.5 |
| Ultimate levels | 3.0 | 1.8 |

Rig ranks are uncapped; cost growth is the only limit. *Rejected: capping Rig ranks at the matching permanent rank.* It reads well — the Workshop raises the ceiling — but it means the stat a player needs is the one they cannot buy, exactly while they are learning what they need. The Workshop keeps one job: raise the value every rank starts from.

### Which rows appear in which lens

| Stat | Workshop | Rig | Why |
| --- | --- | --- | --- |
| Tap Damage, Damage per Second, Damage Multiplier | ✓ | ✓ | |
| Tick Speed, Double Tick, Burst | ✓ | ✓ | |
| Crit Chance, Crit Damage, Crit Chain | ✓ | ✓ | |
| Boss Damage | ✓ | ✓ | Bought two waves before a boss is the intended moment |
| Armor, Siphon, Recoil | ✓ | ✓ | The three stats for a wave you are already stuck on |
| Brace | — | free action | The Defense tab's first row, so the tab works at wave 1 of a fresh run |
| Cushion | ✓ | — | A starting value; there is nothing to buy once the run has started |
| Brace Cost | ✓ | — | |
| Second Wind | ✓ | — | Buying insurance while the hit is inbound removes the tension it exists to create |
| Coin Bonus | ✓ | ✓ | Applies to waves beaten after the purchase, so when you buy it matters |
| Knowledge Bonus | ✓ | — | Paid at run end, so an in-run row would always be bought last: a solved decision |
| Workshop Discount | ✓ | — | A between-run cost |
| Rig Discount | — | ✓ | Rig rows cost X% less for the rest of this run |
| Free Upgrade | — | ✓ | Every Nth Rig purchase costs nothing |
| Ultimates: strength, duration, cooldown | ✓ unlock and permanent levels | ✓ run levels | The Tower's relationship: the Workshop owns the weapon, the run sharpens it |

### Brace and Shield move

Brace becomes the Defense tab's first row: still free to reach, still 30% of Number, still blocking exactly the next hit. Shield leaves the run screen entirely. It is a permanent Coin purchase sitting on the one screen where permanent purchases are forbidden by invariant, and under D013 it becomes Armor in the Workshop's Defense tab.

That makes the reshape a net **simplification** of the run screen, which matters for pillar 1: the encounter line, two text actions, the run button and the tap hint currently occupy roughly 300px above a 92px dock. After the reshape that space holds the encounter line, the run button and one four-item bar.

### What the Rig must not do

- Grant no Coins, no Knowledge and no record. It changes this run and nothing else.
- Survive a save and resume with the run it belongs to (D006, D007), and die with retreat and death like every other piece of run state (D008).
- Open no new RNG stream. **Free Upgrade is deliberately "every Nth purchase" rather than a roll**, in the shape of Burst Relay, because a new random draw inside a run changes what a run seed reproduces. D006's revisit clause reserves that for run-scoped random content with its own stream; a rolled version needs that stream and its own decision first.

## What the player sees

These are requirements. The design is not done if any of them is missing.

### The bottom bar carries whatever is actionable now (D016)

A portrait phone has one strip of thumb-reachable space, and today it holds a five-icon dock — NUMBER, WORKSHOP, LABS, CARDS, MORE — of which three cannot be acted on during a run at all, because permanent purchases are locked while a run is live.

The owner's reference layout (The Tower, 21 September 2026) settles the shape in both lenses: **the four category buttons are a fixed strip at the bottom of the screen, and the panel above them is always open.** It is not a sheet the player opens and closes. In a run the strip is the bottom-most element; in the Workshop it sits above the nav dock.

**The Workshop, between runs** — implemented in step 3:

```
  WORKSHOP                             3.59M COINS
  PERMANENT · APPLIES TO EVERY RUN
  ATTACK UPGRADES                             [x5]   ← multi-buy, one per category
  Beat waves before they hit.
  Buy when the ring isn't closing before the timer runs out.
  ┌──────────────────────┐┌──────────────────────┐
  │ TAP        ┌───────┐ ││ DAMAGE PER ┌───────┐ │   name opens the detail,
  │ DAMAGE     │     4 │ ││ SECOND     │     3 │ │   the box buys
  │            │x2·91 ©│ ││            │x3·539©│ │
  └──────────────────────┘└──────────────────────┘
  ┌──────────────────────┐┌──────────────────────┐
  │ DAMAGE     │  ×1.15 │ ││ TICK SPEED │ ×1.44 │ │
  └──────────────────────┘└──────────────────────┘
  ┌────────┬─────────┬─────────┬──────────┐
  │ ATTACK │ DEFENSE │ UTILITY │ ULTIMATE │            ← fixed strip
  └────────┴─────────┴─────────┴──────────┘
  [ NUMBER  WORKSHOP  LABS  CARDS  MORE ]              ← nav dock
```

**In a run** — step 7, when the Rig arrives. The dock is not shown, so the strip sits flush:

```
              $ 66.99K      WAVE 10 / 191
  ┌──────────────────────────────────────────┐
  │              the ring and the Number      │    top ~55%
  │              WAVE 47 · HITS FOR 900 IN 6s │
  └──────────────────────────────────────────┘
  ATTACK UPGRADES                        [x5]
  ┌──────────────────┐┌──────────────────┐        bottom ~40%, always open,
  │ TAP DAMAGE   4.2 ││ DAMAGE/SEC   890 │        prices in Number
  └──────────────────┘└──────────────────┘
  ┌────────┬─────────┬─────────┬──────────┐
  │ ATTACK │ DEFENSE │ UTILITY │ ULTIMATE │
  └────────┴─────────┴─────────┴──────────┘
```

**This costs the run screen real estate, and that is the accepted trade.** The ring stage has to shrink to roughly the top half so the panel can hold four rows without scrolling. Pillar 1 says the main screen never becomes a spreadsheet; a permanently open panel is closer to that line than the sheet this document first proposed. What keeps it the right side of the line is that the panel holds one category at a time, four rows of two, with no description text — the detail lives behind a tap, as the reference does it.

### Multi-buy (D018)

Each category carries a buy multiplier — `x1 · x5 · x10 · MAX` — shown beside the category header and cycled by tapping it. `MAX` takes every rank the player can afford, up to the row's cap. Ranks are priced one at a time and summed, so a press is never cheaper or dearer than buying the same ranks individually, and the cost shown is the cost paid. The card's cost line shows what the press will actually do: `x3 · 539 ©` when three ranks will land, a bare price when one will.

### The card is compact; the detail is one tap away

Two cards to a row. Each card carries the stat's name on the left and a value-and-cost box on the right:

- the **name** opens a detail panel with the description, the current rank and its value, and the max rank and its value;
- the **box** shows the row's value at its current rank, the cost of the next press underneath, and buys when tapped.

Values are derived from the row's own declared effect rather than authored twice, so a card cannot drift from what the rank grants. Rows with no declared effect (Burst, Crit Chain) show their rank instead, which is what their descriptions already talk in.

### The two lenses read as two lenses

Each panel keeps a one-line banner in the place the Workshop already puts one:

- Workshop: `PERMANENT · APPLIES TO EVERY RUN` (unchanged).
- Rig: `THIS RUN ONLY · RESETS WHEN THE RUN ENDS`.

Each category opens with its purpose and its "buy this when" line. Attack, Defense and Utility are open from the start; Ultimates opens too but holds a locked panel naming the waves that unlock it. (Defense was to unlock on the first hit, but Armor is available from wave 1 today and gating it would remove access — see [What step 3 changed](#what-step-3-changed-and-what-it-deliberately-did-not).)

Not adopted from the reference: Preset 1 / Preset 2, Respec, and the Upgrade / Enhance split. Presets and Respec need a reason to exist before they earn a seat, and Enhance is a second permanent tier that the four categories do not yet need. The reference's per-category colours are also not adopted: this HUD deliberately carries one accent, because per-tab hues read as noise against the stage.

### Labs, Insight and Prestige stop being tabs (D016)

Research Focus is chosen once per Prestige. Insight is one repeatable row. Prestige is rare and irreversible. None of the three earns a permanent seat on the bar, and two of them currently hold one.

They move into a single **Knowledge sheet**, opened by tapping the Knowledge chip already sitting on the run screen, and listed in MORE. The currency is the door to its own spend; the same rule sends the Coins chip to the Workshop. The `highest_number` gates at 10 / 1,000 / 110,000 move with them and gate rows inside the sheet rather than icons on the bar.

### The run screen

This keeps the single ring from the restage.

- The ring is the wave's HP, closing as you deal damage, and its colour heats as the hit approaches. Both are unchanged.
- One line under the ring reads `HITS FOR 900 IN 6s`, replacing `LIABILITY … LEFT · COLLECTION …`.
- When the ring closes, a short `BEATEN` beat plays, then the Number climbs for the rest of the timer. The climb is the reward.
- A hit shows `−900` in the warning colour on the Number, then `STILL STANDING · HITS AGAIN IN 15s` if the wave survives.
- Warm-up waves read `WARM-UP · EVERYTHING BANKS`.
- A ready or firing Ultimate announces itself on the wave line — `SURGE · ALL DAMAGE ×3 FOR 8s` — so it needs no button and no open panel. Ultimates fire on their own (D013, pillar 1); the Rig's Ultimate tab levels them, it does not trigger them.

### The run-over screen becomes the place you fix it

It shows what killed you, what would have saved you, and the two doors to go and buy it:

- **Attack:** how much more damage per second would have beaten that wave inside one timer, for example `2.4× more damage`.
- **Defense:** how much smaller the hits needed to be for you to survive until you beat it, for example `hits 35% smaller`.
- The run's hits taken and the Number lost to them.
- Two actions: `WORKSHOP` and `SPEND KNOWLEDGE`.

The smaller of the two gaps points at the tab to open next. Both numbers come deterministically from state the game already holds. This is the vision's "every number that kills you was visible before it did", applied after the fact as well — and with Labs and Insight off the bar, this screen is where the meta loop is actually offered, at the moment the currency lands.

## Strategies this supports

| Build | Leans on | Plays like | Good for |
| --- | --- | --- | --- |
| Clear-all | Attack | Beats waves in one timer, is never hit, and the Number climbs fast; falls over at the first wall | Farming comfortable waves quickly |
| Grinder | Defense (Armor, Siphon, Recoil) | Gets stuck and grinds through; slow but deep | Bosses and walls beyond your damage |
| Banker | Utility | Farms a comfortable tier for Coins and Knowledge per minute | Funding the next push |
| Burst | Ultimates | Surge and Breach land on bosses | Boss waves and milestone pushes |
| Reinvestor | The Rig | Banks overflow on easy waves and spends it the moment a wave starts resisting | Pushing one tier deeper than the permanent build allows |

The Rig does not add a fifth strategy so much as a second timescale to the four above. The same permanent build plays differently depending on whether its owner spends inside the run or hoards Number as a buffer, and that is the choice the run screen has been missing.

Higher tiers can ask for different builds by changing the *shape* of waves as well as their size. Today D002 multiplies both axes by the same 20× and 60×, so every tier asks for the same build. A later decision could skew them. For example, Tier 2 could start hot, with a hit at wave 1 that calls for Cushion and Armor, and Tier 3 could hit hard relative to its HP, calling for Defense first. Tier conditions would enter through the modifier pipeline (D005), which already supports this. **This is a recommendation only. D002 stands until a new decision replaces it.**

## Balance targets for the retune

Targets 1–4 gate D012's retune; 5 and 6 gate step 4's new stats. `tools/balance_simulator.gd` measures them with its build matrix.

1. A fresh first run still ends around wave 21 and banks at least 48 Coins (D010, and the invariant that the first failed run funds a rank). *Met: wave 21, 48 Coins.*
2. Coins per minute at equal builds are within ±10% of the pre-D012 baseline. *This measures the D012 retune, not the Workshop: Coin Bonus (step 4b) is meant to lift Coins per minute, and does, by 49% at its cap. Compare like builds, not maxed ones.* *Met for the main progression builds: mid −2%, Max Attack −7%, Max Attack + Armor +6%. Two small runs sit above: early is +20% (2.4 Coins a minute) and Tier 2 is +19%, because both go relatively deeper now. Recheck when step 4 adds new Coin sinks.*
3. Tier 1 wave 100 is reachable for a Workshop investment comparable to before. *Met: Max Attack + Armor 40% reaches wave 100, as it did before.*
4. A player who has just unlocked Tier 2 survives its opening waves. *Met: that build reaches Tier 2 wave 26 (was 28).*
5. **The cheapest build that reaches Tier 1 wave 100 includes both Attack and Defense.** This is pillar 2 written as a test. ***Met, and worth watching:*** *maxed Attack alone reaches wave 96 and maxed Defense alone reaches 25, so wave 100 still needs both, and the cheapest route is maxed Attack plus Armor. Boss Damage moved Attack's solo reach from 90 to 96 in step 4b; another Attack row of that size would break this target.*
6. Every stat's first rank visibly moves a simulator outcome. ***Met at the cap for every new stat, with two qualifications:*** *Cushion moves Tier 2 and deliberately not Tier 1, and Brace Cost cannot be measured by a simulator that never Braces — it is covered by test rather than by simulation. Utility's two bonuses move Coins and Knowledge rather than the wave reached, which is the category's whole point. Sizes were chosen from the older measurements that showed Siphon at 10% adding nothing: Siphon caps at 25% and Recoil at 50%.*

Targets 7–9 gate the Rig (step 7). All three need the simulator to model in-run spending, which is itself part of that step.

7. **The Rig cannot replace the Workshop.** A fresh permanent build playing the Rig perfectly does not reach a wave that previously required Workshop investment. If it does, the meta loop is optional and pillar 3 is decorative.
8. **The Rig cannot be ignored.** At the top build, playing the Rig reaches meaningfully deeper than hoarding Number does. If it does not, the panel is four tabs of noise.
9. **No runaway.** Over a long run, Rig cost growth outruns Number income: no build reaches a state where every row is affordable on every wave.

## Implementation order

Each step lands on its own and clears the gate for its risk level in [`QUALITY_GATES.md`](QUALITY_GATES.md).

| Step | What | Risk |
| --- | --- | --- |
| 1 | **Done.** D012 rule in `GameState._add_number`, `tax-foundation-v2` retune, simulator build matrix, and the run screen's rate line (it said `+X / sec` while output was going into the wave) | High: economy and encounter |
| 2 | Player vocabulary (D014) in the remaining UI strings: the encounter line, hit toasts, Brace and Shield text, floating `+X` on taps, the drawer's `NUMBER / SEC` | Low to medium |
| 3 | **Done.** Four Workshop categories; bays retire; Shield Matrix becomes the Armor Workshop row; Research Focus retargets from bay to category; save schema V5 (D017) migrates `selected_bay`, `focus` and `tax_resistance_rank` with no rank lost and a live run intact. Also the reference layout: category strip pinned at the bottom, compact two-column cards with the detail one tap away, and multi-buy (D018) | High: save schema and a purchase path |
| 3b | **Done.** Deep rank ladders (D019): 51 ranks become 906 at the same total Coin cost and the same value at every cap; gates move to 0 / 12 / 30 / 60 and Research Focus to 120 | High: economy |
| 4a | **Done.** The five new Defense stats (D020): Siphon, Recoil, tier-scaled Cushion, Brace Cost, Second Wind. Targets 5 and 6 met | High: economy |
| 4b | **Done.** Boss Damage, Coin Bonus and Knowledge Bonus (D021); Research Focus balanced across all three categories | High: economy |
| 5 | The bar reshape (D016): four category tabs between runs, Labs, Insight and Prestige into the Knowledge sheet, `highest_number` gates moved inside it | Medium: presentation only, no save or economy change |
| 6 | "What would have saved you" and the two doors on the run-over screen | Medium |
| 7 | **The Rig** (D015): the in-run panel, Number prices against wave HP, run-scoped ranks saved with the active run, Brace into the Defense tab and Shield off the run screen | High: economy and save |
| 8 | Ultimates, in both lenses | High: new timed effects and saved cooldown state |

Step 2 should follow step 1 closely, so the new rule is explained on screen in the new words.

Step 3 is the only hard prerequisite for the Rig: it needs a catalogue organised by category to draw on. Step 4 is a soft one — without it Defense is a one-row tab, which undercuts the point of having four. Steps 5 and 6 are independent of 7, so **the shortest path to the in-run panel is 3 → 4 → 7**, with step 5's in-run half landing alongside it because the in-run bar and the between-runs bar are the same control. Do not build the in-run bar at step 5 with nothing behind it.

Held true by step 1:

- `lifetime_generated` counts all output, so the Knowledge formula is unchanged; Knowledge per minute holds.
- `highest_number` runs lower, but the 110,000 dock unlock is still reached by Max Attack builds.
- Brace still costs 30% of the Number. With a smaller Number it is cheaper in absolute terms and a more meaningful choice.
- Save shape is unchanged. A save taken mid-wave before step 1 resumes that wave with its saved HP and hit, then continues on v2 curves.

## Open questions

1. **What Ultimates cost to upgrade permanently.** Recommendation: Knowledge. It gives Knowledge a second sink beside Insight and adds no currency (pillar 4). The alternative, Coins, competes directly with the Workshop. Their in-run levels cost Number like every other Rig row.
2. **The Tier 2+ opening.** Should Cushion scale with the tier, or should every tier get a few warm-up waves? Recommendation: scaled Cushion, because it makes the opening a Defense decision rather than a free pass. The Rig sharpens this: on Tier 2 the first hit lands before there is any Number to spend, so the opening is the one stretch of a run the Rig cannot help with.
3. **Tier shapes.** Whether and when to skew Tiers 2 and 3 away from uniform multipliers. That would supersede part of D002.

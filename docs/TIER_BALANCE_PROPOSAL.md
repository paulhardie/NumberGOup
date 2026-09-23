# Tiers 1–10 balance proposal

**Status:** Proposed, 23 September 2026. Nothing here is accepted: every change below needs its decision recorded in [`DECISIONS.md`](DECISIONS.md) before it is built, and several supersede accepted ones (listed in [Decisions this needs](#decisions-this-needs)).
**Scope:** Tiers 1–10. Tiers 11 and beyond are left for later, but the rules here are meant to carry on past 10 without a redesign.
**Evidence:** `run_balance.sh` on `tax-foundation-v4`, a measurement of damage against Coins spent on the real Workshop, and a coarse career model, [`tools/career_model.py`](../tools/career_model.py). Every hour figure below comes from that model. Read them as *shapes* to compare, not as promises; [how far to trust the model](#how-far-to-trust-the-model) sets out its limits.

## The short version

Today's game cannot carry ten tiers, and its long-run pacing runs backwards. Four things cause that:

1. **The Workshop runs out.** Every Attack row maxed (about 41,000 Coins) takes damage from 3 to 203 a second. With Knowledge set aside, that build, plus maxed Defense, stalls at Tier 2 wave 38 (the simulator) or 37 (the model), permanently.
2. **Insight is the only open-ended engine, and it snowballs.** Each Knowledge buys ×1.02 damage at a flat price, forever. In the model the first tier takes about 12 hours of play, the second 18, and then every later tier gets *faster*, down to 2–3 hours each. On The Tower's ten-tier table, all ten tiers take 54 hours, and the last seven take 24 of them.
3. **Every wave lasts 15 seconds, however easily it is beaten.** A push to wave 100 is at least 25 minutes; in practice 40–50. A strong player spends most of a run watching waves they have already mastered.
4. **Attack quietly does Defense's job.** Damage beyond a wave's HP becomes Number, and Number is health, so a pure Attack build is also the best-defended build. The simulator's max-Attack build reaches wave 97 of the 100 that are supposed to need Defense, and in the model an all-Attack player finishes ten tiers about 20% faster than a balanced one.

The proposal answers those with seven changes that reinforce each other:

| # | Change | What the player notices | Fixes |
| --- | --- | --- | --- |
| 1 | **Every tier adds a zero.** Wave HP ×10 per tier; Coins ×2.5 per tier; each tier's Hits skewed to ask for a different build | Each new tier is a new order of magnitude, and Number reaches about 10¹⁴ by Tier 10 | Pacing, identity |
| 2 | **Rush.** A broken wave ends there and then, and the rest of its timer pays out in one burst | Early waves fly by, and every clear lands a visible lump of Number | Time floor, flat Number |
| 3 | **The Rig multiplies what you brought.** Each Rig rank is a percentage (×1.2 damage), priced in seconds of your own damage | Rig choices matter at every build, from the first run to Tier 10 | Rig that doesn't pay back early |
| 4 | **Knowledge grows with the Number; Insight adds rather than compounds.** Knowledge per run ∝ √(damage dealt); +5% damage per Knowledge | Knowledge becomes a big, satisfying number too, and later tiers take longer rather than shorter | Insight runaway |
| 5 | **Workshop bands.** Each tier unlocked opens another band of ranks on the multiplying rows | Coins stay worth earning at every tier | Workshop runs out |
| 6 | **Breakthroughs.** Clearing a tier offers a choice of one permanent boost | One big moment per tier | Pacing past Tier 5 |
| 7 | **Toll tiers.** On Tiers 2, 5 and 8, every wave lands its Hit once as it arrives | Some tiers can't be brute-forced with damage | Attack doing Defense's job |

What the model says the whole package does:

| | Today's systems (The Tower's ten tiers) | This proposal |
| --- | --- | --- |
| First run | wave 23, 8.2 min | wave 23, 6.2 min |
| Tier 1 wave 100 | 12.2 h | **3.2 h** |
| Tier 5 wave 100 | 41.8 h | 19.5 h |
| Tier 10 wave 100 | 54.4 h | 72.7 h |
| Each tier compared with the one before | 0.8×, faster and faster | **1.3×, a steady climb** |
| Push run to wave 100 | 44–51 min | 12–33 min |
| Peak Number at Tier 10 | 5 × 10⁹ | 9 × 10¹³ |

The headline is the shape, not the totals: a quick first tier, then each tier asking a bit more than the last, with the Number growing by an order of magnitude every time. Tier by tier it is a gentle sawtooth rather than a smooth curve: each Toll tier takes longer, and the tier after it is quicker (in the model Tier 8 takes 11.4 hours and Tier 9 7.5). That reads as a wall, then a reward, which is arguably good pacing, but it's worth watching.

## What the game does today, measured

### Power runs out after the Workshop

The real Workshop, buying the cheapest next Attack rank each time, at two taps a second:

| Coins spent on Attack | 0 | 100 | 1,000 | 2,700 | 7,000 | 18,000 | 41,000 (all maxed) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Damage a second | 3.0 | 6.3 | 15 | 29 | 51 | 104 | 203 |

That is ×68 in total. Tier 2 is 20 times Tier 1 and Tier 3 is 60 times, so the Workshop alone cannot reach either tier's wave 100: `run_balance.sh` puts the everything-maxed build at Tier 1 wave 110 and Tier 2 wave 38. Labs (Damage Research: at most ×1.49, over weeks of real time) and Cards (at most ×1.19) do not change that.

### Insight carries everything, then runs away

Insight is ×1.02 base production per rank, one Knowledge per rank, uncapped. Knowledge per run is `4 × log10(output ÷ 110,000)`: about two per run at the top of Tier 1. Because Insight compounds while Knowledge grows with the *logarithm* of output, the two together accelerate, and each tier is quicker than the one before:

| Model, today's systems on The Tower's table | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Hours for this tier | 12.2 | 18.5 | 4.9 | 3.0 | 3.1 | 2.4 | 1.6 | 2.3 | 3.0 | 3.3 |

Without Knowledge, the same player is still stuck in Tier 2 at 150 hours.

### Runs are long, and the Rig loses to hoarding

Every wave lasts its full 15 seconds even when it breaks in one. The model's push runs to wave 100 take 44–51 minutes; the simulator's maxed Attack build takes 39. The Rig, meanwhile, still loses to simply keeping the Number at early and mid builds (wave 25 against 30, wave 40 against 50). That is because a Rig rank is worth three *deep-ladder* Workshop ranks (D019 divided each rank's effect by about 20), and it is priced against the wave's HP, not against what the player can do. At a fresh build a rank is worth about +2%.

### Attack is also Defense

Overflow becomes Number, and Number absorbs Hits, so more damage means both fewer Hits and a bigger buffer. Target 5 holds by three waves (max Attack reaches 97; adding Armor reaches 100). In the model, with Hits skewed harder on some tiers, an all-Attack player still finishes all ten tiers in 65 hours, against 79 for a 70/30 Attack/Defense split.

## What "fun, and the Number goes up" means in numbers

These are the targets the proposal is tuned against. They extend the core-loop review's proposed targets in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md#core-loop-balance-review--proposed-23-september-2026); where the two overlap, that review's wording stands.

| When | Target |
| --- | --- |
| First run | 3–4 minutes; the Number rises in the first 30 seconds; a Rig choice is affordable at once and noticeably changes the run |
| First hour | 6–10 runs; the Workshop visibly moves every run; Tier 1 wave 30–40 |
| Tier 1 wave 100 (Tier 2 unlocks) | about 3 hours of play |
| Each later tier | on average 1.2–1.4× the previous tier's time; later tiers never get *faster* on average |
| Tier 10 wave 100 | about 60–100 hours of play for an engaged player |
| A push run | 10–30 minutes; no stretch of mastered waves longer than a minute or two |
| The Number | adds one digit per tier: thousands in Tier 1, millions by Tier 3, billions by Tier 6, about 10¹⁴ by Tier 10 |
| Every tier | asks for something the previous one didn't, and ends with one big moment |
| Builds | a balanced Attack/Defense player is never slower than an all-Attack one across the ten tiers |
| The Rig | worth roughly ×2–3 damage by the end of a push run at *every* build; a player who ignores it still finishes, more slowly |

**The 60–100-hour figure is a product decision, not a law** (see [Decisions](#decisions-this-needs)). Every lever below can make it shorter or longer without changing its shape.

## The proposal

### 1. Every tier adds a zero

Wave HP follows a clean ladder of ×10 per tier from Tier 1. Hits follow the same ladder, then get a per-tier skew so neighbouring tiers ask for different builds. Coins rise ×2.5 per tier.

| Tier | Wave HP × | Hit × (skew) | Coins × | Condition | Asks for |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 1 | Warm-up, waves 1–20 | Learning the loop |
| 2 | 10 | 20 (×2) | 2.5 | **Toll** | Defense: Cushion and Armor |
| 3 | 100 | 70 (×0.7) | 6.25 | — | Attack, Crit, the Rig |
| 4 | 1,000 | 1,000 | 15.6 | — | Balanced; Boss Damage |
| 5 | 10⁴ | 2.5 × 10⁴ (×2.5) | 39 | **Toll** | Defense, harder |
| 6 | 10⁵ | 7 × 10⁴ (×0.7) | 98 | — | Attack |
| 7 | 10⁶ | 10⁶ | 244 | — | Balanced |
| 8 | 10⁷ | 3 × 10⁷ (×3) | 610 | **Toll** | Defense, hardest |
| 9 | 10⁸ | 7 × 10⁷ (×0.7) | 1,526 | — | Attack |
| 10 | 10⁹ | 1.5 × 10⁹ (×1.5) | 3,815 | — | Everything |

What that looks like on the ring:

| Tier | Wave HP, wave 1 → wave 100 boss | Hit, wave 1 → wave 100 boss | Coins for the wave 100 boss |
| --- | --- | --- | --- |
| 1 | 20 (warm-up) → 55K | 1 (warm-up) → 12K | 325 |
| 2 | 94 → 555K | 250 → 245K | 812 |
| 3 | 940 → 5.6M | 876 → 858K | 2,031 |
| 5 | 94K → 555M | 313K → 306M | 12,695 |
| 7 | 9.4M → 55B | 12.5M → 12B | 79,346 |
| 10 | 9.4B → 55T | 18.8B → 18T | 1.24M |

**Why ×10 and ×2.5.** A build that has just cleared a tier's wave 100 lands at about **wave 42** of the next tier: the classic tier drop, where the new tier opens at once but its wave 100 is a real climb. Coins at ×2.5 keep D002's honesty: at equal *difficulty* the two tiers pay about the same (wave 100 below pays 65 × the lower tier's Coins; the equally hard wave 42 above pays 68), so the harder tier isn't automatically the better farm. Past its landing wave, the new tier pays better, which rewards the push.

**Why the skew goes on Hits, not Wave HP.** Wave HP is the pacing spine: skewing it made the Wave-HP-heavy tiers grind to 42–53-minute runs in the model and made them up to twice as slow. Hits change what a build needs without changing how long the climb is.

**Why ×10 rather than The Tower's table.** The Tower's ten tiers span 40,320×, less than five zeros; it saves its big jumps for Tiers 11–24. Number Go Up is a game about the Number itself, so "one more digit every tier" is both the balance and the promise on the tin, and it carries on unchanged into Tiers 11+.

Mechanically, this is tier data: the profile's tier table grows from three rows to ten, and the tier picker lists them. The existing formula and milestone structure stay. Tier unlocks stay "clear wave 100 of the tier below". Existing Tier 2 and 3 records keep their best waves, but **both tiers change difficulty**: Tier 2 halves its Wave HP, keeps its Hits and gains Tolls; Tier 3 goes from 60× to 100× Wave HP and 70× Hits.

### 2. Rush: a broken wave ends there and then

Today a wave you break at second 4 still runs its full 15 seconds, with the overflow trickling into the Number. With Rush, the wave ends the moment it breaks. The rest of its timer's damage is added to the Number **in one burst**, exactly what the trickle would have paid, and the next wave starts. A wave never lasts less than **3 seconds**, so each clear still has a beat to land.

- **Same Number, less time.** Per wave, a player earns exactly what they earn today. Nothing about D012 changes: damage still beats the wave before it becomes Number.
- **The Number goes up in visible lumps.** Every clear is a small payout. This is the "burst on break" half of Gemini's piñata idea, delivered by the rules rather than an animation.
- **Mastered waves stop costing real time.** In the model, removing Rush makes the whole ten-tier career 77% longer (72.7 to 128.5 hours), and push runs go back to 28–49 minutes, against 12–33 with it. That extra time is almost entirely spent on waves the player has already mastered.
- **Attack pays in time, not in extra Number.** This is why Rush is safer for the Attack/Defense balance than Fever (which multiplies post-clear Number and stays parked). A faster build earns more Coins per minute, not a bigger health bar per wave.
- **Stuck waves are unchanged.** A standing wave still hits every 15 seconds.

It touches the encounter clock, so it's high risk: RNG and tick phase must stay deterministic (the burst is computed, not simulated at 10× speed), and a saved run must resume identically. The Coin-per-minute targets need re-measuring, because a strong build farms faster.

### 3. The Rig multiplies what you brought

**Rule:** the Workshop raises the floor, and the Rig multiplies it. Each Rig rank is a percentage of what the player already has, and is priced in seconds of the player's own damage rather than in Wave HP.

| Rig row | Per rank | First rank costs | Each further rank |
| --- | --- | --- | --- |
| Damage | ×1.2 all damage | 15 seconds of your current damage | ×2.0 |
| Boss Damage | ×1.5 against bosses | 8 seconds of your damage | ×2.0 |
| Armor | Hits ×0.9 (to the 75% ceiling) | 15 seconds of your damage | ×2.0 |
| Siphon | +5% (to the 50% ceiling) | 15 seconds of your damage | ×2.0 |
| Recoil | +10% (to the 100% ceiling) | 15 seconds of your damage | ×2.0 |
| Coin Bonus | +10% Coins for the rest of the run | 30 seconds of your damage | ×1.8 |

The prices and step sizes are starting values for the career simulator to tune; the principle is the proposal. Why this shape:

- **It's worth the same at every build.** A +20% rank is +20% whether the player has 3 damage a second or 3 billion, so the first run finally has a Rig decision that changes something. In the model the player buys about **five ranks per push run at every tier**, about ×2.5 by the end: a real in-run arc, the same at Tier 1 and Tier 10.
- **It can't run away.** A rank adds 20% of output, and the next one costs twice as much: price grows faster than income, so ranks thin out through the run (target 9 by construction).
- **It is optional.** A player who never touches the Rig still clears all ten tiers in the model, in 137 hours rather than 73, so it roughly halves the career without being mandatory.
- **It is simpler.** A handful of multiplier rows replaces a mirror of ten deep-ladder Attack rows, which serves pillar 1 (simple surface) better.

Pricing in "seconds of your damage" should use the steady damage rate the HUD already shows, excluding the current tap burst, so a price doesn't flicker while the player taps.

This supersedes part of D015 (the Rig sells "the same stat catalogue") and D023 (a rank is worth three Workshop ranks). **Target 7 needs rewording**: a scale-free Rig can let a fresh player go a few waves deeper, which is fun rather than a threat, as long as the Workshop still sets the starting line. Proposed wording: *an equally skilled player with more Workshop investment always goes deeper*.

### 4. Knowledge grows with the Number; Insight adds, not compounds

- **Knowledge per run = √(damage dealt in the run ÷ 100,000)**, times Knowledge Bonus, paid on death or Prestige as today. At the top of Tier 1 that is a few a run, about what it pays today; by Tier 10 it is tens of thousands a run. Knowledge becomes another number that goes up.
- **Insight = +5% damage per Knowledge spent, added together, not compounded.** A thousand Knowledge is ×51, not ×400 million.

Why: the Number grows ×10 a tier, so Knowledge grows ×3.2 a tier (the square root), and Insight follows it. That automatic ×3 a tier is the career's backbone, and it *cannot* snowball, because it is a square root rather than a power. Swapping just this piece back to today's rules turns the proposal's 73-hour career into a 17-hour one, with later tiers again getting faster. That is exactly the runaway described above.

Existing saves: Insight ranks are declared permanent progress, so **migration must never lower a player's multiplier**. Convert each save's Insight ranks to at least the Knowledge that reproduces its current ×1.02ⁿ under the new rule. The formula and Knowledge's other future uses (the open question of Ultimates costing Knowledge) need checking together.

### 5. Workshop bands: each tier opens more Workshop

Each tier unlocked opens one more **band** of ranks on the rows that multiply damage (Damage Multiplier, Tick Speed, Crit Damage) and on Coin Bonus. Target elasticity: beyond today's caps, **damage grows with the square root of Coins spent**, and each band costs about **four times** the one before. Coins grow ×2.5 a tier, so each band takes a little longer to fill than the last, and the Workshop is never simply "done".

The percentage Defense rows (Armor, Siphon, Recoil, Brace Cost, Second Wind) keep their caps, because their value is already the same at every tier. Cushion already scales with the tier. Rank *values* at today's caps are a contract ("A Workshop row's value at its maximum rank is a contract"), so bands add ranks beyond today's caps rather than stretching existing ones.

The exact per-rank values are for the career simulator (step 0 below). As a starting shape: Damage Multiplier's band ranks are ×1.035 each at 1.10 cost growth, 20 ranks a band, which is about ×2 a band.

### 6. Breakthroughs: one choice per tier cleared

When a tier's wave 100 falls, the game offers **one of three permanent Breakthroughs**, each worth about ×1.4 in its own direction, for example:

- Damage ×1.4
- Hits ×0.7
- Coins and Knowledge ×1.4

It uses the name the vision already reserves, arrives through the modifier pipeline as a permanent modifier (pillar 5), and gives each tier a big, visible moment and a real build decision. Without it, the model's tier times grow ×1.5 a tier: fine to Tier 5, but Tier 10 is still out of reach at 250 hours. With a ×1.4 Breakthrough, the growth settles at ×1.3. **The size of the Breakthrough is the main dial for total career length.**

### 7. Toll tiers: some Hits can't be outrun

On Tiers 2, 5 and 8, every wave lands its Hit **once, as it arrives**, as well as at each 15-second boundary it survives. Breaking a wave fast stops the *later* Hits but never the first, so only Defense (Armor, Cushion, Brace, Siphon and the Defense Breakthrough) shrinks the toll.

In the model this flips the build balance: an all-Attack player can't clear Tier 2 at all, because it arrives with no Cushion. A 70/30 player finishes all ten tiers in 72.7 hours and a 50/50 player in 81. Without Tolls, all-Attack was the fastest route. Tolls also give the three Defense tiers a readable identity. The run-over screen already says "Lost to: the Hit" and shows the Number shortfall, which points the player straight at Defense.

A Toll is a tier condition: it enters the modifier pipeline as a rule on Collection rather than a special case in `GameState` (pillar 5, architectural law 3).

**Watch-out:** as modelled, this is a hard gate. The first Cushion ranks must be cheap enough that a player bouncing off Tier 2 can fix it in one Workshop visit. Tier 2's landing must be survivable with modest Defense, not only with a lot.

### 8. The first run

With Rush and the new Rig, the model's first run shortens from 8.2 to 6.2 minutes at the same wave 23. The first Rig rank (×1.2 damage for about 45 Number at two taps a second) is affordable from the 50 starting Number, and every early clear bursts into the Number. That meets "Number rises in the first 30 seconds" and "a consequential Rig choice at once". **It does not yet meet the 3–4-minute target.** The warm-up's length and HP growth need retuning in the real per-second simulator once Rush and the new Rig exist, measured against the core-loop review's targets.

*Superseded on 23 September 2026: D037 replaced D012, and Rush is part of it.* This proposal **keeps D012**. Rush and the scale-free Rig attack the flat-Number problem without diverting damage. The 10%-tap split stays the documented alternative if a phone playtest still finds the opening flat.

### Labs, Cards, Ultimates and Gems

- **Labs and Cards stay seasoning**: each worth up to about ×1.5–2 across the whole career, never a spine. Labs' Damage and Resilience Research could open a band per tier like the Workshop, but only if the career simulator shows Labs being ignored.
- **Ultimates** keep their milestone unlocks (waves 10, 25, 50 and 100). Their effects are already percentages (Surge ×N, Breach X% of max HP), so they work at every tier unchanged.
- **Gems** stay with the separate Gem economy pass. Tier 10's checkpoints pay far more Gems than today's at ×2.5 a tier, which that pass must price.

### Considered, and not proposed

- **A default Siphon rising to 50%+** (Gemini): brings back the pre-D012 problem of earning Number while losing.
- **Fever**, where post-clear Number is multiplied: parked by owner instruction. Rush delivers the "clearing fast pays" feeling through time rather than health, which the Attack/Defense balance can survive.
- **Interest on held Number** (The Tower's in-run interest): a strong hoard-versus-spend tension with the Rig, but a third new Number flow on top of Rush and Siphon. Revisit if the Rig or Defense still feels flat after this pass.
- **Skewing Wave HP by tier**: made HP-heavy tiers up to twice as slow in the model, with 40–50-minute push runs.

## How far to trust the model

[`tools/career_model.py`](../tools/career_model.py) plays whole careers with one calculation per wave instead of per tick, and runs every scenario above in about a second. It reproduces the two checks that matter: a fresh run (wave 23, 8.2 minutes, 56 Coins, against the simulator's 23, 8.3 and 56) and the Workshop's ceiling (Tier 2 wave 37 against the simulator's 38).

**It does not model:** crit randomness, Brace, Second Wind, Labs, Cards, Ultimates, Workshop level gates, farming a lower tier instead of pushing, a player tapping less as the game goes on, or the exact band and Rig row values. Its Defense is a single curve (Armor, then Recoil, then Siphon), and its player buys the Rig perfectly while keeping two Hits in reserve. So:

- **Trust:** the comparisons. Today's pacing runs backwards; the Workshop alone can't pass Tier 2; the Insight snowball is real; Rush, the new Rig and Breakthroughs are each worth a large share of career time; Tolls flip the Attack-versus-Defense result.
- **Don't trust:** any absolute hour figure to better than about ±50%, or any single coefficient as final.
- **Not measured at all:** the first-hour target, the 3–4-minute first run, and how any of this feels on a phone.

| Model scenario | First run | T1 w100 | T5 w100 | T10 w100 | Each tier vs previous |
| --- | --- | --- | --- | --- | --- |
| Today, as shipped (T1–3) | W23, 8.2 min | 12.2 h | — | — | — |
| Today's systems on The Tower's table | W23, 8.2 min | 12.2 h | 41.8 h | 54.4 h | 0.81× |
| Today's systems, no Knowledge | W23, 8.2 min | 12.9 h | stuck in T2 | — | — |
| **Proposal** | W23, 6.2 min | **3.2 h** | **19.5 h** | **72.7 h** | **1.30×** |
| without Rush | W23, 7.8 min | 5.6 h | 36.1 h | 128.5 h | 1.25× |
| without the new Rig | W23, 7.1 min | 6.7 h | 36.6 h | 137.4 h | 1.27× |
| without Breakthroughs | W23, 6.2 min | 3.2 h | 37.6 h | stuck in T10 at 250 h | 1.50× |
| with today's Knowledge and Insight | W23, 6.2 min | 3.5 h | 12.4 h | 16.8 h | 0.87× |
| without Toll tiers | W23, 6.2 min | 3.2 h | 19.7 h | 78.8 h | 1.32× |
| lighter tapper (60% of the damage) | W21, 5.2 min | 5.7 h | 28.2 h | 101.9 h | 1.28× |
| all Coins into Attack | W23, 6.2 min | 2.7 h | stuck in T2 | — | — |
| all Attack, no Toll tiers | W23, 6.2 min | 2.7 h | 16.6 h | 65.1 h | 1.29× |
| half Attack, half Defense | W23, 6.2 min | 3.8 h | 21.9 h | 81.1 h | 1.28× |

Reproduce with `python3 tools/career_model.py` (standard library only; it touches no save and runs no Godot).

## Decisions this needs

Each is a separate decision, so they can be accepted, changed or refused independently.

1. **The tier ladder: ×10 Wave HP, ×2.5 Coins, Hit skews, ten tiers.** Supersedes D002's 20×/60× and 1.8×/2.6×, and the invariant that states them. Changes existing Tier 2 and 3 difficulty.
2. **Rush.** A new rule for the wave clock; no decision supersedes it, but it changes Coins per minute everywhere.
3. **The scale-free Rig.** Supersedes part of D015 (the same catalogue) and D023 (worth three Workshop ranks), and rewords target 7.
4. **Knowledge and Insight.** A new Knowledge formula and additive Insight, with a migration that never lowers a save's multiplier. A save-schema change.
5. **Workshop bands.** New ranks beyond today's caps, opened by tiers unlocked; today's cap values stay as they are.
6. **Breakthroughs.** A new permanent layer (the reserved name) and new saved state.
7. **Toll tiers.** The first tier conditions through the modifier pipeline.
8. **Career length.** The proposal aims at 60–100 hours to Tier 10's wave 100 for an engaged player. Recommendation: accept the *shape* (each tier 1.2–1.4× longer than the last) and treat the total as a dial, set mainly by the Breakthrough size.

## Build order

Each step lands on its own, behind its decision, and clears the gate for its risk level in [`QUALITY_GATES.md`](QUALITY_GATES.md).

| Step | What | Why here | Risk |
| --- | --- | --- | --- |
| 0 | **A GDScript career simulator** on the real `GameState`: runs back to back, Workshop buying policy, Knowledge, tier unlocks, hours per tier. First job: reproduce this model's result for today's game | Every later step needs career-length evidence, and the current simulator only measures fixed builds. This is the foundation gap the proposal depends on | Low: a tool |
| 1 | Knowledge and Insight (4) | Removes the runaway before anything else is tuned on top of it; touches saves, so it goes early and alone | High: economy and migration |
| 2 | Rush (2) | Changes Coins per minute and run length everywhere; the Rig and tiers are tuned after it | High: encounter clock and determinism |
| 3 | The scale-free Rig (3) | Needs Rush's run shape; fixes the early-build Rig problem | High: economy, and saved Rig ranks change meaning |
| 4 | Tiers 4–10 data, the ×10 ladder and ×2.5 Coins (1) | Needs 1–3 in place so tiers are tuned once | High: economy, tier records, unlock UI |
| 5 | Workshop bands (5) | Only matters once Tier 2+ is reachable in normal play | High: economy |
| 6 | Breakthroughs (6) | The pacing dial, tuned last against the whole career | High: new permanent state |
| 7 | Toll tiers (7) | Needs the tier table and Defense tuned against it | Medium–high: encounter rule through the pipeline |
| 8 | The first-run retune and a phone playtest | Needs Rush and the Rig; decides whether D012 stays | High: economy |

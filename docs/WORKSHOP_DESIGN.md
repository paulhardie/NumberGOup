# Workshop design

**Status:** Accepted direction. Steps 1–3 (the wave rule, retune, player vocabulary and Workshop categories) implemented 21 September 2026; later steps not yet.
**Decisions:** [D012](DECISIONS.md) (output beats the wave before it becomes Number), [D013](DECISIONS.md) (four Workshop categories) and [D014](DECISIONS.md) (player vocabulary).
**Owns:** the wave rule as the player should understand it, the four Workshop categories and every stat's reason to exist, what the player sees, the build strategies this supports, the balance targets the retune must hit, and the implementation order.

This document uses the accepted player vocabulary (Wave HP, Hit, Armor). [Vocabulary](#vocabulary-d014) maps every term to its current code or save authority.

## The wave, in one paragraph

Each wave has **HP** (the ring) and a **Hit**. Everything you produce, taps and ticks alike, is **damage**, and it goes into the wave first. Beat the wave before its 15-second timer runs out and it never hits you; for the rest of that timer your output overflows into your Number. If the timer runs out with the wave still standing, it **hits** your Number, keeps the HP it has left, and the timer starts again. It hits every 15 seconds until you beat it. If a hit takes your Number to zero, the run ends.

That gives each half of the Workshop one plain job:

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

Player-facing words move away from tax and collection phrasing. The UI string pass is step 2. Encounter code names remain unchanged; D013's later Workshop migration deliberately moved Armor into the normal Workshop purchase map under save V5.

| Former wording | Player sees | Current code or save authority | Plain meaning |
| --- | --- | --- | --- |
| Tax encounter | Wave | `TaxEncounter` | One 15-second fight |
| Liability | Wave HP, shown as the ring | `liability`, `remaining_liability` | How much damage beats this wave |
| Compliance | Damage | `apply_compliance()` | What your taps and ticks do to the wave |
| Liability cleared | Beaten | `is_cleared()` | The wave is done and can't hit you |
| Collection, Tax collected | Hit | `collection` | What the wave takes from your Number when its timer runs out |
| Grace wave · nothing due | Warm-up wave | `is_pressured_wave() == false` | No HP, no hit; everything banks |
| Brace | Brace (keep) | `braced` | Spend 30% of your Number to block the next hit |
| Shield, Shield Matrix | Armor | `purchased["armor"]` | Every hit is permanently smaller |
| Number, Coins, Knowledge, Retreat | Keep | — | — |

Player-facing text never calls the Number "health". It says "If a hit takes your Number to zero, the run ends." That keeps one HP on screen, not two.

## The four categories (D013)

Each category opens with the problem it solves, in the player's words, and every stat has a "buy this when" line, so a player can map any failure to a fix. Stats use plain names in the style of The Tower. Existing flavour names (Hand Press, Desk Dynamo) can stay as subtitles, and existing upgrade ids stay stable for saves.

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
| Boss Damage | More damage against boss waves | New |

Attack consolidates the former Output, Speed and Chance bays, otherwise nearly unchanged. Boss Damage is the one new stat: a targeted choice for players whose runs end on bosses.

### Defense — "Survive the hits"

**Buy Defense when** a wave outlasts its timer and the hits drain your Number. That happens most often on bosses, and from wave 1 on Tier 2 and above.

| Stat | Does | Source |
| --- | --- | --- |
| Armor | Every hit is X% smaller | Former Shield Matrix rank; now `purchased["armor"]` |
| Siphon | X% of the damage you deal still reaches your Number | New |
| Recoil | X% of every hit you take is dealt back to the wave | New |
| Cushion | Start every run with X Number | `priority_buffer` moves here |
| Brace Cost | Brace costs less than 30% of your Number | New |
| Second Wind | Once per run, a hit that would end the run leaves you with X% of your highest Number this run instead | New |

Each works on a different part of being stuck:

- Armor shrinks each hit.
- Siphon refills you between hits.
- Recoil turns being hit into progress on the wave.
- Cushion gives you an opening buffer.
- Brace Cost improves the manual block.
- Second Wind forgives one mistake.

That spread is what makes Defense a build rather than one number.

Cushion does nothing on Tier 1, because warm-up waves bank at least 600 Number before the first hit, even for a fresh player. On Tier 2 and above, the first hit lands at wave 1. That is deliberate: Cushion is the first stat whose value depends on which tier you play. It has to scale with the tier, or it is a trap: today's 250 per rank against Tier 2's wave-1 hit of 500.

### Utility — "Get more from every run"

**Buy Utility when** you survive comfortably but progress between runs feels slow.

| Stat | Does | Source |
| --- | --- | --- |
| Coin Bonus | +X% Coins from every wave beaten | New |
| Knowledge Bonus | +X% Knowledge when a run ends | New |
| Discount | Workshop costs X% lower | `smarter_efficiency` |
| Auto-Brace (later) | Braces for you when the next hit would take more than X% of your Number | New; waits until Brace is a solved decision |

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

## What the player sees

These are requirements. The design is not done if any of them is missing.

**Run screen.** This keeps the single ring from the restage.

- The ring is the wave's HP, closing as you deal damage, and its colour heats as the hit approaches. Both are unchanged.
- One line under the ring reads `HITS FOR 900 IN 6s`, replacing `LIABILITY … LEFT · COLLECTION …`.
- When the ring closes, a short `BEATEN` beat plays, then the Number climbs for the rest of the timer. The climb is the reward.
- A hit shows `−900` in the warning colour on the Number, then `STILL STANDING · HITS AGAIN IN 15s` if the wave survives.
- Warm-up waves read `WARM-UP · EVERYTHING BANKS`.

**Workshop.**

- There are four tabs. Each opens with its one-line purpose and its "buy this when" line.
- Every row shows the plain stat name, current → next value, and cost.
- Defense unlocks the first time a wave hits you, so the tab appears exactly when the player first needs it.
- Ultimates shows all four slots from the start, locked, each labelled with the wave that unlocks it.

**Run-over screen: "What would have saved you".** It shows two numbers, both worked out from the wave that ended the run:

- **Attack:** how much more damage per second would have beaten that wave inside one timer, for example `2.4× more damage`.
- **Defense:** how much smaller the hits needed to be for you to survive until you beat it, for example `hits 35% smaller`.

It also shows the run's hits taken and the Number lost to them. The smaller gap points at the tab to open next. Both numbers come deterministically from state the game already holds. This is the vision's "every number that kills you was visible before it did", applied after the fact as well.

## Strategies this supports

| Build | Leans on | Plays like | Good for |
| --- | --- | --- | --- |
| Clear-all | Attack | Beats waves in one timer, is never hit, and the Number climbs fast; falls over at the first wall | Farming comfortable waves quickly |
| Grinder | Defense (Armor, Siphon, Recoil) | Gets stuck and grinds through; slow but deep | Bosses and walls beyond your damage |
| Banker | Utility | Farms a comfortable tier for Coins and Knowledge per minute | Funding the next push |
| Burst | Ultimates | Surge and Breach land on bosses | Boss waves and milestone pushes |

Higher tiers can ask for different builds by changing the *shape* of waves as well as their size. Today D002 multiplies both axes by the same 20× and 60×, so every tier asks for the same build. A later decision could skew them. For example, Tier 2 could start hot, with a hit at wave 1 that calls for Cushion and Armor, and Tier 3 could hit hard relative to its HP, calling for Defense first. Tier conditions would enter through the modifier pipeline (D005), which already supports this. **This is a recommendation only. D002 stands until a new decision replaces it.**

## Balance targets for the retune

Targets 1–4 gate D012's retune; 5 and 6 gate step 4's new stats. `tools/balance_simulator.gd` measures them with its build matrix.

1. A fresh first run still ends around wave 21 and banks at least 48 Coins (D010, and the invariant that the first failed run funds a rank). *Met: wave 21, 48 Coins.*
2. Coins per minute at equal builds are within ±10% of the pre-D012 baseline. *Met for the main progression builds: mid −2%, Max Attack −7%, Max Attack + Armor +6%. Two small runs sit above: early is +20% (2.4 Coins a minute) and Tier 2 is +19%, because both go relatively deeper now. Recheck when step 4 adds new Coin sinks.*
3. Tier 1 wave 100 is reachable for a Workshop investment comparable to before. *Met: Max Attack + Armor 40% reaches wave 100, as it did before.*
4. A player who has just unlocked Tier 2 survives its opening waves. *Met: that build reaches Tier 2 wave 26 (was 28).*
5. **The cheapest build that reaches Tier 1 wave 100 includes both Attack and Defense.** This is pillar 2 written as a test. *Not yet measurable: Armor is the only Defense stat until step 4.*
6. Every stat's first rank visibly moves a simulator outcome. *For step 4: Siphon at 10% added nothing on v1 curves.*

## Implementation order

Each step lands on its own and clears the gate for its risk level in [`QUALITY_GATES.md`](QUALITY_GATES.md).

| Step | What | Risk |
| --- | --- | --- |
| 1 | **Done.** D012 rule in `GameState._add_number`, `tax-foundation-v2` retune, simulator build matrix, and the run screen's rate line (it said `+X / sec` while output was going into the wave) | High: economy and encounter |
| 2 | **Done.** Player vocabulary (D014) in the encounter line, hit toasts, Brace and Armor text, tap feedback and the drawer's `DAMAGE / SEC` | Low to medium |
| 3 | **Done.** Four Workshop categories; bays retired; Shield Matrix became Armor; Research Focus retargeted from bay to category | High: save schema V5 migrates `selected_bay`, `focus`, bay unlock access and `tax_resistance_rank` without losing ranks |
| 4 | New Defense stats (Siphon, Recoil, scaled Cushion, Brace Cost, Second Wind), then Boss Damage and the Coin and Knowledge bonuses | High: economy; targets 5 and 6 |
| 5 | "What would have saved you" on the run-over screen | Medium |
| 6 | Ultimates | High: new timed effects and saved cooldown state |

Step 2 followed step 1 closely, so the new rule is explained on screen in the new words. Step 3 preserves every existing upgrade id and rank. Armor also preserves Shield Matrix's effect, price sequence and exclusion from Workshop-level gates; only the Workshop organisation, Research Focus scope and Armor save authority changed.

Held true by step 1:

- `lifetime_generated` counts all output, so the Knowledge formula is unchanged; Knowledge per minute holds.
- `highest_number` runs lower, but the 110,000 dock unlock is still reached by Max Attack builds.
- Brace still costs 30% of the Number. With a smaller Number it is cheaper in absolute terms and a more meaningful choice.
- Save shape is unchanged. A save taken mid-wave before step 1 resumes that wave with its saved HP and hit, then continues on v2 curves.

## Open questions

1. **What Ultimates cost to upgrade.** Recommendation: Knowledge. It gives Knowledge a second sink beside Insight and adds no currency (pillar 4). The alternative, Coins, competes directly with the Workshop.
2. **The Tier 2+ opening.** Should Cushion scale with the tier, or should every tier get a few warm-up waves? Recommendation: scaled Cushion, because it makes the opening a Defense decision rather than a free pass.
3. **Tier shapes.** Whether and when to skew Tiers 2 and 3 away from uniform multipliers. That would supersede part of D002.

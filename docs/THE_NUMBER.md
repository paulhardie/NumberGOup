# The Number: design considerations

**Status (6 October 2026):** the Number is the tower **and the run's money** (D158). This page grew over two weeks, and its early sections describe what the Number *was*. **Read the table and "The Number today" first, then only the sections you need.** The owner's answers go into [`DECISIONS.md`](DECISIONS.md) (find one in [`DECISIONS_INDEX.md`](DECISIONS_INDEX.md)), and this page is updated to match.

### Which section to trust

| Section | What it is | Status |
|---|---|---|
| The direction, 1 to 6 | The first design (D080, D081): the Number as the tower's Health, in the centre | **History.** Its decisions stand (D080 to D083) but the Number is no longer only Health |
| 2, 7, 8 | How enemies act on the Number; the enemy brainstorm; our base roster (D133) | **Live** for how Dividers, Locks and flat hits work. 7 is a brainstorm, 8 is built |
| 3, 4, 5 | Systems the Number touches, the screen, the balance plan | **Partly live.** The screen and targets still hold; the Cash and Health rows changed (13, 14) |
| 9 | "Is the Number a health pool?" (2 October) | **History.** It led to 10 |
| 10 | The Number as the player's capital (D152) | **Tried and failed.** Kept for its criteria and as the model for an experiment |
| 11 | The Number is the goal (D153): the design note | **Partly built.** Cash as the Number and the Workshop rows' jobs survive; the fixed shot price failed (12). 11.15 (pacing) is still a proposal |
| 12 | The fuel economy, measured (D155) | **Parked.** Every configuration failed; a fixed price can't fit Tier 1 |
| 13 | The Number is Cash (D156, D157): rules, criteria, results, the enemies | **Live.** The rules are built and the results stand |
| 14 | It becomes the game (D158) | **Live. The current rules**, compatibility reasoning and what is undecided |
| 15 | Coins from the peak Number: what the peak is made of (6 October) | **Live finding.** The peak is the Health row's Number for strong builds, so the reward follows the Number earned (16) |
| 16 | Coins from the Number earned (D162): definitions, options and pass criteria | **Criteria written; nothing built.** Written before any option, per QUALITY_GATES |

### The Number today (D158)

- **One number is your health, your wallet and your score.** Kills and each wave's end pay into it. A run's upgrades are bought with it, never below 1. Enemies' hits and Dividers take from it. The best Number is the record.
- **Regen and Lifesteal refill only what enemies took.** Spending lowers the ceiling they refill to, so every purchase is a real cost. Recovery Packages are the one exception (14.4).
- **Health is a Workshop row only:** the Number a run starts with. Interest is on the Number, capped. Free levels don't raise prices.
- **A Lock holds the Number's growth and the income it blocks,** and pays it all when the last Lock dies (D157).
- **Run upgrades off** (a setting, chosen before a run) shuts the shop for that run.
- **Runs begun before D158 play their Cash rules to the end.** The game's rules are `RunConfig.game_tuning()`; the code's own defaults stay off so old saves and measurements replay exactly. No version bump (14.2).
- **What the bots say (13.3, 14.3):** the same pace as Cash, a Number a fifth to a quarter of its old size, no runaway. The shop adds 25 to 37% of a run's waves even at 1M Coins, as it does under The Tower's own rules.
- **Growth after the Workshop flattens:** [GROWTH_LAYERS.md](GROWTH_LAYERS.md) (D161), a design note.
- **Undecided (14.4, HANDOVER.md):** the Number milestones now pay less; whether a run's reward follows its peak Number; how Workshop power outgrows the run shop; Recovery Packages; the Thorns turtle against a Lock.
- **The lesson that cost two experiments:** the Number runs from 5 to millions inside Tier 1, so anything priced in a flat amount of it breaks. Use shares or time.

## The direction, in the owner's words

- "V1.0 can't be signed off until we get the number in the middle of the screen, and rework the enemies so they interact with it when they collide."
- "This is a delicate operation as the game's identity hinges on this."
- "Basic enemies are flat damage, maybe certain enemies do division damage, maybe some % damage."
- "For tier 1 we keep the tower's shape and progression."
- "We need to create a full list of things to consider now the tower is a number, and we need to meticulously balance it to make the core gameplay loop satisfying and fun."

This replaces D079's option A (the Number as a score beside the battle, after 1.0). **The Number is the tower**, and 1.0 needs it.

## What the old game already taught us

The pre-rebuild game had a Number at its centre for four days of design. Two of its lessons bear directly on this:

1. **A percentage hit makes upgrades pointless** ([D001](DECISIONS.md#d001--replace-percentage-tax-with-two-absolute-axes)). It took a share of the Number each wave, so "weak and strong builds lost the same fraction and production growth did not extend survival." Any % enemy has to be designed so that buying Health still helps.
2. **A Number that rises from your own output never falls** ([D037](DECISIONS.md#d037--the-number-always-rises-missed-waves-move-on-bosses-stay-and-fight), undone by [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second)). When every shot also added to the Number, attack did defence's job, and "runs stopped ending from the third". Whatever makes the Number go up must not be the same thing that kills enemies.

The vision's test still applies: **honest.** Every number that kills you should have been visible before it did.

---

## 1. What the Number is

**1.1 Is the Number the tower's Health?** In The Tower, the tower has Health: it starts at 5, is bought up to thousands, regenerates towards its maximum, and ends the run at zero.
- **Recommend:** yes. The Number *is* the current Health, drawn big in the centre. That keeps every Tier 1 number, benchmark and Workshop row The Tower's, as the owner asked.
- "Number go up" then happens the way The Tower's Health does: from 5 at the start of a run to hundreds or thousands as you buy Health, with regen filling it.

**1.2 Does the Number have a ceiling?**
- **(a) Capped at Health, as in The Tower.** Regen and Lifesteal fill it to the cap; Recovery Packages go past it up to Max Recovery.
- **(b) No ceiling.** Regen, Lifesteal and packages keep raising it for ever. Flat hits threaten a small Number, and ÷ and % hits bite a big one, so the Number settles where healing equals loss, and upgrades raise that level. It's elegant and very "number go up", but it's a new balance, not The Tower's, and it risks D037: a Number that outgrows every hit.
- **Recommend (a) for Tier 1,** because the owner wants Tier 1 to keep The Tower's shape. Hold (b) as a candidate twist for a later tier, measured on its own.
- **Revisited (26 September 2026).** Playing (a), the owner found the Number "literally just a swap of health" and chose (b) for 1.0, measured first. The setting is `Guesses.NUMBER_OVERFILL`: how much of Regen and Lifesteal works past Health. It's still 0 in the game.
- **Measured** (30-run `core` careers per setting, with `--curve`; 20-seed single runs):

  | Past Health | Runs end? | First past wave 11 | Reaches wave 30 | Median Number, waves 5 / 10 / 15 / 20 / 25 (last 10 runs) | ÷ landed (last 10 runs) |
  |---|---|---|---|---|---|
  | 0 (a ceiling) | yes | run 12 | never in 30 runs | 33 / 49 / 78 / 44 / – | 20 of 70 |
  | ¼ | yes | run 10 | run 28 | 55 / 92 / 154 / 100 / 150 | 38 of 91 |
  | ½ | yes | run 10 | run 26 | 74 / 138 / 248 / 180 / 182 | 44 of 100 |
  | all (no ceiling) | yes | run 10 | run 21 | 124 / 260 / 480 / 359 / 314 | 65 of 129 |

  - Fresh runs are unchanged at every setting: buying nothing dies at wave 3, and spreading Cash at wave 8, since Regen starts near zero.
  - With no ceiling, the Number climbs about fourfold from wave 5 to wave 15, then falls as the waves outgrow Regen, until the run ends. So a run has an arc: the Number goes up, and the run is the fight to keep it up.
  - Every run still ends, and more Dividers land, because towers live into harder waves.
  - The cost is pace: careers pass the wave-20 wall sooner (wave 30 by run 21, against never with the ceiling).
- **Decided (D083): no ceiling.** Built with Tier 1's gentle Divider (÷1.25 then ÷1.5, 4× health). As shipped, careers reach wave 30 by run 24, and the Number's median at waves 5 to 30 runs 113, 236, 459, 392, 408 and 151.

- **Decision 1.**

**1.3 Is the Number ever spent?** The old vision made it "score, health and ammunition at once". **Recommend no:** Cash stays the run's currency, as now. Spending the Number would bring back D037's tangle, where every choice trades survival for power.

**1.4 What is the score?** **Recommend:** keep the best wave as the record, and add the run's **peak Number**, shown on the run-over screen and kept as a best on Home. Option A's idea survives as a record, not as the centrepiece.

**1.5 Whole numbers or decimals?** The Tower's Health has decimals (5.00 at the start; regen 0.04 a second). **Recommend:** keep full precision in the simulation, and show whole numbers rounded to the nearest, never 0 while the tower stands, and never above Health unless overhealed (today's rule, `Palette.number_shown`, the same in the centre and the panel). Death stays at ≤ 0 exactly.

**1.6 Scale.** A Number of 5 is small for a centrepiece. We could multiply Tier 1 by a constant (start 50, hits ×10), which balances identically.
- **Recommend 1:1,** so the owner's Tower screens compare directly. The Number reaches the hundreds within minutes anyway.

---

## 2. How enemies act on the Number

**2.1 The operators are fewer than they look.** Halving the Number (÷2) is the same as taking 50% of it. "Division" and "% of the current Number" are one family. To be genuinely different threats, the three kinds should be:

| Kind | Symbol | What it does | Dangerous when | Countered by |
|---|---|---|---|---|
| **Subtract** | −3 | Takes a flat amount | The Number is small | Health, Defense Absolute |
| **Divide** | ÷2 | Takes a share of the Number *now* | The Number is big | Defense %, killing it first |
| **Percent of Health** | −10% | Takes a share of *Health* (the maximum), whatever the Number is now | Always, equally, whatever the build (D001) | Regen, Defense %, killing it first |

- **Recommend:** subtract and divide as the two main kinds.
- Percent of Health should be rare and small if we use it at all, because of D001: buying Health doesn't help against it. Divide doesn't have that problem, since buying Health makes the Number bigger, and a ÷ hit then takes more but leaves more.
- **Decision 2.**

**2.2 Divide on its own can never kill.** Half of anything is more than zero. That's a feature: ÷ is a dramatic drop, and the flat hits finish the job. It needs the rounding rule in 1.5, and it must never be floored to zero.

**2.3 One pipeline for every hit.** Each hit becomes the amount it would take off, and the defences then work on that amount the same way for every kind: Defense % first, then Defense Absolute.
- A ÷2 on a Number of 1,000 would take 500. With 20% Defense and 30 Absolute it takes 370.
- This is easy to read ("÷2 would take 500; your defences stopped 130"), keeps every Defense row useful against every kind, and keeps one rule in `BattleSim`.
- The alternative is each defence treating each kind differently, for example Defense % shrinking the divisor. It's more expressive, but that's a table of special cases the player can't see.
- **Recommend the single pipeline.**

**2.4 Do operator enemies stay and hit, as The Tower's do?**
- A ÷2 enemy standing at the tower and hitting every second halves the Number every second, which is fatal within seconds.
- **Recommend:** a divide or percent enemy is **used up on contact**. It applies its operator once, the collision the owner described, and vanishes without paying Cash, because it wasn't killed. Flat enemies keep The Tower's rule: they stay and hit every second.
- This also gives the player a clear job: kill the ÷ enemies before they arrive.

**2.5 Heat-up.** Today an enemy's flat hit grows 4% for every hit it lands. **Recommend:** it applies to flat hits only; used-up operator enemies only ever hit once.

**2.6 Which enemies carry which operator in Tier 1?** The Tower's Tier 1 is 85% basic, 7% fast, 6% tank, 2% ranged and a boss every tenth wave, all flat.
- **(a) Convert some of The Tower's types,** e.g. tanks divide and the boss divides on arrival. Few new parts, but it breaks the Tier 1 benchmarks (the tank mix alone changes how runs end).
- **(b) Keep all of The Tower's types flat, and add new operator enemies on top,** at a small, tunable share that grows with the wave. The Tower's benchmarks hold, and the operators come in one at a time, each measured.
- **Recommend (b).** For example, ÷2 enemies from wave 3 at about 3% of a wave, and percent enemies not in Tier 1.
- *Since D094 the Divider replaces a basic, in The Tower's Protector slot, rather than coming on top, so The Tower's wave sizes hold exactly.*
- *Since D133 our new enemies come on top of The Tower's waves, as (b) first proposed (the owner's choice); the Divider keeps its basic's slot.*
- **Decision 3.**

**2.7 Bosses.** A Tier 1 boss stays and hits flat, like The Tower's. A boss that divided every second would be unwinnable. **Recommend:** the boss stays flat in Tier 1. Operator bosses belong to later tiers, if anywhere.

**2.8 Ranged enemies.** Their shots are hits like any other; a ranged ÷ enemy would divide from the Range edge. **Recommend:** ranged stays flat in Tier 1, since a ÷ at range can't be answered by killing it first.

**2.9 How big is the divisor?** *Decided (D083):* Tier 1 is the tutorial, so ÷1.25 (a fifth) to wave 17, then ÷1.5 (a third), in clean steps of 0.25. ÷2 and beyond are for later tiers. A bigger divisor takes more (÷2 half, ÷3 two thirds), so gentle means closer to 1. *The first recommendation, kept for the record:*  ÷2 is legible and dramatic. **Recommend** starting at ÷2 and tuning by how often they come, not by odd divisors like ÷1.37. If a softer step is needed, ÷1.5 reads fine.

**2.10 Telegraphing (honesty).** Every operator enemy carries its symbol ("÷2") on its body, has its own shape and colour, and is visible from the spawn edge. At its speed that gives several seconds' warning. **To measure:** the time from spawn to contact for each operator enemy is never under a set minimum, e.g. 4 seconds.

**2.11 Targeting.** The tower shoots the nearest enemy, as The Tower's does. With ÷ enemies among basics, the player can't choose to kill the ÷ first, so the only answers are builds: range, orbs, knockback, shockwave, mines.
- **Recommend:** keep nearest-first for 1.0, and check in play whether it feels unfair. A "target operators first" upgrade is a later option, and The Tower has nothing like it.

---

## 3. Every system the Number touches

Every Workshop row needs a line on what it now does. Most are unchanged in meaning; the ones marked ★ change value a lot.

| Row or system | With the Number |
|---|---|
| Health | The Number's ceiling, and it raises the Number when bought (today's rule). Rename to "Number"? **Decision 4:** keep The Tower's names, or rename Health to Number and Health Regen to Number Regen. |
| Health Regen | Fills the Number towards Health. |
| Defense %, Defense Absolute | The single pipeline above: they cut every kind of hit. |
| Thorns | Unchanged: it hurts what hits the tower. A used-up operator enemy takes no Thorns, since it's gone. |
| Lifesteal | Heals the Number, never past Health. |
| ★ Orbs, Knockback, Shockwave, Land Mines | Now the answer to operator enemies, killing or holding them before contact. Their value rises; watch that they don't become compulsory. |
| ★ Death Defy | Ignores a killing hit. A ÷ can't kill, so it only matters against flat and percent hits. |
| ★ Wall | Its own health. Does a ÷ enemy divide the Wall, or pass it? **Recommend:** used-up operators break on the Wall like anything else, with the loss taken from the Wall's health through the same pipeline. |
| ★ Recovery Packages | Overheal to Max Recovery: a bigger Number is a bigger ÷ target, a real trade-off. |
| Enemy Level Skip | Unchanged. |
| Free Upgrades, Interest, Cash and Coins rows | Unchanged: Cash and Coins stay separate from the Number. |
| Resuming (D078) and the report (D077) | Unaffected in design. Saved runs from 0.9 won't resume after the change (by design). Reports gain the Number's path and each operator's losses (section 5). |

---

## 4. The screen

- **4.1 The Number sits in the middle, in place of the hexagon,** big, in Inter at its thinnest (Geist Mono until D138), whole and rounded up.
  - Its size must fit from "5" to "1.23M" without jumping about. The suffixes start at 1,000 as they do now; the full digits up to 99,999 may read better in the centre. To be decided on a screenshot.
- **4.2 (Superseded, D083 and D084: no ceiling and no ring; the Number stands alone.)** Health (the ceiling) shows small beneath it, or as a ring around it that empties. **Recommend a ring:** it reads at a glance without a second big number.
- **4.3 Every contact shows its operator** as floating text at the Number: "−3", "÷2", "−10%". A ÷ gets the biggest moment (a flash and a short shake), because it's the identity beat. (No reduced-motion option: D093.)
- **4.4 The Number animates to its new value** (counting, not jumping) over a fraction of a second, fast enough never to lie about the real value when it matters.
- **4.5 The enemy's collision point is the tower's edge (3 m),** not the Number's text, which grows as digits are added.
- **4.6 Colour:** the Number turns warning-coloured when low, and has its own tint when overhealed past Health.
- **4.7 The run-over screen** shows the peak Number and what took it: how much flat, how much ÷, and the blow that ended it.
- **4.8 Operator enemies** are distinct in shape, not just colour, for colour-blind players.

---

## 5. How we'll balance it, meticulously

**5.1 Targets that must still hold** (The Tower's, from the spec's benchmarks):
- a fresh tower that buys nothing dies on waves 2–5;
- spreading Cash evenly dies around wave 8;
- the wave-10 boss is beatable by run 10 to 13 of a focused career;
- Coins per run are unchanged.

If operator enemies move these, their share or divisor is tuned, not The Tower's numbers.

**5.2 New targets for the Number.** These are proposals, to be agreed:
- ~~**About five digits by Tier 2 (D107).**~~ Replaced by D110: a run's shape (starts at Health, climbs through the run, something can still hurt it while the tier is a fight, and it never races: growth adds rather than compounds, at most about a digit every 50 waves), not a size. The turtle stays. A player clearing Tier 1's wave 100, where Tier 2 opens, has a best Number around 10,000–50,000: Tier 1 is the journey from one digit to five. It's the yardstick for the growth rules still on test (D097, D098), not a gate.
  - *Measured 27 September (HANDOVER.md, Tier 1's ceiling):* a Workshop of about 2.1 million Coins ends at waves 86–91 with a five-digit Number; about 3.4 million turtles, and the Number reaches six digits by wave 100 and millions later, with nothing able to hurt it. The target holds only below that cliff.
- **The Number goes up over a run.** In a run that buys sensibly, the median Number at each wave's end rises across the run: wave 20 higher than wave 10, higher than wave 5. This is measurable from the report's wave snapshots, which already record Health.
- **Divide moments are events, not noise.** Roughly one ÷ contact a minute in Tier 1's middle waves (tunable), each visible and survivable in a sensible build.
- **Operators kill honestly.** A ÷ never ends a run alone (by design). Flat hits end most runs, as in The Tower. What ended each run is recorded and counted.
- **No row becomes useless (D001's test).** For each operator, buying more Health or Defense must still lengthen runs. Measure the waves gained per 1,000 Coins on each Defense row with and without operators.
- **No row becomes compulsory.** Orbs and the like help against operators, but a run without them still reaches the same benchmark waves.

**5.2a What the owner's runs show** (reports of 26–27 September: 12 runs with the Number, on a Workshop of 37 runs):
- **The Number goes up: met.** Its median at the end of waves 1, 5, 10, 15 and 19 is 16, 27, 40, 156 and 332. It dips at boss waves (wave 10 below wave 9, wave 20 below 19).
- **Divide moments are rarer than the target.** From wave 5, 0.73 Dividers came a minute and 0.31 landed: about one ÷ every three minutes, against "roughly one a minute". The owner's builds kill more of them (16 of 38 landed, 42%) than `sim_runs.gd`'s did (59%). The levers are `Guesses.DIVIDER`'s share and health.
- **Operators kill honestly: met.** No run ended on a ÷. Basic enemies ended 5, bosses 3, ranged 2, tank and fast 1 each. Of the Number lost, basic took 36%, ranged 24%, bosses 18%, Dividers 16%.
- **The wave-10 boss wall holds** in 9 of the 12, as The Tower's design intends. Coins per run fit The Tower (the spec's [Benchmarks](REBUILD_SPEC.md#benchmarks)).
- **Then the wall broke the way The Tower intends (27 September, a fifth report).** After the owner put 540 Coins into Workshop Damage (3 to 6) and raised Regen, the next run reached **wave 31**. It lasted 17 min 21 s and earned 302 Coins, and the Number peaked at 989. The boss ended it.
- **In a long, strong run the ÷ becomes the main force on the Number.** In that run Dividers took 636 of about 1,600 lost (40%) with only 4 landings, because a ÷ takes a share and the Number was large. The Number went from 938 at wave 25 to 277 at wave 27, most likely two landings close together. This is the Number's intended drama, but it means **more Dividers hit strong runs hardest**. Any change to their rate must be measured on long careers, not just early waves.

**5.2b Where the Number's growth comes from** (measured 27 September, `sim_runs.gd --gains`, on D094's game). The owner asked whether the player can grow visibly stronger without Number Regen being the star of the Number's growth. `BattleSim` now books every gain by source (`gained_from`) and the part of each that lifted the Number to a new high rather than refilling it (`raised_by`). The bookkeeping changes nothing: 20 core runs print identically with and without it.

| Where | Regen's share of gains / of new highs | Bought Health | Lifesteal |
|---|---|---|---|
| Fresh runs (20 seeds, spread Cash or core) | 35–55% / 13–60% | 45–65% / 40–87% | not open |
| Core career, runs 8–40 (Workshop Regen building up) | 87–94% / 85–94% | 6–13% | not open |
| Spread-Coins career, runs 16–60 (it never reaches Lifesteal's 2,000 Coins) | 71–96% / 64–94% | 4–29% | not open |
| Core career, Lifesteal opened free at run 31, level 10 (0.93%) | 82–86% / 85–89% | 6–7% | 8–10% / 6–8% |
| The same at level 40 (2.99%, about 158K Coins of levels) | 67–73% / 73–77% | 5–6% | 22–27% / 17–21% |
| The same at level 80, its last (4.46%, about 1.5M Coins) | 59–65% / 66–71% | 4–5% | 30–36% / 23–28% |

- **Regen is the star, as the owner suspected.** From the moment the Workshop holds some Regen, about nine tenths of everything that lifts the Number to a new high is regen. Damage, Attack Speed and Range add nothing to the Number directly; they only stop it falling.
- **Most of regen is growth, not repair.** In the core career's last runs about two thirds of all gains set a new high (run 40: 1,621 of 2,526).
- **The Tower's own damage-to-Number row can't dethrone it in Tier 1.** Lifesteal at its last level, 1.5 million Coins away, still leaves regen two thirds of new highs. It didn't move the wave these runs end on either (31 every time).
- **The Number's arc stands:** in the core career it peaks around waves 20–25 (run 40: 204, 379, 709, 1,153, 1,195 at waves 5–25) and falls to 900 by wave 30 as the waves outgrow regen.
- **The Multiplier, on test (D097):** with the switch on, a 40-run core career makes 30–50% of its new highs from Multipliers from run 15, regen about half, while the career's milestones and The Tower's fresh-run benchmarks stay where they were. Its peaks roughly double.
- **Regen that restores, and kills that grow (D098):** with both switches on, regen makes none of the new highs, and kills and bought Health share them. The Number climbs through the whole run, smaller (about 224 at wave 30 against 900). With all three switches on, Multipliers make 45% of new highs. The Tower's early benchmarks hold with kills at a 5% share; D098 has the table.
- **Settled by D111:** the Multiplier is gone, and regen restoring plus kills growing are the game's rules, weak early on purpose, for Labs and Cards to raise.
- **Tried and dropped (28 September): kills growing the Number only by the hit that would have got through the defences.** The idea was that a turtle, safe from every hit, would stop the Number climbing. Measured with a scratch option, it didn't: The Tower's benchmarks were unchanged (fresh runs 3 / 8 / 6, the boss beaten on run 11 of a career), but a turtle at every affordable row's level 25 still reached 11–13 million by wave 300, as without it, and Tier 2 barely moved. **The Number in a long run is mostly Health bought with Cash:** in a core career, bought Health makes 53% of the new highs and kills 47%; with the threat rule, 92% and 5%. So kills fighting for it barely matter, and the lever for the Number's growth is the Cash → Health buy, which is the player's own choice each wave. D111 stands.
- **Measured 28 September, four experiments** (`sim_runs.gd`, rules unchanged; new rules behind measuring flags):
  - **Spending on the Number is a trap, not a choice.** Putting 60% of Cash into Health dies earlier *and* peaks lower than buying the cheapest core row: run 40 of four 40-run careers reaches wave 21 with a peak of 190, against 31 and 348. Buying Health only when below half the run's best, and otherwise Damage, Attack Speed and Defense Absolute, goes furthest (wave 35, peak 235). On a fixed Workshop (every affordable row at level 10, 20 seeds) the order holds: Health-heavy wave 75, peak 6,552; core 87, 9,147; survival 95, 10,764. The Number peaks higher by surviving longer, since waves pay the Cash that buys it.
  - **An unstoppable Divider doesn't plateau a turtle.** Landing ÷1.1 every fifth wave from wave 100 on a turtle (every affordable row at level 25) roughly halves the Number (peak at wave 400: 28–34 million against 54–67 million), but it still grows about 1.4 times every 25 waves by wave 375, against 1.5 without.
  - **Recovery Packages overhealing are a quarter of the growth where they exist.** Opened at level 25 in a core career, they lift run 40's peak from 348 to 437 and set 24% of new highs; refilling only to the run's best, they set none and the career plays almost exactly as without them.
  - **Pace:** a core career's best Number reaches 100 on runs 12–14 (1.2–1.7 hours of play) and stands at 334–366 after 40 runs (about 8 hours); a run starts at 5 until run 5, 11 by run 10, 26 by run 20 and 49 by run 40. Played on to 200 runs, the best reaches 1,000 on runs 128–136 (39–42 hours) and 1,673–1,732 by run 200 (72 hours), with runs stuck at the wave-50 boss and starting at 229; 10,000 is out of reach.
- **What this left open** (settled by D111): a rule of ours that ties the Number's growth to play, such as enemies carrying a positive operator that the Number gains on a kill, and whether regen's growth past Health (`Guesses.NUMBER_OVERFILL`) should shrink so regen keeps the tower alive while kills make the Number climb. Either needs measuring against 5.1 before it ships.

**5.3 Tools.** Nothing ships on feel alone.
- `tools/sim_runs.gd` gains columns for the peak Number, the Number by wave, losses by operator and deaths by cause, and (`--gains`) where the Number's gains came from.
- The activity report records the same, so the owner's own runs measure it too.
- Tests cover each operator's arithmetic:
  - ÷ never reaches zero;
  - the pipeline order;
  - rounding;
  - huge numbers;
  - used-up enemies paying nothing;
  - determinism and replay.

**5.4 Order of work, once the decisions are made:**
1. The rules in `BattleSim`, measured headless. Then tuned until 5.1 holds and 5.2 reads right.
2. The screen: the Number in the centre, operators drawn, contact moments.
3. The owner plays it. This is the part that decides whether it's fun, and nothing above replaces it.

---

## 6. Decisions

**Answered by the owner on 26 September 2026 (D081): "go with your recommendations on all four."**

1. **The Number has a ceiling in Tier 1:** The Tower's Health (1.2).
2. **Operators: subtract and divide.** Percent of Health is rare or left out; The Tower's own Vampire is the model if it comes (2.1, section 7).
3. **The Tower's enemies stay flat, and new operator enemies are added on top,** at a small share (2.6).
4. **Health is renamed Number, and Health Regen Number Regen** (3).

Taken as agreed with them:
- operator enemies are used up on contact (2.4);
- one defence pipeline for every hit (2.3);
- heat-up applies to flat hits only (2.5);
- bosses and ranged enemies stay flat in Tier 1 (2.7, 2.8);
- ÷2 as the divisor (2.9);
- nearest-first targeting for 1.0 (2.11);
- the Number isn't spent (1.3);
- peak Number as a record (1.4);
- whole numbers shown, never 0 while standing (1.5);
- scale 1:1 (1.6).

The owner also asked for divide enemies to be "balanced carefully".

---

## 7. Enemies: the brainstorm (proposed, 26 September 2026)

The owner shared The Tower's in-game enemy list and asked for a brainstorm on how enemies work, **focused on the ones The Tower launched with** (Basic, Fast, Tank, Ranged, Boss). The later ones are for later tiers. This section is a proposal until the owner answers its questions.

### What The Tower's list says

| Enemy | The Tower | Tier | Fits the Number as |
|---|---|---|---|
| Basic | "Just a basic enemy" | Launch | Subtract |
| Fast | 2× speed; 2 Coins | Launch | Subtract, sooner |
| Tank | 50% speed, 5× health; 4 Coins | Launch | Subtract, soaks shots |
| Ranged | Shoots projectiles from range; 2 Coins | Launch | Subtract, from the Range edge |
| Boss | 30% speed, 20× health; 5 Coins | Launch | Subtract, stays and hits |
| Protector | Enemies near it can't be insta-killed and take 60% less damage; 3 Coins | Later | A shield around operators |
| Vampire | 2× health; drains 2% of the tower's max health a second and disables regen; 4 Coins | Later (elite) | **Percent of Health**: The Tower's own percent enemy |
| Ray | Basic health; charges 30 s, then fires ×2 basic damage; 4 Coins | Later (elite) | A telegraphed big hit |
| Scatter | 2× health; splits in half 4 times, halving its health each time; 4 Coins | Later (elite) | **Divide, on itself** |
| Commander, Overcharge, Saboteur | 20× health; buff enemies, exponential shots, lower Ultimate Weapon levels | Late game | Out of scope |

Three things stand out:
- **The Tower already has one of each of our operators in its later enemies.** The Vampire is a percent drain, and the Scatter divides itself. So operators aren't foreign to The Tower's shape; they arrive with its elites.
- **Its figures differ from our data in three places:**
  - Ranged is worth 2 Coins here against our 3 (D074, from the owner's earlier table).
  - Tank is "50% speed" against TheTowerSDK's 0.34.
  - Fast is "2×" against the SDK's 2.31.

  The encyclopedia may round, so these need a decision rather than a quiet change (see the handover).
- **Launch Tower enemies are all squares,** elites are triangles and the late game are pentagons. The shape tells you the class before you read anything. Ours should keep that grammar.

### The proposal for 1.0 (Tier 1)

**A. The five launch enemies stay The Tower's, and flat.** Their stats, mix and pay are unchanged, so the Tier 1 benchmarks hold. What changes is how they read:
- each contact shows as "−1.64" at the Number;
- the enemy's shape says "subtract";
- the Tank and the Boss get the biggest numbers.

**B. One new enemy: the Divider (÷2).** The only new rule in 1.0, so it can be balanced on its own, as the owner asked.

| | Proposal | Why |
|---|---|---|
| **What it does** | On contact, the Number loses half of itself (through the defence pipeline), and the Divider is used up | The identity beat; used up so it can't halve every second |
| **Shape** | A diamond (a square turned 45°) with "÷2" on it, in its own colour | Reads as related to the launch squares but different, and the symbol is always visible (honesty) |
| **Health** | 2× a basic enemy of its wave | Survives the first shot, so it isn't trivially one-shot; not a tank |
| **Speed** | A basic enemy's | Arrives mixed in with the basics, as a threat you can see coming for the whole walk (about 10 s from spawn) |
| **When** | Not before wave 5; about 3% of a wave there, rising to about 6% by wave 30. *Since D094: in the Protector's slot, replacing a basic, one every third wave rising to every other wave by wave 30* | Roughly one every 3 waves at first, about one a minute by the middle waves (THE_NUMBER.md 5.2). Wave 5 is after a fresh player has learnt the basics |
| **Pay** | Cash as a fast enemy (2×) and 2 Coins | Worth killing first. It pays only if killed, since a used-up one pays nothing |
| **Heat-up, Thorns** | None (used up on contact) | Rules 2.4 and 2.5 |
| **Knockback, Shockwave, Orbs, Mines** | Work on it like any non-boss | These become the ways to stop it |
| **The Wall** | Breaks on it: the Wall loses half its health instead of the Number | Rule 3 |

The numbers to tune are its share by wave, its health and the divisor. **Tune share first, then health, then divisor last:** ÷2 is the identity, so it moves only if the other two can't balance it.

**How we'll know it's balanced** (5.2's targets, applied to the Divider):
- The Tier 1 benchmarks still hold: buy nothing and die on waves 2–5, spread your Cash and die around wave 8.
- A Divider reaches the Number about once a minute in middle waves, not more. *Since D094 an upper bound: the owner judged one a wave too much for Tier 1.*
- Most Dividers are killed before contact in a sensible build, and fewer still reach the Number as Range, Orbs and Knockback are bought.
- A Divider never ends a run on its own (it can't), and what does end runs is still mostly flat hits and bosses.
- Buying Health still lengthens runs, and Defense % becomes the answer to Dividers, as planned.

**C. Parked for later tiers, not 1.0:**
- **The Vampire as percent:** drains a share of the Number's ceiling each second while in range, and stops regen. It's The Tower's own design and the only percent enemy we'd keep, placed where D001's lesson can be watched.
- **The Scatter as a divide pun:** it halves into two on each hit.
- **The Ray** as a charged ×2 hit.
- **The Protector** as a shield that makes Dividers harder to stop.

### Changed by D083

Tier 1's Divider is gentler than D082 built it: ÷1.25 to wave 17, then ÷1.5, with 4× a basic enemy's health throughout. Most land, as frequent, small ÷ moments, and the Number has no ceiling. The measurements are in D083.

### Answered and built (D082)

The owner said yes to all three questions: the Divider as proposed, "÷2" shown only on the Divider, and no "plus" enemy in 1.0. Ranged pays 2 Coins, and Dividers walk at a basic enemy's speed.

Measuring changed one number. **Its health ramps from 2× at wave 5 to 4× by wave 30,** instead of a flat 2×:
- at 2×, almost none got through in the middle waves;
- a flat 4× cost a fresh tower a wave.

As built:
- The Tower's benchmarks are unchanged, for single runs and careers.
- About a third of Dividers reach the Number: one every 6 minutes or so in the middle waves.
- That's rarer than 5.2's first target of one a minute. Getting there needs more Dividers or tougher ones, and the owner judges that in play. The figures are in D082, and the levers are in `Guesses.DIVIDER`.

## 8. Our base roster (D133)

The owner asked for enemy types that fit a game about a number, for the base roster a player meets in Tier 1 and the early tiers; elites and fleets stay The Tower's, late. Until D133 the base roster said nothing about numbers bar the Divider, and D132 showed the Divider can't change a run's outcome.

**Every base enemy of ours:**
1. Carries one arithmetic idea a player gets at a glance, written on its body in its own typeface and colour (D085, D086, D128), readable in a crowd (D127).
2. Lets only flat hits kill (2.2).
3. Takes no percent of maximum Health (D001) and adds nothing to the Number (D097, D111).
4. Is answered by rows the Workshop already has (D068): kill it first, hold it off, or absorb it.
5. Comes on top of The Tower's waves, at most one of a kind a wave at first, so each moves the benchmarks and is sized by measuring.
6. Is explained once, by a card the first time a player meets it (D125's disclosure).

**The proposed roster**, each asking a different build question (and so giving Cards clear jobs later):

| Enemy | Sign | Rule | Tests | Status |
|---|---|---|---|---|
| Divider | ÷1.25, ÷1.5 | Takes a share of the Number now | Big Numbers | Built (D082, D094) |
| **Lock** | = | While it stands on the range's edge, the Number can't go up | The turtle's Regen | **Built (D133)** |
| Countdown | 5…4…3 | Stops inside the range and counts down, then hits hard, flat | Burst damage | Proposed, around wave 15 |
| Carrier | 36 | Killed, it splits into its digits, small and fast | Area damage | Proposed, around wave 25 |
| Rounder | ≈ | On contact, rounds the Number down to two leading digits | Hovering under a round number | Proposed, around wave 50 |

Dropped: a digit Reverser (random, not skill), Modulo (swingy and opaque), a ÷10 shift (too brutal), a zero-shield (0 is the orbs'), parity or prime immunities (opaque), and buffers that strengthen other enemies (a late Commander's job, if anyone's).

**How The Tower's base enemies read as ours (D145).** They keep The Tower's health, attack, speed and pay; only how each one reads changes, plus one small rule on the tank:

| Enemy | The Tower | Ours |
|---|---|---|
| Basic | A square | A bare number in the plain cut. **Left plain on purpose:** it's the unit every other enemy is read against, and anything added to it repeats across every crowd |
| Fast | A triangle | Narrow and slanted, trailing two faint copies of its number while it walks in |
| Tank | A big square | Wide, heavy and glowing (D144), and its cut **thins as it's shot**, from the heaviest weight towards a light one. It keeps its weight however hurt (D154, reversing D145's mass loss), so Knockback never throws a worn tank like a basic |
| Boss | A big shape | **A rival Number**, in the Number's own Inter. While it lives the wave line reads "Wave 10 · Boss" and fills in its glow, and a first-sight card says orbs and shockwaves can't touch it |
| Divider | (ours) | When a ÷ lands, the Number as it stood peels away in the Divider's colour behind the Number that's left |

**The Divider's slow refill (D134)** was tried with the Lock: what a ÷ took, held back from Regen for 10 to 120 seconds. It moved no wall, since by the time basics break a tower the Number is nowhere near its best, so it stays a measuring option (`--divider-refill`), off in the game.


## 9. Revisited (2 October 2026): is the Number a health pool?

The owner has now said it twice: "literally just a swap of health" (26 September, which led to D083's no ceiling) and, after Dividers, the Lock and growth rules were built, "a bit of an add on ... effectively a health pool". I read "identity" as what the Number does; how it looks (D131's digit milestones, typefaces) follows from that. **Status: open, waiting for the owner's choice of what the Number is** (HANDOVER).

**It is, as measured.** Median wave on `main` at `0cb286d`, bots, Tier 1, with the Number's own rules on and then stripped (`--divider-share 0 --lock off --kill-share 0 --peak-drift 0`, which leaves a plain health bar that regen refills):

| Build | With the Number's rules | Stripped |
|---|---|---|
| Fresh run, Cash spread (20 seeds) | 6 | 6 |
| Core, 10K Coins (8 seeds) | 31 | 31 |
| Turtle, 10K | 41 | 41 |
| Core, 100K (4 seeds) | 51 | 51 |
| Turtle, 100K | 84 | **89** |
| Core career: run that first reaches wave 31 | run 47 | run 60 |

- **No build's wave depends on the Number's rules.** The turtle does five waves *better* without them.
- **Only the growth rules show, and only in pace:** a career without regen's drift past the best and kills growing the Number is about 13 runs (about two game hours) slower to wave 31. That is "a bigger health pool", not an identity.

**Why, three reasons:**
1. **Every loss is transient.** Regen refills the Number to the run's best before the next threat (D111).
2. **Size can't beat a boss.** An enemy at the Number hits 4% harder each hit (`heat_up_per_hit` 1.04), so survival against one that stands there grows only about with the log of the Number: a Health card at level 7 took the peak from about 340 to 720 and the run still died on wave 31 (CARDS.md). This is a reading of the code and a traced collapse, not a separate measurement.
3. **Tier 1's Dividers are gentle by decision** (÷1.25, ÷1.5, D083) and can't end a run (2.2), so they can't be a threat whatever surrounds them.

**Two obvious fixes, tried and not enough** (scratch or existing options, 10 seeds or fewer, bots; nothing is in the game):
- **Make losses durable:** `--divider-refill 1000000`, a Divider's bite never coming back. Fresh 6 → 6, core 10K 31 → 31, turtle 10K 41 → 40, core 100K 51 → 51, turtle 100K 84 → 83. Only the career moved (wave 31 on run 60, from 47).
- **Make the Number ammunition:** each shot's Damage × (1 + c · log10(Number ÷ 5)), the Number floored at 5. It is a strong lever on pace and an inadequate one on identity:

| | c = 0 | c = 0.5 | c = 1 |
|---|---|---|---|
| Fresh run, Cash spread | 6 | 7 | 10 |
| Core 10K / core 100K | 31 / 51 | 41 / 73 | 51 / 81 |
| Turtle 100K | 84 | 91 | 97 |
| Core career: wave 31 on run | 47 | 20 | 9 |
| Core 10K without Dividers / core 100K without | | 41 / 74 | 51 / 81 |
| Health card, level 7, wave-21 build (no card → card) | | 31 → 33 | 40 → 42 |
| Damage card for comparison | | 31 → 61 | 40 → 81 |

  - **It breaks the early benchmarks well before it makes anything else matter.** Spread Cash dies on wave 10 at c = 1 against The Tower's 8, and a career passes wave 31 in 9 runs. A usable c would be small.
  - **Dividers still don't matter** (41 → 41, 73 → 74 without them): a ÷1.5 costs a smooth function of the Number a few per cent.
  - **A Health card gains two waves, Regen and Extra Defense none to one,** against Damage's thirty to forty.

**What that says.** The wall is decided by killing power against a boss's health, so the Number can only gain an identity if one new rule makes its size or state decide something *at that wall*. Tuning the rules we have can't, and a smooth coupling can't by itself. The candidates, none built:
1. **Ammunition.** The Number powers the shots: the old vision's "score, health and ammunition at once". One-way (the Number sets damage, damage doesn't set the Number), so D037's loop doesn't return. Tested above: needs a small c and something steeper than a log to bite; changes every benchmark when real.
2. **A stake.** Losses that last and gains that can be taken away (÷ and Locks cutting the run's best, not only what stands). Tested in its mildest form above, which moved no wall; it would need bigger or more frequent ÷, against D083's choice.
3. **Spent.** The player trades Number for a burst of power, a decision in place of a bar. It reopens 1.3 ("the Number isn't spent"), and The Tower has no tap, so the trigger would be a rule.

The cheapest next step for any of them is the card test series' method: a measure-only candidate, swept against the three card builds, before any rule reaches a real run.

### 9.1 Tested: the Number as the in-run currency (2 October 2026)

The owner asked whether the Number could also be what run Upgrades are bought with, with the early game balanced so it wasn't brutal. D015 tried Number as the Rig's currency and D042 replaced it with Cash, because players could spend themselves to death and seven rows were locked out of the run. So the design tested **cannot hurt the tower**: only Number *above Health* is spendable.

**What was built (a scratch patch, never committed):**
- kills and wave ends pay the Number, `s` per Cash;
- an upgrade costs `s` times its Cash price from the Number above Health, never from Health itself;
- spent Number leaves for good, so regen can't refill it;
- a standing Lock freezes the income, since the Number can't rise under it (D133);
- a policy knob, ρ, keeps `Health × (1 + ρ)` unspent, which is how a bot "holds".

**Results**, bots, Tier 1, 3 to 20 seeds a line. Cash game in brackets; `s` = 0.25 / 0.5 / 1:

| | |
|---|---|
| Buys nothing / spread Cash / Damage and Attack Speed only (median wave) | 3, 6, 10 / 3, 6, 10 / 4, 6, 10 (3, 6, 10) |
| Core 10K Coins | 38 / 35 / 31 (31) |
| Turtle 10K | 45 / 41 / 41 (41) |
| Core 100K | 55 / 51 / 51 (51) |
| Turtle 100K | 82 / 79 / 77 (84) |
| Core career: run that first reaches wave 31 | 34 / 46 / 47 (47) |
| Core 10K, waves lost to Dividers (with against without) | 2 / 3 / 4 (0 in the Cash game); none at 100K |
| Wave-21 build, level-7 card: Damage / Health / Health Regen | +25, 0, 0 / +29, +1, 0 / +26, 0, 0 |

- **It doesn't break the early game.** Every fresh-run benchmark holds and builds land within a few waves of the Cash game's, so nothing needs rebalancing to make it safe. The reason is the same as its weakness: a bot spends each point the moment it is affordable, so the bank stays near zero and the Number stays near Health.
- **It adds no decision.** Keeping a reserve is never better than spending: with ρ = 1 core 10K is 31 against 31–35 spending everything, and with ρ = 4 it is 21–26. The best play is always to turn Number into Damage at once, because killing power is what decides the walls.
- **It makes no card matter,** and Dividers move a build by at most four waves, at 10K only.
- **Adding the ammunition coupling (c = 0.15 and 0.3) doesn't change that.** Spending still wins (core 10K, ρ = 0 / 1 / 4: 40 / 35 / 21 at c = 0.15 and 41 / 40 / 28 at c = 0.3), Dividers still move at most a wave, and the level-7 Health card gains three waves at c = 0.15 and none at 0.3.
- **What it would give is feel, which this can't measure:** one Number that jumps with every kill and drops with every purchase, health and wallet at once.
- **Holding would have to pay more than spending** for a decision to exist. Two ways, both untested: Interest on the bank (The Tower's own saving mechanic, already a Workshop row), or a reward for a big Number much steeper than a log.
- **The cost is large.** Cash becomes Number across `BattleSim`, the Upgrades panel, the Cash Bonus, Cash / Wave and Interest rows, battle snapshots and saves. That is high risk under QUALITY_GATES, and it overturns D042 and AGENTS.md's law 4 (run Upgrades spend Cash), which are the owner's to change.

---

## 10. The Number as the player's capital (3 October 2026, D152)

**Status:** the owner's direction, tried; **the declared candidate failed (10.5)**. Nothing here is in the game. The candidate in 10.3 is a set of measuring options, off by default, and 10.4 was written before the candidate existed, so the results can't be graded afterwards.

### 10.1 What the owner decided

The Number should give the player two feelings: the hit of watching it go up, and being protective of it. The Tower's shape no longer binds this, and fundamental stats may change. Recovery is behind Labs, weak at the start. The goal is "I can't wait to invest enough into stats so this problem is solved". D152 has the owner's words.

### 10.2 The design

| Part | What it does | Why |
|---|---|---|
| **Every rise and fall has an author** (agent's proposal) | A rise comes from something the player did; a fall only from something an enemy did. No spending the Number, no decay. | A loss only feels worth protecting against if someone took it. |
| **Thieves** | A Divider still divides on contact, but is no longer used up: it carries the bite away. | Makes the loss visible and personal. |
| **Recovery by damage dealt** (agent's proposal) | Each hit on the carrier returns its share of what it holds, in proportion to the damage. Escaping (reaching where enemies set off) keeps the rest taken. | No cliff where a thief escapes on 1 HP with everything, and killing power protects the Number without a formula. |
| **Recovery strength is the Lab's** (owner) | The share returned starts small. Labs raise it to all of it and past it (over 100% is the hit: the Number lands above where it was). In the trial, `thief_recovery` stands in for the Lab. | The weak start is what makes the Lab worth wanting. |
| **Durable loss** (agent's proposal) | What a thief carries off stays out of Regen's reach, for ever or for a set time. Without it, Regen fills the gap and recovery does nothing. | D134 already has the held-bite mechanism: `divider_held`. |
| **A power coupling** (agent's proposal) | The tower's shots are multiplied by (Number ÷ 5) to the power `number_power`. A log left ÷ harmless (section 9). | Gives the Number's size and its losses a cost at the walls. |
| **Solved with stats** (owner) | Thorns and Orbs kill a thief as it grabs. Range, Damage and Knockback catch one fleeing. | Each threat gets an answer stat, a crossing the player can read, and a solved moment. |

### 10.3 The candidate (measure-only)

Six new measuring options, all off by default so every run and replay is as before, in `Guesses`-style tuning with `RunConfig` validation:

| Option (`sim_runs.gd` flag) | Meaning | Off |
|---|---|---|
| `thieves` (`--thieves`) | Dividers carry the bite away instead of being used up (only when they reach the Number, not the Wall). | off |
| `thief_recovery` (`--thief-recovery R`) | The share of the carried bite returned if the carrier is killed (R = 1 returns all of it; more than 1 is the Lab bonus). | 0 |
| `thief_speed` (`--thief-speed S`) | The carrier's flight speed, times the Divider's walking speed. | 1 |
| `thief_fade` (`--thief-fade SECONDS`) | How long the unreturned bite stays out of Regen's reach, evenly released from the theft. 0: for ever. | 0 |
| `thief_priority` (`--thief-priority`) | The tower shoots carriers before anything else in range. | off |
| `number_power` (`--number-power K`) | The tower's shots × (Number ÷ 5) to the power K. Mines, Thorns and Orbs are unchanged. | 0 |

Taken, recovered and escaped are counted for the ledger. A carrier that is killed pays like any killed enemy, its recovery ignores a standing Lock and a Vampire's drain (they stop Regen, not a payback), and Knockback and Shockwaves skip it, since they would only help it escape. Not part of the candidate: the Lifesteal rework (Lifesteal stays as it is), a Labs catalogue, any screen, and Tier 2 and 3.

`python3 tools/number_trial.py` measures one configuration against the six criteria below, through the harness's own scenarios, and a cache keeps repeat runs free. Its criteria logic has its own tests (`tests/test_number_trial.py`).

### 10.4 The pass criteria (written 3 October 2026, before the candidate was built)

Measured with the balance harness's own scenarios and seeds (`tools/balance_report.py`, BALANCE_TESTS.md), Tier 1, bots. **Baseline** (`data/balance/full.json`, unchanged code):

| Scenario | Median wave | Other |
|---|---|---|
| `fresh_none` / `fresh_even` / `fresh_core` (20 seeds) | 3 / 6 / 3 | |
| `budget_10000_core` / `_turtle` (4 seeds) | 31 / 41 | |
| `budget_100000_core` / `_turtle` (4 seeds) | 51 / 84 | turtle's median peak Number 2,820 |
| `career_core` (50 runs) | first run reaching wave 31: **47** | |

A configuration is one value for each option. For the Coins builds, **10K Coins uses the weak recovery** (`r_base`) and **100K uses the Lab-maxed recovery** (`r_max`), as a stand-in for what Labs add. It passes if **all six** hold:

1. **The Number decides something.** With the candidate on, switching off the coupling (K = 0) costs at least 2 median waves on at least one of core and turtle at 10K and 100K, and so does setting recovery to 0 (thieves on). Today neither moves any wave.
2. **The problem is real, then solved.** For **both** the core and the turtle builds, thieves cost at least 2 median waves against the same build with no Dividers at 10K Coins (`--divider-share 0`), and at most 1 at 100K.
3. **The dead cards come alive.** With the candidate on at `r_base`, the level-7 Health card and the level-7 Health Regen card each gain at least 1 median wave on at least one of CARDS.md's three card builds (2K core, 4K turtle, 40K core). This is D149's floor. The ratio to the Damage card's gain is reported, not judged.
4. **No runaway.** The core career first reaches wave 31 between run 35 and run 60 (baseline 47), and the turtle's median peak Number at 100K is at most 3 times the baseline's (8,460).
5. **The early game holds.** `fresh_none`, `fresh_even` and `fresh_core` each keep their median wave within 1 of the baseline.
6. **The ledger has the intended shape.** At 10K Coins on the core and turtle builds, a run recovers at most half of what thieves take, with at least 3 thefts in the median run. At 100K Coins with `r_max`, it recovers at least 90%.

**The grid** (fixed now): `number_power` 0.1, 0.2, 0.3; `thief_speed` 1, 2; `thief_fade` 0 and 600 seconds; `thief_priority` off and on; `r_base` 0.25 and 0.5; `r_max` 1.0 and 1.5.

**Rules of the trial:**
- Every configuration run is reported, passing or not.
- No seed is chosen; the harness's seeds are used as they are.
- The criteria above are not changed after results are seen. If none passes, that is the finding, and any change goes to the owner as a proposal.
- The coupling is judged one build at a time, so a pass on the turtle alone doesn't count for the core.
- A pass means the numbers hold, not that it's fun. The owner's play is the next gate.

**Clarifications, 3 October 2026, after a review of the pull request and after the first results.** The text above stays as written. Each change makes the trial harder to pass or fixes the candidate, none makes it easier, and no configuration had passed:
- **Criterion 1 is judged for each lever in each build at each budget:** all four cells need 2 or more. The wording "at least one of core and turtle at 10K and 100K" was ambiguous, and the rule that builds are judged one at a time points the stricter way. The tool first graded the loosest reading (one build at 2 or more), and now reports that reading beside the verdict.
- **The Damage card's gain is reported in criterion 3** as the yardstick for the Health and Health Regen cards' gains, as 10.4 said, and is never judged.
- **An exploratory run reports EXPLORATORY, never a pass,** whatever it measures.
- **A thief takes Thorns as it grabs,** as any enemy does on contact. The first build skipped it, so Thorns could never kill or recover a thief, against the design in 10.2. The results run before the fix are void for builds with Thorns and are not kept here.

**Limits known now:** bots, not players. The budget scenarios have 4 seeds, so a 2-wave bar is above most of their noise but not all. The Lab's cost isn't modelled: `r_max` at 100K assumes the Lab is already paid for. Lifesteal, Tier 2 and Tier 3, and the screen (the thief drawn carrying its bite, the Taken / Recovered line) are not measured.

### 10.5 Results

All on the fixed candidate (after the clarifications in 10.4), against `data/balance/full.json`'s baseline, bots, Tier 1. Reproduce a configuration with `python3 tools/number_trial.py`.

**Verdict: the declared candidate fails, and no configuration on the declared grid can pass.**

What was run, all of it reported here:
- **8 of the grid's 96 configurations**, the centre and each single variation, build phase (criteria 1, 2 and 6, and the peak half of 4). All fail 1, 2 and 6.
- **The slow phase (criteria 3, 4 and 5) for the centre and the lowest power.** Both pass 3 and 5 and fail 4.
- **All 48 combinations of power, speed, fade, priority and `r_base` on the core build at 10K Coins.** `r_max` only acts at 100K, so these decide criteria 2 and 6 for all 96 configurations. Thieves cost 0 waves in every one, and the most thefts a run is 2 at power 0.1, 1 at 0.2 and 0 at 0.3.
- **Three exploratory runs with more Dividers** (outside the grid, so they can't count as a pass).

**The declared grid, build phase.** C1 is judged for each lever in each build at each budget; C2 needs thieves to cost 2 or more waves at 10K and 1 or less at 100K for both builds; C6 needs at least 3 thefts a run.

| Configuration | Waves lost without the power (core 10K, turtle 10K; core 100K, turtle 100K) | Waves lost without recovery | C2: waves thieves cost (core, turtle at 10K; core, turtle at 100K) | C6: thefts a run (core, turtle) |
|---|---|---|---|---|
| Centre (`number_power` 0.2) | 20, 10; 30, 18 | 0, 0; 0, 17 | 0, 4; 0, −6 | 1, 2 |
| `number_power` 0.1 | 10, 5; 14, 11 | 0, 1; 1, 16 | 0, 4; 3, −10 | 2, 5 |
| `number_power` 0.3 | 40, 22; 50, 33 | 0, 0; 0, 11 | 0, 1; 0, 0 | 0, 0 |
| speed 2 | 20, 10; 30, 20 | 0, 0; 0, 16 | 0, 4; 0, −5 | 1, 2 |
| fade 600 s | 20, 10; 30, 18 | 0, 0; 0, 16 | 0, 4; 0, −6 | 1, 2 |
| priority off | 20, 10; 30, 19 | 0, 0; 0, 13 | 0, 4; 0, −2 | 1, 2 |
| `r_base` 0.25 | 20, 10; 30, 18 | 0, 0; 0, 17 | 0, 4; 0, −6 | 1, 2 |
| `r_max` 1.0 | 20, 10; 30, 17 | 0, 0; 0, 11 | 0, 4; 0, 0 | 1, 2 |

Every row fails C1 (recovery matters in one cell of four), C2 (the core build loses nothing to thieves at 10K) and C6 (the core build is robbed at most twice a run, and the criterion needs 3). A negative C2 figure means the run with thieves went further than the run with no Dividers at all.

**Why no configuration on the grid can pass.** Criterion 2 needs thieves to cost the core build 2 waves at 10K, and criterion 6 needs at least 3 thefts a run on it. Both depend only on the core build at 10K, and on the five options that can change it (`r_max` acts at 100K). All 48 combinations of those were measured: the cost is 0 waves in every one, and the most thefts a run is 2 (at power 0.1; 1 at 0.2, 0 at 0.3). So criteria 2 and 6 fail in all 96 configurations, measured rather than inferred. The mechanism is under "What it shows" below: a stronger power means fewer Dividers land, and recovery, speed, fade and priority act only after one has.

**The slow phase.**

| | C3: level-7 Health card's gain (early, turtle, later builds) | Health Regen's gain | Damage card's gain | C4: career's first wave-31 run (window 35 to 60, baseline 47); turtle 100K peak Number (at most 8,461) | C5: fresh runs against the baseline |
|---|---|---|---|---|---|
| Centre (0.2) | **pass:** 10, 1, 10 | 2, 0, 0 | 47, 40, 51 | **fail:** run 16; 20,830 | pass: 0, 1, 0 |
| `number_power` 0.1 | **pass:** 3, 6, 1 | 0, 3, 0 | 32, 28, 36 | **fail:** run 29; 24,849 | pass: 0, 1, 0 |

At 0.2 the Health card's gain is 21% and 20% of the Damage card's on the early and later builds and 3% on the turtle; at 0.1 it is 21% on the turtle and 9% and 3% elsewhere. Without the trial the Health and Health Regen cards gain 0 at every level on every build (D149).

**Exploratory, outside the grid (never a pass).** The same build-phase runs with a harsher Divider, so the problem might actually occur:

| Run (centre otherwise) | Thefts a run (core, turtle) | C2: waves thieves cost at 10K (core, turtle) | At 100K (core, turtle) |
|---|---|---|---|
| 3 times as many Dividers | 2, 7 | 0, 5 | 0, −208 |
| and ÷2 | 2, 6 | 1, 7 | 0, −208 |
| and 8 times a basic's health | 3, 9 | **8, 14** | −228, −208 |

**What it shows**
- **The power coupling does what the owner asked of the Number, and too much of it.** The Number now decides waves (removing the power costs the four builds 5 to 50 waves), the early game holds (C5), and the Health card finally earns its place (C3). But even the smallest power on the grid breaks the pace: the core career first reaches wave 31 on run 29 at 0.1 and run 16 at 0.2, against 47, and the turtle's Number ends at 7 to 9 times the baseline's. The grid's lowest value is already too strong.
- **Thieves aren't a problem at Tier 1's Divider.** A competent build kills nearly every Divider before it lands, so the core build is robbed once or twice a run and loses nothing. The answer is in place before the first Coin, so there is nothing to wait for and nothing to protect. Nothing on the grid changes this.
- **A harsher Divider does make the problem real, and the stats do solve it.** With 3 times as many, ÷2 and 8 times the health, thieves cost the core build 8 waves and the turtle 14 at 10K, and are answered by 100K. That is the shape the owner described. It overturns D083's deliberately gentle Tier 1 Divider, which is the owner's to change.
- **A recovery over 1 with the coupling is a Number printer.** In the exploratory runs the turtle at 100K never dies: it reaches the 3-hour cap at wave 309, with a peak Number of 2 to 4 trillion, against a death at wave 87 without recovery and 101 with no Dividers. It is robbed about 150 times and gets back 150% of every bite, so each theft makes it stronger, and a stronger Number kills carriers more surely. That is D037's loop returning through recovery. In the declared grid, with 1 times the Dividers, the same mechanism shows as thieves *helping* the turtle at 100K by up to 10 waves.
- **A flaw in C2's wording.** It says thieves cost "1 or less" at 100K, which a negative number satisfies, so a runaway counts as "solved" (the exploratory 8-times-health run passes C2 and C6 for that reason). Solved should mean close to 0, not far below it. The criteria are unchanged here, as the rules require, and the next round should bound C2 from below.

**What this does not show.** Players, whether any of this is fun, Tier 2 and 3, Lifesteal, and the Labs' cost (`r_max` assumes the Lab is paid for). The budget scenarios have 4 seeds.

**What I'd propose next, for the owner to decide (nothing is built):**
1. **Change it, don't drop it.** The coupling works but is far too strong, the threat is far too weak, and recovery needs a ceiling.
2. **A new Number-taking enemy rather than a rougher Divider,** tuned near the exploratory shape (frequent, ÷2 or so, tough), so D083's gentle Divider stays. Arriving at Tier 1 wave 30, when Labs open, would put the problem and its first Lab together. The cost is a Number that is only a health pool for the first 30 waves.
3. **Recovery capped at 1** (Labs raising it from a quarter to the whole bite), with any over-100% hit a bounded bonus, never a share of the bite each time.
4. **A coupling weaker than the grid's 0.1, or bounded** (a ceiling on the multiplier), tested against the same career window.
5. **Criteria for the second round written first, again,** with C2 bounded from below.

---

## 11. The Number is the goal (4 October 2026, D153): design note

**Status:** the owner decided the goal (D153): the Number is what the player plays for, and waves are the test it faces. The owner has also chosen how shots are priced (11.3: a fixed price per shot) and that **each tier sets the Number's demands** as part of its difficulty (11.5). Everything else below is a **proposal for the owner to accept or change; nothing is built**. It supersedes section 10's next round: the trial (10.5) showed a coupling makes the Number matter, and this turns that into the game's spine.

### 11.1 The decision, and the owner's sketch

The owner chose the Number over waves as the goal, then sketched the core of it: "1 basic shot costs 1 number, number regen is giving us extra number to compensate, but then we have a barrier as a player to overcome of 'Okay I'm now regenning more than I am losing on shooting now'".

That sketch solves what section 9 found missing. Today the Number is a health pool: nothing at the walls depends on its size or state. If every shot is paid for out of the Number, then the Number is the tower's fuel as well as its health, and running low means you can't fight.

### 11.2 The one rule: the Number is fuel, health and score

| The Number goes up from | The Number goes down from |
|---|---|
| Regen, every second | Every shot the tower fires (11.3) |
| Kills by the tower's shots: each pays a bounty | Enemies' hits, as now, through the defences |
| Buying Starting Number (today's Health row) before a run | Dividers' ÷, and later thieves (D152) |

Nothing else moves it: no spending it on upgrades in v1 (Cash stays the run's currency, AGENTS.md law 4), and no decay. A rise has an author (the player's build) and a fall has an author (an enemy, or the tower's own shots), the rule section 10 proposed.

### 11.3 Shots cost a fixed price (the owner's choice)

**Every shot the tower fires costs the tier's shot price: 1 Number in Tier 1.** Its damage doesn't change the price. Two prices were weighed: a fixed price per shot (A) and a price per point of damage dealt (B). B would give every boss a price that only grows, so the Number's size would decide every wall; the agent first recommended it. **The owner chose A** after the agent re-weighed the two for how they feel to play:
- **Every Damage upgrade is a gift:** shots hit harder and still cost 1, so each Number goes further, and the player feels it at once. Under B, Damage only kills faster and the price per kill stays put.
- **The barrier can be solved:** once Regen and bounties outpace your shooting, you've beaten it, which is D152's test ("I can't wait to invest enough into stats so this problem is solved"). Under B the prices keep climbing, a treadmill the player can see.
- **It reads at a glance:** −1 a shot, +x a kill, and Regen against shots a second. The early decision is plain: Attack Speed burns faster, Regen refills.

**What a volley costs:** you pay for each shot the tower fires. Anything that multiplies a shot is free: a critical, a Super Crit, Multishot's extra copies and Bounce Shot's bounces. Those rows stretch each Number, so they are where the economy's "efficiency" lives (11.7). Attack Speed and Rapid Fire raise how often the tower fires, so they spend faster.

**A boss has a price too,** read as the shots it takes: its health ÷ your Damage, times the shot price. Unlike B's, it **falls as you upgrade** ("this boss used to cost 400, now 120"), which is satisfying to watch shrink.

**When the Number can't pay:** a shot never takes the Number below 1, so the tower can't shoot itself dead; when it's broke it goes quiet and the enemies close in. That is the end of a run, and it is legible: you ran out. (The gentler alternative, a free weak "pilot" shot, is open in 11.12.)

**A's known weakness, and the answer:** within a tier, once the Number is in the thousands, a 1-Number shot is noise, so late in a tier the Number drifts back towards a health pool and the boss wall towards killing speed. The answer is the tier (11.5): each new tier raises the Number's demands and the barrier comes back at a new scale.

### 11.4 The run's arc: the barriers a player clears

1. **Survive.** The Starting Number carries the first waves.
2. **Sustain.** The owner's barrier: income (Regen and bounties) at least matches spending (shots and hits). The screen shows it as a net rate under the Number ("+3.2/s" in green, "−1.4/s" in red), so crossing it is a moment the player sees.
3. **Grow.** The surplus banks, the Number climbs, and kills pop. This is the dopamine.
4. **The wall.** Enemies need more shots than their bounties pay for, the net rate turns red, the Number peaks and drains, and the boss you can't afford ends it. **The peak is the run's score.**

Between runs the Workshop, and within a run the Cash upgrades, push each crossing later: every barrier is a crossing of two numbers the player can read.

Illustrative, in Tier 1 with a shot price of 1 and a kill paying its enemy's Attack (today a clean kill pays 5% of it, D111), on the owner's screens' basic enemy. Two towers: a fresh one (Damage 3) and one with the Damage the owner's fresh Tower run had bought by wave 8 (19):

| Wave | Basic's health | Bounty (its Attack) | Shots at Damage 3 | Net per kill | Shots at Damage 19 | Net per kill |
|---|---|---|---|---|---|---|
| 1 | 2.35 | 1.18 | 1 | +0.18 | 1 | +0.18 |
| 2 | 3.31 | 1.39 | 2 | −0.61 | 1 | +0.39 |
| 5 | 7.20 | 2.30 | 3 | −0.70 | 1 | +1.30 |
| 8 | 12.15 | 3.56 | 5 | −1.44 | 1 | +2.56 |
| 22 | 63.11 | 15.90 | 22 | −6.10 | 4 | +11.90 |

A tower that buys no Damage loses Number on every kill from wave 2; one that buys Damage profits more with every wave. **Buying Damage is how you stay in the black**, which is the satisfying loop: upgrade, and watch each kill pay more. Overkill is wasted damage, not wasted Number. The numbers are guesses to be measured, not a tuning: a missed shot, Regen and hits aren't in the table, and a bounty of a whole Attack is too generous (11.14 shows why).

### 11.5 Tiers set the Number's demands (the owner's direction)

The owner: "We could always increase number demands the higher the tiers go too, so it could be tier specific, with the tier being the overall difficulty."

So **a tier is the game's overall difficulty dial, and its row in the tier data carries the Number's demands** beside its enemy multipliers and Coins bonus:
- **The shot price:** 1 in Tier 1, then higher per tier. This re-opens the sustain barrier at each tier's start, so a build that solved Tier 1 has a new problem in Tier 2, which is D112's shape (each tier breaks the last answer).
- **What else a tier can raise,** each measured before it is added: a Divider's bite, the Number a run starts below its build, or the digits that tier's milestones sit at.
- **Proposed calibration:** each tier's price is chosen so that a build that had just solved the tier before it turns net-negative early in the new one, and has to rebuild its economy with better stats. A tier already multiplies enemy health (×20 in Tier 2, ×60 in Tier 3, D107), which multiplies the shots a kill needs, while bounties follow its attack multiplier. The price step is the extra knob on top, so it may be modest. Measured per tier, not guessed.
- **The trade:** a higher tier asks more of the Number and pays more Coins for it (its Coins bonus, 1.8× in Tier 2 and 2.6× in Tier 3), so choosing a tier is choosing difficulty for reward.

### 11.6 What the player chases

- **The record is the best Number,** by tier. Best wave is still shown, beneath it.
- **Coins come from the run's peak Number,** not from kills and waves, so pushing the Number is what pays. Proposal: Coins grow with the peak as a power below 1, times the tier's Coins bonus, calibrated so today's typical runs earn about what they do now. The Coins / Kill and Coins / Wave rows go (11.7).
- **Digits open systems.** The Workshop still opens after the first run; Cards, Labs and Tier 2 open at Number digits, set by measurement so they arrive at about the same play time as The Tower's waves 20, 30 and 100. D131's typefaces stay as the identity reward for each digit, on top.
- **Tiers still pose a new problem each** (D112), open by Number, and raise its demands (11.5).

### 11.7 The Workshop, reworked

The rows stay The Tower's, with its Coin prices, but each has a job in the Number's economy:

| Job | Rows | Change |
|---|---|---|
| **Budget** | Health | Becomes Starting Number: the fuel a run opens with |
| **Income** | Health Regen; Coins / Kill Bonus; Lifesteal | Regen stays. Coins / Kill Bonus becomes **Bounty** (Number per kill). Lifesteal becomes a share of each kill's shots refunded |
| **Power** (each shot does more for the same price) | Damage, Critical Chance and Factor, Super Crit, Damage / Meter, Rend Armor | Unchanged rules: now they are also the economy, since a shot that kills sooner costs fewer Number |
| **Free shots** | Multishot, Bounce Shot | Unchanged rules: their extra copies and bounces cost nothing, so they stretch each Number |
| **Rate** | Attack Speed, Rapid Fire | Unchanged rules: kill sooner, but spend faster. The early tension: rate against Regen |
| **Control** | Range, Knockback, Shockwave | Unchanged: they keep enemies off the Number |
| **Guard** | Defense % and Absolute, the Wall, Thorns, Death Defy, Recovery Packages | Unchanged: they keep the Number from enemies |
| **Free killers** | Orbs, Thorns' damage, Land Mines | **Their kills pay no bounty at first** (open, 11.12): they protect the Number without printing it, since they aren't shots and cost nothing. **Labs raise their share** (the owner, 11.14) |
| **Run economy** | Cash Bonus, Cash / Wave, Interest, Free Upgrades | Unchanged while Cash stays the run's currency |
| **Meta** | Coins / Wave | Goes: Coins come from the peak |
| **Enemy Level Skip** | Health and Attack skip | Unchanged; with Bounty tied to Attack, skipping Attack also lowers bounties, a real trade |

There is **no new stat**: under A, Damage and the rows that multiply a shot are the efficiency. Cards follow the rows: the Health card becomes a Starting Number card and Health Regen an income card, so D149's dead cards get a job. Labs get their first entries here (Regen, Bounty, Starting Number), on the research engine D126 built.

### 11.8 The threats to the Number

- **Flat hits** (The Tower's enemies) subtract as now, and every Number they take is a shot you can't fire.
- **Bosses** are price tags (11.3). The screen can show one ("Boss: 120"), which keeps the vision's honesty test: every number that ends a run was visible before it did.
- **Dividers** take a share of the war chest. They stay gentle in Tier 1 (D083), and a tier may raise them (11.5); a share-based hit is a tax, not the main threat (D001's lesson).
- **The Lock** holds the Number's growth, as now.
- **Thieves** (D152) can return later as a separate enemy, with recovery capped at 1 so they can't become a Number printer (10.5).

### 11.9 Pacing: how big, how fast

- **Growth compounds where it is earned:** bigger waves pay bigger bounties, so a build whose Damage keeps up sees the Number accelerate. Enemy health outgrows attack, so a build that stops keeping up loses money on each kill and the run peaks.
- **D110's rule that nothing grows by a share of itself stays:** no interest on the Number. That is what keeps D037's loop shut.
- **D110's pace target (a digit every 50 waves) goes,** replaced by a target the owner sets in play time. My proposal: a new best digit roughly every 30 to 60 minutes early, slowing later, so numbers get big but not "absurdly high too quickly" (the owner, D110).
- **Showing it (the owner, D154):** in full, with commas, all the way to 999,999,999,999, so the digits keep ticking as it grows (built: `Palette.FULL_BELOW` is a trillion). Past that, which Tier 1 rarely reaches (11.15), it shortens; later tiers' format is decided when they come.

### 11.10 What we keep from The Tower, and what we let go

| Keep | Let go |
|---|---|
| The battle: the tower in the middle, enemies walking in, shots, defences | Waves as the goal, and wave milestones as the gates (D125, D136) |
| The Tower's enemies, their stats and spawns (generated data) | Best wave as the headline record |
| The 26 s + 9 s wave rhythm | Coins per kill and per wave (D074) |
| The Workshop's structure and Coin prices | Health as its own stat, apart from the Number |
| Tiers that break the last answer, now also raising the Number's demands | The Tower's benchmarks as pass or fail (D149 A): kept as a sanity reference only |
| Cards, Labs, Cash for run upgrades (for now) | D152's power coupling, replaced by fuel |

### 11.11 Risks

- **D037's loop.** Kills pay the Number that pays for the shots that make kills. It is bounded only because enemy health outgrows bounties, so a build that stops upgrading loses money on each kill, and that has to be measured; the criteria include a runaway check (10.5 showed how fast an unbounded loop runs away).
- **Solved too well within a tier.** A fixed price fades as the Number grows (11.3). The tier steps are the answer, but late in each tier the Number matters less at the boss wall.
- **Losing The Tower as proof of fun.** Its benchmarks were the only outside check that the pace felt right. The owner's play becomes the real gate, so a playable build should come early, behind a switch.
- **A death spiral that feels unfair.** When broke, the tower goes quiet. That is dramatic, but if it comes without warning it is frustrating; the net-rate readout and boss price are what make it fair.
- **A busy Number.** It moves constantly (down 1 each shot, up with each kill). The screen has to make the trend readable, not just the value.
- **Size.** This touches `BattleSim`, the economy, Coins, milestones, saves and screens: high risk under QUALITY_GATES. It goes in stages, measure-only first (11.13). Workshop ranks and Coins carry over; milestone claims change, so saves need a migration.

### 11.12 Open questions for the owner

1. ~~Shots: a fixed price or a price per damage?~~ **A fixed price per shot, set per tier** (the owner, 4 October).
2. **When broke: the tower goes quiet, or fires a free weak "pilot" shot?** I'd go quiet (dramatic and legible), never below 1.
3. **Free killers (Orbs, Thorns, Mines): their kills pay no bounty, until Labs give them a share?** The owner's idea, and I agree (11.14): nothing at the start, a Lab per killer raising it, capped at half a shot's bounty.
4. **Cash: keep it for run upgrades, or buy upgrades with the Number?** I'd keep Cash for v1 and revisit once the fuel economy is measured. One big change at a time.
5. **The pacing target:** how often a new best digit, early and late. Proposed in 11.9.
6. **Digit unlocks, the Coins formula and each tier's shot price:** I'd set them by measurement, so play time to Cards, Labs and Tier 2 stays about where it is and each tier re-opens the barrier.

### 11.13 How we'd prove it

In stages, each played by the owner before the next (REBUILD_SPEC rule 5):

1. **The fuel economy, measure-only:** the shot price, bounties and the broke rule as off-by-default options in `BattleSim`, with `sim_runs.gd` and `number_trial.py` reporting peak Number, the sustain crossing and the net rate. Criteria written and agreed first. A draft:
   - **C1. The Number decides the run:** making shots free moves the median wave by 2 or more in every build at both budgets.
   - **C2. The sustain barrier exists, and investment moves it:** a fresh tower that buys nothing turns net-negative between waves 2 and 10, and a 10K-Coin build at least 10 waves later.
   - **C3. Runs have an arc:** the median run's peak Number comes before its last 3 waves.
   - **C4. No runaway:** no build reaches the 3-hour cap at 100K Coins, and no single source supplies most of the Number.
   - **C5. The early game holds:** fresh runs end by wave 10.
   - **C6. The stats that should matter do:** Regen, Starting Number and Bounty each raise the median peak Number by at least 10% at Workshop level 25 against level 0.
2. **Tier 2's shot price:** measured so a build that solved Tier 1 starts Tier 2 net-negative (11.5).
3. **Coins from the peak and digit unlocks:** economy and saves, high risk, with migration fixtures.
4. **The screen:** the net rate, boss prices, the drain and the pops.
5. **The owner plays it,** and decides whether The Tower's shape goes for good.

### 11.14 The mechanics in numbers (4 October 2026)

Worked out from the generated enemy data; still to be measured.

**The economy is one sum.** Every second:

> net = Regen + kills × bounty − shots × price − hits that get through

The tower only fires while something is in range, so excess Damage means fewer shots, not wasted Number. Per kill, that comes to **bounty − price × shots to kill**, and shots to kill are the enemy's health ÷ your Damage, rounded up.

**Break-even Damage.** A kill pays for itself once your Damage passes roughly

> price × (enemy health ÷ enemy attack) ÷ bounty share

when the bounty is a share of the enemy's Attack. That is a number the player can be shown ("your shots pay for themselves from Damage 42"), and passing it is the owner's barrier made visible. What moves it is the enemy's health over its attack, which climbs with the waves (a basic enemy, from the generated data):

| Level | 1 | 5 | 10 | 22 | 50 | 100 | 200 | 500 |
|---|---|---|---|---|---|---|---|---|
| Health ÷ attack | 2.0 | 3.2 | 3.8 | 4.4 | 5.9 | 10.8 | 22.6 | 116 |

So the bar roughly doubles by wave 20, again by 100, then climbs steeply: **the barrier is solved, then quietly comes back**, which is the treadmill done gently, and Damage upgrades can outpace it.

**Three things follow.**
1. **A whole Attack as the bounty is far too generous.** Break-even Damage would be 2 at the start and 4.4 at wave 22, so one cheap Damage purchase solves the economy for most of Tier 1 and shooting stops mattering. **A share of about a quarter** puts it at about 8 at the start, 18 at wave 22 and 43 at wave 100. A fresh tower loses a little on each kill until it buys Damage in the run; the owner's fresh Tower run had Damage 19 by wave 8, where break-even would be about 14. That crossing would land inside a first run. A guess to measure.
2. **Enemies split into earners and costs.** The bounty follows Attack but the price follows health, so a kind's health ÷ attack sets its break-even: a tank (5× health, ½ attack) needs 10 times a basic's Damage to pay, and a boss (20× health, 1× attack) 20 times. **Basics are income, tanks are a drain, and a boss is a bill every tenth wave.** That is a budget wall even with a fixed price per shot: the war chest you bring to wave 30 is what pays for its boss, and the bill falls as Damage rises.
3. **A tier's multipliers alone don't move the barrier.** A tier multiplies enemy health and attack alike (×20 in Tier 2), so the shots per kill and the bounty grow together and break-even Damage stays put; only killing speed gets harder. **The tier's shot price is the lever that re-opens the barrier**, which is why the owner's tier demands (11.5) are needed, not optional: Tier 2's price multiplies break-even Damage by itself.

**The start: shooting is free, exactly.** A fresh tower fires once a second at 1 Number a shot, and The Tower gives it no Regen, so it would be broke within five shots. **Proposal: the tower starts with 1 Regen a second, its fire rate times the price**, so at the start shooting costs nothing net and the owner's barrier begins at parity. Then the first Attack Speed purchase is the first real decision (faster, but now spending more than Regen gives), kills add bounty on top, and hits are the only loss. A tier's base Regen would scale with its price.

**Free killers, and the Labs that wake them (the owner's idea).** Orbs, Thorns and Mines kill without firing, so their kills pay nothing at first: they guard the Number without printing it. **A Lab for each** (Orb, Thorn and Mine bounty) raises their kills' share of the bounty from nothing, **capped at half** a shot's bounty, so a paid shot is always the better earner per kill and a blender build earns more slowly than it kills. Their income is bounded by how many enemies arrive, not by its own size, so it can't compound the way 10.5's over-100% recovery did. It also gives Labs a clear first purpose, beside Regen, Bounty and Starting Number.

**Knockback: probably broken today, and in the way of measuring this** (the owner, 4 October: it "pushes tanks and bosses back way more than it should, which is likely why runs just last forever"). From the code, not yet measured:
- A push is Knockback Force × `KNOCKBACK_METRES_PER_FORCE` ÷ the enemy's mass over a basic's. That 5 metres per unit of force is **our guess**; The Tower gives no units (`guesses.gd`).
- At Force level 25 (4.15) a basic goes back 21 m a knock, a tank 4.3 m and a boss 1.7 m; at the last level (6.08), 30 m, 6.3 m and 2.5 m. **A worn tank shed mass down to a basic's (D145, ours), so a nearly dead one flew the full 21 to 30 m; D154 removed that on the owner's word**: tanks keep their weight, can still be killed outright by Orbs, but don't fly like fast enemies.
- The chance (up to 80%) rolls on every strike, including Multishot copies and bounces. A boss walks about 3 m a second (0.4 of a basic's 7.66). At the last levels, with about five strikes a second, it is pushed back about 10 m a second, so **it never arrives.** That would explain runs that never end once Knockback is high.
- **The fix is for later, as the owner asked.** But it confounds the Number's measurements (a run that can't end trips the runaway check for the wrong reason), so stage 1 should run with Knockback both as it is and switched off, and report both.

### 11.15 Pacing Tier 1, and the very early game (4 October 2026)

**The owner's direction:** "I want to pace the number, so you don't end up in the trillions on tier 1 unless you get really deep into the run", and "later tiers are where you will have all the multipliers so the number will start running away with it". Starting with 1 Regen is accepted (D153, amended).

**The Tower's own curve does most of the pacing.** A kill's bounty follows the enemy's attack, which grows slowly enough that the Number can't explode in Tier 1. A rough upper bound from the generated data: a strong build that kills everything with one shot, a bounty of a quarter of the Attack, nothing lost to hits, and no Bounty bought. The wave by which a run would first hold each amount:

| Bounty share | 1,000 | 10,000 | 100,000 | 1,000,000 | 1,000,000,000 | 1,000,000,000,000 |
|---|---|---|---|---|---|---|
| a quarter | 32 | 62 | 116 | 213 | about 1,025 | not within 3,000 waves |
| a half | 24 | 50 | 96 | 178 | about 890 | not within 3,000 |
| all of it | 18 | 40 | 79 | 149 | about 770 | about 2,730 |

Real runs lose Number to hits and shots and gain from bought Bounty, Cards and Labs, so this is a ceiling to calibrate against, not a forecast. What it says is that **with a modest bounty, Tier 1 reaches the billions only in very deep runs and the trillions practically never**, which is the owner's pacing. A tier's attack multiplier (×20 in Tier 2, ×60 in Tier 3) multiplies every bounty, so the Number starts running away there, as the owner wants.

**The Number to beat Tier 1: 1,000,000** (proposed). The first million is the most recognisable number there is, seven digits is a moment, and in the model a strong build reaches it a little after wave 200 on base bounty. Bought Bounty would bring it nearer wave 100 to 150, about where The Tower opens Tier 2 (clearing wave 100). The digits before it would open the rest:

| Digit | Opens | Model wave (a quarter share, no Bounty bought) | The Tower's equivalent |
|---|---|---|---|
| — | The Workshop, after the first run (as now) | — | after the first run |
| 1,000 | Cards | about 32 | wave 20 |
| 10,000 | Labs | about 62 | wave 30 |
| 1,000,000 | Tier 2 | about 213 | clearing wave 100 |

The model's waves run later than The Tower's because it buys no Bounty; stage 1 calibrates the bounty share and the first Bounty levels so the play time to each digit lands near The Tower's. The values here are the target ladder, which is the owner's to change.

**The very early game, item by item:**
1. **Start: Number 5, Regen 1 a second, shots 1 each** (accepted). Shooting is free at the start, and the first Attack Speed purchase tips you into spending more than Regen gives.
2. **Regen sustains, kills grow.** Keep D111's rule that Regen refills only up to the run's best, so the Number climbs from kills (bounties), never from waiting. Regen pays for shooting; bounties are growth.
3. **The Regen row needs rescaling.** The Tower's first Regen levels add hundredths of a point a second, invisible beside a base of 1. Its values should scale so a first level is a step the player notices (for example ten times as large); measured in stage 1.
4. **Fractions early.** A wave-1 bounty is about 0.3. The kill pops should show one decimal while they're under 10, and the Number tenths while it's under 100 (as it already does under 1,000 in `Palette.number`'s style), so the opening moves visibly.
5. **No paying for doomed shots.** Under a fixed price, a shot still flying at an enemy that an earlier shot kills is Number spent for nothing. The tower should hold fire on an enemy that shots already in flight will kill. The Tower doesn't do this, but it removes a cost the player can't see or control.
6. **Any kill by a shot pays.** D111 paid only for clean kills (the enemy hadn't hit yet); with hits already costing Number, a simpler rule reads better.
7. **The first run's Coins.** Coins come from the peak (11.6), so the formula has to give a first run of a few dozen Number about what a first run earns now, on top of the welcome's 57 (D137).
8. **Fresh runs still end early** (C5): one that buys nothing by about wave 5, one that spreads its Cash by about wave 10.
9. **Cash is unchanged**, so the first Damage purchase stays affordable in the first waves; it is now also the first economy purchase (11.4).


## 12. Stage 1: the fuel economy, measured (4 October 2026, D155)

The owner said "go" to stage 1 (11.13) with its six draft criteria, plus a Multishot build in the runaway check. This section fixes the criteria, the configurations and the rules **before the options exist**, as section 10 did. Nothing here changes the game: every option is off by default, recorded in a run only while it is on, and played only by `tools/sim_runs.gd` and `tools/fuel_trial.py`.

### 12.1 What stage 1 builds

`BattleSim` measuring options, each off by default:

| Option | What it does | Off |
|---|---|---|
| `shot_price` | Every volley the tower fires costs this much Number; Multishot's copies and Bounce Shot's bounces are free (11.3). A shot is never fired if it would leave the Number below 1: the tower goes quiet until Regen or a kill pays for it | 0 |
| `bounty_share` | A kill by a shot (a bounce's too) pays this share of the enemy's Attack, times Coins / Kill (standing in for the Bounty row, 11.7), through the same Lock rule as today (none while a Lock stands). It replaces D111's clean-kill growth while the fuel economy is on, so any shot kill pays (11.15, item 6). Dividers and Locks, which have no Attack, pay a basic's | 0 |
| `free_bounty_share` | Kills by Orbs, Thorns and Mines pay this share of a shot kill's bounty, at most 0.5: the Labs that wake the free killers (11.14) | 0 |
| `base_regen` | Regen a second added to the Health Regen row: the starting Regen the owner accepted (D153) | 0 |
| `regen_scale` | Multiplies the Health Regen row (11.15, item 3) | 1 |
| `hold_doomed` | The tower doesn't fire at an enemy that shots already in flight will kill, counting their damage before anything that would only add to it (so it may still waste a shot, never hold one it needed) | off |

**The fuel economy is on** whenever `shot_price` or `bounty_share` is above 0. While it is on, a run also keeps a ledger: the shots paid for and their cost, what bounties paid, the wave the peak was set, and each wave's income and spending. `sim_runs.gd` gets a flag for each option, plus `--knockback off` (the Workshop's Knockback rows at 0 and its group closed), `--row-levels ID:N,...` (set rows to Workshop levels, opening their groups) and a `multishot` Workshop plan (Multishot and Bounce Shot opened and bought beside the core rows).

### 12.2 Definitions

- **A wave's net:** what the Number gained in that wave from everything but bought Health (Regen, bounties, Lifesteal, packages), minus what shots cost and what enemies took (hits, drains, ÷). The wave a run ends in counts, up to the moment it ends.
- **A run's crossing:** its first wave with a negative net. A run that never has one counts as its last wave plus 1.
- **A run's peak wave:** the wave in which the Number first stood at its peak.
- **The builds:** `core`, `turtle`, `blender` and `multishot`, each built from 10K and from 100K Coins with `--workshop-plan`, buying `core` in the run, 3-hour cap, **6 seeds** (the harness's 1 to 6). Eight cells, each judged alone.

### 12.3 The pass criteria (written before the options were built)

The baseline is `data/balance/full.json` on `main` (`401deb1`): fresh runs' median waves 3 (none), 6 (even) and 3 (core); 10K core 31, turtle 41, blender 31; 100K core 51, turtle 84, blender 48.

1. **The Number decides the run.** With the fuel economy on, making shots free (`shot_price` 0, all else the same) adds at least 2 median waves in each of the eight build cells.
2. **The sustain barrier exists, and investment moves it.** The fresh tower that buys nothing (`fresh_none`, 20 seeds) has its median crossing between waves 2 and 10, and the 10K core build's median crossing is at least 10 waves later than that.
3. **Runs have an arc.** In each of the eight cells, the median run's peak wave is at least 3 waves before its last wave. A run stopped by the cap counts as having no arc.
4. **No runaway.** At 100K Coins, no run of any build reaches the 3-hour cap with Knockback off (the blender's Knockback rows at 0; the other builds buy none). And in every cell, in the median run, no source other than bounties and bought Health lifts more than half of the Number's rise to new highs: Regen's drift, Lifesteal, packages or the free killers must not become a printer (10.5). The runs with Knockback on are reported beside it; a cap reached only with it on is Knockback's problem, not the fuel economy's.
5. **The early game holds.** `fresh_none`, `fresh_even` and `fresh_core` (20 seeds, 10-minute cap) each have a median wave of at least 2 and at most 10, and no fresh run reaches the cap.
6. **The stats that should matter do.** On the 10K core build, Health Regen, Health (the Starting Number) and Coins / Kill (Bounty's stand-in) each raise the median peak Number by at least 10% at Workshop level 25 against level 0, one row at a time, the rest of the build unchanged.

### 12.4 Configurations

- **The centre:** `shot_price` 1, `bounty_share` 0.25, `free_bounty_share` 0, `base_regen` 1, `regen_scale` 1, `hold_doomed` on.
- **The grid, one lever at a time around the centre:** `bounty_share` 0.125 and 0.5; `regen_scale` 10; `hold_doomed` off; `free_bounty_share` 0.5. Six configurations in all, each measured on every criterion.

### 12.5 Rules of the stage

- Every configuration is reported, passing or not, and no seed is chosen.
- The criteria are not changed after results are seen. If none passes, that is the finding, and any change goes to the owner as a proposal. A grid configuration that passes where the centre fails is reported as a candidate, not adopted.
- Exploring outside the grid is allowed, labelled exploratory, and never counts as a pass.
- A pass means the numbers hold, not that it's fun: the owner's play is the next gate (11.13, stage 5).

### 12.6 Results (4 October 2026): every configuration fails, and a fixed price can't fit Tier 1

Measured on the committed options (`claude/number-fuel`), the harness's seeds, nothing chosen. `python3 tools/fuel_trial.py --grid` reproduces the declared runs; the exploratory ones add `--price N`.

| Configuration | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|
| **Centre** (price 1, bounty 0.25, Regen +1, hold on) | FAIL | FAIL | FAIL | pass | pass | pass |
| Bounty 0.125 | FAIL | FAIL | FAIL | pass | pass | pass |
| Bounty 0.5 | FAIL | pass | FAIL | pass | pass | pass |
| Regen row ×10 | FAIL | FAIL | FAIL | pass | pass | pass |
| Hold off | FAIL | FAIL | FAIL | pass | pass | pass |
| Free killers 0.5 | FAIL | FAIL | FAIL | pass | pass | pass |
| *Exploratory:* price 3 | FAIL | FAIL | FAIL | pass | pass | pass |
| *Exploratory:* price 5 | FAIL | FAIL | FAIL | FAIL | FAIL | pass |
| *Exploratory:* price 10 | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL |

What the runs show (medians; 6 seeds a build, 20 a fresh policy):

1. **At a price of 1, shots don't decide anything (C1).** Free shots add 0 waves in seven of the eight build cells (2 for the 10K turtle). On the 10K core build the shots cost about 7% of the peak (1,338 paid, 1,437 free) and bounties pay back about twice what shots cost. By 10K Coins, the Health row starts a run with a Number in the hundreds, so a 1-Number shot is noise. This is 11.3's known weakness, and it arrives early in Tier 1, not late.
2. **A higher fixed price breaks the start before it bites the middle.** At 3, fresh towers die by wave 2; at 5 and 10, on wave 1, because 5 Number can't pay for the shots that would save it (C5). Only at 10 does the price decide 10K runs (free shots add 25 to 30 waves), and even then the 100K core shrugs it off (1 wave). **Within Tier 1 the Number spans 5 to thousands, and no single price fits both ends.**
3. **The opening can't grow the Number.** A wave-1 kill pays about 0.3 for a 1-Number shot, and Regen refills only up to the best (D111), so early bounties just save Regen work: the fresh tower's first wave nets 0.00, −0.37 and 0.00 on three seeds, and its Number sits at 5 until a kill pays more than its shot (around wave 10 for a one-shot kill at a quarter share). C2 fails on that hair: the median crossing is wave 1. A bounty of 0.5 moves it to wave 2 and passes C2.
4. **Runs end at a wall, not a drain (C3).** In most cells the Number peaks within 2 waves of the end, with shots paid or free: enemies' hits end the run, so the arc the design wants (peak, then the price outgrowing income) never forms. Only the 100K turtle, which outlasts its income for 19 waves, has one.
5. **No runaway (C4).** No build reaches the cap, Multishot included, and nothing but bounties and bought Health lifts the Number's highs (at the centre at most 21%, the 100K blender's Lifesteal; 29% at bounty 0.125). Knockback didn't matter: the blender ends without it too.
6. **The stats that should matter do (C6):** at the centre, Regen +88%, Starting Number +88% and Bounty +17% on the 10K core build's peak.
7. **Bounties lengthen runs against today's game.** The 10K core build reaches wave 38 against the baseline's 31: a quarter of the Attack on any shot kill pays far more than D111's clean-kill 5%, and the Number is still the tower's health. The bounty share moves the peak most (844, 1,338 and 2,330 at 0.125, 0.25 and 0.5) and the wave not at all.
8. **Holding fire changed nothing:** at these fire rates a second shot almost never leaves while the first is still flying at a one-shot kill. It works (a test at top Attack Speed shows it) but costs nothing to leave off.

**The finding:** a price per shot fixed for the tier can't do the job in Tier 1, because the Number's own scale grows a hundredfold inside the tier. Section 12.3's rules say a change goes to the owner as a proposal; mine is in HANDOVER.md and D155: **set the price per wave, as a share of the wave's enemy Attack**, so a kill's profit is the bounty share less the price share times the shots it takes. The barrier is then your Damage against the wave's health, the same at a Number of 5 or 5,000, re-opened as the waves grow and solved by Damage, with a boss's price still falling as you upgrade. It keeps the owner's choice of a price per shot (not per damage) and moves the per-tier price to per-wave. It would be measured against these same criteria, written down again first.

## 13. The Number is Cash (4 October 2026, D156)

*D158 (section 14) made these the game's rules. Mentions below of a Testing switch describe how it was first built, played and measured.*

After stage 1 failed (12.6), the agent laid out the options for the Number: drop it, keep it as health, make it a score, or make it the run's money as well as its life. The owner chose the last: "Let's also make it the cash as well, with the players aim that when they get strong enough they don't need to buy upgrades", "We could also give the player the option to complete switch them off before a run, but not during", and "Coins can still exist, and will be the way of upgrading the workshop permanently, so the player is stronger without sacrificing as much number to grow". The owner then accepted the four rules below that the agent said the plan needed ("Happy with all of these").

### 13.1 The rules

- **Every Cash payment goes into the Number:** a kill's Cash, Cash / Wave and Interest, with Cash Bonus and the Cash card multiplying them as now. Starting Cash adds to the starting Number. D111's clean-kill growth is off, since Cash replaces it.
- **Run upgrades are bought with the Number**, at their Cash prices. A purchase can never take the Number below 1.
- **Regen and Lifesteal restore what enemies took, not what you spent** (the owner accepted): their ceiling falls by every purchase, so spending is a real cost and not a loan Regen repays.
- **Health is Workshop-only** (accepted): it is the Starting Number. It isn't in the run shop, and Free Upgrades skip it.
- **Interest is paid on the Number, capped per wave as now** (accepted): the cap is what keeps D110's rule against growth by a share of itself.
- **Free levels don't raise prices** (accepted): a run's price for a row counts only the levels bought.
- **Run upgrades off:** a switch set before a run closes the shop for the whole run; it can't be changed mid-run. Free Upgrades still land.
- **Coins are unchanged:** earned as now, and the Workshop is still bought with them.
- **Unchanged and worth knowing:** a Divider's ÷ now cuts your wallet too, and a standing Lock (D133) holds the Number, so Cash paid while it stands is lost.

Built as measuring options (`number_cash`, `upgrades_off`), off by default and recorded only while on, and as two switches in Settings → Testing, off by default, that apply from the next run, so the owner can play it beside today's game.

### 13.2 The pass criteria (written before the options were built)

Bots: the core and turtle Workshop plans at 10K, 100K and 1M Coins, 6 seeds each (the harness's 1 to 6), buying `core` in the run with **half the run's best Number kept in reserve** (a bot that spends to 1 dies to the next hit; `--reserve` changes it), and the same builds with run upgrades off. Fresh runs: 20 seeds, 10-minute cap. Every cell is also played as today's game (Number is Cash off) on the same seeds, as the control.

1. **Buying matters while weak.** At 10K Coins, buying adds at least 3 median waves over run upgrades off, for core and for turtle.
2. **Strong builds stop needing it.** The share of waves buying adds ((buying − off) ÷ buying) falls from 10K to 100K to 1M Coins for both plans, and at 1M it is at most 10%.
3. **The Number goes up.** In every cell at 10K and 100K, buying, the median run's peak Number is at least the control's.
4. **No runaway.** No run at 100K or 1M Coins reaches the 3-hour cap unless the control's same cell does too, and Interest supplies at most a quarter of the Number's income in every cell.
5. **The pace holds.** Buying, each 10K and 100K cell's median wave is within 25% of the control's.
6. **The early game holds.** Fresh runs buying nothing, evenly and core each have a median wave from 2 to 10, and none reaches the cap.

The rules of section 10.4 and 12.5 apply: every configuration is reported, no seed is chosen, the criteria aren't changed after results are seen, and a pass means the numbers hold, not that it's fun. **The owner playing it is the real test.**

### 13.3 Results (4 October 2026): pace and safety hold; the shop never stops mattering, and buying keeps the Number low

Measured on the committed options with `python3 tools/cash_trial.py` (the declared run: bots keep half their best in reserve; 6 seeds a cell, 20 a fresh policy). **Overall: FAIL, on criteria 2 and 3.** Unlike sections 10 and 12, nothing breaks: the pace holds, nothing runs away and the early game stands.

| Criterion | Result | What the runs show (medians) |
|---|---|---|
| 1. Buying matters while weak | **pass** | At 10K, buying adds 10 waves (core) and 18 (turtle) over the shop shut |
| 2. Strong builds stop needing it | **FAIL** | The share of waves buying adds barely falls: core 32%, 26%, 25% and turtle 44%, 43%, 37% at 10K, 100K and 1M. In waves it grows: 10, 13, 20 (core) and 18, 34, 52 (turtle) |
| 3. The Number goes up | **FAIL** | Buying, the peak is a quarter to a fifth of today's: 141 against 527 (10K core), 242 against 584 (10K turtle), 409 against 2,354 and 560 against 2,747 at 100K |
| 4. No runaway | pass | No run reaches the cap. Neither plan opens Interest, so its half was checked separately (exploratory): maxed Interest on a 100K core build is 15% of income, under the cap and with no change in waves |
| 5. The pace holds | pass | Buying reaches today's waves: 0% at 10K and 100K core, 0% and −6% turtle. (At 1M, outside the criterion: core 0%, turtle −12%) |
| 6. The early game holds | pass | Fresh runs end on waves 4, 6 and 3 (buying nothing, evenly, core), none capped |

What it means:
1. **The swap is safe.** For the bots, buying with the Number is the same game as buying with Cash: the same waves, no runaway, Interest bounded by its cap. Nothing else measured here argues against playing it.
2. **The owner's arc ("strong enough not to need upgrades") doesn't arrive through Coins in Tier 1,** at least by 1M Coins: run upgrades add more waves the stronger the build, because they stack on Workshop levels. It would need something that lets Workshop power outgrow the run shop (Labs, or run prices that rise with the tier), which is a design choice for the owner.
3. **There is a fork instead: go far, or go big.** With the shop shut the Number climbs higher than today's at 10K (543 against 527 core, 744 against 584 turtle) while the run ends 10 to 18 waves sooner; buying goes further with a much smaller Number. If a run's reward followed its peak Number (11.6's Coins from the peak), "upgrades off" would be a real strategy rather than a handicap.
4. **A fresh tower's Number now climbs from its kills:** buying nothing, its peak is 29 against today's 6.
5. **The bots' reserve changes the peak, not the verdicts** (exploratory, 0.25 and 0.75: peaks 103 to 255 at 10K core, every verdict the same).

These are bots spending by a fixed rule. A player banks, spends in bursts and reads the Number; **the owner's play is the test that matters**, and the Testing switches exist for it.

### 13.4 The enemies under the Number as Cash (5 October 2026)

The owner played it ("way better … I need to sort this friction out so I can keep climbing"; early on "feels a bit harder than the tower does, but that's fine") and asked for the enemies to be checked, since the main mechanic has changed. Measured with `sim_runs.gd --json-out` on the harness's seeds (fresh `even`, 20 seeds; core, turtle and blender at 10K, 100K and 1M Coins, 6 seeds), each buying with the Number (bots keeping half their best), with the shop shut, and as today's game. New counters (`paid_by`, `locked_out`) record what each kind's kills paid and the Cash a standing Lock kept out.

**Overall difficulty is unchanged:** buying, every cell ends on today's median wave or within a few (13.3). What changed is which enemy matters, and why:

| Share of the Number lost, median run's build totals | Today's game | Buying with the Number | Shop shut |
|---|---|---|---|
| **Dividers**, 10K (core / turtle / blender) | 26% / 48% / 34% | 2% / 7% / 3% | 30% / 47% / 26% |
| **Dividers**, 100K | 39% / 85% / 34% | 0% / 0% / 3% | 42% / 80% / 48% |
| **Dividers**, 1M | 42% / 92% / 44% | 6% / 0% / 5% | 41% / 96% / 30% |
| **Ranged**, 10K | 37% / 10% / 32% | 57% / 22% / 56% | 4% / 5% / 5% |
| **Ranged**, 1M | 52% / 2% / 52% | 93% / 19% / 95% | 22% / 1% / 50% |

1. **Dividers now punish banking, not playing.** A ÷ takes a share of the Number, and a player who spends keeps the Number low, so for them Dividers all but vanish (0 to 7% of losses, against 26 to 92% today). With the shop shut, banking, they take as much as ever (up to 96%). That is the risk the owner wants on a big Number, and it arrives on its own.
2. **The Lock has become an income thief.** It holds the Number (D133), and with the Number as Cash that means every kill's Cash and every wave's pay while it stands is lost. Builds that kill it fast lose about 5% of their income; the turtle, which kills slowly, loses **36% at 100K and 58% at 1M** (a Lock held in range for half an hour of a run). In today's game it only held growth. **This is the one enemy that is out of balance.**
3. **Ranged enemies are the wall for every build that buys.** They were already the main killer in today's game; with Dividers fading they take most of what's lost (57% at 10K core, 93 to 95% at 1M) and end most runs. Not a new problem, but now the clearest one: Range and Defense answer it.
4. **Basics, fast enemies, tanks and bosses pay well:** buying, their kills pay 2 to 44 times what they take. Tanks, which rarely land a hit, bring in an eighth to over a quarter of a run's income.
5. **The early game:** a fresh tower loses to the same enemies as today (basics 84% of losses against 78%) and ends on the same wave (6). The owner's sense that it's harder fits what the bots can't feel: every early purchase lowers the Number a hit takes from.

**Proposal for the Lock (the owner's call):** while a Lock stands, the Cash it blocks is held on it, and killing it pays the lot into the Number. Holding stays a threat, a slow-killing build still waits for its income, and killing the Lock becomes a payday rather than just relief. Built as a measuring option first and checked against the turtle's 36% and 58%.

### 13.5 The Lock holds the Cash it blocks (5 October 2026, D157)

The owner agreed to the proposal in 13.4 ("ye"): while a Lock stands, the Cash it blocks is held, and killing it pays all of it into the Number. **Built as the option `lock_holds_cash` (off by default, recorded only while on) before it was measured**, and **on whenever the Testing switch Number is Cash is on**, so the owner plays it. A Lock's own kill now also ends the hold before its own Cash is paid (until now the flag from the tick before still read "locked", so a Lock's own Cash was lost to itself). The held pool is the run's, not one Lock's: with two Locks it is paid when the last falls.

**Pass criteria, written before the first measurement of the option** (the same cells and seeds as 13.4: core, turtle and blender at 10K, 100K and 1M Coins, 6 seeds, buying with the Number, bots keeping half in reserve; each against the same cell without the option):
1. **The income comes back.** At 100K and 1M Coins, the share of income still lost to Locks at a run's end (held at the end ÷ income paid plus that) is at most 10% in every cell, against 36% and 58% for the turtle without it.
2. **The pace holds.** Every cell's median wave is within 10% of the same cell without the option.
3. **No runaway.** No run reaches the 3-hour cap, and no cell's median peak Number is more than double that of the same cell without it.
4. **Nothing changes where nothing was blocked.** A cell whose runs were never locked plays identically with the option on (same waves, same peaks).

The rules of 10.4 and 12.5 apply: every cell reported, no seed chosen, criteria not changed after results. A pass means the numbers hold; **the owner's play is the test.**

**Results (5 October 2026), on the committed option:** `lock_holds_cash` against the same cells without it. **Overall: FAIL on criterion 1, for the turtle only; criteria 2, 3 and 4 pass.**

| Cell (buying with the Number) | Median wave, without → with | Peak Number, without → with | Income still lost to Locks at the end, without → with |
|---|---|---|---|
| core 10K / 100K / 1M | 31 / 51 / 81, no change | 1.00× | 0% / 5.4% / 12.6% → 0% / 0% / 2.5% |
| blender 10K / 100K / 1M | 31 / 50 / 81, no change | 1.00× | 0% / 5.2% / 15.7% → 0% / 0% / 3.1% |
| **turtle 10K** | 41, no change | 1.04× | 5.0% → 0% |
| **turtle 100K** | 79 → 83 (+5%) | 1.24× | **36.0% → 19.5%** |
| **turtle 1M** | 142 → 150 (+6%) | 1.16× | **58.2% → 43.4%** |
| fresh `even` | 6, no change | 1.00× | no Lock came |

1. **C1 fails where a build can't kill a Lock.** Core and blender, which shoot, are down to 0 to 3%. The turtle still ends with 19.5% (100K) and 43.4% (1M) of its income held on a Lock that is still standing: at 1M a Lock stands for about 2,000 seconds of its run, and every run ends with 22,000 to 29,000 held. **Thorns don't hurt a Lock (D133)**, so the turtle's main damage (14.7M of its 20.9M at 1M) never touches it, and its shots (6.2M) are the only answer.
2. **C2, C3, C4 pass.** No cell moves more than 6% in waves, none reaches the cap, no peak is more than 1.24 times the unheld one, and the one cell that was never locked plays identically.
3. **What the option does for the turtle:** 5 to 6% more waves and 16 to 24% more peak Number than losing the income outright. It recovers about half of what was lost, and no more than the turtle can pay for in killing a Lock.
4. **The game is unchanged:** the quick balance comparison shows no movement (the option is off by default and needs the Number as Cash).

**For the owner:** the remaining loss is the turtle's, and it is the same fact that made Locks a Tier 1 wall in D133 and D144 (kill it or knock it back): a build with no shots can't answer one. I'd leave it, and **let Thorns' build feel it in play** before changing D133. If it feels bad, the narrow fix is to let Thorns hurt a standing Lock at a share of its strength, built as a measuring option first.

## 14. The Number is Cash becomes the game (5 October 2026, D158)

After playing D156 and D157 behind the Testing switch the owner said "way better … I need to sort this friction out so I can keep climbing", then "merged and proceed" to the agent's offer to make it the game. **From D158, every new run plays the Number as Cash, with a Lock that holds the Cash it blocks.** The measuring options keep their off defaults, so the tools can still play the old game for comparison.

### 14.1 The change snapshot (QUALITY_GATES, high risk: economy, purchasing and saves)

- **Current behaviour:** runs play Cash rules unless the Testing switch is on (D156, D157); Cash is the run's currency in the code, the screens, the cards and the docs.
- **Intended:** every new run plays Number as Cash and the held Lock. **Run upgrades off** becomes an ordinary setting, not a Testing one (the owner asked for "the option to completely switch them off before a run, but not during"). Cash is gone from the screens of a new run.
- **Directly affected:** `RunConfig.game_tuning` (the game's rule set, one authority), `Settings` (the Testing switch Number is Cash goes; Run upgrades off stays, as a setting), `main.gd`, Home's Settings sheet, the words on the Workshop, Cards and run-over screens, AGENTS.md law 4, the balance harness and its baselines, the capture tool, README, TOWER_RULES.
- **Adjacent:** saved battles and run reports (their rules), the settings file, the Coins and milestones (unchanged), `read_report.gd` and the activity log (they read a run's start config).
- **Must preserve:** a saved battle or report from before resumes and replays under the rules it began with; Workshop ranks, Coins, Gems and cards; determinism; the real save's protection.
- **Planned proof:** boundary and repeated-action tests; old-save, current-save, malformed and round-trip fixtures; a replay of a run in each rule set; the harness measuring the game's rules with re-recorded baselines; screenshots of Home, Settings and a battle; **an independent adversarial review of the final diff**.

### 14.2 What changes, and what doesn't

- **The game's rules live in one place:** `RunConfig.game_tuning()` returns the tuning a new run starts with (`number_cash`, `lock_holds_cash`, and `upgrades_off` while the setting is on). The code's own defaults stay off, so a run that starts without them (every existing save, report and test) plays exactly as before.
- **No combat-rules version bump, deliberately.** A start config records its tuning, and a saved battle or report from before D156 has none of the new keys, so it restores and replays as Cash rules, to the byte. A bump would have ended saved battles on update. It is tested, not assumed: a run started under each rule set round-trips and replays, and a snapshot without the keys resumes with the Cash chip and Cash words.
- **A resumed old run shows its own words.** A battle's screen follows its run's rules, so a Cash-rules battle saved before the update still reads "Cash" and "$", while Home, the Workshop and Cards read as the Number's.
- **Settings:** the file's old `number_cash` key (written while D156 was a Testing switch) is ignored and dropped on the next write; `upgrades_off` is kept and now sits among the ordinary settings.
- **Unchanged:** Coins and what they buy, the Workshop's ranks and prices, Gems and Cards, the milestone thresholds, the tiers, the enemies' stats. **But the Number milestones are reached later** (14.4). Cash's data rows keep The Tower's ids and values, shown under Number names (a presentation layer, since the generated data mirrors The Tower's table).

### 14.3 Measured under the game's rules (the harness, 5 October 2026)

The balance harness now plays the game's rules (BALANCE_TESTS.md) and both baselines are re-recorded on the committed code (source digest `ea78c9aa…`). Median waves and peak Numbers, today's rules against the game's, on the harness's seeds (the full suite):

| Scenario | Median wave | Median peak Number |
|---|---|---|
| fresh, buying nothing / evenly / core | 3 → 4 / 6 → 6 / 3 → 3 | 6 → 29 / 14 → 20 / 6 → 13 |
| 10K Coins: core / turtle / blender / spread | 31 → 31 / 41 → 42 / 31 → 31 / 31 → 31 | 527 → 137 / 584 → 252 / 576 → 149 / 389 → 173 |
| 100K Coins: core / turtle / blender / spread | 51 → 51 / 84 → 82 / 48 → 51 / 63 → 68 | 2,442 → 409 / 2,820 → 692 / 2,898 → 409 / 5,029 → 742 |
| career (core / grow / even) | 21 → 21 / 21 → 21 / 10 → 10 | 136 → 70 / 158 → 75 / 35 → 38 |
| Tier 2 / Tier 3 at level 20 | 18 → 18 / 18 → 17 | 4,504 → 499 / 11,392 → 561 |

**The pace is the same and the Number is a fifth to a quarter of its old size** (13.3). Under the game's rules **four of D149's six dead cards meet the floor**: Extra Defense, Free Upgrades, Range and Health (by a single wave, in one build), because every point of defence now protects the Number a purchase just lowered. **Critical Chance and Health Regen still fail.** (The harness still lists all six as its documented known failures; it labels one only when it fails.)

### 14.4 What the owner hasn't decided, and this doesn't do

- **The Number milestones pay less, because spending keeps the peak Number low (found by the independent review, then measured).** The digits (10, 100, 1,000 … 1,000,000) pay Coins once, when the run's best Number first reaches them (D125, D131), and the Number as Cash holds a buying run's peak at a fifth to a quarter of today's (13.3). From the 13.3 medians: at 10K Coins nothing changes (60 Coins of digits either way); at 100K a core build's digits pay **60 instead of 310** and a turtle's the same; at 1M **310 instead of 2,810**, against a 1M core run's own Coins of about 910 (a run's Number earned is 11,000, which an earlier version of this sentence took for Coins; re-measured 6 October, 6 seeds) and a turtle's of about 2,450, so the digits go from about three runs' Coins to about a third of one for a core build. The best Number the Home screen shows is also smaller. **The owner's call**; I'd keep the record as the true peak and **recalibrate the digit ladder to the new scale** (11.15 already planned this), measured, not guessed.
- **Recovery Packages refill spending too.** A package heals a share of Workshop Health, up to its Max Recovery, and the Number's ceiling rises with it, so after a purchase it can give some of it back. Bounded by `max_health × max_recovery` and Packages open at 1.5M Coins, so I left it; **if the owner wants D156's "only what enemies took" to hold for them too, a package should not raise the ceiling.**
- **A Lock still standing when a run ends takes its held Cash with it** (the run-over panel now says how much).

- **Coins from the peak Number (11.6)** and the digit ladder (11.15): not built; Coins are earned as now.
- **A way for Workshop power to outgrow the run shop** (13.3's finding): not built.
- **The turtle and the Lock** (13.5): left for play.
- **Tier 2 and 3** are not measured under the new rules.

## 15. Coins from the peak Number: what the peak is made of (6 October 2026)

The owner answered **yes** to both open questions of 14.4: keep the record as the true peak and recalibrate the digit ladder, and let a run's reward follow its peak Number. Before writing the experiment's criteria the agent measured what the peak is made of in today's game (the committed full baseline, `data/balance/full.json`, each run's `peak_number` and the part of it raised in play), because the whole design leans on it.

**The finding: for most strong builds the peak Number is the Number the run starts with, which is the Workshop's Health row, not anything done in the run.** Spending lowers the Number and kills only refill it, so a buying run rarely climbs above where it began.

| Cell (game's rules, buying) | Median peak | Raised in play | Share of the peak that play built |
|---|---|---|---|
| fresh, buying nothing / evenly / core | 29 / 20 / 13 | 24 / 16 / 8 | 83% / 79% / 67% |
| 10K Coins: core / turtle / spread | 133 / 252 / 171 | 67 / 281 / 154 | 52% / 106% / 88% |
| **100K Coins: core / blender** | **409 / 409** | **0 / 6** | **0% / 1%** |
| 100K Coins: turtle / spread | 688 / 718 | 1,300 / 681 | 184% / 92% |
| Tier 2 / Tier 3 at level 20 | 493 / 503 | 165 / 180 | 33% / 35% |
| **1M Coins, core, 6 seeds (`sim_runs.gd`)** | **2,763.5, every seed** | none | **0%** |

A 1M-Coin core run's peak is the same 2,763.5 on every seed: it is the Health row's Number, reached on wave 1 and never beaten. Its run earned 11,000 to 12,000 Number over 81 waves and spent it all.

**What that means for the plan:**
1. **A reward that follows the peak pays for the Health row, not for play,** for core and blender builds from about 100K Coins up. Only builds that keep the Number growing (Thorns turtle, spread) or weak and fresh runs get a peak that play moved.
2. **The record is the same:** the best Number on Home is, for those builds, their Health row. That is a fair description of the Number as the tower's health, but it is not "how well you played".
3. **The digit ladder has the same problem.** A 1M-Coin core build tops out at 2,763 and so reaches digit 1,000 and never 10,000; the top three digits (10K, 100K, 1M) are out of reach in Tier 1 for a spender whatever the rewards are. Recalibrating their Coins changes nothing for them.
4. **What does move with play is the Number earned,** every point paid into the Number by kills, waves and Interest, whatever it is then spent on: 11,000+ for that 1M run, 4,000 for a 100K core run, 1,500 at 10K. Spending doesn't lower it, so a spender and a hoarder are measured alike, and it grows with the waves reached.

**The question this raised, answered (6 October):** the owner chose to pay the reward from the Number *earned* rather than the peak, keeping the record as the true peak. The experiment's design and criteria are section 16.


## 16. Coins from the Number earned (6 October 2026, D162)

**The owner's direction:** after section 15, "yeah go with earned, write the criteria". A run's Coin reward follows the **Number earned** in the run, not its peak, and the record stays the true peak. **This section is the experiment's design and its pass criteria, written before any option is built or measured.** Nothing is built. The digit ladder (11.15, 14.4) is a second stage with its own criteria, written after this stage's results, because what a digit should pay depends on what a run's Coins are by then.

### 16.1 What today's game already does (measured 6 October, the game's rules, buying `core` in the run, reserve 0.5, 6 seeds, core Workshop plan)

| Budget | Buying: wave / Number earned / Coins | Coins per Number earned | Run upgrades off: wave / earned / Coins | Coins per earned |
|---|---|---|---|---|
| 10K | 31 / 1,455 / 178 | 0.123 | 20.5 / 621 / 92 | 0.148 |
| 100K | 51 / 3,951 / 421 | 0.106 | 36.5 / 1,893 / 219 | 0.116 |
| 1M | 81 / 11,229 / 915 | 0.081 | 61 / 5,772 / 578 | 0.100 |

Turtle at 1M (4 seeds, buying): wave 150 every seed, about 36,800 earned, about 2,460 Coins (0.067 per earned). The harness's medians say the same shape: 0.07 to 0.15 Coins per Number earned for core, turtle and spread at 10K and 100K, and 0.16 to 0.19 for Tier 2 and 3 at level 20 (their Coin bonus is 1.8 and 2.6, and the tier's enemies hit ×20 and ×60).

**Prediction, written before measuring:** because Coins per Number earned is already stable to within a factor of two across builds, budgets and rules, a reward that follows the Number earned will move a run's Coins by tens of percent, not by multiples. Its value is **structural** (the Coin economy becomes a share of the Number's income, so a tier's scale arrives through the Number and the Coin bonus, and "pushing the Number" pays), **not a change of pace.** I expect E1, E3, E4 and E7 to pass; **E5 (the Coin rows still matter) is the one most likely to fail**, at the largest share.

### 16.2 The definitions

- **Number earned, `E`:** the run's `cash_earned`: every point paid into the Number by kills, wave ends and Interest, when it lands (a Lock's held share counts when it is paid out). Not Regen, Lifesteal or Recovery Packages, which only refill what enemies took. **Spending doesn't lower it.**
- **Tier-normalised earned, `E_n = E / (the tier's enemy Attack multiplier)`:** 1 in Tier 1, 20 in Tier 2, 60 in Tier 3. Without it a Tier 2 run would earn twenty times the Coins; with it the tier's Coin bonus (`TowerData.tier(n).coins`) keeps its meaning.
- **The reward rule:** a run's Coins are `(1 − s) × ordinary Coins + s × K × coin_bonus × E_n^p`, where ordinary Coins are what kills and waves pay today (with the Workshop's Coin rows), `coin_bonus` is the tier's Coin bonus times the run's Coin multiplier (cards, Labs), `s` is the share that follows the Number, `p` the power and `K` a constant fixed by the rule below. The earned part is paid as `E` rises (the increase in `E_n^p` since the last payment, at each wave's end and when the run ends), so it banks like today's Coins and a saved run resumes the same.
- **Calibration rule (declared now, never retuned after results):** `K = 420.5 / 3,950.5^p`, so that at the reference cell (core Workshop plan, 100K Coins, buying, Tier 1) the earned part pays exactly `s` times the 421 Coins that cell earns today. One cell sets `K`; every other cell tests the shape.

### 16.3 The options

All off by default, in the style of D155 to D157: BattleSim fields `earned_share` (`s`), `earned_power` (`p`) and `earned_scale` (`K`); recorded in a run's start config only while on (`RunConfig.trial_tuning`, validated by `valid_tuning`); the earned part's running total saved in a snapshot only while on; flags in `sim_runs.gd`; the criteria as code in `tools/earned_trial.py` (the pattern of `cash_trial.py`) with a test that each criterion fails at its boundary and that a criterion whose runs weren't played reads "not run", never a pass. A run made without them is byte for byte what it was; **the quick balance comparison showing no movement is the proof.**

### 16.4 The cells

Bots playing the game's rules (`--number-cash --lock-holds-cash --reserve 0.5`), buying `core` in the run, and each cell again with run upgrades off. Seeds 1 to 6 (1 to 4 for turtle at 1M Coins, which runs 87 minutes of game time), no seed chosen. Each is also played as a control, the same cell with the options off.

- **Workshop cells:** the core and turtle plans at 10K, 100K and 1M Coins.
- **Tier cells:** Tier 2 and Tier 3 with every row at level 20 (the harness's cells).
- **Fresh runs:** 20 seeds, buying nothing, evenly and core, 10-minute cap.
- **Careers:** `--careers` from a fresh Workshop, the `core` and `grow` policies (`grow` also buys Coins income), as the harness's career cells.

### 16.5 The pass criteria

**Configurations, all reported:** `s` in {0.25, 0.5, 1.0} and `p` in {0.8, 1.0}, six in all. (`s` = 1.0 is the bound where the Workshop's Coin rows pay nothing; it is expected to fail E5 and is measured to say so.) A configuration passes when every criterion below holds.

1. **E1. The Workshop's pace holds.** Buying, every core and turtle cell at 10K, 100K and 1M Coins has a median Coins per run within 25% of its control's. *Why: Coins are how the Workshop grows, so the reward must not speed it up or slow it by more than a quarter, whatever it follows.*
2. **E2. Coins follow the Number earned, however it is spent.** For each plan and budget, Coins per Number earned buying and with run upgrades off are within 10% of each other (today they differ by 9% to 23%). *Why: the point of the change is that a run that spends and one that doesn't are paid by the same measure.*
3. **E3. Run upgrades off stays a real option, not a handicap and not dominant.** For each plan and budget, off-runs' Coins per game-minute are between 70% and 130% of buying runs' (today 72% to 84%). *Why: the owner's switch should be a way to play.*
4. **E4. Tiers keep their meaning.** Tier 2 and Tier 3 at level 20 have a median Coins per run within 30% of their controls'. *Why: the tier Coin bonuses (1.8, 2.6 and on) are The Tower's sizing of income against the tiers.*
5. **E5. The Workshop's Coin rows still matter.** In the careers, `grow` earns at least 25% more Coins over its runs than `core` (it earns about 75% more today). *Why: a share that follows the Number must leave Coins / Kill and Coins / Wave worth buying.*
6. **E6. The early game holds.** Each fresh policy's median Coins is within 50% of its control's, or within 2 Coins, whichever is larger; none is zero. *Why: the first runs fund the Workshop's first rows.*
7. **E7. No runaway.** In every cell no run's Coins exceed 1.5 times its control's median, and Interest (already capped) supplies at most a quarter of the Number earned. *Why: the reward is a function of income, so a cap bypass would show here.*

**The rules of 10.4, 12.5 and 13.2 apply:** every configuration is reported whether it passes or not, no seed is chosen, the criteria and the calibration rule are not changed after results are seen, a run outside the declared grid is labelled exploratory and never counts as a pass, and a pass means the numbers hold, not that it is fun. **The owner playing it is the real test.** A failure is a finding: it is written up with a proposal and the owner decides.

### 16.6 What this stage proves, and what it leaves

- **Proves, if it passes:** a Coin reward that follows the Number earned keeps the Workshop's pace, the tiers' sizing and the Coin rows' worth, and treats spenders and hoarders alike. It does not prove it is more fun.
- **Compatibility, to be shown when it is built:** options off leave every existing run, snapshot, report and baseline unchanged; a run begun under them saves and resumes with the earned part intact, and a snapshot carries that state if and only if the run's rules say so (the D156 tests are the pattern).
- **Making it the game is its own change** (QUALITY_GATES): `RunConfig.game_tuning()` gains the option, the run-over and Home text say what a run's Coins followed, and **an independent adversarial review of the final diff** is required (economy, saves).
- **Not in this stage:** the digit ladder and its unreachable top digits (stage 2); how the Workshop's power outgrows the run shop; the Labs that GROWTH_LAYERS.md proposes.

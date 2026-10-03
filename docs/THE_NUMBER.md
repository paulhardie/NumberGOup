# The Number: design considerations

**Status:** the direction is decided (D080), its four decisions are answered (D081, section 6), and the enemy design is answered and built (D082, section 7): the Number in the centre, and the Divider. Since then the owner removed the Number's ceiling and made Tier 1's Divider gentle (D083: ÷1.25, then ÷1.5). What's left for 1.0 is the owner playing it. Section 9 (2 October 2026) reopens what the Number *is*: it is measurably a health pool. Section 10 (3 October 2026) is the owner's answer (D152): the Number is the player's capital, tried as a measure-only candidate against criteria written down first. This page is the working list of everything that changes now that the tower *is* a number; the owner's answers go into [`DECISIONS.md`](DECISIONS.md), and this page is updated to match.

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
| Tank | A big square | Wide, heavy and glowing (D144), and it **loses weight as it's shot**: its cut thins from the heaviest weight towards a light one, and its mass falls with its health, never below a basic's, so Knockback moves a worn tank further |
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

**Status:** the owner's direction, being tried. Nothing here is in the game. The candidate in 10.3 is a set of measuring options, off by default, and 10.4 was written before the candidate existed, so the results can't be graded afterwards.

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

**Limits known now:** bots, not players. The budget scenarios have 4 seeds, so a 2-wave bar is above most of their noise but not all. The Lab's cost isn't modelled: `r_max` at 100K assumes the Lab is already paid for. Lifesteal, Tier 2 and Tier 3, and the screen (the thief drawn carrying its bite, the Taken / Recovered line) are not measured.

### 10.5 Results

**Interim, 3 October 2026: the trial is under way, so this is partial and not a verdict.** Only the build phase has run so far (criteria 1, 2 and 6, and the peak half of 4). The career, the fresh runs and the card sweeps (3, the rest of 4, and 5) have not.

The centre of the grid (`number_power` 0.2, speed 1, fade 0, priority on, `r_base` 0.5, `r_max` 1.5) and each single variation of it, build phase only. That is 8 of the grid's 96 configurations, all of which fail criteria 2 and 6.

| Configuration | C1 (the Number decides) | C2 (waves thieves cost: core 10K, turtle 10K; core 100K, turtle 100K) | C6 (median thefts a run: core, turtle) |
|---|---|---|---|
| Centre | pass | **fail:** 0, 4; 0, −4 | **fail:** 1, 2 |
| `number_power` 0.1 | pass | **fail:** 0, 4; 3, −6 | **fail:** 2, 5 |
| `number_power` 0.3 | pass | **fail:** 0, 1; 0, 0 | **fail:** 0, 0 |
| speed 2 | pass | **fail:** 0, 4; 0, −4 | **fail:** 1, 2 |
| fade 600 s | pass | **fail:** 0, 4; 0, −5 | **fail:** 1, 2 |
| priority off | pass | **fail:** 0, 4; 0, 1 | **fail:** 1, 2, and 0.87 recovered on the turtle at 100K (needs 0.9) |
| `r_base` 0.25 | pass | **fail:** 0, 4; 0, −4 | **fail:** 1, 2 |
| `r_max` 1.0 | pass | **fail:** 0, 4; 0, 0 | **fail:** 1, 2 |

C2 needs 2 or more at 10K and 1 or less at 100K, for both builds. C6 needs at least 3 thefts. Criterion 1 passes everywhere because of the power coupling: removing it costs the four builds 20, 10, 30 and 19 waves at 0.2 (10, 5, 14 and 10 at 0.1, and 40, 22, 50 and 36 at 0.3). Removing recovery costs only the turtle at 100K, 10 to 15 waves, and nothing elsewhere.

What it shows so far:
- **The power coupling is a very strong lever, even at the smallest value on the grid.** At 0.2 the core build at 10K Coins goes from wave 31 to wave 51. Whether that is too much is criterion 4, not yet reported.
- **Thieves are rare for a competent build, and that is why criteria 2 and 6 fail.** The core build sees at most 2 a run (at the lowest power), because nearly every Divider is killed before it lands (about 20 come, 0 to 2 land). Theft count depends on how fast the tower kills Dividers, which only the power changes, and a stronger power means fewer thefts. Nothing else on the grid (recovery, speed, fade, priority) should change how many land, so by that reasoning no combination of them reaches 3; the combination check below tests it.
- **A recovery over 1 turns a thief into a gift.** On the turtle at 100K, the run with thieves reaches up to 6 more waves than the run with no Dividers at all. That is the intended hit, but it also means the player wants to be robbed.
- **Recovery only matters on the turtle at 100K.** There the carriers are caught, and taking recovery away costs 10 to 15 waves.

Still to report before a verdict: the career, fresh runs and card sweeps for the centre and the lowest power, a check of every combination at the lowest power on the core build, and exploratory runs with more Dividers. Anything outside the declared grid will be labelled exploratory and can't count as a pass.

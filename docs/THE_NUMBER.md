# The Number: design considerations

**Status:** the direction is decided (D080), its four decisions are answered (D081, section 6), and the enemy design is answered and built (D082, section 7): the Number in the centre, and the Divider. Since then the owner removed the Number's ceiling and made Tier 1's Divider gentle (D083: ÷1.25, then ÷1.5). What's left for 1.0 is the owner playing it. This page is the working list of everything that changes now that the tower *is* a number; the owner's answers go into [`DECISIONS.md`](DECISIONS.md), and this page is updated to match.

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

- **4.1 The Number sits in the middle, in place of the hexagon,** big, in Geist Mono, whole and rounded up.
  - Its size must fit from "5" to "1.23M" without jumping about. The suffixes start at 1,000 as they do now; the full digits up to 99,999 may read better in the centre. To be decided on a screenshot.
- **4.2 Health (the ceiling) shows small beneath it,** or as a ring around it that empties. **Recommend a ring:** it reads at a glance without a second big number.
- **4.3 Every contact shows its operator** as floating text at the Number: "−3", "÷2", "−10%". A ÷ gets the biggest moment (a flash and a short shake), because it's the identity beat. Reduced motion turns the shake off.
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
- **The Number goes up over a run.** In a run that buys sensibly, the median Number at each wave's end rises across the run: wave 20 higher than wave 10, higher than wave 5. This is measurable from the report's wave snapshots, which already record Health.
- **Divide moments are events, not noise.** Roughly one ÷ contact a minute in Tier 1's middle waves (tunable), each visible and survivable in a sensible build.
- **Operators kill honestly.** A ÷ never ends a run alone (by design). Flat hits end most runs, as in The Tower. What ended each run is recorded and counted.
- **No row becomes useless (D001's test).** For each operator, buying more Health or Defense must still lengthen runs. Measure the waves gained per 1,000 Coins on each Defense row with and without operators.
- **No row becomes compulsory.** Orbs and the like help against operators, but a run without them still reaches the same benchmark waves.

**5.3 Tools.** Nothing ships on feel alone.
- `tools/sim_runs.gd` gains columns for the peak Number, the Number by wave, losses by operator and deaths by cause.
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
| **When** | Not before wave 5; about 3% of a wave there, rising to about 6% by wave 30 | Roughly one every 3 waves at first, about one a minute by the middle waves (THE_NUMBER.md 5.2). Wave 5 is after a fresh player has learnt the basics |
| **Pay** | Cash as a fast enemy (2×) and 2 Coins | Worth killing first. It pays only if killed, since a used-up one pays nothing |
| **Heat-up, Thorns** | None (used up on contact) | Rules 2.4 and 2.5 |
| **Knockback, Shockwave, Orbs, Mines** | Work on it like any non-boss | These become the ways to stop it |
| **The Wall** | Breaks on it: the Wall loses half its health instead of the Number | Rule 3 |

The numbers to tune are its share by wave, its health and the divisor. **Tune share first, then health, then divisor last:** ÷2 is the identity, so it moves only if the other two can't balance it.

**How we'll know it's balanced** (5.2's targets, applied to the Divider):
- The Tier 1 benchmarks still hold: buy nothing and die on waves 2–5, spread your Cash and die around wave 8.
- A Divider reaches the Number about once a minute in middle waves, not more.
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

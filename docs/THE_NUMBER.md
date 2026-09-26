# The Number: design considerations

**Status:** open. This is the owner's direction of 26 September 2026 (D080), and the working list of everything that changes now that the tower *is* a number. Nothing here is built. Each question has a recommendation; the owner's answers go into [`DECISIONS.md`](DECISIONS.md), and this page is updated to match.

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
- **Decision 1.**

**1.3 Is the Number ever spent?** The old vision made it "score, health and ammunition at once". **Recommend no:** Cash stays the run's currency, as now. Spending the Number would bring back D037's tangle, where every choice trades survival for power.

**1.4 What is the score?** **Recommend:** keep the best wave as the record, and add the run's **peak Number**, shown on the run-over screen and kept as a best on Home. Option A's idea survives as a record, not as the centrepiece.

**1.5 Whole numbers or decimals?** The Tower's Health has decimals (5.00 at the start; regen 0.04 a second). **Recommend:** keep full precision in the simulation, and show whole numbers, rounded up, so a standing tower never reads 0 (today's rule). Death stays at ≤ 0 exactly.

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

**2.9 How big is the divisor?** ÷2 is legible and dramatic. **Recommend** starting at ÷2 and tuning by how often they come, not by odd divisors like ÷1.37. If a softer step is needed, ÷1.5 reads fine.

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

## 6. Decisions for the owner

1. **Does the Number have a ceiling?** Recommend: yes in Tier 1, The Tower's Health (1.2).
2. **Which operators?** Recommend: subtract and divide; percent of Health rare or not at all (2.1).
3. **New operator enemies on top of The Tower's, or converting its types?** Recommend: new ones on top, a small share from wave 3 (2.6).
4. **Rename Health to Number?** Recommend: yes, Health → Number and Health Regen → Number Regen, since this is the identity (3).

Also recommended, and taken as agreed unless the owner says otherwise:
- operator enemies are used up on contact (2.4);
- one defence pipeline for every hit (2.3);
- heat-up applies to flat hits only (2.5);
- bosses and ranged enemies stay flat in Tier 1 (2.7, 2.8);
- ÷2 as the divisor (2.9);
- nearest-first targeting for 1.0 (2.11);
- the Number isn't spent (1.3);
- peak Number as a record (1.4);
- whole numbers shown, rounded up (1.5);
- scale 1:1 (1.6).

# What each of The Tower's tiers asks you to solve

The owner asked what each Tier of The Tower needs before a player can "solve" it (reach wave 100, which opens the next tier): its build, labs, cards, Ultimate Weapons and base stats. They also asked what that means for our Tier 2 and beyond (roadmap 1.4). This page gathers the community's account, with sources, and sets our simulations beside it. It is research, not a decision.

**Sources** (read 2 October 2026):
- [Tier-Specific Guide](https://the-tower-idle-tower-defense.fandom.com/wiki/Tier-Specific_Guide) and [Tiers](https://the-tower-idle-tower-defense.fandom.com/wiki/Tiers), the community wiki;
- [Milestones](https://www.tower-hub.com/wiki/guide/milestones), Tower Hub;
- [The Tower best Workshop builds](https://mmoculture.com/tips-guides/the-tower-best-workshop-builds/), MMO Culture;
- the wiki's [Beginner Guide](https://the-tower-idle-tower-defense.fandom.com/wiki/Beginner_Guide).

The guide is one experienced player's write-up, several of its tier sections are empty, and the sources disagree on a few unlock waves (noted below). Treat it as a strong reading, not the game's code.

## The shape: each tier breaks the last tier's answer

**Tiers:**
- Tier N+1 opens at wave 100 of Tier N; from Tier 16 it takes wave 300.
- Tier 2 is about 20× harder than Tier 1 and pays 1.8× the Coins. The Coin bonus climbs to 103× at Tier 24.
- Enemy health and attack multiply by tier (our data: Tier 2 ×20, Tier 3 ×60).

**The pattern the guides describe: a tier is solved by a mechanic that doesn't scale with enemy stats, until a later tier takes that mechanic away.**

| Stage | What breaks the previous answer | What solves it |
|---|---|---|
| **Tier 1** | Nothing yet | **Damage and Attack Speed** first. Then the **Turtle**: Defense Absolute above enemy attack, plus Thorns at 5% or more, so it no longer matters which enemies spawn |
| **Tier 2** | Enemy attack ×20 outruns any Defense Absolute the player can afford, so the Turtle breaks by design | **Blender**: Knockback holds normal enemies at the range's edge, Orbs sit at that edge and kill them outright, and **Thorns plus the Plasma Cannon card** two-shot bosses (Plasma Cannon takes 54% of a boss's health). Set the Range lab to Orb range |
| **Tier 3** | Longer runs and bosses that hurt | **Perks** (open after Tier 2 wave 150): −50% damage taken (and dealt), +5% Defense ×5, earlier perks. With 99% Thorns, survive two hits from each boss |
| **Tier 3–4** | Vampires (immune to Thorns, stop Regen and Lifesteal) in long runs | **Garlic Thorns** lab (Tier 2 wave 1,000); **Death Wave** labs at Tier 3 wave 250 (Max Health ×12.5) |
| **Tiers 5–6** | Coin pace | **Black Hole** coin and damage labs (Tier 5 wave 150): ×11 Coins, or a permanent Black Hole that holds every enemy off the tower (perma-stall) |
| **Tier 7** | DPS | Ultimate Weapon power spikes (Chain Lightning and the others) |
| **Tier 10** | Vampires again, in very long runs | **Wall Regen** (300% of the tower's Regen, which Vampires can't stop) and **Wall Thorns** labs at wave 70. Defensive builds now farm far |
| **Tier 11** | Enemy scaling itself | **Enemy Level Skip** labs at wave 200, "the single most important upgrade in the game". Runs of 10,000+ waves and 14+ cards (Wave Accelerator, Wave Skip, Energy Shield and others) |
| **Tier 14+** | **Battle conditions** take the answers away, tier by tier | Resistances to Orbs, Death Ray, Thorns and Plasma Cannon (down to 5% damage), more bosses, Knockback resistance, armoured enemies, then each enemy's "ultimate". Each needs a new answer (modules, Ultimate Weapons, raw DPS) |
| **Wave 4,500+** | Overheat | Skip decay and more fleets from wave 10,000–15,000, to end very long runs |

**What a player has by when** (Tower Hub's milestones; the guide differs where noted):
- **Tier 1:**
  - Cards at wave 20 and Labs at 30;
  - Tournaments at 60 and Events at 70;
  - Modules at 100;
  - Perks at 150 (the guide says Tier 2 wave 150).
- **Tier 2:**
  - Guilds at wave 10 and the buy multiplier at 30;
  - Workshop discounts at 40–60;
  - Interest at 80–90;
  - Lab Speed at 200 (the guide says Tier 1 wave 150);
  - Card presets at 250.
- **Tier 3 wave 200:** first perk choice.
- **Tier 4:** Workshop respec at wave 30, auto-pick perks at 50.
- **Tier 10 wave 10:** the Nuke card.
- **Tier 13 wave 50:** Ultimate Crit.

## Our game against it (simulated 2 October 2026)

All `sim_runs.gd`, seeds as stated, `--buy core` unless "none". Our Tier 2 is The Tower's as TheTowerSDK and the wiki give it:
- enemy health and attack ×20;
- Coins ×1.8;
- enemies ×1.04 faster;
- Protectors from wave 80;
- elites from wave 450 (D107, D115).

| Build | Tier 1 | Tier 2 |
|---|---|---|
| Every Workshop row at level 12 | wave ~105–111 (12 seeds) | **wave 20** (11–21; 5 seeds), killed by bosses and the crowd |
| Every row at level 20 | — | **wave 61** (3 seeds), all at the wave-60 boss |
| Every row at level 30 | — | **alive at 4 h, wave 412** (3 seeds) |
| Every row at level 45 | — | alive at 4 h, wave 412 |
| Fully maxed Workshop | **alive at 10 h, wave 1,029**; no Divider landed (510 came) | **alive at 10 h, wave 1,029**, earning 1.83× Tier 1's Coins |

- **Run on to 25 game hours** (1 seed each, `--cap-minutes 1500`): both maxed runs are still alive on **wave 2,572**. None of 1,281 Dividers landed. Tier 2 earned 1.14M Coins against Tier 1's 622K (1.84×).
- Runs to the generated wave-6,500 horizon didn't finish within the 2-hour time limit for a background job, so whether anything ends a maxed run before then is unknown.

**What it shows:**
- **The 20× jump lands as The Tower intends:** a Workshop that clears Tier 1 to wave ~110 dies around Tier 2's wave 20, so a player can't carry straight on.
- **But the band from "dies at a boss wave" to "never dies" is narrow.** Every row at level 20 dies at Tier 2's wave 60; at level 30 it lives for hours. With no Perks, Labs, Ultimate Weapons or battle conditions yet, nothing in our Tier 2 asks for a *different* build. It asks for *more* of the same stats.
- **A maxed Workshop is untouchable in both tiers** for at least 10 hours of play. The Tower keeps it honest with more tiers, Overheat and battle conditions; we have three tiers of data.

**The same Coins, three ways** (`--workshop-coins 1000000 --workshop-plan <plan>`, 3 seeds, Tier 2; core in Tier 1 for reference):

| Plan (what 1M Coins bought) | Tier 1 | Tier 2 |
|---|---|---|
| **Core**: Damage 46, Attack Speed 39, Health 47, Regen 47, Defense Absolute 46 | wave 81 (78–82) | **wave 21**, killed by the crowd |
| **Blender**: Health 50, Damage 37, Attack Speed 31, Regen 37, Defense Absolute 37, Lifesteal 33, Knockback 32/31, **1 orb**, Orb Speed 22 | — | **wave 21** (20–21) |
| **Turtle**: Defense Absolute 55, Thorns 47, Defense % 31, Damage 33, Attack Speed 28, Health 34, Regen 34, Cash / Wave 29 | — | **wave 36**, 2.1× the core build's Coins |

- **This misses D149.** The owner decided tiers keep The Tower's shape: the turtle best in Tier 1, and a pivot to the blender for Tier 2. Our Tier 2 doesn't deliver the second half yet.
- **Our Tier 2 rewards the opposite of The Tower's.** The Turtle, which The Tower's Tier 2 is built to break, goes furthest. The Blender, The Tower's answer, does no better than plain stats.
- **Likely reasons** (inferred, not traced):
  - At this budget the Blender buys a single slow orb. The Tower's Blender leans on several orbs, the Range lab set to Orb range, and the Plasma Cannon card for bosses, none of which we have.
  - Our Thorns and Defense % carry the Turtle further than The Tower's would.

## The Tier 2 pivot test (3 October 2026)

Can a blender beat the turtle in our Tier 2, the shape D149 asks for? And is the boss what holds the blender back? Every line is Tier 2, 5 seeds, `--buy core`, `--cap-minutes 240`, Workshop built by `--workshop-coins N --workshop-plan P`.

**The builds:**
- `blender_thorns`, added for this test, is the wiki's "Blender Thorns" build. The plain `blender` plan opens Thorns but buys none.
- Factor (a boss arrives with ×0.70, or at level 7 ×0.46, of its health) stands in for The Tower's Plasma Cannon.

Median wave (range):

| Plan | Coins | No card | Factor 1 | Factor 7 | Kills by shots / Thorns / orbs |
|---|---|---|---|---|---|
| **Turtle** | 1M | **36** (35–36) | 36 | 36 | 76% / 24% / — |
| Blender | 1M | 21 (20–21) | 21 | 21 | 94% / — / 6% |
| Blender Thorns | 1M | 25 (23–27) | 26 | 25 | 84% / 11% / 5% |
| **Turtle** | 10M | **80** (80–81) | 80 | 80 | 58% / 42% / — |
| Blender | 10M | 42 (42–51) | 48 | 48 | 75% / — / 25% |
| Blender Thorns | 10M | 58 (52–59) | 58 | 61 | 65% / 11% / 24% |

**What the 10M Coins bought:**
- **Turtle:** Defense Absolute 111 (1,331 off every hit), Defense % 33%, Thorns 96%, Damage 70, Attack Speed 59, Health and Regen 72.
- **Blender Thorns:** Thorns 99%, Health 99, Damage 72, Defense Absolute 73 (466), Lifesteal 65, Knockback 63/40, **2 orbs**, Orb Speed 38, and no Defense %.

**What it shows:**
- **The turtle wins at both budgets, by a wide margin.** The blender never catches it.
- **Bosses aren't the missing piece.** Factor doesn't move the turtle at all and moves the blenders 0–6 waves. The turtle already kills bosses with Thorns, a share of the attacker's own health that doesn't care how big Tier 2 makes enemies. That's the job Plasma Cannon and Thorns do for The Tower's blender.
- **Defense Absolute doesn't hold Tier 2 either.** Basic attack at wave 80 is 4,599 in Tier 2. After 33% Defense and 1,331 Absolute, about 1,750 still lands. The turtle wins on Thorns plus taking less of each hit, not on blocking.
- **The blender's own pieces underperform.** Orbs make 5–6% of kills at 1M (one orb) and about a quarter at 10M (two orbs).
- **Likely cause** (inferred, not traced): our orbs circle at least 60 m out (`Guesses.ORB_MIN_RADIUS_M`, our guess, not The Tower's), while Range is about 30 m and Knockback holds enemies near it. The Tower's blender sets Range to the orb circle so held enemies sit in it. Ours are held well inside the orbs.

**The levers for D149's pivot, in the order to test them:**
1. **Orb placement:** orbs at the range's edge, as The Tower's Range-lab blender has them. This is a change to our guess, so it's the owner's call to test.
2. **Orb count** within Tier 2 budgets.
3. **Defense %**, if The Tower's is weaker early than ours.

Plasma Cannon or Factor is not a lever while Thorns already handles bosses.

### At the orb line, with every orb (3 October 2026)

The owner asked to test the blender "at the orb line": Range raised so the orbs, which circle at 60 m, sit on the Range edge where Knockback holds enemies. That is The Tower's Range-lab blender.
- Our Range upgrade reaches 60 m at level 60 (about 597K Coins in the Workshop), and the orbs stay at 60 m while Range is 60 m or less. So it's buildable today, with no rule change.
- **A second flaw in the measuring plans turned up:** they buy whichever level is cheapest for its weight, so the third orb (120K) never came up, and every blender above reached 10M Coins with only one or two of the four orbs.

**The two new plans** (Tier 2, 5 seeds, `--buy core`):
- `blender_orbs` is Blender Thorns with all four orbs bought first.
- `blender_orbline` is that, plus Range bought to 60 m first.

Median wave (range), and orbs' share of kills:

| Coins | Turtle | Blender Thorns | Blender, all orbs | **Blender, all orbs, at the orb line** |
|---|---|---|---|---|
| 1M | **36** | 25 | 19, orbs 21% | 2: orbs and Range take the whole budget |
| 3M | **52** | 39 | 40, orbs 31% | 40, orbs 35% |
| 5M | **63** (62–63) | — | — | 61 (56–65), orbs 53%: about level with the turtle |
| 10M | 80 (80–81) | 58 | 66, orbs 48% | **83 (82–91), orbs 59%, 13% more Coins than the turtle** |
| 20M | 106 (106) | — | — | **110 (101–123), orbs 67%**. Both builds clear Tier 2's wave 100, the way to Tier 3 |


**What it shows:**
- **The pivot exists in our Tier 2, with today's upgrades.** Once a Workshop can afford all four orbs and Range at the orb line and still buy its stats, the blender passes the turtle.
- **The geometry matters as much as the orbs.** With every orb, Range at the orb line is worth 17 more waves at 10M (66 → 83). The orbs' share of kills climbs from 24% to 59% over the steps.
- **The crossover is around 5M Coins.** Below it the turtle is right. That matches The Tower's account: the turtle first, then the blender once you can afford it.
- **Bosses still aren't the lever** (Factor, above). The levers were orb count and Range at the orb line.
- **Measuring plans need care.** Cheapest-per-weight buying can't express "buy all the orbs", which made the blender look broken twice. `max_first` and `range_m` now let a plan say it.

## What it means for our roadmap

- **Tier 2 (1.4) needs a reason to change build, not just bigger numbers.** In The Tower that reason is the Turtle breaking:
  - Defense Absolute is a flat subtraction that ×20 enemy attack outruns;
  - the Blender's answers (Orbs' instant kills, Thorns as a share of enemy health, Plasma Cannon as a share of boss health) don't care how big enemies are.
  - We have Orbs, Knockback and Thorns in the Workshop, so the Blender is buildable. Whether our Tier 2 *rewards* it over plain stats is the measurement above.
- **Tiers 3 and on lean on systems we haven't built:**
  - Perks (Tier 3);
  - Death Wave and Black Hole (Ultimate Weapons, 1.3, with their labs);
  - Wall Regen and Wall Thorns labs (Tier 10);
  - Enemy Level Skip labs (Tier 11);
  - battle conditions (Tier 14+).
  - Labs (1.2) and Ultimate Weapons (1.3) are on the roadmap. Perks, modules and battle conditions are "later, unscheduled".
- **Cards' value follows the tier.**
  - The test series (CARDS.md) found Tier 1 a pure killing-power check.
  - Super Tower and Berserker were measured since (D148): Super Tower is a strong killing card, and Berserker does nothing at The Tower's numbers.
  - The Tower's Tier 2 answer needs the **Plasma Cannon** card (and later Energy Net) against bosses. Our Factor candidate is a stateless stand-in for it, and passes D149's card floor.
- **To meet D149's shape in Tier 2**, the blender has to beat the turtle there. The likely levers (to test, not decided) are:
  - Plasma Cannon or Factor against bosses;
  - more orbs within Tier 2's budgets;
  - checking our Thorns and Defense % against The Tower's, which is what lets the turtle survive ×20 attack.
- **Not a decision:** which of these to build, and in what order, is the owner's call. This page is the evidence.

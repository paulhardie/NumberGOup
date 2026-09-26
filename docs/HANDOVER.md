# Handover

**Last updated:** 26 September 2026 (D084, the Number without its ring, and the enemy design brief), by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, brought up to `main` after #72 merged. It carries D084: the ring round the Number removed, and [`design/ENEMY_NUMBERS_BRIEF.md`](design/ENEMY_NUMBERS_BRIEF.md) for Claude Design. Not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`**, the only project Godot's Project Manager knows. `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute; the old `ngu-autopull` job is disabled. There is no `~/Desktop/NumberGOup`.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **The plan is the roadmap** in [`REBUILD_SPEC.md`](REBUILD_SPEC.md#roadmap) (D079):
   - the game is 0.9;
   - 1.0 is the first hours **with the Number as the tower** (D080): the Number in the centre, and enemies that subtract, divide or take a share on contact;
   - then Cards, Labs, Ultimate Weapons and Tier 2.

   Raise `application/config/version` in `project.godot` only when a version's "done when" is met.
4. **Next:** the owner plays and exports a report (D077). **When one arrives, read it first:** `tools/read_report.gd -- --file <report>` on the commit it names. It is the best evidence there is for decision 1.

## Where the game is

**Version 0.9, with 1.0's Number built (D082, D083).** The Number sits in the centre as the tower, with no ceiling: regen keeps raising it. The Tower's enemies subtract ("−x"), and from wave 5 a Divider divides it, ÷1.25 then ÷1.5 from wave 18, most of them landing. Home, battle and Workshop on Tier 1, saved, with every one of The Tower's Workshop groups (D076, merged). The owner played milestone 4.

- **Resuming (D078, merged):** the save carries the run in progress; the game opens back into it by replaying it. If an update means it no longer replays the same, it ends at its saved wave with its Coins kept.
- **Activity report (D077):** every run (seed, starting Workshop, each buy with its tick, a snapshot per wave) and every Workshop buy and unlock is logged to `user://number_go_up_activity.jsonl`. Home's Export report writes it to `user://reports/` and opens the folder. `tools/read_report.gd` reads and replays it.

- **Workshop groups, all of them open and work:** Range and Damage / Meter, Multishot, Rapid Fire, Bounce Shot, Super Crit, Rend Armor (Attack); Defense % and Absolute, Thorns, Lifesteal, Knockback, Orbs, Shockwave, Land Mines, Death Defy, the Wall (Defense); Cash rows, Coins rows, Free Upgrades, Interest, Recovery Packages, Enemy Level Skip (Utility). A tab shows only its next locked group, as a big Unlock card (D076).
- **Multi-buy:** a Buy button on the Workshop and the run's panel cycles ×1, ×5, ×10 and Max; cards quote what the press buys ("+5 $123").
- **A run** starts from the Workshop's levels, with $0 Cash, and sells its open groups, priced by the run's own purchases. The upgrade panel scrolls at three rows. An End run button ends a run early.
- **Battle rules:** Defense % then Absolute; Thorns (half on bosses); Multishot; Damage / Meter; Rapid Fire (×4 fire rate for its duration, rolled per volley); Bounce Shot (first strike rolls, then nearest within range, up to its targets, never twice); Lifesteal (share of what strikes take off); Knockback (force × 5 m over mass, never past the spawn); Orbs (kill walking non-boss enemies within 3 m of one); Cash Bonus, Cash / Wave, Interest (cap $50), Coins / Kill Bonus, Coins / Wave, Free Upgrades (a random open row of the tab, per wave). New in D076: Super Crit; Rend Armor (stacks per enemy to 800% more); Shockwave (pushes non-bosses in range); Land Mines (laid per volley, set off by walkers, blast a radius); Death Defy; the Wall (10 m ring melee enemies stop at, rebuilds); Recovery Packages (at a wave's end, overheal to Max Recovery; regen never cuts it); Enemy Level Skip (steady, not random). Our own rules for these are in the spec's Guesses.
- **Pay:** a kill pays $1 plus $1 every ten waves times its type's Cash multiplier, and its type's Coins flat (D074).
- **Saving:** `user://number_go_up_tower.json`, version 1 (unchanged by milestone 4).
- **The owner's timings (D075):** 11 enemies in wave 1, an enemy in place hits once a second, ranged enemies and orbs sit on the Range edge, and orbs turn once a second at their first level.
- **Careers** (`--careers N --buy core`, a focused player): the wave 10 boss holds until about run 13 (1.3 hours), then wave 20–21 until about 5½ hours. With the owner's ×9 pack Coins the same career reaches wave 21 on run 3 (about 25 minutes), close to the owner's own Tower save. Boss waves are the walls.
- **Not played by the owner yet, not on a phone.**

## Open decisions for the owner

1. **How should a pack-free account pace?** Under D075, a focused pack-free career spends about 1.3 hours at the wave 10 boss and about 5½ hours reaching wave 30. With ×9 Coins it matches the owner's own account. The "wave 100 in an hour" research is unverified. **Recommend** keeping The Tower's rules and deciding the target by playing: if the first hours feel slow without packs, the lever is Coins per kill or Coins / Wave, not the enemy rules.
2. **The Number's four decisions:** answered (D081): ceiling at Health, subtract and divide, new operator enemies on top of The Tower's, and Health renamed Number.
2a. **The enemy brainstorm:** answered and built (D082).
2b. **The Tower's enemy list against our data:** Ranged now pays 2 Coins (D082); the speeds stay the SDK's.
2d. **A Number with no ceiling (option b, THE_NUMBER.md 1.2):** the owner chose it for 1.0, to be measured first. It's measured, and **waiting on the owner's pick of setting**. Recommend all of Regen past Health (no ceiling): runs still end, fresh runs are unchanged, and the Number climbs about fourfold before the waves overtake it. Trade-off: careers reach wave 30 by run 21. The game still has the ceiling (`NUMBER_OVERFILL` 0) until the owner says.
2c. **Do the Number's climb and the ÷ moments feel right?** Built as D083 decided: no ceiling, and ÷1.25 then ÷1.5. Only play answers it. The levers are `Guesses.NUMBER_OVERFILL` and `Guesses.DIVIDER`, measured with `sim_runs.gd --curve`.
3. **Cheaper Workshop prices?** Answered: keep The Tower's (the owner, 26 September: "fair enough").
4. **Lighter process while rebuilding.** **Recommend yes.**
5. **AGENTS.md's architectural law 3** (the modifier pipeline) names removed code. **Recommend** dropping it until a system needs stacked rules.

## Next steps, in order

0. **Owner:** send [`design/ENEMY_NUMBERS_BRIEF.md`](design/ENEMY_NUMBERS_BRIEF.md) and its screenshots to Claude Design. **Agent, when the design returns:** build the enemies as numbers in `src/ui/arena_view.gd`, with bundled OFL fonts. Drawing only; no rule changes (D084).

1. **Owner:** merge this, play, and export a report. Say whether the Number in the centre and the ÷ moments feel right, and how often they come. Done when the owner has played it.
2. **Agent:** read the report. It records each run's peak Number, what Dividers took, and how many came and landed. Tune `Guesses.DIVIDER` from it with `sim_runs.gd` against the benchmarks (THE_NUMBER.md 5).
3. **Owner, then:** sign off 1.0, or name what's missing. After that comes Cards (1.1).

## How to measure

- **Ran on this branch (26 September, D083):** `bash run_tests.sh`: `PASS: tower tests (2428 checks)`. New checks cover:
  - the overfill rule;
  - Tier 1's divisors (÷1.25 to wave 17, ÷1.5 after, always clean);
  - a Divider keeping the divisor of its wave;
  - a fifth taken at ÷1.25, the Wall included.

  `sim_runs.gd`: 20 seeds each for `none`, `even` and `core`, and 30-run `core` careers with `--curve` at overfill 0, ¼, ½ and 1 (with ÷2), then the gentle divisor with health 2×→4× and 4× (figures in D083 and THE_NUMBER.md 1.2). Captures inspected: a Divider walking in with its divisor under it, and the Number against its peak.
- **Ran on this branch (26 September, D082):** `bash run_tests.sh`: `PASS: tower tests (2385 checks)`. New checks cover:
  - Dividers coming on top of The Tower's enemies without changing them, in time order, as many as their share adds up to;
  - a Divider's share through the defences, used up, unpaid, never ending a run;
  - shots at a landed Divider being lost;
  - a killed Divider's pay;
  - the Wall halving;
  - the peak Number and best Number through a save and from an older save;
  - Health reading as Number, and Ranged's 2 Coins.

  `sim_runs.gd`, 20 seeds each for `none`, `even` and `core`, and 30-run `core` careers at Divider health 2×, 4×, 6× and 10×, 0.75× speed, none, and the ramp as built (figures in D082). The headless boot is clean. The capture's new `battle_divided.png` shows a ÷ landing; the strong tower, a fresh run and the run-over panel were inspected.
- **Not run for D082:** play on the Mac, and how ÷ moments feel. The simulation measures balance, not fun.
- **Ran on this branch (26 September, D078):** `bash run_tests.sh`: `PASS: tower tests (2320 checks)`.
  - **Independent review done:** a separate agent session reviewed the diff and reproduced its findings. Every finding was fixed, with a test each (see D078): the match check now compares Cash, levels, enemies, inputs and the random streams; damaged records are rejected whole; runs after "Battle again" are logged; the failure handling can't be crashed by a damaged wave; and a lost run's log entry keeps the version that recorded it.
  - The reviewer's price-change reproduction now fails the match, as it should.
  - New checks drive the game's real entry point with test files: opening into a saved run, and ending a changed or damaged one. They check that each is counted at its wave, keeps its Coins, is logged as lost and shows the note on Home.
  - **Not run:** a real close and reopen on the Mac.
- **Ran for D077:** `bash run_tests.sh`: `PASS: tower tests (2254 checks)`. New checks cover:
  - inputs and wave snapshots being recorded;
  - a 15-minute run with every multiplier going through JSON and replaying to the same ticks, wave, kills, Cash, Coins and health, while another seed doesn't match;
  - the log appending, skipping a torn last line, stamping the version and exporting;
  - the Workshop screen and the battle reporting what the log needs;
  - Home's export message.

  The headless boot is clean. A sample export was made with two 10-wave runs (about 3.7 KB each) and read with `read_report.gd`: both replays match. The Home screen capture shows the Export report button.
- **Not run for D077:** a real export on the Mac (Finder opening, and the commit read from `~/NumberGOup-main/.git`), and quitting with Cmd+Q mid-run. Godot should send the same close notification, so the run is logged as closed, but that's unverified.
- **Ran on this branch (26 September, D076):** `bash run_tests.sh`: `PASS: tower tests (2228 checks)`. New checks cover every group opening in order and every row buyable in the Workshop and a run; multi-buy's ×5, ×10 it can't afford, Max, and stopping at a row's last level, in both; the Buy button cycling and a card buying five; the Workshop showing only each tab's next group; an overhealed health readout; and each new mechanic, including that none acts before its group opens. The headless boot is clean. `sim_runs.gd --seeds 10 --buy even` still gives median wave 8. `capture_battle.gd` under xvfb: the strong tower now shows the wall, a mine, a shockwave ring and overheal; `workshop_defense_x5.png` shows the Unlock card and Buy ×5 quotes.
- **Ran on this branch (26 September, D075):** `bash run_tests.sh`: `PASS: tower tests (1290 checks)`; new checks cover orbs on the Range edge at a turn a second, one orb sweeping a ranged enemy off the edge within a second, ranged enemies stopping on the edge as Range grows, and a hit a second. `sim_runs.gd` with `none`, `even`, `attack` and the new `core`, and careers with `attack` and `core`, plus two measurements patched locally and not committed (no per-hit heat-up; ×9 Coins). The strong-tower capture shows the orbs on the range circle.
- **Milestone 4's checks:** `bash run_tests.sh`: `PASS: tower tests (1281 checks)` (some new tests check every tick). New checks: Rapid Fire's rate and start; Bounce Shot to the nearest in range and not past it; Lifesteal's heal; Knockback by mass and never past the spawn; Interest and its cap; Free Upgrades' rows, count and cost; Orbs killing walkers but not bosses; Rapid Fire and Bounce Shot openable, Super Crit not. `--careers 40 --buy attack` and `--seeds 10 --buy even` (still wave 8). `capture_battle.gd` adds a strong tower (`battle_strong.png`).
- **Milestone 3's checks:** `bash run_tests.sh` gives `PASS: tower tests (356 checks)`. The new checks cover Workshop prices and group order; a run starting from the Workshop; save round trip, no save, three unreadable saves (broken JSON, another version, not an object) kept aside whole, and a damaged save cleaned; Defense, Thorns, Multishot volleys, Damage / Meter, the Cash and Coin rows, ending a run; and the battle banking Coins once. The headless boot is clean. `tools/sim_runs.gd --careers 12` with `even` and `attack`, and (patched locally, not committed) with flat Coins for decision 1. `tools/capture_battle.gd` under xvfb: the home screen, the Workshop's Attack and Utility tabs, and battle moments were inspected.
- **Not run:** CI, a phone, a separate reviewer on the save code, the Mac editor with its old class cache (every script loads by path to avoid a blank window there, per `QUALITY_GATES.md`), and a real close of the window on macOS (the save on close is only read in the code).
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`.
- **Regenerating enemy data:** see the header of `tools/import_tower_enemies.mjs` (npm pack the SDK, `npm install --omit=dev` inside it, run the script). Never edit `data/tower/enemies.json` by hand.

## Known issues and risks

- **Enemy count per wave** is the owner's 11 at wave 1 (D075); the 0.123 more a wave is ours.
- **The D076 mechanics follow The Tower where it says, and our guesses where it doesn't** (the spec's Guesses): the wall's distance, ranged shots passing the wall, mine placement and trigger distance, shockwaves sparing bosses. None of these groups is reachable in the first hours (100K Coins and up).
- **Enemy health past wave 22 is a guess:** the correction fitted to the owner's readings is held at wave 22's value beyond it, so health may run up to 10% high or low there.
- **The Tower's data is its own,** under the SDK's MIT licence: fine privately; publishing needs a decision.
- A shot whose target dies first is lost, and the tower doesn't avoid overkill. That's our reading of The Tower, not checked.
- Past wave 6,500 the enemy data holds its last value; generate more before a run can reach it.
- **Boss waves are the walls:** careers end on or just after every tenth wave. That's The Tower's design (bosses are walls, D063), but worth watching in play.
- **Resuming replays the whole run,** about 4.6 s per hour of game time here. Fine now; several-hour runs will need a full battle-state snapshot instead.
- **An update between closing and reopening usually ends a saved run** at its saved wave (D078). The Mac's sync pulls merges within a minute.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (D074 onwards), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, and push it.** Don't open or merge a PR unless the owner asks.
5. **Leave no scratch files** in the repository.

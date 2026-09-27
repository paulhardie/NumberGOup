# Handover

**Last updated:** 27 September 2026, by Claude, handing on to the next agent. This session read the owner's first activity reports, moved the Divider into The Tower's Protector slot (D094), restyled the battle screen to the owner's main-screen design (D095), carried it to Home and the Workshop (D096), measured where the Number's growth comes from (THE_NUMBER.md 5.2b), built the Multiplier as a switch to test, with free Coins and a reset for testing (D097), added two more switches, regen stopping at the Number's best and kills growing it (D098), made each new digit a moment (D099), wrote the Number out in full below a million (D100), made the view zoom out as Range grows (D101), and made enemies show what they do to the Number, dropping the hitbox prototype (D102).

**Branch:** `claude/dazzling-gates-54ahbr`, from `main` after #88 (D099, D100) merged. It carries D101's zoom and D102 (enemies show what they do; the hitbox dropped). Open as #89, not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`.** `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute, imports new assets, and notifies the owner when `claude/` work is waiting to be merged (AGENTS.md).

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), then [`REBUILD_SPEC.md`](REBUILD_SPEC.md)'s Roadmap and Benchmarks. Fetch and check the branch against `origin` before new work.
2. **The Tower is the spec** (D073): copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each version before the next starts.
3. **The plan is the roadmap** (D079). The game is 0.9. 1.0 is The Tower's first hours with the Number as the tower (D080), and it is close: see Next steps. Then Cards (1.1), Labs, Ultimate Weapons and Tier 2.
4. **When a report arrives, read it first** with `tools/read_report.gd -- --file <report>`. Runs replay only on the commit that recorded them. For totals across several reports, dedupe runs by their time and seed: each export repeats everything before it.

## Where the game is

**Version 0.9, with all of 1.0's Number built.**

- **The battle.** Tier 1, with every one of The Tower's Workshop groups working (D076). The Number sits in the centre as the tower, white, with no ceiling (D083), large and thin, in the design's soft warm light that breathes (D096), inside a faint ring at the range. The screen follows the owner's main-screen design (D095): pill buttons, hairline readouts, underlined tabs and quiet cards, on near-black.
- **Enemies.** The Tower's enemies subtract. A Divider divides the Number: ÷1.25, then ÷1.5 from wave 18. It takes the Protector's slot, replacing a basic, so waves are The Tower's size: one every third wave from wave 5 (the first on wave 7), every other wave by wave 30 (D094). The nearest one in range is previewed above the Number (D086).
- **Enemies as numbers** (D085, D086). Each type has its own typeface and colour. An enemy shows what it does to the Number (−2.4, ÷1.5, ×1.1) from start to death, with the damage dealt so far in small white under it once it survives a shot (D102).
- **Shots** have trails, hits chip the enemies' numbers, and knockback slides (D090).
- **Sound.** No combat sounds (D091). Generative ambient music plays across every screen (D092).
- **Home and the Workshop** wear the same look, with a bar along the bottom (D096). Home follows The Tower's: Coins, the best Number in its light, the Coin bonus, the tier, Battle. Cards, Labs, Weapons, Missions, Milestones and the tier arrows stand locked as placeholders. Settings (Music, Export report) opens over Home and is kept in `user://number_go_up_settings.json` (D088).
- **Saving, resuming and the report.** The save is `user://number_go_up_tower.json`, version 1. A run closed mid-way resumes by replay (D078). Every run and Workshop buy is logged, and Home exports a report (D077).
- **The owner has played it:** 37 runs in the Workshop, and reports exported on 26 and 27 September. Not yet on a phone or the web build.

**What the owner's reports show** (21 runs, deduplicated; details in the spec's Benchmarks and THE_NUMBER.md 5.2a):
- **The Tower's benchmarks hold.** Wave 20–21 runs take 11½ minutes of game time and earn 117–165 Coins, against The Tower's 12½ minutes and about 162 Coins for wave 22.
- **The wave-10 boss is the wall:** 13 of 19 runs ended on waves 10–11, as The Tower intends. Then the owner put 540 Coins into Workshop Damage (3 to 6), and the next run reached **wave 31** (Number peak 989), where a boss ended it.
- **In that long run, Dividers took 40% of the Number lost with 4 landings**, since a ÷ takes a share of a large Number. Any change to their rate must be measured on long careers.
- **The Number climbs through a run**, as the Number's targets want. Its median at the end of waves 1, 10 and 19 was 16, 40 and 332.
- **÷ moments are about a third of the target rate:** 0.31 a minute landed, against one a minute. 58% of Dividers never landed.
- **No run ended on a ÷.** Ranged enemies took 24% of the Number lost and ended 2 runs.
- **Two runs were lost to updates:** a merge landed while a run was saved, so resuming ended it at its saved wave, by design (D078).
- **The owner plays half their real time at ×5.**
- **The replays match:** the two runs recorded on today's `main` replay exactly with `read_report.gd`.

## Open decisions for the owner

1. **Which of the three testing switches to keep** (D097, D098). Measured: regen at best plus kills together make the Number's growth come from fighting and buying, not waiting, and keep The Tower's benchmarks at a 5% kill share, but the Number is smaller and the career about four runs slower to wave 30. **Recommend** playing "both on" and "all three on"; D098's table has the numbers. Earlier note on the Multiplier alone: Regen makes about nine tenths of the Number's new highs without it (THE_NUMBER.md 5.2b), and about half with it, with The Tower's benchmarks and the career's pace unchanged. The owner is playing runs both ways to judge the fun. **Recommend** keeping it if the ×-moments feel good, then deciding on regen's reach past Health (`NUMBER_OVERFILL`) as a separate test.
2. **Sign off 1.0, or name what's missing,** after playing D094. The Tower's benchmarks hold and the Number climbs. In simulation, D094 left fresh runs as they were but a core career beat the wave-10 boss on run 9 (it was 11; The Tower's is 10–13), and ÷ landings sit about 0.3 a minute. **If that feels too easy or ÷ too rare, recommend** raising the Divider's health from 4× to 5× before its rate, since the owner set the rate's ceiling.
3. **Game speed.** The spec calls the 1×/2×/5× switch a testing tool, yet it's half of how the owner plays. **Recommend** keeping it as a player feature, since The Tower's first hours are long.
4. **Updates mid-run.** Two runs were lost when a merge landed while a run was saved. **Recommend** the Mac's sync job wait to update while the save holds a run in progress, and say so in its notification. It's small, and changes nothing in the game.
5. **The lighter rebuild process** (REBUILD_SPEC.md, "Process while the rebuild is in progress"), open since 25 September. **Recommend yes.**
6. **AGENTS.md's law 3** names a modifier pipeline that no longer exists. **Recommend** dropping it until a system needs stacked rules. Only the owner changes that file's rules.
7. **Publishing The Tower's data** (its Workshop and enemy numbers, under the SDK's MIT licence) needs a decision before anything is public. Not urgent.
8. **Idle play (D089)** waits for servers. Nothing is built.
9. **Milestones and Missions** stand on Home as placeholders at the owner's request, but aren't on the roadmap. **Recommend** deciding whether they join it before 1.1, or dropping them, so a placeholder never promises something unplanned.

## Next steps, in order

1. **Owner:** play runs with Settings → Testing's switches in a few combinations (none; regen at best and kills; all three), using free Coins or a reset to try different stages. Done when the owner says which to keep.
1a. **Owner:** sign off 1.0 or name what's missing (decision 2).
2. **Agent, on the owner's word:** tune the Divider's health with `sim_runs.gd --careers 40 --buy core --divider-health N` if play says so. Then raise `application/config/version` to 1.0 when the owner signs it off. `--careers` always plays the same seeds (run N is seed N), so a second career needs a seed option first.
3. **Owner:** try the web build on a phone. The light's shader, the music and the portrait layout have never run there.
4. **Then Cards (1.1).** Before them, split `src/ui/arena_view.gd` (509 lines: the battle, effects, the light, fonts) so effects have their own file, and consider moving the later Workshop mechanics (Wall, Mines, Orbs, Shockwave) out of `battle_sim.gd` (821 lines), per AGENTS.md's law 7.

## How to measure

- **This session (27 September):**
  - `read_report.gd` on the owner's latest report: runs 20 and 21, recorded on `af32bb6`, **match** on replay. The others were recorded on older commits.
  - The report figures above come from the four exported reports, with runs deduplicated by time and seed.
  - D102: `bash run_tests.sh` passes (2799 checks); captures of a crowd, a tank and a Divider with damage dealt, checked by eye.
  - D101: `bash run_tests.sh` passes (2805 checks). The hitbox at 0.5, 1 and 2 m per digit on 40 fresh seeds (spread, damage-only, core) and 40-run core careers; with it off, 20 core runs print identically. `battle_full_range` checked by eye.
  - D100: `bash run_tests.sh` passes (2796 checks); captures of 5, 1,000 (its moment), 12,863 and 27,976 checked by eye.
  - D099: `bash run_tests.sh` passes (2792 checks), and `capture_battle.gd`'s `battle_new_digit` was checked by eye. The chime was tested for its notes and silence, not listened to.
  - D098: `bash run_tests.sh` passes (2781 checks). The grid in D098: each switch alone, both, and all three, on 20-seed fresh runs (40 for core) and 40-run core careers, plus kill shares of 3%, 5%, 7% and 10%. With every switch off, 20 core runs print identically.
  - D097: `bash run_tests.sh` passes (2768 checks). `sim_runs.gd --multipliers --gains` measurements are in D097. With the switch off, 20 core runs print identically to before. `capture_battle.gd` now also shoots a Multiplier walking in and one killed, both checked by eye.
  - Gains: `bash run_tests.sh` passes (2617 checks). `sim_runs.gd --gains` on 10 seeds each of even and core, a 40-run core career, a 60-run even career, and three scratch careers opening Lifesteal free at run 31 (levels 10, 40, 80). With and without the bookkeeping, 20 core runs print identically.
  - D096: `bash run_tests.sh` passes (2610 checks); `capture_battle.gd` screenshots of Home, the Workshop's tabs, a battle, a ÷ and the run-over panel checked by eye.
  - D095: `bash run_tests.sh` passes (2604 checks); `capture_battle.gd` screenshots checked by eye at wave 1, a crowd, a ÷ landing, a large Number with the Wall up, Home and the Workshop.
  - D094: `bash run_tests.sh` passes (2604 checks). `sim_runs.gd` 20 seeds before and after, and a 40-run core career; figures in D094. Not played; the owner hasn't seen it.
- **The tools:** `bash run_tests.sh` (the baseline); `sim_runs.gd` for balance; `capture_battle.gd` for screenshots; `record_music.gd` for the music; `read_report.gd` for the owner's runs. AGENTS.md's Commands has their options.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`. Wrap window tools in `xvfb-run -a -s "-screen 0 1024x1100x24"`. Run `--import` once after new assets.
- **Not yet run anywhere:** a phone; the web build's performance; a real close and reopen on the Mac.

## Known issues and risks

- **Settings → Testing isn't meant to ship** (D097): free Coins and Reset progress act on the real save. Remove or hide them before anything goes public.
- **Turning Multipliers on or off mid-run changes nothing until the next run**: a run keeps the switch it started with, and so does its replay (D078). Runs saved before this update still resume, since with the switch off the battle is unchanged.
- **Readings still needed from The Tower:** one boss kill's Cash (20× is ours), and a basic enemy's Health at wave 30 or 50. The health correction is only fitted to wave 22.
- **Heat-up is unsettled:** we use 4% per hit landed; the owner's research says per wave survived. Watching a boss stand at the tower in The Tower settles it.
- **A run saved mid-way before D094 won't resume identically**, so it ends at its saved wave (D078). Finish or end a run before merging.
- **The Tier 1 turtle hasn't been measured since the Divider arrived.** A ÷ goes through the defences almost untouched by Defense Absolute, so the turtle's "I've stopped dying" moment should be checked with `sim_runs.gd`.
- **The D076 mechanics use our guesses where The Tower is silent** (the spec's Guesses): the Wall's distance, mines, shockwaves. None is reachable in the first hours.
- **Resuming replays the whole run,** about 4.6 s per hour of game time. Several-hour runs, and idle play, will need a battle-state snapshot instead.
- **Enemies bunch at the Number:** those on the same side overlap. It's worth watching in play.
- **The light's shader and the music are unmeasured on a phone.**
- Past wave 6,500 the enemy data holds its last value.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (the last is D102), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, push it, and open a pull request for it** (AGENTS.md's hand-off). Never merge one; that's the owner's.
5. **Leave no scratch files** in the repository.

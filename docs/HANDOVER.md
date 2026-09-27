# Handover

**Last updated:** 27 September 2026, by Claude, handing on to the next agent. This session read the owner's first activity reports, cleaned up the docs, and moved the Divider into The Tower's Protector slot (D094).

**Branch:** `claude/dazzling-gates-54ahbr`, from `main` after #83 (the owner's wave-31 run) merged. It carries D094: the Divider now replaces a basic, at most once a wave. Not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`.** `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute, imports new assets, and notifies the owner when `claude/` work is waiting to be merged (AGENTS.md).

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), then [`REBUILD_SPEC.md`](REBUILD_SPEC.md)'s Roadmap and Benchmarks. Fetch and check the branch against `origin` before new work.
2. **The Tower is the spec** (D073): copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each version before the next starts.
3. **The plan is the roadmap** (D079). The game is 0.9. 1.0 is The Tower's first hours with the Number as the tower (D080), and it is close: see Next steps. Then Cards (1.1), Labs, Ultimate Weapons and Tier 2.
4. **When a report arrives, read it first** with `tools/read_report.gd -- --file <report>`. Runs replay only on the commit that recorded them. For totals across several reports, dedupe runs by their time and seed: each export repeats everything before it.

## Where the game is

**Version 0.9, with all of 1.0's Number built.**

- **The battle.** Tier 1, with every one of The Tower's Workshop groups working (D076). The Number sits in the centre as the tower, white, with no ceiling (D083), in a soft light that swirls with smoke (D087). It is on pure black.
- **Enemies.** The Tower's enemies subtract. A Divider divides the Number: ÷1.25, then ÷1.5 from wave 18. It takes the Protector's slot, replacing a basic, so waves are The Tower's size: one every third wave from wave 5 (the first on wave 7), every other wave by wave 30 (D094). The nearest one in range is previewed above the Number (D086).
- **Enemies as numbers** (D085, D086). Each type has its own typeface and colour. An enemy shows its health while it walks in, then its hit once it arrives.
- **Shots** have trails, hits chip the enemies' numbers, and knockback slides (D090).
- **Sound.** No combat sounds (D091). Generative ambient music plays across every screen (D092).
- **Home.** Two switches, Show range (off) and Music (on), kept in the settings file `user://number_go_up_settings.json` (D088).
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

1. **Sign off 1.0, or name what's missing,** after playing D094. The Tower's benchmarks hold and the Number climbs. In simulation, D094 left fresh runs as they were but a core career beat the wave-10 boss on run 9 (it was 11; The Tower's is 10–13), and ÷ landings sit about 0.3 a minute. **If that feels too easy or ÷ too rare, recommend** raising the Divider's health from 4× to 5× before its rate, since the owner set the rate's ceiling.
2. **Game speed.** The spec calls the 1×/2×/5× switch a testing tool, yet it's half of how the owner plays. **Recommend** keeping it as a player feature, since The Tower's first hours are long.
3. **Updates mid-run.** Two runs were lost when a merge landed while a run was saved. **Recommend** the Mac's sync job wait to update while the save holds a run in progress, and say so in its notification. It's small, and changes nothing in the game.
4. **The lighter rebuild process** (REBUILD_SPEC.md, "Process while the rebuild is in progress"), open since 25 September. **Recommend yes.**
5. **AGENTS.md's law 3** names a modifier pipeline that no longer exists. **Recommend** dropping it until a system needs stacked rules. Only the owner changes that file's rules.
6. **Publishing The Tower's data** (its Workshop and enemy numbers, under the SDK's MIT licence) needs a decision before anything is public. Not urgent.
7. **Idle play (D089)** waits for servers. Nothing is built.

## Next steps, in order

1. **Owner:** answer decision 1. Done when 1.0 is signed off, or what's missing is named.
2. **Agent, on the owner's word:** tune the Divider's health with `sim_runs.gd --careers 40 --buy core --divider-health N` if play says so. Then raise `application/config/version` to 1.0 when the owner signs it off. `--careers` always plays the same seeds (run N is seed N), so a second career needs a seed option first.
3. **Owner:** try the web build on a phone. The smoke shader, the music and the portrait layout have never run there.
4. **Then Cards (1.1).** Before them, split `src/ui/arena_view.gd` (509 lines: the battle, effects, the light, fonts) so effects have their own file, and consider moving the later Workshop mechanics (Wall, Mines, Orbs, Shockwave) out of `battle_sim.gd` (821 lines), per AGENTS.md's law 7.

## How to measure

- **This session (27 September):**
  - `read_report.gd` on the owner's latest report: runs 20 and 21, recorded on `af32bb6`, **match** on replay. The others were recorded on older commits.
  - The report figures above come from the four exported reports, with runs deduplicated by time and seed.
  - D094: `bash run_tests.sh` passes (2604 checks). `sim_runs.gd` 20 seeds before and after, and a 40-run core career; figures in D094. Not played; the owner hasn't seen it.
- **The tools:** `bash run_tests.sh` (the baseline); `sim_runs.gd` for balance; `capture_battle.gd` for screenshots; `record_music.gd` for the music; `read_report.gd` for the owner's runs. AGENTS.md's Commands has their options.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`. Wrap window tools in `xvfb-run -a -s "-screen 0 1024x1100x24"`. Run `--import` once after new assets.
- **Not yet run anywhere:** a phone; the web build's performance; a real close and reopen on the Mac.

## Known issues and risks

- **Readings still needed from The Tower:** one boss kill's Cash (20× is ours), and a basic enemy's Health at wave 30 or 50. The health correction is only fitted to wave 22.
- **Heat-up is unsettled:** we use 4% per hit landed; the owner's research says per wave survived. Watching a boss stand at the tower in The Tower settles it.
- **A run saved mid-way before D094 won't resume identically**, so it ends at its saved wave (D078). Finish or end a run before merging.
- **The Tier 1 turtle hasn't been measured since the Divider arrived.** A ÷ goes through the defences almost untouched by Defense Absolute, so the turtle's "I've stopped dying" moment should be checked with `sim_runs.gd`.
- **The D076 mechanics use our guesses where The Tower is silent** (the spec's Guesses): the Wall's distance, mines, shockwaves. None is reachable in the first hours.
- **Resuming replays the whole run,** about 4.6 s per hour of game time. Several-hour runs, and idle play, will need a battle-state snapshot instead.
- **Enemies bunch at the Number:** those on the same side overlap. It's worth watching in play.
- **The smoke shader and the music are unmeasured on a phone.**
- Past wave 6,500 the enemy data holds its last value.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (the last is D094), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, push it, and open a pull request for it** (AGENTS.md's hand-off). Never merge one; that's the owner's.
5. **Leave no scratch files** in the repository.

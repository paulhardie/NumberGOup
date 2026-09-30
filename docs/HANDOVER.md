# Handover

**Last updated:** 30 September 2026, by Claude, handing on to the next agent. Since the last handover (D125) the owner merged the look review (D127–D129), the Workshop-only wall and its correction (D130, D132) and the waves-versus-digits split (D131). This session designed our own base enemy roster and built its first enemy, the Lock (D133); the Divider's slow refill was measured and left off (D134).

**Branch:** `claude/lock-enemy`, from `main` after #120. It carries D133 and D134. Not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`.** `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute, imports new assets, and notifies the owner when `claude/` work is waiting to be merged (AGENTS.md).

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), then [`REBUILD_SPEC.md`](REBUILD_SPEC.md)'s Roadmap and Benchmarks. Fetch and check the branch against `origin` before new work.
2. **The Tower is the spec** (D073): copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. **Our own enemies are the exception:** they follow [`THE_NUMBER.md`](THE_NUMBER.md) section 8's rules. The owner plays each version before the next starts.
3. **The plan is the roadmap** (D079). The game is 0.9. 1.0 is The Tower's first hours with the Number as the tower (D080). Then **1.0.x, The Tower's rules finished** (D115: the build list in [`TOWER_RULES.md`](TOWER_RULES.md#7-before-11-the-build-list)). **Cards (1.1) wait** until the wall is understood (the owner, after D130).
4. **A foundation pass may be running in parallel** (another model, on the owner's prompt): wave milestones as the one source of unlocks (D131), a run record with its tier and effects, and a save migration. D126 is left for it. Stay off its files and review its pull request when it's up, the save migration above all (law 5).
5. **When a report arrives, read it first** with `tools/read_report.gd -- --file <report>`. Runs replay only on the commit that recorded them.

## Where the game is

**Version 0.9, with all of 1.0's Number built.**

- **The battle.** Tier 1, with every one of The Tower's Workshop groups working (D076). The Number sits in the centre as the tower, white, with no ceiling (D083), fitted inside a visible range ring (D123, D128). The run's upgrade panel folds away to give the arena more room (D129).
- **The Tower's pace and spawning** (D113–D124): its spawn rate chart, 104 rolls a wave (D135: 208 overwhelmed a fresh tower on wave 1), its mix by wave, its walk speeds, 9 s cooldown and ×1 clock, its caps, the Protector from Tier 2 and elites from wave 500. Wave Info opens from the wave readout.
- **Enemies as numbers** (D085, D102, D127, D128): each type in its own typeface and colour, showing what it does, bare (20, not −20). A crowd keeps one full label a spot, with counts and signs for the rest.
- **Our enemies.** The Divider (÷1.25, then ÷1.5 from wave 18) takes a basic's place from wave 7 (D094). **The Lock (=, D133)** comes on top of The Tower's waves from wave 35 (every third wave, every other from 60), stops on the range's edge, and while it stands the Number can't go up: no Regen, Lifesteal, Recovery Package or kill growth; bought Health still lands. It has no Attack. The first one past a player's best wave brings a card saying what it does.
- **How the Number grows** (D111): regen only restores it up to the run's best; a clean kill adds 5% of its Attack; bought Health and Lifesteal lift it too.
- **Home and the Workshop** (D096, D125): The Tower's welcome (50 Coins after the first run, a popup into the Workshop), screens shown only once The Tower would, and a popup saying what each newly opened group's rows do. Milestones pay Coins for each new digit of the best Number (D107).
- **Saving, resuming and the report.** The save is `user://number_go_up_tower.json`, version 1. A run closed mid-way resumes by replay (D078); one that no longer replays after an update ends at its saved wave with its Coins kept. Every run and Workshop buy is logged, and Home exports a report (D077).

**The wall, measured (D130, D132, D133):** on the Workshop alone, the turtle (Defense Absolute, Thorns) is the best Tier 1 build at every budget from 10K Coins. It breaks as The Tower's does, when basic enemies' Attack outgrows Defense Absolute; Dividers don't decide where. **Coins set the pace:** about 50 game hours to wave 100 on the Workshop alone. D133 has the table with and without the Lock.

## Open decisions for the owner

1. **The Lock (D133): keep it as built, or tune it?** It takes the turtle's wall down by a few waves and barely touches other builds. **Recommend** playing it first; `sim_runs.gd --lock-health N` and `--lock-every A:B` measure changes.
2. **The Divider's slow refill (D134): leave it off?** It moved no wall at 10 to 120 seconds, so it's off. **Recommend** leaving it off; if Dividers must matter to the outcome, a Countdown (THE_NUMBER.md section 8) is the stronger lever.
3. **Should the Divider come on top too?** New enemies come on top (the owner's choice); the Divider still takes a basic's place (D094). **Recommend** leaving it, as moving it would shift the early benchmarks for no measured gain.
4. **The next enemy** from section 8's roster. **Recommend** the Countdown (burst damage, around wave 15), since it tests a different build question and lands before the wave-20 Cards.
5. **More unlocks than The Tower, and a UI of our own** (D131): both to be discussed before anything is built.
6. **Sign off 1.0, or name what's missing,** after playing.
7. **AGENTS.md's law 3** still names a modifier pipeline in `GameState`, which is gone. **Recommend** rewording it for `StatStack` (D119). Only the owner changes that file's rules.
8. **The Tower's wave milestones** (TOWER_RULES.md build item 6) are part of the foundation pass (item 4 above).

## Next steps, in order

1. **Owner:** merge D133 and play past wave 35 (free Coins or a strong Workshop helps). Say whether the Lock reads and feels fair. Done when the owner says keep, tune or drop.
2. **Agent, on the owner's word:** the next roster enemy (decision 4), built as the Lock was: a kind in `enemy_kinds.gd`, numbers in `guesses.gd`, its slot in `battle_spawns.gd`, its rule in `battle_sim.gd`, its look in `arena_view.gd`, a first-sight line in `battle_screen.gd`, a `sim_runs.gd` switch, and the D130 sweep with and without it. Done when it's measured and the owner has played it.
3. **Agent:** review the foundation pass's pull request when it appears. Done when reviewed.
4. **Owner:** record one whole early Tower wave at ×1 for the enemy count (TOWER_RULES.md reading 4). Done when it's counted.

## How to measure

- **D133 and D134 (30 September):** `bash run_tests.sh` passes (4315 checks, with new ones for the Lock's hold, its beat on top of the wave with every Tower spawn unchanged, the cap, Wave Info, the first-sight card, and the refill). The headless boot is clean. With `--lock off --divider-refill 0`, runs print identically to `main`. The D130 sweep (four plans at 10K–10M Coins, 4 seeds, 180-minute cap) on `main` and with the Lock, and 40-run core careers: D133's table. The refill at 10, 30, 60 and 120 seconds on the 10K turtle: D134. `capture_battle.gd`'s new `battle_lock` checked by eye. The review was the author's own. Not played.
- **The tools:** `bash run_tests.sh` (the baseline); `sim_runs.gd` for balance (`--workshop-coins N --workshop-plan P` for walls); `capture_battle.gd` for screenshots; `record_music.gd` for the music; `read_report.gd` for the owner's runs. AGENTS.md's Commands has their options.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`. Wrap window tools in `xvfb-run -a -s "-screen 0 1024x1100x24"`. Run `--import` once after new assets.
- **Not yet run anywhere:** a phone; the web build's performance.

## Known issues and risks

- **A run saved mid-way past wave 35 before D133 won't resume identically,** so it ends at its saved wave with its Coins kept (D078). Finish or end a run before merging.
- **The first-sight card shows only past a player's best wave,** so a player already past wave 35 never sees the Lock's. That keeps the save unchanged; a "seen" list would need a save key.
- **The music test sometimes leaves audio playbacks at exit** (13 or 24 "leaked" warnings, varying run to run; none on some runs). A warning, not a failure, and not from the game's code under test.
- **`capture_battle.gd`'s seeded run dies on wave 1,** so its timed screenshots (4 s to 600 s) show little.
- **The README is stale** (the foundation pass was to refresh it).
- **TOWER_RULES.md says The Tower's wave-10 milestone pays 10 Coins;** the SDK says 25. Unchecked.
- **Settings → Testing isn't meant to ship** (D097): free Coins and Reset progress act on the real save.
- **Resuming replays the whole run,** about 4.6 s per hour of game time. Idle play will need a battle-state snapshot.
- **Seven save-file checks fail locally on the owner's Mac** (`DirAccess.get_files_at("user://")` lists the project folder there); CI on Linux passes.
- **The light's shader and the music are unmeasured on a phone.** Past wave 6,500 the enemy data holds its last value.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (the last is D134; D126 is left for the foundation pass), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, push it, and open a pull request for it** (AGENTS.md's hand-off). Never merge one; that's the owner's.
5. **Leave no scratch files** in the repository.

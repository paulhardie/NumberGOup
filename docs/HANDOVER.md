# Handover

**Last updated:** 26 September 2026, by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, restarted from `main` after [paulhardie/NumberGOup#61](https://github.com/paulhardie/NumberGOup/pull/61) (milestone 1) and [paulhardie/NumberGOup#62](https://github.com/paulhardie/NumberGOup/pull/62) (the Mac sync) merged. It carries milestone 2, not yet merged. The old game is commit `f4f1e95`; a `pre-rebuild` tag for it can be pushed from the Mac: `git tag -a pre-rebuild f4f1e95 -m "The game before the rebuild" && git push origin pre-rebuild`.

**The owner's play folder** follows `origin/main` once `tools/mac/install_sync.sh <folder>` has been run on the Mac (README, "Playing on the Mac"). It was tested on Linux with `launchctl` stubbed. Whether the owner has run it yet isn't known here.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **Next:** milestone 3, the Workshop, Coins, a home screen and saving (below), once the owner has played milestone 2.

## Where the game is

Milestone 2: the battle on Tier 1, with run upgrades bought with Cash. The owner played milestone 1 ("looks good", combat a little jittery).

- A fresh tower: Damage 3, one shot a second, Critical 1% at ×1.20, Range 30 m, Health 5, Regen 0.
- **Run upgrades:** Attack, Defense and Utility tabs under the readouts. Damage, Attack Speed, Critical Chance, Critical Factor, Health and Health Regen are open. Each costs The Tower's Cash price for how many of that row the run has bought ($10, $12, $14… for Damage). Health bought heals by its gain. Utility is empty until the Workshop opens its rows. Levels last one run.
- **Smooth movement:** enemies and shots are drawn between their last two ticks (the sim ticks 30 times a second), which fixes the jitter the owner saw.
- Waves: 26 seconds of spawning, then about 8.7 seconds of cooldown. There are 20 enemies at wave 1 (a guess) and a boss every tenth wave. The mix is 85% basic, 7% fast, 6% tank and 2% ranged.
- Enemies: The Tower's own health and Attack for their wave. They set off 100 m out. Melee enemies stop at the tower and ranged ones at 30 m. Each hits every 5 seconds from arrival, 4% harder each time.
- Pay: a kill pays $1 plus $1 every ten waves, times its type's Cash multiplier (tank 5, boss 20), and its type's Coins times its wave. **Coins are counted but lost at the end of a run: nothing spends or keeps them until milestone 3.**
- **Result** (`tools/sim_runs.gd`, 10 seeds each): spreading Cash evenly dies on wave 8 (median, range 8–10), the owner's benchmark; only Damage and Attack Speed reaches wave 10, where the boss ends most runs; cheapest-first and buying nothing die on wave 2.
- **Not played by the owner yet, not on a phone.** There's no saving.

## Open decisions for the owner

1. **Lighter process while rebuilding** (REBUILD_SPEC, "Process while the rebuild is in progress"). **Recommend yes:** disposable saves until the loop is fun, economy changes treated as medium risk, and decision entries only for owner choices.
2. **AGENTS.md's architectural law 3** ("all future rules enter through the modifier pipeline") names code the rebuild removed. **Recommend** dropping it until a system needs stacked rules (Perks, Cards), then deciding again. Only the owner changes the rules.

## Next steps, in order

1. **Owner:** merge milestone 2 and play a few runs. **Done when:** the owner says how buying feels, and whether movement is smooth now.
2. **Agent: milestone 3, the Workshop, Coins, home and saving** (REBUILD_SPEC, "Milestones"). Coins earned in a run are kept. A Workshop screen spends them on permanent levels at The Tower's Coin prices, and opens groups in The Tower's order: Cash rows 40 Coins, Range 50, Defense 75, Coins rows 100, Multishot 400, Thorns 500. A run starts from Workshop levels, with the opened groups on sale in the run. A home screen shows Battle, best wave and Coins. The game saves to a new file, never the old one. **Done when:** the owner has played several runs from a fresh save, and a career in the measuring tool (runs with Workshop spending between them) still has runs ending for a reason after run 3.
3. **Owner, when convenient:** a boss kill's Cash, a basic enemy's health from Wave Info past wave 22, and the enemy count at a known wave.

## How to measure

- **Ran on this branch (26 September):** `bash run_tests.sh` gives `PASS: tower tests (287 checks)`, including pressing the real Damage card on the battle screen. The headless boot is clean. `tools/sim_runs.gd` with each `--buy` strategy over 10 seeds (figures above). `tools/capture_battle.gd` under xvfb, buying evenly as it goes: screenshots at 4, 30, 120, 240 and 600 seconds were inspected (the panel, prices greyed when short, whole Damage and Health).
- **The smoothing** is covered by a test of where things are drawn between ticks. It can't be seen in still screenshots; only play shows it.
- **Not run:** CI, a phone, the Mac editor with its old class cache (every script loads by path to avoid a blank window there, per `QUALITY_GATES.md`).
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`.
- **Regenerating enemy data:** see the header of `tools/import_tower_enemies.mjs` (npm pack the SDK, `npm install --omit=dev` inside it, run the script). Never edit `data/tower/enemies.json` by hand.

## Known issues and risks

- **Enemy count per wave is a guess** (20 at wave 1, D065). The SDK says about 4, which the owner's screens contradict.
- **Enemy health past wave 22 is a guess:** the correction fitted to the owner's readings is held at wave 22's value beyond it, so health may run up to 10% high or low there.
- **The Tower's data is its own,** under the SDK's MIT licence: fine privately; publishing needs a decision.
- A shot whose target dies first is lost, and the tower doesn't avoid overkill. That's our reading of The Tower, not checked.
- Past wave 6,500 the enemy data holds its last value; generate more before a run can reach it.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (D074 onwards), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, and push it.** Don't open or merge a PR unless the owner asks.
5. **Leave no scratch files** in the repository.

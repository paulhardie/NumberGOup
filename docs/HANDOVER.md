# Handover

**Last updated:** 25 September 2026, by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, unmerged, no PR. It carries the rebuild (D073): the spec, then milestone 1. `main` still has the old game, which the owner's local checkout plays until this merges. The old game is commit `f4f1e95`; a `pre-rebuild` tag for it exists only in the session that made it (the push was refused), so push it from a machine that can: `git tag -a pre-rebuild f4f1e95 -m "The game before the rebuild" && git push origin pre-rebuild`.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **Next:** milestone 2, run upgrades and Cash (below), once the owner has played milestone 1.

## Where the game is

Milestone 1: the battle alone, on Tier 1, with nothing to buy.

- A fresh tower: Damage 3, one shot a second, Critical 1% at ×1.20, Range 30 m, Health 5, Regen 0.
- Waves: 26 seconds of spawning, then about 8.7 seconds of cooldown. There are 20 enemies at wave 1 (a guess) and a boss every tenth wave. The mix is 85% basic, 7% fast, 6% tank and 2% ranged.
- Enemies: The Tower's own health and Attack for their wave, generated from TheTowerSDK and calibrated to the owner's screens. They set off 100 m out. Melee enemies stop at the tower and ranged ones at 30 m. Each hits every 5 seconds from arrival, 4% harder each time.
- Pay: a kill pays $1 plus $1 every ten waves, times its type's Cash multiplier (tank 5, boss 20), and its type's Coins times its wave.
- **Result:** a fresh tower dies on wave 2 in 46–57 seconds on every seed, as The Tower's "dies at once".
- **Not played by the owner, not on a phone.** There's no saving: the game doesn't write a save yet.

## Open decisions for the owner

1. **Lighter process while rebuilding** (REBUILD_SPEC, "Process while the rebuild is in progress"). **Recommend yes:** disposable saves until the loop is fun, economy changes treated as medium risk, and decision entries only for owner choices.
2. **AGENTS.md's architectural law 3** ("all future rules enter through the modifier pipeline") names code the rebuild removed. **Recommend** dropping it until a system needs stacked rules (Perks, Cards), then deciding again. Only the owner changes the rules.

## Next steps, in order

1. **Owner:** pull the branch and play a few runs of milestone 1 (it lasts about a minute). **Done when:** the owner says how the battle looks and feels.
2. **Agent: milestone 2, run upgrades and Cash.** Buy the opened rows' levels with Cash at The Tower's prices (`cash_prices` in `upgrades.json`), from an Attack/Defense/Utility panel under the readouts. At first that's only the start rows (Damage, Attack Speed, Critical Chance, Critical Factor, Health, Health Regen); the rest open with the Workshop. Add a buying strategy to `tools/sim_runs.gd`. **Done when:** a fresh run that buys upgrades dies near wave 8 (the owner's benchmark, with starting Cash of $0, not the owner's $93), and the tests and captures pass.
3. **Owner, when convenient:** a boss kill's Cash, a basic enemy's health from Wave Info past wave 22, and the enemy count at a known wave.

## How to measure

- **Ran on this branch (25 September):** `bash run_tests.sh` gives `PASS: tower tests (252 checks)`. The headless boot is clean. `tools/sim_runs.gd` over 10 seeds: all die on wave 2. `tools/capture_battle.gd` under xvfb: screenshots at 4, 12, 30, 45 and 200 seconds were inspected (arena, readouts, stats and the run-over panel). The enemy generator checks itself against the owner's ten readings.
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

# Handover

**Last updated:** 26 September 2026 (milestone 3), by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, restarted from `main` after milestone 2 merged ([paulhardie/NumberGOup#63](https://github.com/paulhardie/NumberGOup/pull/63)). It carries milestone 3, not yet merged. The old game is commit `f4f1e95`; a `pre-rebuild` tag for it can be pushed from the Mac: `git tag -a pre-rebuild f4f1e95 -m "The game before the rebuild" && git push origin pre-rebuild`.

**The owner's play folder** follows `origin/main` once `tools/mac/install_sync.sh <folder>` has been run on the Mac (README, "Playing on the Mac"). It was tested on Linux with `launchctl` stubbed. Whether the owner has run it yet isn't known here.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **Next:** the owner's answer on Coins per kill (below), then milestone 4, The Tower's next groups, once the owner has played milestone 3.

## Where the game is

Milestone 3: home, battle and Workshop on Tier 1, saved between sessions. The owner played milestone 2 and merged it.

- **Home:** Battle, Workshop, best wave, runs and Coins.
- **Workshop:** Attack, Defense and Utility tabs. Permanent levels cost The Tower's Coin prices (30, 55… for Damage; 50 for the crit rows). Groups open in The Tower's order, one at a time per tab: Cash rows 40, Range and Damage / Meter 50, Defense % and Absolute 75, Coins rows 100, Multishot 400, Thorns 500. Later groups show "Coming soon" (`Workshop.BUILT_GROUPS`).
- **A run** starts from the Workshop's levels and sells its open groups for Cash, priced by the run's own purchases. Coins go into the Workshop as they're earned. An End run button ends a run early and keeps what it earned.
- **Battle rules added:** Defense % then Defense Absolute off each hit (can reach nothing); Thorns deals a share of the attacker's maximum health (half on a boss); Multishot fires the same shot at up to its targets' nearest enemies in range; Damage / Meter multiplies a hit by (1 + value × distance); Cash Bonus multiplies kill and wave Cash; Cash / Wave and Coins / Wave pay as a wave ends (Coins / Wave only once opened); Coins / Kill Bonus multiplies kill Coins.
- **Saving:** `user://number_go_up_tower.json`, version 1: Coins, levels, opened groups, best wave, runs. It saves after purchases, at a run's end, every 20 seconds of battle and on closing or losing focus. It's written to a temporary file and swapped in. A file that can't be read, or has another version, is moved aside as `.unreadable-<time>.json` and the game starts fresh. Damaged values are cleaned on load (negative Coins, levels past a row's end, unknown rows and groups). **A run in progress isn't saved**: closing mid-run keeps its Coins, but the run doesn't count towards runs or best wave.
- **Careers** (`tools/sim_runs.gd -- --careers 12`): a focused player reaches wave 22 on run 12 (1.3 hours), matching the owner's wave-22 time almost exactly. Spreading every Coin and Cash evenly stalls at waves 7–10. **Coins run about 14 times the owner's Tower figures** (decision 1).
- **Not played by the owner yet, not on a phone.**

## Open decisions for the owner

1. **Coins per kill: times the wave (D066, as built) or flat?** Measured on a 12-run career: times the wave, a wave-22 run earns 2,340 Coins; flat, about 280; the owner's Tower report is about 160 (1,460 at ×9). The owner's first Tower run (27 Coins over 8 waves at ×1) fits flat too. **Recommend flat:** one line in `battle_sim.gd` and a test, and the Workshop then paces like The Tower's.
2. **Lighter process while rebuilding** (REBUILD_SPEC, "Process while the rebuild is in progress"). **Recommend yes.** Milestone 3 touched saving, which the quality gates rate high risk and which calls for an independent review. It had a self-review against the gate and fixture tests, not a separate reviewer.
3. **AGENTS.md's architectural law 3** (the modifier pipeline) names code the rebuild removed. **Recommend** dropping it until a system needs stacked rules.

## Next steps, in order

1. **Owner:** answer decision 1, merge milestone 3, and play from a fresh save for a few runs. **Done when:** the owner says whether the Workshop feels like The Tower's early game.
2. **Agent: milestone 4, The Tower's next groups:** Free Upgrades (800), Rapid Fire (1,500), Lifesteal (2,000), Knockback and Interest (5,000), Bounce Shot (10,000), Orbs (15,000). Each is a mechanic, its tests, and its group added to `Workshop.BUILT_GROUPS`. **Done when:** each opens and works in battle, and the career tool shows them bought.
3. **Owner, when convenient:** a boss kill's Cash, a basic enemy's health from Wave Info past wave 22, and the enemy count at a known wave.

## How to measure

- **Ran on this branch (26 September, milestone 3):** `bash run_tests.sh` gives `PASS: tower tests (356 checks)`. The new checks cover Workshop prices and group order; a run starting from the Workshop; save round trip, no save, three unreadable saves (broken JSON, another version, not an object) kept aside whole, and a damaged save cleaned; Defense, Thorns, Multishot volleys, Damage / Meter, the Cash and Coin rows, ending a run; and the battle banking Coins once. The headless boot is clean. `tools/sim_runs.gd --careers 12` with `even` and `attack`, and (patched locally, not committed) with flat Coins for decision 1. `tools/capture_battle.gd` under xvfb: the home screen, the Workshop's Attack and Utility tabs, and battle moments were inspected.
- **Not run:** CI, a phone, a separate reviewer on the save code, the Mac editor with its old class cache (every script loads by path to avoid a blank window there, per `QUALITY_GATES.md`), and a real close of the window on macOS (the save on close is only read in the code).
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`.
- **Regenerating enemy data:** see the header of `tools/import_tower_enemies.mjs` (npm pack the SDK, `npm install --omit=dev` inside it, run the script). Never edit `data/tower/enemies.json` by hand.

## Known issues and risks

- **Enemy count per wave is a guess** (20 at wave 1, D065). The SDK says about 4, which the owner's screens contradict.
- **Enemy health past wave 22 is a guess:** the correction fitted to the owner's readings is held at wave 22's value beyond it, so health may run up to 10% high or low there.
- **The Tower's data is its own,** under the SDK's MIT licence: fine privately; publishing needs a decision.
- A shot whose target dies first is lost, and the tower doesn't avoid overkill. That's our reading of The Tower, not checked.
- Past wave 6,500 the enemy data holds its last value; generate more before a run can reach it.
- **Ranged enemies stop exactly at the base Range (30 m),** and in careers they end many runs. That's our guess (D067), not checked against The Tower.
- **The Workshop buys one level per tap;** The Tower has ×10 and Max buttons. Fine early, tedious later.
- **A run in progress isn't saved** (The Tower resumes one). Closing mid-run loses the run but not its Coins.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (D074 onwards), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, and push it.** Don't open or merge a PR unless the owner asks.
5. **Leave no scratch files** in the repository.

# Handover

**Last updated:** 26 September 2026 (milestone 4), by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, restarted from `main` after flat Coins merged ([paulhardie/NumberGOup#65](https://github.com/paulhardie/NumberGOup/pull/65)). It carries milestone 4, not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`**, the only project Godot's Project Manager knows. `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute; the old `ngu-autopull` job is disabled. There is no `~/Desktop/NumberGOup`.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **Next:** the owner plays milestone 4; then the pace question (Risks): why careers plateau at waves 19–28.

## Where the game is

Milestone 4: home, battle and Workshop on Tier 1, saved, with every Workshop group up to Orbs. The owner played milestone 3 and merged flat Coins (D074).

- **Workshop groups that open and work:** Range and Damage / Meter, Multishot, Rapid Fire, Bounce Shot (Attack); Defense % and Absolute, Thorns, Lifesteal, Knockback, Orbs (Defense); Cash rows, Coins rows, Free Upgrades, Interest (Utility). Super Crit and Death Defy show "Coming soon".
- **A run** starts from the Workshop's levels, with $0 Cash, and sells its open groups, priced by the run's own purchases. The upgrade panel scrolls at three rows. An End run button ends a run early.
- **Battle rules:** Defense % then Absolute; Thorns (half on bosses); Multishot; Damage / Meter; Rapid Fire (×4 fire rate for its duration, rolled per volley); Bounce Shot (first strike rolls, then nearest within range, up to its targets, never twice); Lifesteal (share of what strikes take off); Knockback (force × 5 m over mass, never past the spawn); Orbs (kill walking non-boss enemies within 3 m of one); Cash Bonus, Cash / Wave, Interest (cap $50), Coins / Kill Bonus, Coins / Wave, Free Upgrades (a random open row of the tab, per wave).
- **Pay:** a kill pays $1 plus $1 every ten waves times its type's Cash multiplier, and its type's Coins flat (D074).
- **Saving:** `user://number_go_up_tower.json`, version 1 (unchanged by milestone 4).
- **Careers** (`--careers 40 --buy attack`): wave 20 on run 18 (1.7 hours); Free Upgrades opened on run 35 and Rapid Fire on run 39 (about 6 hours). **Runs plateau at waves 19–28 from about 2 hours on**, most ended by ranged enemies.
- **Not played by the owner yet, not on a phone.**

## Open decisions for the owner

1. **Is the pace right?** Careers plateau at waves 19–28 from about 2 hours in. Community research says a new Tower player reaches wave 100 in about an hour (unverified). The likely causes are our guesses: 20 enemies at wave 1, a hit every 5 seconds, ranged enemies firing from exactly the base Range, and orbs too far out and too slow. **Recommend:** the owner reads, in The Tower, the enemies on screen at a known wave, how often an enemy at the tower hits, and where ranged enemies stop; then we replace those guesses before any tuning.
2. **Cheaper Workshop prices?** Answered: keep The Tower's (the owner, 26 September: "fair enough").
3. **Lighter process while rebuilding.** **Recommend yes.**
4. **AGENTS.md's architectural law 3** (the modifier pipeline) names removed code. **Recommend** dropping it until a system needs stacked rules.

## Next steps, in order

1. **Owner:** merge milestone 4 and play; read the three numbers in decision 1 from The Tower. **Done when:** they're in `src/tower/guesses.gd`.
2. **Agent: the pace pass.** Replace the guesses with the owner's readings, then measure careers against The Tower's early pace. **Done when:** a career's early hours match what the owner sees in The Tower.
3. **Agent, later:** Super Crit and Death Defy; multi-buy (×10, Max) in the Workshop; saving a run in progress.

## How to measure

- **Ran on this branch (26 September, milestone 4):** `bash run_tests.sh`: `PASS: tower tests (1281 checks)` (some new tests check every tick). New checks: Rapid Fire's rate and start; Bounce Shot to the nearest in range and not past it; Lifesteal's heal; Knockback by mass and never past the spawn; Interest and its cap; Free Upgrades' rows, count and cost; Orbs killing walkers but not bosses; Rapid Fire and Bounce Shot openable, Super Crit not. `--careers 40 --buy attack` and `--seeds 10 --buy even` (still wave 8). `capture_battle.gd` adds a strong tower (`battle_strong.png`).
- **Milestone 3's checks:** `bash run_tests.sh` gives `PASS: tower tests (356 checks)`. The new checks cover Workshop prices and group order; a run starting from the Workshop; save round trip, no save, three unreadable saves (broken JSON, another version, not an object) kept aside whole, and a damaged save cleaned; Defense, Thorns, Multishot volleys, Damage / Meter, the Cash and Coin rows, ending a run; and the battle banking Coins once. The headless boot is clean. `tools/sim_runs.gd --careers 12` with `even` and `attack`, and (patched locally, not committed) with flat Coins for decision 1. `tools/capture_battle.gd` under xvfb: the home screen, the Workshop's Attack and Utility tabs, and battle moments were inspected.
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

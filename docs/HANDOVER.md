# Handover

**Last updated:** 26 September 2026 (D075, the owner's timings), by Claude, handing on to the next agent.

**Branch:** `claude/great-tesla-9kfp95`, restarted from `main` after milestone 4 merged ([paulhardie/NumberGOup#66](https://github.com/paulhardie/NumberGOup/pull/66)). It carries D075, not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`**, the only project Godot's Project Manager knows. `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute; the old `ngu-autopull` job is disabled. There is no `~/Desktop/NumberGOup`.

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), [D073](DECISIONS.md#d073--rebuild-the-tower-first-the-number-second) and [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (its Progress, Milestones, Benchmarks and Guesses). Fetch and check the branch against `origin` before new work.
2. **Owner direction:** "go ahead with the rebuild". The Tower is the spec; copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each milestone before the next starts.
3. **Next:** the owner plays D075's rules; the open question is how a pack-free account paces (decision 1).

## Where the game is

Milestone 4: home, battle and Workshop on Tier 1, saved, with every Workshop group up to Orbs. The owner played milestone 3 and merged flat Coins (D074).

- **Workshop groups that open and work:** Range and Damage / Meter, Multishot, Rapid Fire, Bounce Shot (Attack); Defense % and Absolute, Thorns, Lifesteal, Knockback, Orbs (Defense); Cash rows, Coins rows, Free Upgrades, Interest (Utility). Super Crit and Death Defy show "Coming soon".
- **A run** starts from the Workshop's levels, with $0 Cash, and sells its open groups, priced by the run's own purchases. The upgrade panel scrolls at three rows. An End run button ends a run early.
- **Battle rules:** Defense % then Absolute; Thorns (half on bosses); Multishot; Damage / Meter; Rapid Fire (×4 fire rate for its duration, rolled per volley); Bounce Shot (first strike rolls, then nearest within range, up to its targets, never twice); Lifesteal (share of what strikes take off); Knockback (force × 5 m over mass, never past the spawn); Orbs (kill walking non-boss enemies within 3 m of one); Cash Bonus, Cash / Wave, Interest (cap $50), Coins / Kill Bonus, Coins / Wave, Free Upgrades (a random open row of the tab, per wave).
- **Pay:** a kill pays $1 plus $1 every ten waves times its type's Cash multiplier, and its type's Coins flat (D074).
- **Saving:** `user://number_go_up_tower.json`, version 1 (unchanged by milestone 4).
- **The owner's timings (D075):** 11 enemies in wave 1, an enemy in place hits once a second, ranged enemies and orbs sit on the Range edge, and orbs turn once a second at their first level.
- **Careers** (`--careers N --buy core`, a focused player): the wave 10 boss holds until about run 13 (1.3 hours), then wave 20–21 until about 5½ hours. With the owner's ×9 pack Coins the same career reaches wave 21 on run 3 (about 25 minutes), close to the owner's own Tower save. Boss waves are the walls.
- **Not played by the owner yet, not on a phone.**

## Open decisions for the owner

1. **How should a pack-free account pace?** Under D075, a focused pack-free career spends about 1.3 hours at the wave 10 boss and about 5½ hours reaching wave 30. With ×9 Coins it matches the owner's own account. The "wave 100 in an hour" research is unverified. **Recommend** keeping The Tower's rules and deciding the target by playing: if the first hours feel slow without packs, the lever is Coins per kill or Coins / Wave, not the enemy rules.
2. **Cheaper Workshop prices?** Answered: keep The Tower's (the owner, 26 September: "fair enough").
3. **Lighter process while rebuilding.** **Recommend yes.**
4. **AGENTS.md's architectural law 3** (the modifier pipeline) names removed code. **Recommend** dropping it until a system needs stacked rules.

## Next steps, in order

1. **Owner:** merge D075 and play; say whether the first hour feels right (decision 1).
2. **Agent: the next piece of the plan:** multi-buy (×10, Max) in the Workshop and the run, saving a run in progress, then Super Crit and Death Defy. Or the Number (milestone 5, REBUILD_SPEC), once the owner picks A, B or C.

## How to measure

- **Ran on this branch (26 September, D075):** `bash run_tests.sh`: `PASS: tower tests (1290 checks)`; new checks cover orbs on the Range edge at a turn a second, one orb sweeping a ranged enemy off the edge within a second, ranged enemies stopping on the edge as Range grows, and a hit a second. `sim_runs.gd` with `none`, `even`, `attack` and the new `core`, and careers with `attack` and `core`, plus two measurements patched locally and not committed (no per-hit heat-up; ×9 Coins). The strong-tower capture shows the orbs on the range circle.
- **Milestone 4's checks:** `bash run_tests.sh`: `PASS: tower tests (1281 checks)` (some new tests check every tick). New checks: Rapid Fire's rate and start; Bounce Shot to the nearest in range and not past it; Lifesteal's heal; Knockback by mass and never past the spawn; Interest and its cap; Free Upgrades' rows, count and cost; Orbs killing walkers but not bosses; Rapid Fire and Bounce Shot openable, Super Crit not. `--careers 40 --buy attack` and `--seeds 10 --buy even` (still wave 8). `capture_battle.gd` adds a strong tower (`battle_strong.png`).
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
- **Boss waves are the walls:** careers end on or just after every tenth wave. That's The Tower's design (bosses are walls, D063), but worth watching in play.
- **The Workshop buys one level per tap;** The Tower has ×10 and Max buttons. Fine early, tedious later.
- **A run in progress isn't saved** (The Tower resumes one). Closing mid-run loses the run but not its Coins.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (D074 onwards), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, and push it.** Don't open or merge a PR unless the owner asks.
5. **Leave no scratch files** in the repository.

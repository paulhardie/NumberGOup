# Balance comparisons (D150)

The simulator already runs the real `BattleSim` and existing bot buying policies. This harness adds structured measurements and a committed baseline so a change can be reviewed before its new pace is accepted. It changes no gameplay, prices, combat contract, save schema or public version.

## Commands

Run from the checkout, with Python 3.9+ and the Godot used by `run_godot.sh`:

```bash
python3 tools/balance_report.py compare
python3 tools/balance_report.py compare --suite full
```

The default is `quick`, comparing against `data/balance/quick.json`; `full` uses `data/balance/full.json`. Both write `/tmp/ngu-balance-current.json` and `/tmp/ngu-balance-report.md`. Use `--output PATH` and `--report PATH` for different destinations. The report includes the baseline and current commit, dirty-worktree flag, source digest, engine, scenario definitions, medians, ranges, outcome counts and per-seed differences. The JSON preserves per-run values, starting builds, milestone times, damage/loss sources and stopping reasons. It contains no player save or machine-specific measurement paths.

Every Godot process goes through `run_godot.sh` and uses scratch storage. The harness neither loads real progress nor writes a player save. It refuses measurements if simulation/reporting sources change during a run.

## Coverage and limits

**Since D158 every scenario plays the game's rules** (`GAME_RULES` in `tools/balance_report.py`: the Number as Cash, the held Lock, and bots that keep half their best Number in reserve), so the baseline measures the game as it is played. The bots' reserve is a stand-in for a player's feel for what is safe to spend; the criteria in THE_NUMBER.md 13.2 show the verdicts don't depend on it. A baseline recorded before D158 fails validation ("Scenario definitions changed") until re-recorded.

| Suite | Scenarios |
|---|---|
| Quick (every PR) | Fresh no-buy, even and core: 20 seeds each. Four 10K-Coin Workshop plans: 4 seeds each. One 50-run core career. Uniform-level-20 Tier 2/3 smoke measurements: 2 seeds each, to wave 100 or 10 game minutes. |
| Full (manual) | Quick plus four 100K-Coin plans, 70-run grow/even careers, and every drawable card alone at level 7 on the three D149 builds: 2K core, 4K turtle and 40K core, 10 seeds each. |

Single-run earning rates are battle Coins per game hour; career totals also include the welcome and one-time milestone Coins. Career milestone times include previous runs plus the actual tick reaching the target, not the later death. Fixed buying policies skip redundant purchase checks only while Cash and wave are unchanged (automatic Free Upgrades occur at wave boundaries); Health and survival policies still check every tick. `sim_runs.gd -- --uncached-buys` retains the original checking frequency for parity measurements. Buying choices and timing are unchanged. Spending policy and seed choices are fixed in `tools/balance_report.py`. These are deterministic bots, not an estimate of human play, real wall-clock progression, a stochastic card-acquisition career, or a proof of fun.

Median means the **upper middle sample** for an even cohort, matching `sim_runs.gd` and the existing card readings. The per-seed table catches changes an unchanged median can hide. Comparisons tolerate numeric differences of 1e-9 relative or 1e-8 absolute to avoid insignificant floating-point noise. New/removed samples and changed starting builds are explicitly reported.

Death, time cap, wave target and data horizon are separate outcomes. A stopped run is a lower-bound observation of survival, never a death. Aggregate tables include stopped runs with outcome counts shown; do not interpret those medians as death waves. Card-floor and build-order checks are inconclusive when their needed samples are censored.

Tier smoke scenarios do not prove D149's turtle-to-blender pivot. A Tier 2 build comparison (TOWER_TIERS.md, "The Tier 2 pivot test") found the turtle ahead until a blender buys all four orbs and Range to the orb line (`blender_orbline`). That blender passes the turtle from about 5M Coins. It isn't part of these suites. Extra career seed sequences, card pairs, Labs, weapons, player checks and late-game performance measurements remain additions when their features/decisions need them. Full measurements can take several minutes; each scenario has a 15-real-minute timeout. There is no automatic periodic run.

## Three separate outcomes

1. **Execution and validity:** runtime/script errors, missing or duplicated samples, invalid/non-finite values, incorrect milestone times and mismatched scenario definitions fail with exit **2**. No new baseline is written after a failed capture.
2. **Impact:** a valid comparison exits **0**, including intentional balance movement. It shows changes rather than automatically approving them. `--fail-on-change` opts into exit **1** for any paired movement or added/removed sample, useful for a change intended to preserve balance exactly. It is not a design-approval gate.
3. **Design expectations:** the report explicitly marks the early no-buy benchmark, D149 Tier 1 turtle ordering and the full suite's level-7 card floor as MEETS, FAIL or INCONCLUSIVE. Quick reports the card floor as NOT MEASURED and names the six documented known failures. Full measures them afresh; a known failure is still FAIL, not grandfathered into acceptable balance. Coins is judged on a positive median Coin gain; other cards need at least one median wave on one of the three builds. These findings do not change the process exit status.

A green CI run proves the measurements ran and were valid. **It does not sign off balance.** Review the job summary and uploaded JSON/Markdown. CI runs Quick on PRs/pushes; a manually dispatched Verify workflow with `balance_suite=full` also runs Full. The existing required check name stays unchanged.

## Reviewing and updating a baseline

1. Run the comparison, inspect per-seed changes, stopped runs, career milestones and design findings. Keep accepted design intent in DECISIONS; baseline data is an observation, not intent.
2. After the owner accepts an intended balance change, regenerate only the affected suite explicitly:

```bash
python3 tools/balance_report.py record --suite quick --replace
python3 tools/balance_report.py record --suite full --replace
```

3. Commit the regenerated data with the reason and relevant before/after evidence. Do not hand-edit measurements or overwrite a baseline to make a failure disappear. `record` refuses an existing baseline unless `--replace` is supplied. Comparison never edits its baseline. `--baseline PATH` supports a separate reference file; baseline/current/report paths must differ.

The first baseline was captured with reporting changes in a dirty worktree based on `4989a44`; this is recorded honestly in its provenance. Game combat and progression sources remain unchanged. Old-baseline/new-code comparisons always run the current simulator against historical measurements; they do not recreate the historical executable. Engine/platform differences can affect seeded results and must be reviewed rather than explained away.

## Verification contracts

`bash run_tests.sh` also runs the Python reporting tests. They exercise changed per-seed results under unchanged medians, censoring, card floors, new/removed card samples, malformed output, scenario mismatches, career times, explicit replacement and exit codes. The regular battle/foundation suites retain ownership of saves, deterministic combat and reward correctness.

`sim_runs.gd -- --json-out PATH` writes the structured measurements alongside its existing console text. The harness checks process status **and** runtime error lines, because Godot can print an error while returning zero. The ordinary simulator remains a measurement tool; callers outside this harness must still check its diagnostics.

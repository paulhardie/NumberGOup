# Handover

**Last updated:** 3 October 2026, by Claude Code.
- Base `main` is `a58eeec` (PR #146, the Tier 2 pivot tests). It includes D149, the Tier research and D150's balance harness.
- Branch `claude/number-capital-candidate` carries D151, the Number-as-capital candidate (measuring options, off by default) and its trial tool. It changes no game behaviour or save format, and the public version stays 0.9. None of it is in the play folder until the owner merges its pull request; the play folder follows `origin/main` through `com.paulhardie.ngu-sync`.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. The next free ID is **D152**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth. It is still only a health pool (THE_NUMBER.md section 9).
- **Cards (D146, D147):** they open at Tier 1 wave 20. Eleven of The Tower's cards are built, and save version 3 holds the collection. Nine measure-only candidates (Slow Aura, Critical Coin, Compound, Remainder, Unequal, Interest, Factor, Berserker, Super Tower) are never drawn.
- **What the card tests found** (CARDS.md): Tier 1's walls are its boss waves and only killing power moves them. Super Tower works (D148). Berserker does nothing at The Tower's numbers, and at about 30 times its share a tank build wins.

## The Number (D151, 3 October 2026): being tried

The owner chose to try the Number as the player's capital: the hit of watching it rise and being protective of it. The Tower's shape no longer binds the work, recovery is behind Labs and weak at the start, and every threat is meant to be solved with stats. D151 has the owner's words, and THE_NUMBER.md section 10 has the design, the options, **the six pass criteria written before the candidate existed**, and the results.

- **Built (measure-only):** `--thieves` (a Divider carries its bite away instead of being used up), `--thief-recovery` (damage dealt to it pays the bite back, standing in for Labs), `--thief-speed`, `--thief-fade`, `--thief-priority` and `--number-power` (the Number multiplies the tower's shots). Off by default and recorded only while on, so every run, report and snapshot made without them is byte for byte what it was. `tools/number_trial.py` measures one configuration against the criteria.
- **Interim results (partial, not a verdict):**
  - The power coupling is a very strong lever even at the grid's smallest value (core at 10K Coins goes from wave 31 to 51 at 0.2).
  - **Thefts are rare for a competent build** (0 to 2 a run for the core build, since nearly every Divider is killed before it lands), so the problem is not real for it and nothing on the declared grid changes that.
  - A recovery over 1 turns a thief into a gift: the turtle at 100K does better with thieves than with no Dividers.
  - The centre of the grid and `number_power` 0.1 fail criteria 2 and 6. The career, fresh runs and card sweeps have not run.
- **Not yet done:** the other six single variations, the slow phase for the best configurations, and labelled exploratory runs with more Dividers (outside the grid, so they can't count as a pass).

## Balance and the baseline (D149, D150)

- **"Balanced" (D149):** Tier 1 keeps The Tower's shape until the owner adopts a candidate, and every drawable card meets a floor. Six of the eleven built cards fail it: Health, Health Regen, Range, Critical Chance, Extra Defense and Free Upgrades.
- **The baseline is bots, not players** (`data/balance/`). `python3 tools/balance_report.py compare` writes a before/after report, `--suite full` adds the card floor and broader careers ([BALANCE_TESTS.md](BALANCE_TESTS.md)). A green run means valid measurements, not balance sign-off.

## Checked, and not checked (this branch)

- **Checked:** `bash run_tests.sh` passed on the candidate: 4,773 tower checks (41 new), 262 foundation checks (19 new) and the Python reporting and criteria tests, exit 0. The new checks cover the carry-off, proportional payback, recoveries of 0, 0.5 and 1.5, escape and fade, the Wall, targeting priority, no push on a thief, the power coupling, option validation, and a snapshot and replay with a thief mid-flight. The headless project boot passed.
- **Not checked:** that default play is unchanged against the committed baseline (a `compare` run is pending; the code paths are guarded so defaults take the old branch). Players, Tier 2 and 3, Lifesteal, and any screen for thieves.

## Open decisions for the owner

1. **Once the trial's verdict is in: adopt, change or drop the candidate.** It will come with a recommendation. The interim finding is that Dividers rarely land, so a thief problem needs a stronger or more frequent threat than D083's gentle Divider, which the owner would have to change.
2. **Which cards to make drawable next?** Factor, Super Tower and a rescaled Berserker are the candidates in CARDS.md. Park the rest.
3. **Changing cards mid-run:** I'd still keep them fixed for the run.
4. **Still open from before:** play the D145 enemies and the Lock; sign off 1.0; the D131 digit rewards; the speed switch; the Mac sync waiting on a saved battle; the AGENTS.md modifier-law wording; publishing Tower-derived data.

## Next steps, in order

1. **Agent:** finish the trial: the remaining variations, the slow phase and the labelled exploratory runs, then report the verdict against the written criteria.
2. **Owner:** read the verdict and decide (open decision 1). If the idea stands, Labs (1.2) get their first entries from it.
3. **Owner:** sequence the six card failures and the next drawable cards (open decision 2).

## Known issues and limits

- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

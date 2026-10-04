# Handover

**Last updated:** 4 October 2026, by Claude Code.
- Base `main` is `5513c27`, including D150's balance harness (PR #143), the Tier research (PRs #144 to #146), D151, menus and pop-ups (PR #147), [PR #148](https://github.com/paulhardie/NumberGOup/pull/148) (D152, the Number-as-capital candidate: measuring options, off by default, and its trial tool) [PR #149](https://github.com/paulhardie/NumberGOup/pull/149) (the trial's results, THE_NUMBER.md 10.5, and D152's outcome) and PR #150 (a handover fix). None of it changes game behaviour or a save format, and the public version stays 0.9.
- Branch `claude/number-first-design` carries D153 and its design note (THE_NUMBER.md section 11), documents only, in its own pull request. The play folder follows `origin/main` through `com.paulhardie.ngu-sync`; none of this changes what you play.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. The next free ID is **D154**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth. It is still only a health pool in the game (THE_NUMBER.md section 9). Section 10 tried a fix; section 11 is the new direction (D153).
- **Enemies:** the five base enemies read as ours (D145).
- **Cards (D146, D147):** they open at Tier 1 wave 20 (the dock shows them then, and the run pays 10 Gems). Eleven of The Tower's cards are built, laid out as a grid with a card's details on tap, and save version 3 holds the collection.
- **Menus and pop-ups (D151):** every pop-up is one `Overlay` (a SHEET over a shade, or a BANNER under the top bar), and holding a Workshop row, the next unlock or a run's upgrade tile reads it while a tap still buys. [UI_POPUPS.md](UI_POPUPS.md) has the rules, what exists and where else we should.
- **Candidates:** nine measure-only cards (Slow Aura, Critical Coin, Compound, Remainder, Unequal, Interest, Factor, Berserker and Super Tower) can be equipped in `sim_runs.gd` and are never drawn.
- **What the card tests found** (CARDS.md): Tier 1's walls are its boss waves and only killing power moves them. Super Tower works (D148). Berserker does nothing at The Tower's numbers, and at about 30 times its share a tank build wins.

## The Number is the goal (D153, 4 October 2026): designed, not built

The owner decided the Number is what the player plays for and waves are the test, and sketched the core: shots cost Number, Regen earns it back, and the first barrier is earning more than you spend. [THE_NUMBER.md section 11](THE_NUMBER.md#11-the-number-is-the-goal-4-october-2026-d153-design-note) is the design note. Everything in it beyond the goal and the sketch is a proposal:
- **Shots priced per damage dealt (B), not per shot (A),** so every enemy and boss has a price in Number and the Number's size decides the wall; recommended, the owner's call.
- **The run's arc:** survive, sustain (a net-rate readout under the Number), grow, then hit the wall where prices outgrow income. The peak is the score.
- **The best Number is the record, Coins come from the run's peak, and digits open systems**, set by measurement so play time to Cards, Labs and Tier 2 stays about where it is.
- **The Workshop's rows each get a job:** Health becomes Starting Number, Coins / Kill becomes Bounty, the crit rows and a new Efficiency row stretch each Number, and free killers pay for their damage.
- **Pacing:** growth compounds where it's earned and every run peaks; no interest on the Number (D110's guard stays), and a new digit pace in play time for the owner to set.
- **Proof in stages, measure-only first,** with draft criteria to agree before anything is built (11.12).

## The Number as capital (D152, 3 October 2026): tried, and the declared candidate failed

The owner chose to try the Number as the player's capital: the hit of watching it rise and being protective of it. The Tower's shape no longer binds the work, recovery is behind Labs and weak at the start, and every threat is meant to be solved with stats. D152 has the owner's words, and THE_NUMBER.md section 10 has the design, the options, **the six pass criteria written before the candidate existed**, and the results.

- **Built (measure-only):** `--thieves` (a Divider carries its bite away instead of being used up), `--thief-recovery` (damage dealt to it pays the bite back, standing in for Labs), `--thief-speed`, `--thief-fade`, `--thief-priority` and `--number-power` (the Number multiplies the tower's shots). Off by default and recorded only while on, so every run, report and snapshot made without them is byte for byte what it was. `tools/number_trial.py` measures one configuration against the criteria.
- **Verdict: the declared candidate fails, and no configuration on its grid can pass** (THE_NUMBER.md 10.5, with every run reported; criteria 2 and 6 are measured across all 96 configurations, through the 48 that can change the core build at 10K):
  - **The coupling works and is far too strong.** The Number decides waves (removing the power costs 5 to 50), the early game holds, and the Health card finally earns its place (up to 10 waves). But even the grid's lowest power breaks the pace: the career first reaches wave 31 on run 29 (0.1) or 16 (0.2), against 47 and a window of 35 to 60.
  - **Thieves aren't a problem at Tier 1's Divider.** The core build is robbed at most twice a run and loses nothing, because nearly every Divider dies before it lands. Nothing on the grid changes that.
  - **A harsher Divider (exploratory, outside the grid) makes the problem real and solvable:** with 3 times as many, ÷2 and 8 times the health, thieves cost the core build 8 waves and the turtle 14 at 10K Coins.
  - **A recovery over 1 with the coupling is a Number printer** (D037's loop through recovery): the turtle at 100K never dies, hitting the 3-hour cap at wave 309 with a Number in the trillions.
  - **C2's wording lets a runaway count as "solved"** (a negative cost passes). The rules stopped me changing it after the results; the next round should bound it from below.
- **Four review findings were fixed on the way** (a thief didn't take Thorns on its grab; criterion 1 judged too loosely; the Damage card's ratio wasn't reported; an exploratory run could report a pass). The first round's numbers were void and the results above are from the re-run.

## Balance and the baseline (D149, D150)

- **"Balanced" (D149):** Tier 1 keeps The Tower's shape until the owner adopts a candidate, and every drawable card meets a floor. Six of the eleven built cards fail it: Health, Health Regen, Range, Critical Chance, Extra Defense and Free Upgrades.
- **The baseline is bots, not players** (`data/balance/`). `python3 tools/balance_report.py compare` writes a before/after report, `--suite full` adds the card floor and broader careers ([BALANCE_TESTS.md](BALANCE_TESTS.md)). A green run means valid measurements, not balance sign-off. D150's evidence is in PR #143 and BALANCE_TESTS.md.

## Checked, and not checked

- **Checked, on the code now in `main`:** `bash run_tests.sh` passes: 4,778 tower checks (46 new in PR #148), 331 foundation checks (19 new, on top of D151's 312) and 26 Python tests (the criteria's own 11 included), exit 0. GitHub's CI passed on the PR. The trial's results were measured on that exact code, and PR #149 changed documents only. The headless boot is clean. The checks cover the carry-off, Thorns on the grab, proportional payback, recoveries of 0, 0.5 and 1.5, escape and fade, the Wall, targeting priority, no push on a thief, the power coupling, option validation, and a snapshot and replay with a thief mid-flight.
- **Checked, D151 (PR #147):** merged. Its evidence is in the PR, and its checks are in the suites above.
- **D153's design note** is documents only: nothing ran for it. Its worked example (11.4) uses the owner's screens' enemy stats and guessed prices, not measurements.
- **Not checked:** a phone, or a real finger, for the pop-ups. Players, whether any of the Number's design is fun, Tier 2 and 3, Lifesteal, the Labs' cost, and any screen for thieves. The budget scenarios have 4 seeds.

## Open decisions for the owner

1. **The Number-first design (THE_NUMBER.md 11.11):** the questions that decide the first build.
   - **Shots: a price per damage dealt (B) or a fixed price per shot (A)?** I'd choose **B**, because it's the only one where the Number's size decides the boss wall and the economy never quietly solves itself. Trade-off: one new stat (Efficiency) to explain.
   - **When broke: the tower goes quiet, or fires a free weak shot?** I'd go quiet, never below 1.
   - **Orbs, Thorns and Mines pay for their damage like shots?** I'd say yes, so nothing prints Number for free.
   - **Keep Cash for run upgrades in v1?** I'd keep it; one big change at a time.
   - **The pace of new digits,** early and late (proposal in 11.8).
2. **Pop-ups (D151):** does holding stay, and what next? I'd keep it and add **a one-line hint that holding reads** (nothing tells a player today), then **hold the daily Gems pill** (its tooltip never shows on a phone). Two are yours: **a confirm on End run** (it ends a run on one tap; a confirm adds a tap at ×5) and **moving the run-over panel onto a sheet** (it shades the arena). UI_POPUPS.md section 3 has the rest.
3. **Which cards to make drawable next?** Factor, Super Tower and a rescaled Berserker are the candidates in CARDS.md. Park the rest.
4. **Changing cards mid-run:** I'd still keep them fixed for the run.
5. **Still open from before:** play the D145 enemies and the Lock; sign off 1.0; the D131 digit rewards; the speed switch; the Mac sync waiting on a saved battle; the AGENTS.md modifier-law wording; publishing Tower-derived data.

## Next steps, in order

1. **Owner:** answer open decision 1, at least shot pricing (A or B). That unlocks the first stage.
2. **Agent, on a yes:** write the stage-1 criteria into THE_NUMBER.md first (from the draft in 11.12), then build the fuel economy as off-by-default measuring options with `sim_runs.gd` and `number_trial.py` support, and report every run.
3. **Owner:** **play a run holding tiles on a phone**: it is the one check on the pop-ups that couldn't be made, and it settles the hold's timing.

## Known issues and limits

- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **Nothing tells a player that holding reads** (D151), and the daily pill's explanation is a hover tooltip, which a phone never shows.
- **The run-over panel isn't on `Overlay`:** it doesn't shade the arena like every other panel.
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

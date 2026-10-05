# Handover

**Last updated:** 5 October 2026, by Claude Code.
- Base `main` is `827e14c`: D150's balance harness, the Tier research, D151's menus and pop-ups, D152's capital trial (failed), D153's design note, D154 (tanks keep their weight, the Number in full to a trillion), D155 (the fuel economy measured, every configuration failed), D156 and D157 (the Number as Cash and the held Lock, first behind a Testing switch the owner played) and the Number names (PR #159). The public version stays 0.9.
- Branch `claude/number-is-cash` carries **D158, which changes the game: the Number is Cash for every new run**, with the independent review's fixes, the balance harness playing the game's rules and **re-recorded baselines**. The play folder follows `origin/main` through `com.paulhardie.ngu-sync`, so none of it is in the game until its pull request merges.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. The next free ID is **D159**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower and the run's money (D156, D157, D158).** Kills and each wave's end pay into it; a run's upgrades are bought with it (never below 1); Regen and Lifesteal refill only what enemies took; Health is a Workshop row only (the Number a run starts with); Interest is on the Number, capped as before; free levels don't raise prices. A Lock (from wave 35) holds the Number's growth and the income it blocks, and pays it all when the last Lock dies. **Run upgrades off** in Settings shuts the run shop for the next run. Cash is gone from a new run's screens; the Workshop's Cash rows and the Cash card read as the Number's. THE_NUMBER.md sections 13 and 14 have the rules, criteria and results.
- **A run begun before D158 plays its Cash rules to the end,** with its own words and Cash chip. The game's rules are `RunConfig.game_tuning()`; the code's own defaults stay off, so old saves, reports and the tools that don't ask replay exactly. There is no combat-rules version bump, deliberately (THE_NUMBER.md 14.2).
- **Tanks keep their weight (D154)** and **the Number is written in full to a trillion (D154).**
- **Enemies:** the five base enemies read as ours (D145). Under the new rules overall difficulty is unchanged, but **Dividers punish banking, not playing** and **the Lock holds a slow build's income** (13.4, 13.5).
- **Cards (D146, D147):** they open at Tier 1 wave 20. Eleven of The Tower's cards are built; the Cash card reads as **Number Income**.
- **Menus and pop-ups (D151):** every pop-up is one `Overlay`; holding a Workshop row, the next unlock or a run's upgrade tile reads it. [UI_POPUPS.md](UI_POPUPS.md).
- **Candidates:** nine measure-only cards can be equipped in `sim_runs.gd` and are never drawn. **What the card tests found** (CARDS.md): Tier 1's walls are its boss waves and only killing power moves them.

## The Number is Cash (D156 to D158, 4 to 5 October 2026): the game

After stage 1 failed (below) the owner chose to make the Number the run's Cash as well as its life, keep Coins for the Workshop, aim for players strong enough not to need run upgrades, and allow switching the run shop off before a run. It was built as measuring options and played behind a Testing switch ("way better … I need to sort this friction out so I can keep climbing"; early on a bit harder than The Tower, "but that's fine"; seeing Cash / Wave and Coins / Wave feed the Number at a wave's end feels good), then made the game (D158, "merged and proceed").
- **Measured (13.3):** the same waves as Cash at 10K and 100K, no runaway, maxed Interest 15% of income. **Two criteria failed with nothing broken:** the run shop never stops mattering (it adds 25 to 37% of a run's waves even at 1M Coins), and a bot that buys keeps its Number at a fifth to a quarter of today's peak. With the shop shut the Number climbs higher and the run ends sooner: **a fork between going far and going big**.
- **The Lock (13.5):** core and blender lose 0 to 3% of income to Locks (from up to 16%); **the Thorns turtle still loses 19.5% at 100K and 43% at 1M**, because Thorns can't hurt a Lock (D133).
- **The independent review of D158 (QUALITY_GATES)** found no defect in saves, replays or determinism, and four real things, all fixed here: the committed baselines no longer matched the harness (re-recorded), the run-over panel showed a dead "Kills grew the Number by 0" line, a kill under a standing Lock popped "+N" while the Cash was held (it now says "held"), and a saved Number-as-Cash block could restore without its rules (now rejected). It also surfaced the milestone and Recovery Packages findings in the open decisions below.

## Stage 1, the fuel economy (D155, 4 October 2026): measured, and a fixed price fails

The owner said "go" to stage 1 with its six draft criteria plus a Multishot runaway check. THE_NUMBER.md section 12 has the options, the criteria (committed before the options existed), the configurations and **the results (12.6)**:
- **Built, measure-only:** `shot_price`, `bounty_share`, `free_bounty_share`, `base_regen`, `regen_scale` and `hold_doomed` in `BattleSim`, off by default and recorded only while on, with a per-wave ledger; `sim_runs.gd` flags for each, `--knockback off`, `--row-levels` and a `multishot` plan; `tools/fuel_trial.py` measures the criteria.
- **Verdict: every configuration fails, the centre and all five grid configurations.** C1 (the Number decides the run), C2 (the sustain barrier) and C3 (runs have an arc) fail; C4 (no runaway), C5 (the early game) and C6 (the stats matter) pass.
- **Why:** by 10K Coins the Health row starts the Number in the hundreds, so a 1-Number shot is noise (free shots add 0 waves in seven of eight builds). A higher fixed price (3, 5, 10, exploratory) kills fresh towers on wave 1 before it bites the middle: **inside Tier 1 the Number spans 5 to thousands, and no fixed price fits both ends.** Runs end at a wall of hits, not a drain, so the arc doesn't form. The opening can't grow the Number at all: a wave-1 kill pays 0.3 for a 1-Number shot, and Regen only refills to the best.
- **No runaway:** nothing reached the cap, Multishot included, and no printer appeared. Regen, Starting Number and Bounty each lift the peak (+88%, +88%, +17%).
- **My proposal, the owner's call:** a price per wave, as a share of that wave's enemy Attack (12.6), measured against the same criteria.

## The Number is the goal (D153, 4 October 2026): the design note, partly built as D156 to D158

The fixed shot price in this note failed (above); what survives is Cash as the Number, the Workshop rows' jobs and the pacing ideas, still proposals.

The owner decided the Number is what the player plays for and waves are the test, and sketched the core: shots cost Number, Regen earns it back, and the first barrier is earning more than you spend. [THE_NUMBER.md section 11](THE_NUMBER.md#11-the-number-is-the-goal-4-october-2026-d153-design-note) is the design note. Everything in it beyond the goal and the sketch is a proposal:
- **Every shot costs a fixed price: 1 Number in Tier 1** (the owner's choice, over a price per damage; stage 1 found a fixed price can't fit Tier 1, above). Damage and anything that multiplies a shot (crits, Multishot, bounces) make each Number go further; Attack Speed spends faster. A boss's price is the shots it takes, and falls as you upgrade.
- **Each tier sets the Number's demands** (the owner): its shot price rises, so every tier re-opens the sustain barrier. The tier is the overall difficulty dial.
- **The run's arc:** survive, sustain (a net-rate readout under the Number), grow, then hit the wall where prices outgrow income. The peak is the score.
- **The best Number is the record, Coins come from the run's peak, and digits open systems**, set by measurement so play time to Cards, Labs and Tier 2 stays about where it is.
- **The Workshop's rows each get a job:** Health becomes Starting Number, Coins / Kill becomes Bounty, Damage and the shot-multiplying rows are the efficiency (no new stat), and kills by Orbs, Thorns and Mines pay no bounty.
- **Pacing (11.15):** the owner wants Tier 1 in the billions only deep into a run and the trillions practically never, with later tiers' multipliers making it run away. A one-shot-everything model puts a quarter-share bounty at 1,000 by wave 32, 1,000,000 by 213, a billion about 1,025 and no trillion within 3,000 waves, so The Tower's own curve does the pacing.
- **The Number to beat Tier 1: 1,000,000** (proposed), with Cards at 1,000 and Labs at 10,000; stage 1 calibrates the bounty so the play time to each lands near The Tower's (waves 20, 30 and 100).
- **Starting Regen 1 a second is accepted** (shots free at the start). 11.15 lists the rest of the very early game: rescale the Regen row, show tenths early, hold fire on enemies already doomed by shots in flight, pay for any shot kill, and calibrate first-run Coins.
- **Proof in stages, measure-only first,** with draft criteria to agree before anything is built (11.13).

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

- **"Balanced" (D149):** every drawable card meets a floor. Under today's rules six of the eleven built cards failed it; **under the game's rules (D158) four now meet it (Extra Defense, Free Upgrades, Range, and Health by one wave in one build) and Critical Chance and Health Regen still fail** (THE_NUMBER.md 14.3).
- **Since D158 the harness plays the game's rules** (`GAME_RULES` in `tools/balance_report.py`: the Number as Cash, the held Lock, and bots keeping half their best Number in reserve), and the committed baselines are measured under them. A baseline from before D158 doesn't validate against it.
- **The baseline is bots, not players** (`data/balance/`). `python3 tools/balance_report.py compare` writes a before/after report, `--suite full` adds the card floor and broader careers ([BALANCE_TESTS.md](BALANCE_TESTS.md)). A green run means valid measurements, not balance sign-off. D150's evidence is in PR #143 and BALANCE_TESTS.md.

## Checked, and not checked

- **Checked, D158 (this branch):** `bash run_tests.sh` passes (see the pull request for the final counts): boundary and repeated-action tests for the rules, a run begun under each rule set saved and resumed from a snapshot and from a replay (words, chip and shop follow the run), the game starting every run under its rules with Run upgrades off read as a run starts, the settings file from the Testing-switch period, a malformed value, the snapshot tie, the kill pop-up and the run-over panel. The headless boot is clean, the capture tool runs and its Settings and battle screenshots were inspected, the balance harness measured the game's rules on the committed code, and an independent adversarial review of the diff ran (QUALITY_GATES).
- **Not checked, D158:** a player on the final build, a phone, Tier 2 and 3 under the new rules, the Cards screen by eye, and a frozen byte fixture of a pre-D158 save (old-save equivalence holds by construction, since no simulator or snapshot code changed for old runs, and is tested with runs generated from today's code; `tools/check_migration.gd` checks a real save copy).
- **Checked, D156 and D157 (merged):** their tests, the 13.3 to 13.5 measurements on the committed options, and screenshots.
- **Checked, D155 (PR #155, merged):** `bash run_tests.sh` passes: 4,808 tower checks (28 new: the options off and unrecorded by default, a shot's price, the broke rule, Multishot copies free, bounties for shots, free killers, Dividers and under a Lock, Coins / Kill raising it, holding fire, and the ledger adding up to the Number's change), 346 foundation checks (15 new: validation, a snapshot round trip and replay with the ledger) and 36 Python tests (10 new for the criteria's own code), exit 0. The quick balance comparison against a fresh baseline shows the game unchanged. Every result in THE_NUMBER.md 12.6 was measured on the committed options.
- **The balance baselines PR #154 committed were stale.** Both files held the pre-D154 measurements (the 100K spread build still at 66 rather than 63; Tier 3's peaks unchanged), although the recorder measures fresh every time; I couldn't find why that one recording run measured the old behaviour. This branch re-records both from a clean worktree of the committed code, and the full suite equals PR #154's own D154 measurement scenario for scenario. **Merging accepts them.**
- **Checked, D154 (PR #154, merged):** its tests and the D154 measurement; not checked, a twelve-digit Number on a phone.
- **Checked, on the code in `main` before D154:** `bash run_tests.sh` passes: 4,778 tower checks (46 new in PR #148), 331 foundation checks (19 new, on top of D151's 312) and 26 Python tests (the criteria's own 11 included), exit 0. GitHub's CI passed on the PR. The trial's results were measured on that exact code, and PR #149 changed documents only. The headless boot is clean. The checks cover the carry-off, Thorns on the grab, proportional payback, recoveries of 0, 0.5 and 1.5, escape and fade, the Wall, targeting priority, no push on a thief, the power coupling, option validation, and a snapshot and replay with a thief mid-flight.
- **Checked, D151 (PR #147):** merged. Its evidence is in the PR, and its checks are in the suites above.
- **D153's design note** is documents only: nothing ran for it. Its worked example (11.4) uses the owner's screens' enemy stats and guessed prices, not measurements.
- **Not checked:** a phone, or a real finger, for the pop-ups. Players, whether any of the Number's design is fun, Tier 2 and 3, Lifesteal, the Labs' cost, and any screen for thieves. The budget scenarios have 4 seeds.

## Open decisions for the owner

1. **The Number milestones pay less (THE_NUMBER.md 14.4), and the best Number reads smaller.** Spending keeps a buying run's peak Number at a fifth to a quarter of today's, so the digits (10 to 1,000,000), which pay Coins once when the best Number first reaches them, come later: at 100K Coins a core build's digits pay **60 instead of 310**, at 1M **310 instead of 2,810** (about a quarter of a 1M core run's Coins before, about 3% now). Nothing changed at 10K. **I'd keep the record as the true peak and recalibrate the digit ladder to the new scale, measured** (11.15 already planned it). Trade-off: until then, Number digits pay little to a strong player.
2. **Should a run's reward follow its peak Number?** The bots found a fork: buying goes further with a small Number, a shut shop goes bigger and ends sooner. If Coins (or the record) followed the peak, "Run upgrades off" would be a real way to play, not a handicap. I'd say yes, measured first (11.6). It also answers decision 1.
3. **Should Workshop power be able to outgrow the run shop?** Even at 1M Coins the shop adds 25 to 37% of a run's waves, so "strong enough not to need upgrades" doesn't arrive by itself (13.3). Options are Labs that cheapen or replace run upgrades, or tier prices that rise.
4. **Recovery Packages refill spending too** (14.4): a package heals a share of Workshop Health and raises the Number's ceiling, so after a purchase it can give some back. Bounded, and Packages open at 1.5M Coins. **If D156's "only what enemies took" should hold for them, a package must not raise the ceiling.** I left it.
5. **The turtle and the Lock (13.5):** I'd **leave it and play the Thorns turtle first**. If it feels bad, **let Thorns hurt a standing Lock at a share of its strength**, as a measuring option first (it changes D133's "Thorns don't touch a Lock").
6. **The fuel economy (D155) is parked:** a fixed shot price can't fit Tier 1, so shots are free and Cash is the Number's pressure. The per-wave price (12.6), holding fire and bounties stay as measuring options.
7. **Pop-ups (D151):** does holding stay, and what next? I'd keep it and add **a one-line hint that holding reads**, then **hold the daily Gems pill** (its tooltip never shows on a phone). Two are yours: **a confirm on End run** and **moving the run-over panel onto a sheet** (it shades the arena). UI_POPUPS.md section 3 has the rest.
8. **Which cards to make drawable next?** Factor, Super Tower and a rescaled Berserker are the candidates in CARDS.md. Park the rest. **Changing cards mid-run:** I'd still keep them fixed for the run.
9. **Still open from before:** play the D145 enemies; sign off 1.0; the D131 digit rewards; the speed switch; the Mac sync waiting on a saved battle; publishing Tower-derived data.

## Next steps, in order

1. **Owner:** merge this branch's pull request (it makes the Number is Cash the game and re-records the baselines, and merging accepts both), play a few runs as it now plays, and answer decision 1 (the milestones).
2. **Agent, on a yes to decisions 1 and 2:** write the criteria first, then measure Coins from the peak Number and a recalibrated digit ladder as options, and report every run. Medium, touches the economy, so it needs the same review.
3. **Owner:** **play a run holding tiles on a phone**: it is the one check on the pop-ups that couldn't be made, and it settles the hold's timing.

## Known issues and limits

- **Knockback is probably still too strong** (the owner, 4 October): at high levels it pushes tanks and bosses back faster than they walk, so they never arrive and runs never end. D154 removed the worn-tank mass loss; what's left is our guessed 5 metres per unit of force and a chance that rolls on every strike. The diagnosis is in THE_NUMBER.md 11.14; the rest of the fix waits until the Number's role is settled. Stage 1 measured the blender with it on and off: neither run reached the cap.
- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **Nothing tells a player that holding reads** (D151), and the daily pill's explanation is a hover tooltip, which a phone never shows.
- **The run-over panel isn't on `Overlay`:** it doesn't shade the arena like every other panel.
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **`tools/read_report.gd` reads a new run oddly:** its "cash" column is 0 (Cash is the Number now) and its health figures pair the Number with Workshop Health. The report itself is right.
- **A Cash-rules battle saved before D158 resumes with Cash words** while Home, the Workshop and Cards read as the Number's, until it ends. Intended, brief, and the only place Cash still shows.
- **The Enemy Balance and Wave Skip cards still describe "cash"** in their text. They are unbuilt and never drawn.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

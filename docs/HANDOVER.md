# Handover

**Last updated:** 3 October 2026, by Claude.
- Base `main` is `a923f06`, including D150's balance harness (PR #143) and the Tier research follow-up (PR #144).
- [PR #147](https://github.com/paulhardie/NumberGOup/pull/147), `claude/popup-framework`, builds D151, menus and pop-ups. It changes no game rule or save; public version remains 0.9. It isn't in the play folder until the PR is merged; the play folder follows `origin/main` through `com.paulhardie.ngu-sync`.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. The next free ID is **D152**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth.
- **Enemies:** the five base enemies read as ours (D145).
- **Cards (D146, D147):** they open at Tier 1 wave 20 (the dock shows them then, and the run pays 10 Gems). Eleven of The Tower's cards are built, laid out as a grid with a card's details on tap, and save version 3 holds the collection.
- **Menus and pop-ups (D151):** every pop-up is one `Overlay` (a SHEET over a shade, or a BANNER under the top bar), and holding a Workshop row, the next unlock or a run's upgrade tile reads it while a tap still buys. [UI_POPUPS.md](UI_POPUPS.md) has the rules, what exists and where else we should.
- **Candidates:** nine measure-only cards (Slow Aura, Critical Coin, Compound, Remainder, Unequal, Interest, Factor, and now Berserker and Super Tower) can be equipped in `sim_runs.gd` and are never drawn.

**What the card tests have found** (CARDS.md has the numbers):
- **Tier 1's walls are its boss waves, and they test killing power alone.** Cards that kill faster or buy killing power move them (Damage, Attack Speed, Cash, Fortress at level 7). Health, Regen, the defence cards and our Number cards don't, at any level.
- **Super Tower works** (D148). At level 1 it is a Damage card between levels 1 and 2, and a 40-run career with it earns +87% Coins against Damage's +61%. At level 7 it is worth less than flat Damage of the same average, and it can't be lined up with a boss. It is a strong killing card, not a second strategy.
- **Berserker does nothing at The Tower's numbers** (D148). A Tier 1 run absorbs a few hundred damage, so 0.8–1.4% of it is about 3 Damage.
- **At about 30 times its share it works, and a tank build wins.** A build with no Defense Absolute, the worst alone (wave 19 at 4,000 Coins, against the turtle's 31), reaches wave 50 with it, past the turtle with the card (41). That is the second strategy the walls were missing. Runs are volatile (11–68).

## Balance and the Number (D149, 2 October 2026)

- **What "balanced" means (D149):** Tier 1 keeps The Tower's shape (killing power, a turtle that wins, a pivot for Tier 2), and every drawable card meets a floor (it moves a median wave by at least one at level 7 on some build, or Coins pay for the Coins card).
- **Six of the eleven built cards fail that floor today:** Health, Health Regen, Range, Critical Chance, Extra Defense and Free Upgrades. Super Tower and Factor pass; Berserker fails at The Tower's numbers.
- **The Number is a health pool, as the owner says.** Stripping Dividers, the Lock and the growth rules leaves every build's median wave unchanged (the turtle at 100K does five waves better), and making a Divider's bite permanent changes none either. Only careers' pace moves. THE_NUMBER.md section 9 has the table, the three reasons, and two fixes that were tried and weren't enough (a Number that powers the shots, and durable losses).
- **Where the baseline is soft:** it is bots, not players. The core bot's wave-21 runs earn 81–101 Coins against The Tower's about 162; spreading Cash dies on wave 6 against 8.

Recent reference research is preserved in [THE_NUMBER.md section 9.1](THE_NUMBER.md#91-tested-the-number-as-the-in-run-currency-2-october-2026) and [TOWER_TIERS.md](TOWER_TIERS.md). The latter finds the Tier 2 turtle still beats the blender at 1M Coins; this is an existing D149 design gap, not a rule changed by this harness.

## Balance harness (D150)

`python3 tools/balance_report.py compare` writes a quick before/after Markdown report and JSON; `--suite full` adds the card-floor builds and broader careers. [BALANCE_TESTS.md](BALANCE_TESTS.md) owns coverage, commands, outcome labels, replacement rules and interpretation. Quick runs in CI; Full also runs when manually dispatched with `balance_suite=full`.

A green process means execution and valid measurements, **not balance sign-off**. D149 failures stay FAIL. Paired changes include differences hidden by an unchanged median. Deaths and time/wave/data caps remain distinct. Baselines are replaced only by an explicit record command after review.

Bot-only purchase checks skip redundant work while Cash/wave/policy are unchanged; `--uncached-buys` keeps the original frequency for exact parity checks. Health and survival remain evaluated every tick.

Risk: medium, tooling/reporting with broad verification adjacency. Gameplay, simulator buying policies, generated game data, combat version and save schema must remain unchanged. Source changes during capture are refused. Exact numeric comparisons tolerate only 1e-9 relative / 1e-8 absolute noise.

## Checked, and not checked (D151)

- **Ran:** `bash run_tests.sh` passes: 4,732 tower checks (as on `main`), 312 foundation checks (243 before; 69 new, for the gesture, the overlay rules, the Workshop and run cards, `stat_with` and Home's sheets) and 15 Python reporting tests. The headless boot is clean. The new input tests go through the window's own GUI routing, with mouse and touch events. Breaking the hold's tap suppression, a sheet's blocking and a banner's pass-through each failed the tests, as they should.
- **Looked at:** screenshots from `capture_battle.gd` (Linux, xvfb, 390 × 844 canvas) of Settings, the welcome, a held Workshop row, a held unlock, a held run upgrade, Wave Info, the new-enemy card and Cards' details.
- **Not checked:** a phone, or a real finger. The 0.45 s hold and 10-point drift are guesses from platform defaults. Whether a held card over the top of a run gets in the way. Whether a drag that starts on a tile in the Workshop scrolls it or buys it on touch (the tap path is as before; I couldn't tell). The change was not independently reviewed by a separate agent, only re-read against the diff.
- **D150 (PR #143):** merged. Its evidence is in the PR and [BALANCE_TESTS.md](BALANCE_TESTS.md).

## Open decisions for the owner

1. **What should the Number be?** It has no role beyond health, and the wall is decided by killing power, so it can only gain one through a new rule that makes its size or state decide something at the boss walls. Three candidates (THE_NUMBER.md section 9): **ammunition** (it powers the shots), **a stake** (losses that last), **spent** (traded for bursts; tested as the in-run currency, spending only Number above Health: it is safe and benchmark-neutral but adds no decision and makes no card matter, THE_NUMBER.md section 9.1). I'd lead with **ammunition**, the old vision's "score, health and ammunition at once" and the only one that also helps the dead cards, built as a measure-only candidate with a small, steeper-than-log coupling and checked against three tests: the early benchmarks hold, the Health and Regen cards gain a wave, and removing Dividers moves a wave. Trade-off: my log prototype failed the second and third tests and moved pace far too much at a useful strength, so it may need a stake beside it, and every benchmark moves when it is real.
2. **Which cards to make drawable next?** The floor (D149) now applies.
   - **Factor** (ours, rare): a boss arrives with less health. A modest card, safe for Coins.
   - **Super Tower** (The Tower, epic): I'd make this drawable as The Tower has it. It needs no rescale and moves walls like Attack Speed does. Trade-off: at level 1 it beats the common Damage card, because its average is ×1.75 against ×1.5, so one epic at 3% odds becomes the best early card.
   - **Berserker:** not at The Tower's numbers, which do nothing. If you want a tank strategy to exist, I'd make it **ours, rescaled** (shares in the tens of percent), after a finer sweep (×15, ×20, ×30) and a way to test a tank career. Trade-off: it is volatile, and a tank player has to reach wave 20 by some other build before Cards open for them.
   - **Park** the rest: Slow Aura, Critical Coin, Compound, Remainder, Unequal and Interest.
3. **Changing cards mid-run:** I'd still keep them fixed for the run.
4. **Pop-ups (D151):** does holding stay, and what next? I'd keep it and add **a one-line hint that holding reads** (nothing tells a player today), then **hold the daily Gems pill** (its tooltip never shows on a phone). Two are yours: **a confirm on End run** (it ends a run on one tap; a confirm adds a tap at ×5) and **moving the run-over panel onto a sheet** (it shades the arena). UI_POPUPS.md section 3 has the rest.
5. **Still open from before:**
   - play the D145 enemies and the Lock;
   - sign off 1.0;
   - the D131 digit rewards;
   - the speed switch;
   - the Mac sync waiting on a saved battle;
   - the AGENTS.md modifier-law wording;
   - publishing Tower-derived data.

## Next steps, in order

1. **Owner:** review and merge the D151 PR, then **play a run holding tiles on a phone**: it is the one check I couldn't make, and it settles the hold's timing and whether a card over the arena gets in the way.
2. **Owner:** decide what the Number should do at the walls (open decision 1). A measure-only candidate can now show its impact against the baseline before approval.
3. **Owner:** sequence the six drawable-card failures and choose the next drawable candidates (open decision 2). Full reports measure their D149 floor; this harness does not rescale, rework or remove cards.
4. **Agent, when requested:** the hold hint and the daily pill (small), the independent D148 review, finer Berserker sweep, and later Tier 2 strategy comparison. Runtime stress remains separate from balance bots.

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

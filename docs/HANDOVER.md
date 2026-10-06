# Handover

**Last updated:** 6 October 2026, by Claude Code (Home's stand-ins, D160).

This page is the map for the next session: where the game is, what the owner has to decide, what to do next, what is broken, and what was and wasn't checked for the last change. **Replace it at hand-off; never append.** History lives where it belongs: decisions in [DECISIONS.md](DECISIONS.md) (find one in [DECISIONS_INDEX.md](DECISIONS_INDEX.md)), the Number's design and every experiment's criteria and results in [THE_NUMBER.md](THE_NUMBER.md). Don't write a commit hash or "the next free ID" here: they go stale at the next merge (`python3 tools/decisions_index.py --next` prints the ID, `git log` the hash).

## Start here

Read `AGENTS.md`, this page and the top of THE_NUMBER.md (its status table and "The Number today"). New words are in [GLOSSARY.md](GLOSSARY.md) and every command beyond the tests is in [TOOLS.md](TOOLS.md). Fetch and inspect the checkout before editing. The public version stays **0.9**. The pre-rebuild game is commit `f4f1e95`.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower and the run's money (D156, D157, D158).** Kills and each wave's end pay into it; a run's upgrades are bought with it (never below 1); Regen and Lifesteal refill only what enemies took; Health is a Workshop row only (the Number a run starts with); Interest is on the Number, capped as before; free levels don't raise prices. A Lock (from wave 35) holds the Number's growth and the income it blocks, and pays it all when the last Lock dies. **Run upgrades off** in Settings shuts the run shop for the next run. Cash is gone from a new run's screens; the Cash rows and card read as the Number's.
- **A run begun before D158 plays its Cash rules to the end,** with its own words and chip. The game's rules are `RunConfig.game_tuning()`; the code's own defaults stay off, so old saves, reports and the tools that don't ask replay exactly. No combat-rules version bump, deliberately (THE_NUMBER.md 14.2).
- **The owner played it** ("way better … I need to sort this friction out so I can keep climbing"; early on a bit harder than The Tower, "but that's fine"). The bots agree on the pace: the same waves as Cash, a Number a fifth to a quarter of its old size, nothing runs away (13.3, 14.3). Under it **Dividers punish banking, not playing** and **the Lock holds a slow build's income** (13.4, 13.5).
- **Late game (found 5 to 6 October):** a maxed Workshop empties the run shop and the Number is then mostly the Health row and Recovery Packages, not play. The shop's share of a run's waves (25 to 37% even at 1M Coins) is The Tower's own behaviour, not the pivot's. The Tower answers with tiers, Labs and Enhancements.
- **Tanks keep their weight (D154); the Number is written in full to a trillion (D154).** The five base enemies read as ours (D145).
- **Cards (D146, D147):** open at Tier 1 wave 20; eleven of The Tower's cards are built; the Cash card reads as **Number Income**. **Menus and pop-ups (D151):** one `Overlay`; holding a tile reads it ([UI_POPUPS.md](UI_POPUPS.md)).
- **Measure-only, never in the game:** the fuel economy (D155, a fixed shot price can't fit Tier 1), the capital trial (D152, failed), nine candidate cards. **Balance harness (D150):** bots, not players; since D158 it plays the game's rules ([BALANCE_TESTS.md](BALANCE_TESTS.md)). Under them four of D149's six dead cards meet the floor (Critical Chance and Health Regen still fail).
- **The Workshop may flatten, and we aren't bound to The Tower's rows (D161).** The design note [GROWTH_LAYERS.md](GROWTH_LAYERS.md) sets out each growth layer's job (Workshop, run upgrades, Cards, Labs, Ultimate Weapons, tiers, a later Workshop II), a Coin sink ladder, and candidates of our own (Head Start, Run Discount, Interest depth, Lockpick). Nothing is built.
- **Home shows what's coming (D160):** after a first run a shelf above Battle holds **Missions** (sample goals, "later") and the **next tier** (Tier 2's real row and a bar to clearing wave 100, "1.4"), and **Settings is grouped** with six unbuilt settings as tagged text. All stand-ins live in `src/ui/coming_soon.gd`; none reads a save or changes a rule.
- **Development tooling (merged, D159):** the pinned Godot installs itself (`tools/install_godot_linux.sh`, `.godot-version`; CI and a cloud-session hook use it), commands moved to TOOLS.md, a decision index with a test, a glossary.

## Open decisions for the owner

1. **Measured (6 October, D162): the earned-Coins reward fails in all six configurations (THE_NUMBER.md 16.7), so it is not the game's rule.** The peak is the Health row's Number for strong builds (15), so the reward was to follow the Number *earned*. It passes the tier criterion everywhere, but **no share satisfies both "spenders and hoarders are paid alike" (E2) and "the Coin rows still matter" (E5)**, and a power of 0.8 over-pays fresh runs while a power of 1 mis-sizes builds; the nearest (share 0.25) misses two of seven. **Decision: leave Coins as they are?** I'd say yes: they already sit at 0.09 to 0.19 per Number earned, and run upgrades off already earns 72% to 84% of buying's Coins per minute. Trade-off: no explicit link from the Number to Coins. **Then stage 2: a digit ladder keyed on the Number earned in a run, not its peak** (a 1M core run earns about 11,000, a turtle about 36,800, while the peak is the Health row's 2,764), with criteria written first; the record on Home stays the true peak. The ladder's top three digits are out of reach in Tier 1 for a spender today, and the digits pay less than before (about a third of a run's Coins for a 1M core build, three runs' before; a 1M core run earns about 910 Coins, a turtle about 2,450; 14.4).
2. **Answered yes (6 October), see 1.**
3. **Should Workshop power be able to outgrow the run shop?** Even at 1M Coins the shop adds 25 to 37% of a run's waves, so "strong enough not to need upgrades" doesn't arrive by itself (13.3). Options are Labs that cheapen or replace run upgrades, or tier prices that rise.
4. **Recovery Packages refill spending too** (14.4): a package heals a share of Workshop Health and raises the Number's ceiling, so after a purchase it can give some back. Bounded, and Packages open at 1.5M Coins. **If D156's "only what enemies took" should hold for them, a package must not raise the ceiling.** I left it.
5. **The turtle and the Lock (13.5):** I'd **leave it and play the Thorns turtle first**. If it feels bad, **let Thorns hurt a standing Lock at a share of its strength**, as a measuring option first (it changes D133's "Thorns don't touch a Lock").
6. **The fuel economy (D155) is parked:** a fixed shot price can't fit Tier 1, so shots are free and Cash is the Number's pressure. The per-wave price (12.6), holding fire and bounties stay as measuring options.
7. **Pop-ups (D151):** does holding stay, and what next? I'd keep it and add **a one-line hint that holding reads**, then **hold the daily Gems pill** (its tooltip never shows on a phone). Two are yours: **a confirm on End run** and **moving the run-over panel onto a sheet** (it shades the arena). UI_POPUPS.md section 3 has the rest.
8. **Which cards to make drawable next?** Factor, Super Tower and a rescaled Berserker are the candidates in CARDS.md. Park the rest. **Changing cards mid-run:** I'd still keep them fixed for the run.
9. **Growth layers (D161):** the questions in GROWTH_LAYERS.md section 6 are open: the Ultimate Weapons currency, Labs' first catalogue, where our own Workshop rows live.
10. **What should Missions be, if anything?** (D160 shows samples only.) It needs a daily clock, progress counted from runs and a claim-once payout, and the anti-goals still list live-ops before the core run is proven. I'd **keep it a stand-in until the late-game direction (decisions 2 and 3) is settled**, because what a mission asks and pays depends on what Coins and Gems are for by then. Tournaments and events weren't placed (server and calendar).
11. **Still open from before:** play the D145 enemies; sign off 1.0; the D131 digit rewards; the speed switch; the Mac sync waiting on a saved battle; publishing Tower-derived data.

## Next steps, in order

1. **Owner:** decide open decision 1 (leave Coins as they are, and write stage 2's criteria for a digit ladder keyed on the Number earned). The earned-Coins options and trial tool stay in the code, off by default, as the measuring record (D162).
2. **Agent, on a yes to 1:** write stage 2's criteria first (a digit ladder keyed on the Number earned in a run), then build it as an option and measure it. Medium, economy, so high risk and an independent review before it becomes the game. **Owner:** play a few runs as the game now plays.
3. **Owner:** read [GROWTH_LAYERS.md](GROWTH_LAYERS.md) and answer its section 6: which currency pays for Ultimate Weapons (I'd reuse Gems for now), whether Labs lead with run-economy Labs (I'd say yes), and where our own rows live (before the first one). Then Labs (1.2) is the next build.
4. **Owner:** **play a run holding tiles on a phone**: the one pop-up check that couldn't be made.

## Checked, and not checked

- **Checked, D160 (Home's stand-ins; UI only, no rule, save or setting changed):** `bash run_tests.sh` passes (26 new checks: no shelf before a first run, the shelf and its tags after, the tier bar following the best wave cleared, both sheets and what they say, Tier 2's row read from the data, Settings' groups in order, no unbuilt setting has anything to press, only the two real switches are switches, opening them writes nothing); the headless boot is clean; screenshots of Home, Settings (top and bottom), Missions and the next tier at 540 × 960 looked at, the next tier's again after it was changed to read the best wave cleared (PR #164).
- **Not checked, D160:** a real phone, a screen shorter than 960 (the shelf adds about 70 points to Home), the Settings list on a short window beyond its height rule, and whether the owner likes the shelf, the sample goals and the groups.
- **Checked, D159 (merged, tooling and docs only):** the pinned Godot installs and runs the baseline with no `GODOT` set, the install script and session-start hook were run fresh, again and outside a cloud session, the decision index is generated and tested, CI ran the same install script and passed. **Not checked:** the hook inside a brand-new cloud session start, and how much shorter a cold session is.
- **Checked, D158 (PR #161, merged):** tests for the rules, a run begun under each rule set resumed from a snapshot and a replay, the game's own start, the settings file from the Testing-switch period; the headless boot and capture tool; the harness measuring the game's rules; an independent adversarial review (its findings fixed). **Not checked:** a player on that build, a phone, Tier 2 and 3, a frozen byte fixture of a pre-D158 save (old runs are tested with ones generated from today's code; `tools/check_migration.gd` checks a real save copy).

## Known issues and limits

- **Knockback is probably still too strong** (the owner, 4 October): at high levels it pushes tanks and bosses back faster than they walk, so they never arrive and runs never end. D154 removed the worn-tank mass loss; what's left is our guessed 5 metres per unit of force and a chance that rolls on every strike. The diagnosis is in THE_NUMBER.md 11.14; the rest of the fix waits until the Number's role is settled. Stage 1 measured the blender with it on and off: neither run reached the cap.
- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **Home's stand-ins can mislead a quick glance:** the sample missions' rewards are illustrations, and the Missions tile says "Daily goals" though none exist (the tag and the sheet say so).
- **Nothing tells a player that holding reads** (D151), and the daily pill's explanation is a hover tooltip, which a phone never shows.
- **The run-over panel isn't on `Overlay`:** it doesn't shade the arena like every other panel.
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **A Cash-rules battle saved before D158 resumes with Cash words** while Home, the Workshop and Cards read as the Number's, until it ends. Intended, brief, and the only place Cash still shows.
- **The Enemy Balance and Wave Skip cards still describe "cash"** in their text. They are unbuilt and never drawn.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).


## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call. After adding or changing a decision, run `python3 tools/decisions_index.py` (a test fails if the index is out of date or an ID is taken twice).

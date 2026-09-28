# Handover

**Last updated:** 28 September 2026, by Claude, handing on to the next agent. Two sessions worked in parallel today. One completed The Tower's enemy rules for Tiers 1–3 and added Wave Info (D115, merged in #104), after tiers and The Tower's spawn rolls (D113, D114). This one checked the whole run against The Tower's own rules and wrote [`TOWER_RULES.md`](TOWER_RULES.md): what matches, what's wrong, what's guessed, eight readings for the owner, and the build list before 1.1, which the owner ruled must be done first (D116).

**Branch:** `claude/tower-rule-fixes`, from `claude/tower-rules-research` (PR #105, D116's research). It adds the build list's first item, the rule corrections (D116): Cash per kill slowing past wave 200, the Wall taking every hit and pushing enemies out when it rebuilds, average crit on land mines, and heat-up from the generated data. It also restores D116, the roadmap's 1.0.x row and the D115-aware research page: #105's conflicts were resolved on GitHub in favour of `main`'s older text, so `main` has TOWER_RULES.md but not D116. Not yet merged. The old game is commit `f4f1e95`.

**The owner's play folder is `~/NumberGOup-main`.** `com.paulhardie.ngu-sync` keeps it on `origin/main` every minute, imports new assets, and notifies the owner when `claude/` work is waiting to be merged (AGENTS.md).

**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), then [`REBUILD_SPEC.md`](REBUILD_SPEC.md)'s Roadmap and Benchmarks. Fetch and check the branch against `origin` before new work.
2. **The Tower is the spec** (D073): copy it, and put anything unknown in `src/tower/guesses.gd` rather than debating it. The owner plays each version before the next starts.
3. **The plan is the roadmap** (D079). The game is 0.9. 1.0 is The Tower's first hours with the Number as the tower (D080), and it is close: see Next steps. Then **1.0.x, The Tower's rules finished** (D115: the build list in [`TOWER_RULES.md`](TOWER_RULES.md#7-before-11-the-build-list)), and only then Cards (1.1), Labs, Ultimate Weapons and Tier 2.
4. **When a report arrives, read it first** with `tools/read_report.gd -- --file <report>`. Runs replay only on the commit that recorded them. For totals across several reports, dedupe runs by their time and seed: each export repeats everything before it.

## Where the game is

**Version 0.9, with all of 1.0's Number built.**

- **The battle.** Tier 1, with every one of The Tower's Workshop groups working (D076). The Number sits in the centre as the tower, white, with no ceiling (D083), large and thin, in the design's soft warm light that breathes (D096), inside a faint ring at the range. The screen follows the owner's main-screen design (D095): pill buttons, hairline readouts, underlined tabs and quiet cards, on near-black.
- **Enemies.** The Tower's enemies subtract. A Divider divides the Number: ÷1.25, then ÷1.5 from wave 18. It takes the Protector's slot, replacing a basic, so waves are The Tower's size: one every third wave from wave 5 (the first on wave 7), every other wave by wave 30 (D094). The nearest one in range is previewed above the Number (D086).
- **Spawning and the later enemies are The Tower's** (D113–D115): a roll every 1/8 s by the wave's spawn rate, the caps (120 normal, 20 elites with 8 a type, 10 bosses), coin decay, enemies growing heavier while they live, the Protector from Tier 2 wave 80, and the elites (Vampire, Ray, Scatter) from wave 500 in Tier 1. **Wave Info** opens from the wave readout and shows the spawn rate, the wave's count and each kind's numbers. Tiers exist in `BattleSim`; the game still plays Tier 1.
- **How the Number grows** (D111): regen only restores it up to the run's best; an enemy killed before it lands a hit adds 5% of its Attack; bought Health and Lifesteal lift it too. Weak early on purpose, for Labs and Cards to raise later. It's judged by a run's shape (D110). The Multiplier and the testing switches are gone.
- **Enemies as numbers** (D085, D086). Each type has its own typeface and colour. An enemy shows what it does to the Number (−2.4, ÷1.5) from start to death, with the damage dealt so far in small white under it once it survives a shot (D102).
- **Shots** are white and leave from the edge of the Number's digits with a small flash; hits chip the enemies' numbers, knockback slides (D090), and a kill bursts into sparks with its Cash, and Coins if it paid any, floating beside it (D109). Orbs are mint 0s circling at least 60 m out, turning as slowly as The Tower's (D108), and the Wall is a pair of brackets round the Number that fall away when it breaks (D106).
- **Sound.** No combat sounds (D091). Generative ambient music plays across every screen (D092).
- **Home and the Workshop** wear the same look, with a bar along the bottom (D096). Home follows The Tower's: Coins, the best Number in its light, the Coin bonus, the tier, Battle. Milestones opens a list of the best-Number milestones, each paying Coins once (D107). Cards, Labs, Weapons, Missions and the tier arrows stand locked as placeholders; the Difficulty card says Tier 2 opens after wave 100. Settings (Music, Export report) opens over Home and is kept in `user://number_go_up_settings.json` (D088).
- **Saving, resuming and the report.** The save is `user://number_go_up_tower.json`, version 1. A run closed mid-way resumes by replay (D078). Every run and Workshop buy is logged, and Home exports a report (D077).
- **The owner has played it:** 37 runs in the Workshop, and reports exported on 26 and 27 September. Not yet on a phone or the web build.

**What the owner's reports show** (21 runs, deduplicated; details in the spec's Benchmarks and THE_NUMBER.md 5.2a):
- **The Tower's benchmarks hold.** Wave 20–21 runs take 11½ minutes of game time and earn 117–165 Coins, against The Tower's 12½ minutes and about 162 Coins for wave 22.
- **The wave-10 boss is the wall:** 13 of 19 runs ended on waves 10–11, as The Tower intends. Then the owner put 540 Coins into Workshop Damage (3 to 6), and the next run reached **wave 31** (Number peak 989), where a boss ended it.
- **In that long run, Dividers took 40% of the Number lost with 4 landings**, since a ÷ takes a share of a large Number. Any change to their rate must be measured on long careers.
- **The Number climbs through a run**, as the Number's targets want. Its median at the end of waves 1, 10 and 19 was 16, 40 and 332.
- **÷ moments are about a third of the target rate:** 0.31 a minute landed, against one a minute. 58% of Dividers never landed.
- **No run ended on a ÷.** Ranged enemies took 24% of the Number lost and ended 2 runs.
- **Two runs were lost to updates:** a merge landed while a run was saved, so resuming ended it at its saved wave, by design (D078).
- **The owner plays half their real time at ×5.**
- **The replays match:** the two runs recorded on today's `main` replay exactly with `read_report.gd`.

**The road to wave 100** (27 September, `sim_runs.gd --careers 600 --until-wave 101 --curve`, on D107's code; orbs aren't bought, so D108 doesn't change it). No career has reached wave 100. They climb in steps of ten, ended by the boss every tenth wave, and each step takes longer:

| Career | Wave 41 | Wave 51 | Wave 61 | Wave 71 | Peak Number near wave 70 |
|---|---|---|---|---|---|
| core (Workshop: the five core rows) | 11 h | 32 h | 79 h | not by 183 h (68 best) | 29,000–32,000 |
| grow (core, plus Coins income) | 9 h | 23 h | 43 h | 85 h | 45,000–54,000 |
| grow, regen at best and kills (D098) | 11 h | 27 h | 44 h | 98 h | about 4,000 |
| grow, all three switches | 10 h | 25 h | 45 h | 83 h | 34,000–73,000 |

- Hours are game hours of a career played one run after another; a wave-70 run lasts about 40 minutes. The sim buys only seven Workshop rows and no Cards or Labs, which don't exist yet, so a person will be faster, but the shape matters: **at Tier 1 with only the Workshop, wave 100 is well over 100 game hours away.** The Tower gets there with Cards and Labs.
- The Number's size varied tenfold by switch at the same wave, which is why D110 judges it by a run's shape instead of D107's five digits.
- Stopped at about 200 game hours (core at 284): best waves 71 (core), 81 (grow and grow with D098's two), 88 (all three). None reached 100.

**Tier 1's ceiling** (27 September, `sim_runs.gd --workshop N --buy core --seeds 6 --cap-minutes 150 --curve`, D108's code). Tier 1 has a cliff, as The Tower's turtle does:

| Workshop | Coins it costs | Runs end | Number at waves 10, 50, 100, 255 |
|---|---|---|---|
| Every group open, no levels | 502 billion to open | waves 5–11, like a fresh save | — |
| Groups up to Orbs, every row at level 10 | about 2.1 million | waves 86–91, peak 24,000–35,000; ÷ took 40–61% of the Number lost | 1,261, 15,855, — |
| Groups up to Orbs, every row at level 25 | about 3.4 million | never: alive at wave 260 when capped | 7,541, 62,592, 216,211, 5.8 million |
| Every row at 50 / 100 / 200 | 363 billion and up | never | at 255: 10, 18 and 38 million |
| Every row maxed | about 10²⁰ | never: wave 416 at 4 hours | 3.5 trillion at 10, 146 trillion at 4 hours |

- Past the cliff, in-run Cash buys Defense Absolute beyond enemies' Attack, so hits do nothing, and the damage kills Dividers before they land (0–1 of 125). The Number then climbs on bought Health and Regen alone, a new digit every 50 waves or so, and nothing threatens it.
- Below it, the Number stays five digits to wave 90 and Dividers are the main threat. **The owner kept the turtle (D110)**: a solved Tier 1 is the push to Tier 2.
- A wave-90 run pays about 1,700 Coins, so reaching the cliff on the Workshop alone takes on the order of a thousand runs: the pace problem is Coins, which The Tower eases with Cards, Labs and higher tiers.

**Spawns are The Tower's (D114):** a roll every 1/8 s of the spawning window by the wave's spawn rate (5 at wave 1 ours, 15 at wave 22 the owner's, the SDK's chart from wave 1,000), so about 11, 33 and 37 enemies at waves 1, 22 and 100. The early game got harder and pays about twice the Coins at wave 20; D114 has the benchmarks. **Needed from the owner:** the readings in [`TOWER_RULES.md`](TOWER_RULES.md#6-readings-the-owner-can-take-in-the-tower), the spawn rate at waves 1, 50 and 100 first.

**Tiers in the battle (D113):** `BattleSim` has a tier (1–3 generated from the SDK: ×20 and ×60 enemies, ×1.8 and ×2.6 Coins, The Tower's tier spawn mix and double spawns, and the 120-enemy cap in every tier). The game still plays Tier 1; `sim_runs.gd --tier N` measures the others.

**The Tower's enemy rules, completed (D115):** the audit of the SDK against `BattleSim` found the Protector, the elites, coin decay, mass growth, the tier speed-up, the boss cap and Wave Info missing; all are built. Fleets (wave 15,000 on) and more bosses (Tier 14 on) are out of reach and not built. A fresh run and a 40-run core career print identically to before. Realistic Workshops wall a few waves sooner in Tier 2 (Protectors, faster enemies); D115 has the table.

**Tiers, measured (D112):** a maxed Workshop never dies in any tier, because orbs, knockback and Thorns don't feel a stat multiplier. A realistic Workshop does: the one that just clears Tier 1's wave 100 (every affordable row at level 12, 2.2 million Coins) reaches about wave 30 of Tier 2, and Tier 2's wave 100 takes level 25 (3.35 million). D112's table has each tier's problem and the enemy that makes it.

## Open decisions for the owner

1. **Sign off 1.0, or name what's missing,** after playing D094. The Tower's benchmarks hold and the Number climbs. In simulation, D094 left fresh runs as they were but a core career beat the wave-10 boss on run 9 (it was 11; The Tower's is 10–13), and ÷ landings sit about 0.3 a minute. **If that feels too easy or ÷ too rare, recommend** raising the Divider's health from 4× to 5× before its rate, since the owner set the rate's ceiling.
2. **Game speed.** The spec calls the 1×/2×/5× switch a testing tool, yet it's half of how the owner plays. **Recommend** keeping it as a player feature, since The Tower's first hours are long.
3. **Updates mid-run.** Two runs were lost when a merge landed while a run was saved. **Recommend** the Mac's sync job wait to update while the save holds a run in progress, and say so in its notification. It's small, and changes nothing in the game.
4. **The lighter rebuild process** (REBUILD_SPEC.md, "Process while the rebuild is in progress"), open since 25 September. **Recommend yes.**
5. **AGENTS.md's law 3** names a modifier pipeline that no longer exists. Cards and Labs now demonstrably need stats that stack in layers (TOWER_RULES.md build item 6), so **recommend** rewording it to that primitive when it's built, rather than dropping it. Only the owner changes that file's rules.
6. **Publishing The Tower's data** (its Workshop and enemy numbers, under the SDK's MIT licence) needs a decision before anything is public. Not urgent.
7. **Idle play (D089)** waits for servers. Nothing is built.
8. **The design canvas's other proposals** (D106 names them): a Number that grows heavier with each new digit, elites in one shared blue with a typeface each, and the rest of the notation assets. **Recommend** trying the heavier Number next, with the Tweaks slider on its board, since it answers the Number shrinking as digits arrive.
9. **The new enemies' looks (D115)** are ours: the Protector in steel with a faint ring at its shield's radius, the Vampire crimson with a line to the Number while it drains, the Ray lemon with a heavy line when it fires, the Scatter blue, the three elites glowing. `capture_battle.gd`'s `battle_invaders` and `battle_wave_info` show them. **Recommend** looking at those two screens and saying what to change, since the design canvas proposed elites in one shared blue (decision 8).
10. **Elites come to Tier 1 from wave 500**, as The Tower's do, where D112's table had them from Tier 3. Only a deep Tier 1 run meets them (1% of waves at 500). **Recommend** keeping The Tower's placement.
11. **Missions** stands on Home as a placeholder at the owner's request, but isn't on the roadmap (Milestones is now built, D107). **Recommend** deciding whether Missions joins it before 1.1, or dropping it, so a placeholder never promises something unplanned.

12. **The Tower's wave milestones** (TOWER_RULES.md build item 6). They're how The Tower opens Labs (Tier 1 wave 30) and the next tier (wave 100), and pay its Coins and Gems. **Recommend** adding them beside our Number milestones (D107), which stay as the Number's own rewards.
## Next steps, in order

0. **Owner:** open Wave Info in a run (tap the wave readout) and read The Tower's Wave Info at waves 1, 50 and 100, so our straight lines for the spawn rate can go (D114). Done when the three readings are in the spec.
1. **Owner:** play a few runs on D111's growth (free Coins or a reset help try later stages) and say whether the Number's climb feels earned. Done when the owner says so, or names what to change (`--kill-share` and `--peak-drift` measure alternatives).
1a. **Owner:** sign off 1.0 or name what's missing (decision 1).
2. **Agent, on the owner's word:** tune the Divider's health with `sim_runs.gd --careers 40 --buy core --divider-health N` if play says so. Then raise `application/config/version` to 1.0 when the owner signs it off. `--careers` always plays the same seeds (run N is seed N), so a second career needs a seed option first.
2a. **Owner:** send [`design/GAME_STAGE_BRIEF.md`](design/GAME_STAGE_BRIEF.md) to Claude Design with its screenshots (`capture_battle.gd` makes them), and choose from what comes back. **Agent, then:** record the choices as the next D-number and build them in `arena_view.gd`, `arena_effects.gd` and `number_motion.gd`; drawing only. Done when the owner has played the new stage.
3. **Owner:** try the web build on a phone. The light's shader, the music and the portrait layout have never run there.
4. **Owner:** take the rest of the readings in [`TOWER_RULES.md`](TOWER_RULES.md#6-readings-the-owner-can-take-in-the-tower) (with step 0's spawn rate, the spawn chances at waves 1, 50 and 100 matter most). Done when they're in the chat.
5. **Agent: 1.0.x, the build list in [`TOWER_RULES.md`](TOWER_RULES.md#7-before-11-the-build-list), in its order** (D116). Item 1, the rule corrections, is built on `claude/tower-rule-fixes`. Next: item 3 once the owner's readings arrive (item 2), and item 4, the enemy split, which doesn't wait on anything. High-risk gate for each: tests, before-and-after measurements, a review. Done when each item is built or the owner drops it, and the benchmarks are re-measured.
6. **Then Cards (1.1).** The two splits before them are done: the arena's drawing is three files (`arena_view.gd`, `arena_effects.gd`, `number_motion.gd`), and the Wall, orbs, shockwaves and land mines live in `src/tower/battle_defences.gd`, out of `battle_sim.gd` (over 1,000 lines since D115, which is why the enemy split is on the build list).

## How to measure

- **D116's rule corrections (28 September):** `bash run_tests.sh` passes (4092 checks: new ones for Cash by wave to 6,500, a standing Wall taking ranged hits but not a Vampire's drain, the rebuild pushing enemies out, mine crit and heat-up from the data). `import_tower_enemies.mjs` reproduced the committed data byte for byte first, then added only `heat_up_per_hit` and `kill_cash`. The boot is clean. Fresh runs and a 40-run core career print identically; the Workshop runs are in D116. `capture_battle.gd` ran; no capture shows a ranged shot at the Wall, so that drawing is tested but not seen. The review was the author's own, not independent.
- **D115 (28 September):** `bash run_tests.sh` passes (4073 checks, with tests for the Protector, elites, the Vampire, Ray and Scatter, ageing and Wave Info). `import_tower_enemies.mjs` regenerated the data. Fresh runs (10 seeds) and a 40-run core career print identically to before; Tier 1–2 Workshops before and after are in D115; the `battle_invaders` and `battle_wave_info` captures were checked by eye. Tier 3 at level 25 and a maxed Tier 1 run through waves 480–1,300 are in D115. Maxed Tier 2 and 3 runs through the Protector and elite waves are in D115 too. Still running at this commit: the spawn check past wave 4,000. Not played.
- **D114 (28 September):** `bash run_tests.sh` passes (2764 checks). Fresh runs (20 seeds), a 40-run core career and Tier 1–2 Workshops (4 seeds) measured before and after; table in D114.
- **D113 (28 September):** `bash run_tests.sh` passes (2753 checks). `tools/import_tower_enemies.mjs` reproduced the committed data byte for byte before the change, then generated the tier rows. A 40-run core career and the level-25 turtle to wave 400 print identically to before. Tier 2 and 3 runs in D113.
- **Four experiments (28 September):** `sim_runs.gd` gained the `health` and `survival` strategies, `--career-seed`, `--workshop-unlock`, `--until-wave` for single runs, and measuring flags (`--packages`, `--packages-to-best`, `--sure-divider`) that are off by default. A 40-run core career prints identically to before, run for run. `bash run_tests.sh` passes (2742 checks). Results are in THE_NUMBER.md 5.2 ("Measured 28 September").
- **D112 (28 September):** documents only. Tiers were measured with a scratch script (not committed) that multiplies enemy health and attack in a subclass of `BattleSim`, jumps runs to a wave, and plays full runs from wave 1; tier support in the real sim comes with 1.4.
- **D111 (27 September):** `bash run_tests.sh` passes (2734 checks: the Multiplier's and switches' tests replaced by ones for the growth rules, old settings files and old run records). The boot is clean. With a 5% kill share a 40-run core career prints identically to `main` with both switches on. Fresh runs and careers at 5% and 2.5% are in D111's table. `capture_battle.gd`'s new `battle_kill_grows` checked by eye. Not played.
- **D108 and D109 (27 September):** `bash run_tests.sh` passes (2837 checks), with orb tests rewritten for turns a minute and the 60 m circle, and a new test for sparks, the Coins float and the shots' flash. `bash run_godot.sh --headless --path . --quit` boots (13 leaked objects at exit, as on `main`). Orbs measured at three reaches on a 40-run core career's Workshop (D108's table). `capture_battle.gd`'s crowd and Multiplier-kill screens checked by eye: sparks and the ring show; the Coins float and the shots' flash were tested but not seen in a capture. Not seen in motion.
- **D107 (27 September):** `bash run_tests.sh` passes (2825 checks); 40-run careers, core and spread, with and without milestones (same runs to the boss and to waves 21 and 30); Home and the Milestones panel screenshotted and checked by eye.
- **This session (27 September, D106):** `bash run_tests.sh` on the branch with `main` merged in (after #92): 2817 checks, the 6 new ones passing; 7 save-file checks fail on this Mac on untouched `main` too (see Known issues), and CI passed on `main`. `bash run_godot.sh --headless --path . --quit` boots. `capture_battle.gd`'s `battle_strong` (orbs and the Wall up, a four-digit Number) and `battle_wall_down` checked by eye. Not seen: a six-digit Number with the Wall up, or the fall and rise in motion.
- **The session before (27 September):**
  - `read_report.gd` on the owner's latest report: runs 20 and 21, recorded on `af32bb6`, **match** on replay. The others were recorded on older commits.
  - The report figures above come from the four exported reports, with runs deduplicated by time and seed.
  - D105: `bash run_tests.sh` passes (2811 checks); captures of a crowd, a battle and the Workshop checked by eye.
  - The defences split: `bash run_tests.sh` passes (2810 checks). Ordinary runs, a 40-run career and eight runs with every defence open print identically to `main`, RNG states included.
  - D104: `bash run_tests.sh` passes (2810 checks). Orbs measured at four speeds on a 40-run core career's Workshop (20 seeds each; table in D104). Fresh runs unchanged.
  - The arena split: `bash run_tests.sh` passes (2808 checks, as before). Every `capture_battle.gd` screen captured before and after and compared pixel by pixel: the differences match those between two runs of the same code (chips scatter at random), so nothing visible changed.
  - D103: `bash run_tests.sh` passes (2808 checks). Five seconds of live battle were recorded frame by frame from a scratch script (not committed) and looked at: the Number stays anchored as it climbs.
  - D102: `bash run_tests.sh` passes (2799 checks); captures of a crowd, a tank and a Divider with damage dealt, checked by eye.
  - D101: `bash run_tests.sh` passes (2805 checks). The hitbox at 0.5, 1 and 2 m per digit on 40 fresh seeds (spread, damage-only, core) and 40-run core careers; with it off, 20 core runs print identically. `battle_full_range` checked by eye.
  - D100: `bash run_tests.sh` passes (2796 checks); captures of 5, 1,000 (its moment), 12,863 and 27,976 checked by eye.
  - D099: `bash run_tests.sh` passes (2792 checks), and `capture_battle.gd`'s `battle_new_digit` was checked by eye. The chime was tested for its notes and silence, not listened to.
  - D098: `bash run_tests.sh` passes (2781 checks). The grid in D098: each switch alone, both, and all three, on 20-seed fresh runs (40 for core) and 40-run core careers, plus kill shares of 3%, 5%, 7% and 10%. With every switch off, 20 core runs print identically.
  - D097: `bash run_tests.sh` passes (2768 checks). `sim_runs.gd --multipliers --gains` measurements are in D097. With the switch off, 20 core runs print identically to before. `capture_battle.gd` now also shoots a Multiplier walking in and one killed, both checked by eye.
  - Gains: `bash run_tests.sh` passes (2617 checks). `sim_runs.gd --gains` on 10 seeds each of even and core, a 40-run core career, a 60-run even career, and three scratch careers opening Lifesteal free at run 31 (levels 10, 40, 80). With and without the bookkeeping, 20 core runs print identically.
  - D096: `bash run_tests.sh` passes (2610 checks); `capture_battle.gd` screenshots of Home, the Workshop's tabs, a battle, a ÷ and the run-over panel checked by eye.
  - D095: `bash run_tests.sh` passes (2604 checks); `capture_battle.gd` screenshots checked by eye at wave 1, a crowd, a ÷ landing, a large Number with the Wall up, Home and the Workshop.
  - D094: `bash run_tests.sh` passes (2604 checks). `sim_runs.gd` 20 seeds before and after, and a 40-run core career; figures in D094. Not played; the owner hasn't seen it.
- **The tools:** `bash run_tests.sh` (the baseline); `sim_runs.gd` for balance; `capture_battle.gd` for screenshots; `record_music.gd` for the music; `read_report.gd` for the owner's runs. AGENTS.md's Commands has their options.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 as `.github/workflows/verify.yml` does, then set `GODOT`. Wrap window tools in `xvfb-run -a -s "-screen 0 1024x1100x24"`. Run `--import` once after new assets.
- **Not yet run anywhere:** a phone; the web build's performance; a real close and reopen on the Mac.

## Known issues and risks

- **Settings → Testing isn't meant to ship** (D097): free Coins and Reset progress act on the real save. Remove or hide them before anything goes public.
- **A run saved mid-way before D111 won't resume identically** unless it was played with both D098 switches on and Multipliers off, so it ends at its saved wave (D078). Finish or end a run before merging.
- **Readings still needed from The Tower:** eight, listed in [`TOWER_RULES.md`](TOWER_RULES.md#6-readings-the-owner-can-take-in-the-tower). The health correction is only fitted to wave 22, and the SDK's claim to match the game exactly doesn't explain it.
- **TheTowerSDK reads the game's code as sending about 1.86 enemies per successful spawn roll; we send about 1.06** (D114, on the owner's damage evidence). Counting one wave in The Tower settles it.
- **A run saved mid-way before D094 won't resume identically**, so it ends at its saved wave (D078). Finish or end a run before merging.
- **The Tier 1 turtle hasn't been measured since the Divider arrived.** A ÷ goes through the defences almost untouched by Defense Absolute, so the turtle's "I've stopped dying" moment should be checked with `sim_runs.gd`.
- **The D076 mechanics use our guesses where The Tower is silent** (the spec's Guesses): the Wall's distance, mines, shockwaves. None is reachable in the first hours.
- **Resuming replays the whole run,** about 4.6 s per hour of game time. Several-hour runs, and idle play, will need a battle-state snapshot instead.
- **Seven save-file checks fail locally on the owner's Mac** (Godot 4.7.2): `DirAccess.get_files_at("user://")` there lists the project folder, not the save folder, so the tests can't find their own save files to clear them. It happens on untouched `main`; CI on Linux passes. The game's own saving doesn't list folders, so it's a test-only problem, but a local red run hides real failures. Worth fixing in the tests.
- **With the Wall up and a six-digit Number, its brackets reach close to the range ring** (D106).
- **Enemies bunch at the Number:** those on the same side overlap. It's worth watching in play.
- **The light's shader and the music are unmeasured on a phone.**
- Past wave 6,500 the enemy data holds its last value.

## Handing on

1. **Replace this page.** Keep its shape: who hands to whom and when; the branch and what's on it; where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; this section.
2. **Record any new choice the owner accepts** as the next `D0NN` in [`DECISIONS.md`](DECISIONS.md) (the last is D116), and update the spec's Progress.
3. **Say plainly what ran and what didn't.**
4. **Commit on a branch, never `main`, push it, and open a pull request for it** (AGENTS.md's hand-off). Never merge one; that's the owner's.
5. **Leave no scratch files** in the repository.

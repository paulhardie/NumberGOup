# Rebuild spec: The Tower first, the Number second

**Status:** proposed 25 September 2026, waiting on the owner's go. Nothing here is built. If accepted, it becomes D073 and replaces the tuning plan in [`HANDOVER.md`](HANDOVER.md).

## Why rebuild

The game has become The Tower one decision at a time (D009 "shape reference, not a content source" → D068 "go full tower"). Every step carried the one before it: 11 save formats in four days, a one-off Coin conversion, resumed-save reconciliation (D060, D066, D071, D072), a 4,300-line `main.gd` and a 2,300-line `GameState` still named for tax waves. Most recent work has gone on keeping old states valid rather than on the game.

The one open blocker (runs never end from the third) comes from the one piece that is not The Tower: every shot also banks Number (D037). Tuning The Tower's numbers can't fix that.

So: build The Tower's first hours cleanly, check them against The Tower, then add the Number as one deliberate twist.

## The goal of v1

**A brand-new Tier 1 player's first few hours of The Tower, playable in Godot and measured against The Tower's own figures.** v1 is done when the owner plays a fresh save for a few runs and says it feels like The Tower's opening, and the benchmarks below land within about 20%.

## Rules for the rebuild

These keep it from going round in circles again.

1. **The Tower is the spec.** Where The Tower's number is known, use it. Where it isn't, pick one, list it under [Guesses](#guesses) and move on. A guess needs no decision entry; the owner replaces it when they read the real value.
2. **Numbers are generated, never typed.** The Workshop already comes from TheTowerSDK (`tools/import_tower_workshop.py`). Enemy stats get the same treatment: a script generates per-wave health and damage, type multipliers, type mix and spawn counts from the SDK into `data/tower/enemies.json`. Checked: the SDK's `getEnemyWaveStats` gives a Tier 1 basic 2 HP / 1 damage at wave 1 and 4,364 / 402 at wave 100, matching [the research table](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026). **Take the SDK's values before it rounds them down:** its damage function floors to whole numbers, but unrounded it gives 1.176, 1.386 and 15.908 for waves 1, 2 and 22, which are exactly the owner's screens (1.18, 1.39 and 15.90); health unrounded gives 2.35 and 3.32 against the screens' 2.35 and 3.31. Where the owner's screens disagree with the SDK (wave 22 health 63.11 against the SDK's 69), the screen wins and the script applies the correction.
3. **One simulation, two faces.** The battle is a plain GDScript simulation: no nodes, a fixed tick, a seeded RNG. The battle screen draws it; a headless tool runs it at thousands of times real speed. What is measured is exactly what is played, so the balance tools can't drift from the game.
4. **No save compatibility until the loop is fun.** The new game saves to a new file, `user://number_go_up_tower.json`. The old save is left on disk, untouched: not converted and not deleted. The save has a version field. A save from a different version starts fresh and logs why, with no migrations.
5. **The owner plays each milestone before the next starts.** "Done" means played, not just measured.
6. **Light paperwork.** Tests cover the formulas (prices, enemy stats, pay) and the simulation's determinism. The rebuild gets one decision entry, plus one for each owner choice, not one per tuning. The handover stays under a page.

## What v1 has

| Area | In v1 |
|---|---|
| **Battle** | Tier 1 only. The tower sits in the centre and shoots the nearest enemy in range. Waves last 26 s of spawning plus 9 s of cooldown. The run ends at death or on Quit, and the run-over screen shows the wave, time, Coins and what killed you. |
| **Enemies** | Basic, Fast, Tank and Ranged, with a Boss every 10 waves. SDK health, damage and multipliers (tank 5× health, ½ damage; boss 20× health, 1× damage) and SDK speeds (fast 2×, tank ½×, boss 0.3×). Enemies that reach the tower stay and hit, each hit 4% harder than the last. |
| **Tower stats** | The starting rows: Damage, Attack Speed, Crit Chance, Crit Factor, Health and Health Regen. Then the groups that cost 500 Coins or less to open: Range with Damage / Meter (50), Multishot (400), Defense % with Defense Absolute (75), Thorns (500), Cash Bonus with Cash / Wave (40), and Coins / Kill with Coins / Wave (100). This covers roughly the first hour of The Tower. |
| **Run upgrades** | Every opened row, bought one level at a time with Cash at The Tower's Cash prices. |
| **Pay** | Cash per kill as D071 has it ($1, plus $1 every 10 waves, times the type). Coins per kill by type (basic 0, fast 2, ranged 3, tank 4, boss 5) times the wave. Coins / Wave at each wave's end. |
| **Workshop** | Attack, Defense and Utility tabs, rows with multi-buy, and a locked-group card showing its unlock price. Coins are spent between runs. |
| **Home** | Battle button, best wave, Coins. |
| **Look** | D049's look: Geist and Geist Mono, near-black ground, one accent and one warning colour. Portrait-first. |
| **Dev only** | A game-speed switch (1×, 2×, 5×) so the owner can test a run quickly. |

## Straight after v1 (v1.1)

The next groups in The Tower's unlock order, as Coins come in: Free Upgrades (800), Rapid Fire (1,500), Lifesteal (2,000), Knockback (5,000), Interest (5,000), Bounce Shot (10,000) and Orbs (15,000). The Workshop data already describes them; each is a mechanic plus its tests.

## Not in v1

Tiers 2 and up, milestones, Gems, Labs, Cards, Knowledge, Ultimate Weapons, Perks, Modules, offline earnings, Death Defy, Super Crit, Land Mines, Shockwave, Wall, Recovery Packages, Enemy Level Skip. Also tapping to shoot (The Tower has no tap), and the Number.

## The Number (v2)

The Number goes in only once v1 plays like The Tower, as one change measured against a known-good base. The owner picks the version first:

- **A. The Number is the run's score:** everything the tower has dealt this run, shown big and always rising, with the best one kept as the record. It gives the game its name without touching balance. **Recommended.**
- **B. The Number is the tower's Health,** shown as the big readout. It's a rename, with no balance risk but little identity.
- **C. The Number banks from shots, as D037 does now.** This is what stopped runs ending. It would need a limit, such as banking only a share of each shot, and its own measured decision.

## What carries over

- `data/workshop/upgrades.json` and `tools/import_tower_workshop.py`.
- `src/scientific_number.gd`, for display only. The simulation uses plain floats: the largest Workshop value is 2.9e13 and a wave-1,000 Tier 1 enemy has 7.4e8 health, far inside what a float can hold.
- The research docs: [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) and [`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md).
- The fonts, colours, `icon_glyph.gd` and the arena's effects and sounds (`arena_fx.gd`, `audio_feedback.gd`). These are copied in where they fit, without dragging their callers along.
- `run_godot.sh`, `run_tests.sh`, the CI workflow, and the capture and probe tools' approach (rewritten against the new screens).

## What goes

`main.gd`, `game_state.gd`, `tax_*.gd`, `save_data_v1`–`v12`, `rule_modifier_pipeline.gd`, the Lab, Card and Knowledge code and data, `progression_taxonomy.gd`, the old simulators and their Python models. Docs that describe the old game move to `docs/archive/`. Before anything is deleted, current `main` is tagged `pre-rebuild`, so every line stays recoverable.

## Layout

```text
src/tower/   tower_data.gd (loads the JSON), battle_sim.gd, enemy.gd, workshop.gd, save.gd
src/ui/      battle_screen.gd, workshop_screen.gd, home_screen.gd, theme.gd
data/tower/  enemies.json (generated)
data/workshop/upgrades.json (generated, kept)
tools/       import_tower_enemies.mjs, import_tower_workshop.py, sim_runs.gd
tests/       tower_tests.gd
```

`main.gd` only switches between screens. Only `battle_sim.gd` owns combat rules; the screens draw its state and send it purchases.

## Milestones

Each one ends with the owner playing it.

1. **The battle alone.** Generated enemy data, the simulation, the battle screen and the headless run tool, with a fresh tower and no upgrades. **Done when** a fresh tower's run matches The Tower's for a fresh save (the owner's benchmark 1 below) and the tests pass.
2. **Run upgrades and Cash.** The in-run panel, Cash pay and the run-over screen. **Done when** a fresh run that buys upgrades lands near the benchmarks.
3. **Workshop, Coins, home and save.** **Done when** the owner has played several runs from a fresh save and the career tool shows runs still ending for a reason after run 3.
4. **v1.1 rows.**
5. **The Number** (v2), once the owner has picked A, B or C.

## Benchmarks

| What | The Tower | Source |
|---|---|---|
| Fresh save | Damage 3, Attack Speed 1.00, Crit 1% ×1.20, Health 5, Regen 0 | owner's new save, 24 Sep |
| Wave 22 basic | Health 63.11, Attack 15.90; mix 85% basic, 7% fast, 6% tank, 2% ranged | owner's screen, 24 Sep |
| Waves 1 and 2 basic | Health 2.35 and 3.31, Attack 1.18 and 1.39 | owner's screens, 25 Sep |
| First in-run Cash prices | Damage $10, Attack Speed $5, Crit Chance $4, Crit Factor $10 (the same as `upgrades.json`) | owner's screens, 25 Sep |
| **A fresh run that buys nothing** | **dies at once**, in the first waves. The current game's lasts to wave 13 (D072), so it is far too kind | owner, 25 Sep |
| Wave timing | 26 s spawning, 9 s cooldown | owner's screen and the SDK |
| A wave-22 run | 12 min 33 s game time, 1.46K Coins | owner's battle report, build not recorded |
| New player to wave 100 | about an hour at 1× | community research, **unverified** |
| **Needed from the owner** | 1. A fresh save's first run buying run upgrades: the wave reached, the time and the Coins. 2. One boss kill's Cash. 3. Where the fresh run's $93 Cash on wave 1 and its ×9.00 Coin multiplier come from. | **the two most useful numbers we don't have** |

## Guesses

These are carried from the current game until the owner reads the real value:

- An enemy at the tower hits every 5 seconds (the SDK has no attack interval).
- A boss pays 20 basics' Cash (D071).
- Enemies set off 100 m out, basic speed is 10 m a second, the base range is 30 m, and orbs circle at 60 m (D067, D068). The Tower gives no units.
- The Defense % global cap is 98% (community research).

## Process while the rebuild is in progress

This needs the owner's OK, then an edit to [`AGENTS.md`](../AGENTS.md), since only the owner changes its rules:

- Saves are disposable, so the "save compatibility is a contract" law and the old-save fixtures are suspended until the owner says the loop is fun. The new save then becomes version 1 of the contract.
- Economy changes count as medium risk, not high: tests and a headless measurement, without an independent review of each diff.
- `DECISIONS.md` records owner choices, not tuning passes.

## Risks

- **Effort is a guess:** milestones 1–3 look like two or three focused sessions, since the current game was built in four days, and they could run longer.
- **The SDK and the live game disagree in places** (about 10% on wave 22 health, and the type mix). The owner's screens win, which depends on the owner reading a few more.
- **The owner's current progress doesn't carry over.** It stays on disk, and the old game stays reachable at `pre-rebuild`.
- **The Workshop and enemy data are The Tower's own,** redistributed under the SDK's MIT licence. That's fine for a private build; publishing needs a decision (already open under D068).

## Decisions needed before milestone 1

1. **Go on the rebuild,** starting the new game from a fresh save with the old one left untouched.
2. **The process change above.**
3. The Number's version (A, B or C) can wait until milestone 5.

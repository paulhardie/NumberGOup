# NUMBER GO UP

A portrait-first Godot idle game, rebuilding The Tower's opening with the Number as the tower and our own arithmetic enemies ([D073](docs/DECISIONS.md#d073--rebuild-the-tower-first-the-number-second), [`docs/REBUILD_SPEC.md`](docs/REBUILD_SPEC.md), [`docs/THE_NUMBER.md`](docs/THE_NUMBER.md)). Working agreement: [`AGENTS.md`](AGENTS.md); current state and next steps: [`docs/HANDOVER.md`](docs/HANDOVER.md).

## Run

Open the project in Godot 4.7.2 and run `scenes/main.tscn`. From a shell, always through `run_godot.sh`, which keeps every run away from the real save:

```bash
GODOT=/path/to/Godot bash run_tests.sh
GODOT=/path/to/Godot bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd
```

## Balance comparisons

```bash
python3 tools/balance_report.py compare
python3 tools/balance_report.py compare --suite full
```

These run the real battle with repeatable bot strategies and compare waves, earnings and progression against committed measurements. The Markdown report shows per-seed changes and known design failures; balance movement needs review, not automatic approval. The quick suite runs in CI. [Coverage, interpretation and baseline updates](docs/BALANCE_TESTS.md).

## Current game

Version **0.9**: Tier 1, all Workshop groups, run upgrades, the activity report and battle resume. The owner still signs off 1.0 before Cards (1.1), Labs (1.2), Ultimate Weapons (1.3) and selectable tiers (1.4) begin.

The Number is the tower, and it is the run's money too (D158). Basic, fast, tank and ranged enemies subtract from it; Dividers divide it. Kills and each wave's end pay into it, and a run's upgrades are bought with it: an upgrade takes its price off the Number (never below 1), and Regen and Lifesteal only refill what enemies took, so every purchase is a real cost. Health is a Workshop row only: the Number a run starts with. The Lock comes from wave 35: while it stands in range the Number can't grow and the income it blocks is held, then paid in full when it dies. "Run upgrades off" in Settings shuts the run shop for the next run. Waves have 26 seconds of spawning and 9 seconds of cooldown, with a boss every tenth wave. The Workshop keeps permanent upgrades bought with Coins. Every Workshop group works, including Orbs, the Wall, mines, packages and level skips. Fresh even-bought runs reach wave 6 (median over twenty seeds, D135, unchanged by D158); this is a measurement of our game, not a claim about The Tower.

Home shows Coins, Gems, the best Number and Milestones, and after a first run a shelf of stand-ins for what's coming (Missions, the next tier; D160). The first run's end gives the Workshop's 57-Coin welcome. Known early wave milestones pay once alongside Number milestones (each digit the Number earned in a run first reaches, D164), and a free daily claim gives 20 Gems after the first run. Cards and Labs appear at waves 20 and 30 as roadmap placeholders. Settings is grouped (audio, gameplay, display, data, testing) and marks what isn't built yet; it holds Music, Run upgrades off, the invaders view (a prototype layout with the Number at the bottom, D166), Export report, free test Coins and a two-press progress reset.

The bottom bars read their reveal points from the generated milestone table through permanent progression: Workshop after one run, Cards at Tier 1 wave 20 and Labs at 30. The bars contain no separate wave thresholds.

**Scaling foundations (D126)** are built for the next versions: complete starting builds, lossless battle snapshots, rule effects and combat-source counts, deterministic cooldown state, per-tier records and claims, and persisted real-time research jobs. Research has no player catalogue yet; closed-game battles and servers remain D089's later work. See [the contracts and limits](docs/SCALING_FOUNDATIONS.md).

The version-2 save is `user://number_go_up_tower.json`; the old pre-rebuild file stays untouched. Version 1 migrates with a backup and newly introduced wave rewards. New battles resume directly from exact state, including the Lock; old records still replay their seed and inputs. Unsupported or changed battles end with already banked Coins kept. A sound changed-rules record also retains its per-tier reached wave and unlocks. **An active battle with an older snapshot or combat contract can end during recovery after this update.** Newer-schema or damaged current progress is protected from writes and shown with a recovery notice.

Every run, purchase and reward is logged to `user://number_go_up_activity.jsonl`. **Export report** writes the log, Workshop and progression to `user://reports/`; `tools/read_report.gd` reads it and replays on the rules that recorded it. Nothing is sent by the game.

## Playing on the Mac

To keep a folder on the Mac always on the latest merged game, run this once in Terminal, changing the path to the folder you open in Godot:

```bash
git -C ~/NumberGOup-main fetch origin main && git -C ~/NumberGOup-main show origin/main:tools/mac/install_sync.sh | bash -s -- ~/NumberGOup-main
```

After that it checks GitHub every minute and shows a notification when it updates; reopen the game to play the new version. If the folder isn't a checkout of the game, it's renamed with `-old-` and a fresh copy takes its place. Local changes are never thrown away: they go to a `local-backup/` branch. The log is `~/Library/Logs/ngu-sync.log`.

## Where the numbers come from

- `data/tower/enemies.json`: The Tower's Tier 1 enemies, wave by wave, generated from TheTowerSDK by `tools/import_tower_enemies.mjs` and checked against the owner's screens.
- `data/workshop/upgrades.json`: The Tower's Workshop rows, values and prices, generated by `tools/import_tower_workshop.py`.
- `data/tower/progression.json`: checked early wave rewards and the daily Gem amount, regenerated by `tools/import_tower_progression.py` from its recorded reference rows.
- `src/tower/guesses.gd`: everything The Tower doesn't tell us, one constant each, until someone reads the real value.

Never edit the generated JSON by hand. The Tower's data is redistributed under TheTowerSDK's MIT licence (`data/workshop/THETOWERSDK_LICENSE.txt`); publishing the game with it needs a decision first.

## Web export

`export_presets.cfg` defines a single-threaded, PWA-enabled Web export at `build/web/index.html`. Serve it over HTTPS.

## The old game

Everything before the rebuild is commit `f4f1e95` (the `pre-rebuild` tag, where it has been pushed). Its design documents are in [`docs/archive/`](docs/archive/).

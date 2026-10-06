# Tools

The commands for measuring, importing and inspecting the game. [`AGENTS.md`](../AGENTS.md) keeps the two every change needs (`bash run_tests.sh` and the headless boot); everything else is here.

Every Godot run goes through `run_godot.sh`, which keeps it away from the owner's real save. It finds Godot by itself: `$GODOT` if set, the owner's Mac app, `godot` on `PATH`, or the copy `tools/install_godot_linux.sh` installs (the version is pinned in `.godot-version`).

## Measure the game's rules, not the old ones

Since D158 the game plays the Number as Cash with a Lock that holds the Cash it blocks. **`sim_runs.gd`'s own defaults are still the old Cash rules**, so older measurements stay comparable. To measure the game as it plays, add `--number-cash --lock-holds-cash --reserve 0.5` (the reserve is the bot keeping half its best Number back). The balance harness does this for every scenario (`GAME_RULES` in `tools/balance_report.py`).

## The simulator: `tools/sim_runs.gd`

Plays seeded runs headless and prints the wave, game time, kills, Cash and Coins each ended with, and the median. It prints each run's peak Number and how many Dividers came and landed. **It is a measurement tool, not a gate.** Run it as `bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd -- <flags>`.

| Flags | What they do |
|---|---|
| `--seeds N`, `--cap-minutes N` | How many seeded runs, and the game-time cap |
| `--buy none\|cheapest\|even\|attack\|core\|grow\|health\|survival` | How it spends Cash. `core` also focuses a career's Workshop; `grow` does that and also buys Coins income there; `health` puts 60% of Cash into Health; `survival` buys Health only below half the run's best |
| `--workshop open\|max\|N` | Every Workshop group open, at first levels, maxed, or every row at level N (`--workshop-unlock N` opens only groups costing N Coins or less) |
| `--workshop-coins N --workshop-plan core\|turtle\|blender\|blender_thorns\|blender_orbs\|blender_orbline\|tank\|multishot\|spread` | Builds each run's Workshop by spending N Coins that way (up to the 1.5M groups; D130), and prints what took the Number by enemy kind |
| `--careers N` | N runs in a row from a fresh Workshop, spending Coins between them. `--until-wave N` stops it once a run reaches wave N (or ends single runs there); `--career-seed N` plays another career's seeds |
| `--tier N` | Tier N (1 to 3) with its enemy multipliers, Coins bonus and spawns |
| `--divider-share N`, `--divider-health N`, `--divider-speed N`, `--divider-divisor N`, `--divider-refill N`, `--lock off`, `--lock-from N`, `--lock-every A:B`, `--lock-full N`, `--lock-health N`, `--tank-intro N`, `--overfill N` | Try other tunings without changing the game |
| `--curve`, `--gains` | The Number every fifth wave; where the Number's gains came from (each source's share of all gains and of new highs) |
| `--peak-drift N`, `--kill-share N` | Other numbers for how the Number grows (D111) |
| `--packages N`, `--packages-to-best`, `--sure-divider FROM:EVERY:DIVISOR` | Experiments that aren't the game's rules (BattleSim's measuring options, off by default) |
| `--json-out PATH` | Unrounded per-run measurements |

Cards (D146):

- `tools/sim_runs.gd -- --cards ID:LEVEL,...` plays runs with those Cards equipped (in `--careers`, once a run has reached wave 20), and `-- --card-sweep LEVEL` plays the seeds with no card and then each built card alone at that level, printing each one's median wave, Cash and Coins (D146). The card test series' measure-only candidates (`Cards.CANDIDATES`) go in `--cards` by name, or into a sweep with `--with-candidates` or `--sweep-cards ID,ID`, and `--berserker-scale N` multiplies Berserker's share (D148); see [`docs/CARDS.md`](docs/CARDS.md).

## The balance harness

- `python3 tools/balance_report.py compare` compares the quick bot suite against its committed baseline; `--suite full` adds broader careers and the drawable-card floor. Invalid measurements fail; balance movement and known design failures are reported for review. Coverage, explicit baseline replacement and optional `--fail-on-change` are in [`docs/BALANCE_TESTS.md`](docs/BALANCE_TESTS.md). `sim_runs.gd -- --json-out PATH` exports unrounded per-run measurements.

## Trial tools (each measures one experiment against criteria written first)

- `sim_runs.gd -- --thieves --thief-recovery R --thief-speed S --thief-fade SECONDS --thief-priority --number-power K` plays the Number-as-capital candidate (D152, off by default and never in the game): a Divider carries its bite away, the damage dealt to it pays `R` times the bite back, and the Number multiplies the tower's shots. Each run prints the thieves' ledger. `python3 tools/number_trial.py` measures one configuration against the six pass criteria in [`docs/THE_NUMBER.md`](docs/THE_NUMBER.md) section 10.4 (`--no-slow` skips the career, fresh runs and card sweeps; `--cache DIR` keeps measurements between runs).
- `sim_runs.gd -- --shot-price N --bounty-share N --free-bounty-share N --base-regen N --regen-scale N --hold-doomed` plays the fuel economy (D155, off by default and never in the game): shots cost Number, kills pay a bounty, and each run prints the fuel ledger. `--knockback off` and `--row-levels ID:N,...` adjust a built Workshop, and `--workshop-plan multishot` builds around Multishot and Bounce Shot. `python3 tools/fuel_trial.py` measures one configuration against the six criteria in [`docs/THE_NUMBER.md`](docs/THE_NUMBER.md) section 12.3 (`--grid` measures the declared centre and grid; `--cache DIR` keeps measurements between runs).
- `sim_runs.gd -- --number-cash --lock-holds-cash --reserve R` plays the game's rules (D156, D157, D158; the tool's own default is still the old Cash rules, so older measurements stay comparable): Cash pays into the Number and run upgrades spend it, a Lock holds the Cash it blocks, the bot keeping `R` times the run's best in reserve, and `--upgrades-off` shuts the run shop. `python3 tools/cash_trial.py` measures it against the six criteria in [`docs/THE_NUMBER.md`](docs/THE_NUMBER.md) section 13.2 (`--cache DIR` keeps measurements between runs).

## Importers (the generated data under `data/`)

- `tools/import_tower_cards.py` regenerates `data/cards/cards.json` from the community wiki's Cards page (its header says how to fetch it); never edit that JSON by hand.
- `tools/import_tower_workshop.py` regenerates `data/workshop/upgrades.json` from TheTowerSDK's Workshop table (its header says how to fetch it); never edit that JSON by hand (D068). `tools/import_tower_enemies.mjs` does the same for `data/tower/enemies.json` and checks the result against the owner's screens.

## Reports, captures and music

- `tools/read_report.gd` reads an activity report the owner exported from Home (D077): `-- --file <report.json>` lists their runs, replaying each to check it matches (only on the commit that recorded it), and their Workshop spending; add `--run N` for one run wave by wave with its buys.
- `tools/capture_battle.gd` writes screenshots of the home screen with Settings and the Workshop's welcome open, the Workshop with a held row and a held unlock, Cards with a drawn card and a card's details, a seeded run fast-forwarded to a few moments, a held run upgrade, the five base enemies side by side, and Tier 2's Protector and elites with Wave Info open to `user://capture`, printing where, with throwaway Workshops so nothing is saved; inspect them, never assert pixel equality. On headless Linux wrap it in `xvfb-run -a -s "-screen 0 1024x1100x24"`.
- `tools/record_music.gd` records the generative music (D092) from the master bus to `user://music_preview.wav`; `-- --seconds N` sets the length, and it plays in real time.

## Editors and agents

- `opencode.json` disables the GDScript language server for agents that read it. Godot's LSP is TCP and only runs while the editor is open, which hangs clients that expect stdio; the [`opencode-godot-lsp`](https://github.com/MasuRii/opencode-godot-lsp) bridge is the way to turn it back on.

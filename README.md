# NUMBER GO UP

A portrait-first, local-save Godot web idle game with a tiered Tax-run foundation.

The product ambition, design pillars and anti-goals are in [`docs/GAME_VISION.md`](docs/GAME_VISION.md). Working agreement: [`AGENTS.md`](AGENTS.md); behaviour contracts: [`docs/GAME_INVARIANTS.md`](docs/GAME_INVARIANTS.md); verification: [`docs/QUALITY_GATES.md`](docs/QUALITY_GATES.md); accepted choices: [`docs/DECISIONS.md`](docs/DECISIONS.md); motion vocabulary and borrowed animation techniques: [`docs/MOTION_SYSTEM.md`](docs/MOTION_SYSTEM.md).

## Run

```bash
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_tests.sh
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_balance.sh
```

Open the project in Godot 4.7.2 and run `scenes/main.tscn` for the playable build.

`opencode.json` turns the GDScript language server off for coding agents that read it. Godot's LSP speaks TCP and only exists while the editor is open, so a client expecting stdio hangs on a `.gd` project; the [`opencode-godot-lsp`](https://github.com/MasuRii/opencode-godot-lsp) bridge is the way to turn it back on. Agent behaviour itself lives in [`AGENTS.md`](AGENTS.md).

## Web export

`export_presets.cfg` defines a single-threaded, PWA-enabled Web export at `build/web/index.html`.
Exported files must be served over HTTPS for browser persistence and PWA behavior to work reliably. No hosting configuration is included.

## Current game

The playable slice includes tapping, passive production, a permanent Workshop with 21 loaded rows across Attack, Defense and Utility (and an Ultimates category reserved for later) with multi-buy, Research Focus, upgrade synergies, Prestige, Knowledge/Insight, local saves, a stats/settings drawer, and tiered Tax runs.

Tax runs use two independent absolute stats:

- **Liability** is depleted by production, and the same output is also Number (D037): the Number never stops rising while you produce. A beaten wave gives way to the next after a 2.5-second beat; a missed wave moves on, paying Coins for the share cleared, and whatever of it reached the Number stays and keeps hitting, 4% harder each time; a boss is a wall of HP that hits like one enemy and stays at the Number while the next waves come (D058, D063).
- **Collection** is deducted from Number each time an enemy at the Number hits, after Armor and then Guard on that enemy's hit (D063). Number reaching zero ends and resets the run.

Tier 1 runs one difficulty curve from wave 1 (D040): a wave is many enemies (20 at first, about 142 by wave 1,000) arriving over The Tower's 35-second wave, each with health that grows a little faster than wave² (D065), the Hit is that HP over a ratio on The Tower's shape, so enemies grow tankier than they hit (D063), and a run starts with 50 Number; every run also produces a flat 1 a second. Tier 2 and Tier 3 unlock by beating wave 100 or later in the preceding tier and apply 20× and 60× Liability/Collection pressure from wave 1. Rewards rise by smaller 1.8× and 2.6× multipliers. Every tenth wave is a boss and pays a Gem; each tier has twenty-five milestone checkpoints from wave 10 to 5,000 that pay Gems once, and ten of them (10, 25, 50, 100, 250, 500, 750, 1,000, 2,500 and 5,000) also pay a Coin bonus (D030, D043).

Workshop upgrades are bought with Coins between runs and permanently raise the baseline used by every later attempt. Starting a run resets Number to that baseline; death, retreat, and Prestige never remove Workshop ranks. Number production only happens during an active run, so neither waiting at the hub nor going offline can bank a risk-free head start.

Between runs the battle hub (D048) shows the tier's best wave on a ring marked with its milestones, the tier selector, the last run, Milestones, the Coin bonus and BATTLE, and the bottom bar holds Battle, Workshop, Cards, Labs and More, with a seat held for Ultimate Weapons. Labs queue permanent, timed Coin research; Cards are pulled with Gems and only equipped Cards add their effects to a run. Both can be inspected during a run, but spending and loadout changes happen between runs.

Retreat ends and resets a run—it cannot pause Tax while Number keeps growing. Active runs freeze exactly while the app is away. Save schema V9 preserves the permanent Workshop (whose deep rows run past rank 100, D047), Labs (with their slots), Cards, Gems, the active encounter with its Cash, and deterministic RNG state, with V1–V8 migration. A save the game cannot read, or one from a newer version, is never written over (D028).

The look (D049) is deliberately minimal: a near-black ground, Geist for words and Geist Mono for every number (both bundled under the SIL Open Font License in `assets/fonts/`), one accent for good and one warning for bad, with gold and blue kept to the Coin and Gem icons.

The broader inspiration and system roles are mapped in [`docs/TOWER_SYSTEMS_REFERENCE.md`](docs/TOWER_SYSTEMS_REFERENCE.md). The researched scaling rationale, source links, data contracts, and later-system boundaries are in [`docs/TOWER_SCALING_FOUNDATION.md`](docs/TOWER_SCALING_FOUNDATION.md).

## Progression vocabulary

`Workshop` is the permanent machine-building layer, organised as Attack, Defense, Utility, and Ultimates (D013); each row opens at its own Workshop level. `Research` softly specialises permanent Coin costs by discounting one category until the next Prestige rather than closing alternatives. Cards are typed as `Modules`, `Protocols`, or `Routines`. `Knowledge`, `Insight`, Coins, and Workshop ranks survive run resets. The temporary in-run layer is run `Upgrades` (D015; called the Rig in older notes, D045): all 21 Workshop rows bought with run-only Cash (D042), lasting one run and lost at every ending, and never past a row's max rank counting its Workshop ranks (D044). Its run-scoped ranks, income-priced costs (D039), 2× rank worth and combined defensive ceilings are implemented and saved with the active run, and its panel sits below the Number on the run screen (D032). The taxonomy reserves `Breakthroughs`, `Laws`, and `Violations` for future systems that will use the shared modifier pipeline.

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

The playable slice includes tapping, passive production, a four-category permanent Workshop of 20 rows and 1,466 ranks with multi-buy, Research Focus, upgrade synergies, Prestige, Knowledge/Insight, local saves, a stats/settings drawer, and tiered Tax runs.

Tax runs use two independent absolute stats:

- **Liability** is depleted by production first. Output that damages the wave does not become Number; only output beyond the wave's remaining Liability does.
- **Collection** is deducted from Number every 15 seconds while Liability remains. Number reaching zero ends and resets the run.

Tier 1 has 20 grace waves. Tier 2 and Tier 3 unlock by clearing wave 100 in the preceding tier and apply 20× and 60× Liability/Collection pressure from wave 1. Rewards rise by smaller 1.8× and 2.6× multipliers. Every tenth wave is a boss; milestones are tracked at waves 10, 25, 50, and 100.

Workshop upgrades are bought with Coins between runs and permanently raise the baseline used by every later attempt. Starting a run resets Number to that baseline; death, retreat, and Prestige never remove Workshop ranks. Number production only happens during an active run, so neither waiting at the hub nor going offline can bank a risk-free head start.

Retreat ends and resets a run—it cannot pause Tax while Number keeps growing. Active runs freeze exactly while the app is away. Save schema V7 preserves the permanent Workshop, Labs (with their slots), Cards, the active encounter and deterministic RNG state, with V1–V6 migration. A save the game cannot read, or one from a newer version, is never written over (D028).

The researched scaling rationale, source links, data contracts, and later-system boundaries are in [`docs/TOWER_SCALING_FOUNDATION.md`](docs/TOWER_SCALING_FOUNDATION.md).

## Progression vocabulary

`Workshop` is the permanent machine-building layer, organised as Attack, Defense, Utility, and Ultimates (D013); each row opens at its own Workshop level. `Research` softly specialises permanent Coin costs by discounting one category until the next Prestige rather than closing alternatives. Cards are typed as `Modules`, `Protocols`, or `Routines`. `Knowledge`, `Insight`, Coins, and Workshop ranks survive run resets. The temporary in-run layer is the `Rig` (D015): the same four categories bought with Number, lasting one run and lost at every ending. Its run-scoped ranks, wave-priced costs, 3× rank multiplier and combined defensive ceilings are implemented and saved with the active run; its panel is not built. The taxonomy reserves `Breakthroughs`, `Laws`, and `Violations` for future systems that will use the shared modifier pipeline.

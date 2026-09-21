# NUMBER GO UP

A portrait-first, local-save Godot web idle game with a tiered Tax-run foundation.

The product ambition, design pillars and anti-goals are in [`docs/GAME_VISION.md`](docs/GAME_VISION.md). Working agreement: [`AGENTS.md`](AGENTS.md); behaviour contracts: [`docs/GAME_INVARIANTS.md`](docs/GAME_INVARIANTS.md); verification: [`docs/QUALITY_GATES.md`](docs/QUALITY_GATES.md); accepted choices: [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Run

```bash
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_tests.sh
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_balance.sh
```

Open the project in Godot 4.7.2 and run `scenes/main.tscn` for the playable build.

## Web export

`export_presets.cfg` defines a single-threaded, PWA-enabled Web export at `build/web/index.html`.
Exported files must be served over HTTPS for browser persistence and PWA behavior to work reliably. No hosting configuration is included.

## Current game

The playable slice includes tapping, passive production, a four-bay permanent Workshop, Research Focus, upgrade synergies, Prestige, Knowledge/Insight, local saves, a stats/settings drawer, and tiered Tax runs.

Tax runs use two independent absolute stats:

- **Liability** is depleted by Number production. Every unit produced both raises Number and deals one unit of compliance damage.
- **Collection** is deducted from Number every 15 seconds while Liability remains. Number reaching zero ends and resets the run.

Tier 1 has 20 grace waves. Tier 2 and Tier 3 unlock by clearing wave 100 in the preceding tier and apply 20× and 60× Liability/Collection pressure from wave 1. Rewards rise by smaller 1.8× and 2.6× multipliers. Every tenth wave is a boss; milestones are tracked at waves 10, 25, 50, and 100.

Workshop upgrades are bought with Coins between runs and permanently raise the baseline used by every later attempt. Starting a run resets Number to that baseline; death, retreat, and Prestige never remove Workshop ranks. Number production only happens during an active run, so neither waiting at the hub nor going offline can bank a risk-free head start.

Retreat ends and resets a run—it cannot pause Tax while Number keeps growing. Active runs freeze exactly while the app is away. Save schema V4 preserves the permanent Workshop, active encounter, and deterministic RNG state, with V1/V2/V3 migration.

The researched scaling rationale, source links, data contracts, and later-system boundaries are in [`docs/TOWER_SCALING_FOUNDATION.md`](docs/TOWER_SCALING_FOUNDATION.md).

## Progression vocabulary

`Workshop` is the permanent machine-building layer: Output, Speed, Chance, and Logic remain visible, with later bays gated by total ranks. `Research` softly specialises permanent Coin costs by discounting one bay until the next Prestige rather than closing alternatives. Cards are typed as `Modules`, `Protocols`, or `Routines`. `Knowledge`, `Insight`, Coins, and Workshop ranks survive run resets. A future temporary in-run upgrade layer must use a distinct name and resource rather than blurring this boundary. The taxonomy reserves `Breakthroughs`, `Laws`, and `Violations` for future systems that will use the shared modifier pipeline.

# Number Go Up agent guide

**Read [`docs/AGENT_CONSTITUTION.md`](docs/AGENT_CONSTITUTION.md) before doing any task work.** It is the shared behavioural foundation across tools and roles; this guide adds Number Go Up's specific rules without weakening it.

## Who works this repo

Sessions arrive from different tools and model versions, often cold. No session can assume it knows what the last one was doing: the repository is the memory. A session that ends without leaving the docs accurate has handed the next one a stale map.

Explicit owner instructions and accepted decisions in [`docs/DECISIONS.md`](docs/DECISIONS.md) are authoritative. Existing behaviour is evidence, not automatically intended behaviour.

## Talk checklist

Replies use **Answer → What changed → Where we are → Next**. Small chat stays loose; work replies follow the shape.

- Answer first, in plain game words.
- Bold risks and anything that changes a decision.
- One question maximum when blocked, and say what a yes would trigger.
- End with the next step and who owns it.

## Read the right source

Start with the smallest set of current sources:

- [`README.md`](README.md) — what the game is and how to run it.
- [`docs/GAME_VISION.md`](docs/GAME_VISION.md) — the player experience, pillars and anti-goals.
- [`docs/TOWER_SCALING_FOUNDATION.md`](docs/TOWER_SCALING_FOUNDATION.md) — researched encounter foundation and rationale.
- [`docs/WORKSHOP_DESIGN.md`](docs/WORKSHOP_DESIGN.md) — Workshop categories, the wave rule, player-facing vocabulary and balance targets.
- [`docs/GAME_INVARIANTS.md`](docs/GAME_INVARIANTS.md) — behaviour that must remain true.
- [`docs/QUALITY_GATES.md`](docs/QUALITY_GATES.md) — verification required for the change's risk.
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — accepted choices. Grep by ID (for example `grep -n "^## D004" docs/DECISIONS.md`); never read it whole.
- `src/` — the implementation, treated as evidence.

Update whichever of these a change makes stale, in the same change.

## Architectural law

1. **One clear authority per concept.** Balance curves and tier tables live in `src/tax_balance_profile.gd`; encounter state in `src/tax_encounter.gd`; stacking order in `src/rule_modifier_pipeline.gd`; save shape in `src/save_data_v*.gd`. `GameState` coordinates these; it does not re-own them.
2. **UI never owns domain logic.** `src/main.gd` presents and reports; decisions belong to `GameState`. A rule implemented twice is a bug report waiting to happen.
3. **All future rules enter through the modifier pipeline.** Laws, Violations, perks, challenges and tier conditions stack in the documented order rather than as special cases in `GameState`.
4. **Number exists only during an active run.** Permanent power (Workshop, Coins, Knowledge, Insight, Shield Matrix, records) is separate. The temporary layer is the Rig, and it spends Number (D015); do not invent a second one and do not blur the boundary.
5. **Save compatibility is a contract.** Stable keys, versioned schemas, explicit migrations, and no silent loss of declared permanent progress.
6. **Determinism stays deterministic.** Persist the run seed and RNG state; a saved active encounter must resume identically.
7. **Factor before you add.** A new domain growing inside `GameState` should become its own class with focused tests, like `TaxBalanceProfile` and `TaxEncounter` did.
8. **No speculative frameworks.** Build the primitive that the next system demonstrably needs, not a generic system for imagined ones. See the foundation-completeness law in the constitution.

## Risk levels and the fast lane

`docs/QUALITY_GATES.md` owns the detail. The short version:

- **Content rows in an existing shape** (a new upgrade definition, a new tier, a new tuning constant with an existing formula) move fast: change the data, run the baseline, report.
- **Economy, ticking, offline, saves and migrations are high risk regardless of diff size.** They require boundary values, round-trip and old-save fixtures, and an independent review of the final diff.
- Do not quietly downgrade a risk level to avoid a gate.

## Verification

Run the baseline for any maintained-source change:

```bash
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_tests.sh
```

Other tools:

```bash
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot bash run_balance.sh
/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --quit
/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot --path . -s res://tools/capture_ui.gd
```

- `run_tests.sh` is the economy suite; a green count with errors printed is not a pass.
- `run_balance.sh` prints the curve and the representative first run; it is a measurement tool, not a gate.
- The headless project run catches parse and scene-build errors in `main.gd` and the UI classes.
- The capture tool opens briefly and writes hub/run/run_standing/workshop/labs/cards/drawer PNGs at four window sizes to `user://ui_capture` for visual review; inspect them, never assert pixel equality.
- Tests write `res://.number_go_up_test_save.json` and clear it; a leftover file is a bug in the test, not content.

Never weaken a test, fixture or gate to get green.

## Working rules

- Do not commit unless asked. When asked, stage only intended files and match the existing commit style.
- Do not reformat unrelated code or clean up adjacent files as a side effect.
- Keep the tree clean: `.godot/`, `build/` and `*.tmp` are ignored; never commit exported web builds, save files or editor caches.
- Preserve user data paths: `user://number_go_up_save.json` is the live save.
- If a change affects a documented fact — vision, invariants, decisions, README — update the owning document in the same change.

## Handoff

Before finishing, leave the repository able to answer:

- what changed, and at what risk level;
- which checks actually ran, and which could not;
- which invariant or decision the change touched;
- what the next concrete step is.

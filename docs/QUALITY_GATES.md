# Quality gates

**Status:** Working verification policy.
**Purpose:** Apply more proof where a Number Go Up change can cause more harm.

Quality gates support judgement, not replace it. A wording change stays small. A one-line economy or save change can still require high-risk proof.

## Before implementation

Record a proportional change snapshot:

```text
Current behaviour and evidence:
Intended behaviour and success criteria:
Directly affected:
Potentially adjacent:
Must preserve:
Risk level and why:
Planned proof:
```

For a low-risk change this may be a few sentences. Expand it only when the blast radius warrants it.

## Baseline checks

Run for any maintained-source change:

```bash
bash run_tests.sh
```

Supporting checks:

```bash
bash run_balance.sh
bash run_godot.sh --headless --path . --quit
bash run_godot.sh --path . -s res://tools/capture_ui.gd
```

- Every Godot run goes through `run_godot.sh`, which keeps it away from the live save (see "Protect the real save" in [`AGENTS.md`](../AGENTS.md)).

- `run_tests.sh` runs the whole headless economy suite. A green count printed alongside errors is not a pass.
- The headless project run imports and parses every script and builds the main scene; it catches UI-script and scene errors the suite does not load.
- `run_balance.sh` is a measurement tool, not a gate.
- The capture tool renders the main screens at four window sizes into `user://ui_capture`. Inspect the PNGs; never assert pixel equality.
- Documentation-only changes do not need the suite. They still need path, link, scope and contradiction checks against the current repository.

The same baseline runs in CI (`.github/workflows/verify.yml`) on every pull request and push to `main`, using a pinned Godot build with its release checksum verified. `main` requires a pull request and a passing "Economy tests and headless boot" check before a normal merge; repository admins can bypass the requirement. The local checks above remain the developer-side gate; CI is the enforced copy.

## Risk classification

### Low risk

Typical scope:

- wording, colour, spacing, icon or isolated layout work with no rule change;
- comments and documentation.

Required proof:

- relevant baseline checks when source changed;
- focused review of the changed surface;
- confirmation that no gameplay, save or balance path changed.

### Medium risk

Typical scope:

- navigation or interaction behaviour;
- a new upgrade definition or content row in an existing shape;
- unlock, affordability or feedback presentation;
- UI that reads from or writes to game state.

Required proof:

- all relevant low-risk proof;
- focused automated coverage for the changed contract when the suite owns it;
- fresh-run interaction check;
- representative progressed-state check where state is involved;
- save/reload smoke check when state is touched.

### High risk

Typical scope:

- economy or balance formulas and constants;
- wave clock, ticking, automation or offline behaviour;
- purchasing, rewards, retreat/death or encounter resolution;
- save, load, migration, reset or schema keys;
- export structure or source authority.

Required proof:

- all relevant medium-risk proof;
- boundary cases at zero, minimum, typical, large and invalid values;
- deterministic run evidence where randomness is involved;
- old-save, current-save, malformed-save and round-trip fixtures when persistence is touched;
- repeated-action checks for duplicate effects;
- a balance-simulator or representative progression comparison for balance changes;
- an independent adversarial review of the final diff.

## Evidence rules

- Report only checks actually performed.
- Distinguish source inspection, static validation, automated runtime tests, manual interaction, rendered visual review and CI evidence.
- A passing syntax or parse check proves structure, not correct game behaviour.
- A fresh-run check does not prove compatibility with old saves or a progressed run.
- A screenshot proves the captured state only.
- A check is relevant only if it exercises the contract that changed.

If a required check cannot be run, state the missing evidence and the resulting uncertainty. Do not quietly downgrade the risk level to avoid a gate.

## Independent review gate

For high-risk changes — and medium-risk changes with broad adjacency — review the completed diff from a fresh perspective:

> Review this change as if you did not implement it. Do not optimise for proving the requested feature works. Look for what it may have damaged, invalidated, duplicated, bypassed or left inconsistent elsewhere.

Inspect:

1. affected systems;
2. adjacent systems;
3. existing assumptions and accepted decisions;
4. persistence and compatibility;
5. boundary and repeated-action cases;
6. player comprehension and mobile interaction;
7. generated outputs and maintainability.

Always ask:

> Given what changed, what could plausibly have gone wrong that the normal checks would not notice?

## Completion and handoff

A change is complete only when:

- its intended outcome is present;
- directly affected and plausible adjacent behaviour has been checked;
- accepted invariants in [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md) remain true;
- evidence is reported at the correct level;
- remaining uncertainty is explicit;
- the documents the change made stale are updated in the same change.

Do not expand a task solely to make every possible check applicable. Never weaken a test or fixture to get green.

## Release gates

No external release gate is defined yet: the game has not been playtested outside the owner. Before any public build, define measurable gates here (fresh-save onboarding, save-loss tolerance, session pacing) rather than shipping an aspirational checklist.

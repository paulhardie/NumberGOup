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
bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd
bash run_godot.sh --headless --path . --quit
bash run_godot.sh --path . -s res://tools/capture_battle.gd
```

- Every Godot run goes through `run_godot.sh`, which keeps it away from the live save (see "Protect the real save" in [`AGENTS.md`](../AGENTS.md)).

- `run_tests.sh` runs both headless suites (`tests/tower_tests.gd` and `tests/foundation_tests.gd`) and the Python balance-report contracts. A green count printed alongside errors is not a pass: every suite independently fails on any `SCRIPT ERROR`, parse error or `ERROR:` line. A stale `.godot` cache is refreshed with `bash run_godot.sh --headless --path . --import`.
- The headless project run imports and parses every script and builds the main scene; it catches UI-script and scene errors the suite does not load.
- **A new script is loaded by path where it is used** (`const Foo = preload("res://src/foo.gd")`), as every script in `src/` does, not by a global `class_name`. The owner's play folder keeps the editor's class cache across pulls, and a cache that predates the new script fails to parse whatever names it, so the game opens to a blank window (it did after D051 added `ArenaFx`). CI and the headless run import fresh, so they cannot catch this; the check is reading the diff for a new `class_name` used by name elsewhere.
- `tools/sim_runs.gd` is a measurement tool, not a gate. `python3 tools/balance_report.py compare` automates a valid quick comparison in CI; `--suite full` adds the card floors and broader careers. Balance movement is reported for owner review, not automatically approved. Execution/measurement errors fail. See [BALANCE_TESTS.md](BALANCE_TESTS.md) for explicit baseline updates and optional `--fail-on-change` checks.
- The capture tool renders the home screen, the Workshop and a seeded run's battle at a few moments into `user://capture`. Inspect the PNGs; never assert pixel equality.
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

### How to run the review

The review has to be independent of the author: a fresh agent (a subagent, or another session) that reads the diff cold. It is read-only: it reports, it doesn't edit. Give it the brief above, the decision and design notes for the change, and the specific things to break. Ask for this report, under about 1,200 words:

1. **Confirmed defects**, ranked, each with `file:line`, the concrete failure scenario and a narrow fix;
2. **Plausible concerns** it couldn't confirm, each with the evidence that would settle it;
3. **Areas checked and sound**, briefly.

What to ask it to try to break, for a change to rules, purchasing, rewards or saves: saves and reports from before the change (do they restore, resume and replay exactly, and does anything new leak into them); state added by the change (is every field captured, restored and validated, and would a resumed run diverge from an unbroken one); economy edges (zero, exactly at a limit, repeated actions, the largest values, float drift); settings files old and malformed; docs that now contradict the code; determinism (any new draw from the random stream); the words and screens a new player sees on a phone; duplicated rules and dead code. **Record the findings and what was done about each in the pull request.** Anything that is the owner's call goes into HANDOVER.md as a decision, with a recommendation, and is not decided by the agent. The review of D158 found four defects and two owner decisions that the tests had not.

## Experiments: changing a rule by measuring first

Used for D152, D155, D156 and D157, and the way to try a rule that might not work:

1. **Write it down before building.** The options, the definitions, the pass criteria, the configurations and the rules of the experiment go into the owning document and are **committed before the options exist or anything is measured.** The criteria commit comes first in the pull request.
2. **Build it as a measuring option.** A `BattleSim` field that is **off by default and recorded in a run's start config only while on** (`RunConfig.trial_tuning`, validated by `valid_tuning`), saved in a snapshot only while on, with a flag in `sim_runs.gd`. A run made without it is byte for byte what it was; **the quick balance comparison showing no movement is the proof.**
3. **Put the criteria in code.** A trial tool (`tools/number_trial.py`, `fuel_trial.py`, `cash_trial.py` are the pattern) evaluates each criterion, with a test that each one fails at its boundary and that a criterion whose runs weren't played reads "not run", never a pass.
4. **Report every configuration, whether it passes or not.** No seed is chosen. **The criteria are not changed after results are seen.** A run outside the declared grid is labelled exploratory and can never count as a pass. A failure is a finding: write it up with a proposal and stop, and the owner decides.
5. **Measure the game's rules, not the old defaults** (TOOLS.md).
6. **Making it the game is its own change.** The game's rule set is named in one place (`RunConfig.game_tuning`), and it is high risk (above) with its own independent review.

### Compatibility without a version bump

A run's start config records its tuning, so **a new rule for new runs can live in `RunConfig.game_tuning()` while the code's own defaults stay as they were.** A save or report from before has none of the new keys, so it restores and replays exactly as it always did, and `RunConfig.RULES_VERSION` is **not** bumped (a bump would end every saved battle on update). Test it rather than assume it: a run begun under each rule set, saved and resumed from a snapshot and from a replay, with the words, chip and shop following the run; a snapshot's state for the new rule must be present if and only if the run's rules say so.

## Completion and handoff

A change is complete only when:

- its intended outcome is present;
- directly affected and plausible adjacent behaviour has been checked;
- the tests' contracts and the accepted decisions remain true (the pre-rebuild invariants are in [`archive/GAME_INVARIANTS.md`](archive/GAME_INVARIANTS.md), as history);
- evidence is reported at the correct level;
- remaining uncertainty is explicit;
- the documents the change made stale are updated in the same change.

Do not expand a task solely to make every possible check applicable. Never weaken a test or fixture to get green.

## Release gates

No external release gate is defined yet: the game has not been playtested outside the owner. Before any public build, define measurable gates here (fresh-save onboarding, save-loss tolerance, session pacing) rather than shipping an aspirational checklist.

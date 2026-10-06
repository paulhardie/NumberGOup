# Glossary

Words that mean something different in the code, the docs and the old game. When a name in the code disagrees with what the player sees, **don't rename the code**: ids are in saves (law 5).

| Word | What it means now | Where it trips you up |
|---|---|---|
| **Number** | The tower's health **and the run's money** (D158). Code: `health`, `max_health()`, `peak_number`, `_ceiling` (what Regen and Lifesteal may refill to) | It is also the score: the best Number is the record |
| **Cash** | **Gone from a new run.** Kills, waves and Interest pay into the Number. Still real for a run begun before D158, which plays its Cash rules to the end | The code keeps the name: `cash_earned`, `cash_per_wave`, `cash_bonus`, the `cash` card and `sim.cash` all exist. A Cash row reads as "Number bonus" or "Number / wave" on screen (`Palette.row_title`) |
| **Run upgrades** (also "the Rig", "in-run upgrades") | The shop a run buys from during play. Priced in The Tower's Cash price tables, **paid from the Number**, never below 1. Code: `buy`, `plan`, `run_levels`, `free_levels`, `in_shop` | "Run Upgrades off" in Settings shuts it for the next run |
| **Workshop** | Permanent rows bought with Coins between runs. The **Health** row is the Number a run starts with; **Health Regen** is Number Regen | Health is Workshop-only: the run shop doesn't sell it |
| **Coins** | The permanent currency: earned by kills and waves, spent in the Workshop | Not money in a run |
| **Gems** | Cards, card slots and (later) Lab rushing. Wave milestones and a daily claim pay them | |
| **Power Stones** | Ultimate Weapons' currency. Not built | |
| **Tier** | A difficulty level (1 to 3 built): it multiplies enemy health and attack and the Coins bonus | |
| **Lock** | An enemy (from wave 35) that holds the Number's growth while it stands in range. Since D157 it also **holds the income it blocks and pays it all when the last Lock dies** | |
| **Divider** | An enemy that divides the Number by a share | Punishes banking, not spending |
| **The game's rules** | `RunConfig.game_tuning()`: the Number as Cash, the held Lock, and the shop shut if chosen | The code's and the tools' own defaults are still the **old Cash rules**, so old saves and measurements replay exactly (docs/TOOLS.md) |
| **Measuring option** | A `BattleSim` field that is off by default and recorded in a run's start config only while on | `shot_price`, `thieves`, `number_cash`, `lock_holds_cash` … see QUALITY_GATES.md |
| **The Tower / the SDK / the wiki** | The reference game; TheTowerSDK's mapping of its code; the community wiki. The generated data under `data/` comes from them | Never edit the generated JSON by hand |
| **Rig, Tax, Laws, Violations, Knowledge, Insight** | The pre-rebuild game's words (commit `f4f1e95`, docs/archive/) | Don't revive them without a decision |

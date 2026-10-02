# Scaling foundations (D126)

Authorised on 30 September 2026 after the whole-game audit: “can you build that all in for me?” This builds the dependencies of the accepted roadmap. The public version stays 0.9; Cards, the Labs catalogue and Ultimate Weapons remain their own versions.

## Outcome and risk

Previously, active saves replayed every tick, reports omitted tier/effects, saves had no migration, and progression had no wave rewards, Gems or real-time jobs. Tiny Coin awards vanished beside a 1e20 balance and enemy stats silently plateaued beyond wave 6,500.

This high-risk pass supplies a preserved permanent account, exact battle continuation and shared progression/time/combat primitives. Default battle rules, Workshop prices, Number growth, the 50-Coin welcome and Number milestones stay as accepted.

## Authorities and consumers

| Authority | Contract and consumer |
|---|---|
| Generated `data/tower/progression.json`, through `TowerData` | Known free rewards: Tier 1 waves 10–100 and Tier 2 wave 10. `import_tower_progression.py` regenerates it. Unknown late rewards are omitted. |
| Milestone `reveals` and `run_milestones` in that table (D136) | Home/Workshop bars and domain gates share the reveal rules: Battle immediately, Workshop after one run, Cards at Tier 1 wave 20 and Labs at 30. NavBar owns only labels and locked-version presentation. |
| `Progression` | Per-tier reached/cleared records, stable claim ids, Gems and daily claim day. Home, battle screens and career measurement use it. Ordinary reward waves pay on reaching; the tier gate requires clear 100 (D107). |
| `RunConfig` | Frozen ranks/groups, tier, initial stat/rule effects, known measuring switches and contract versions. Tuning is applied before the first wave is rolled. Object-free checksummed Variant payloads preserve exact numbers; readable JSON accompanies reports. |
| `StatStack` / `RunRules` | Add then multiply, with source ids. Rules cover Starting Cash, Interest cap, basic-enemy Coins and Cash/Coin multipliers. Research and recorded mid-run effects enter these domains. |
| `BattleSim.deal_damage` | Shots, Thorns, Orbs and mines share damage/kill resolution. Counts exclude overkill and reject removed actors, preserving side-effect order. |
| `BattleCooldowns` | Stable timer ids for Rapid Fire, Wall and Shockwave. Existing owners advance timers at their existing tick points; no second global tick. |
| `BattleSnapshot` | Explicit actors, shots, schedules, RNG streams, defences, effects, cooldowns and inputs. BattleScreen restores directly; reports replay independently. |
| `RealClock` / `Research` | Saved UTC high-water mark and paid parallel jobs, with frozen cost/duration/effects. Closed time advances jobs independently of battle speed. Completion replaces that id's old effect for the next run. |
| `Workshop` | Compensated Coin high/remainder parts, saved losslessly. Small awards survive a large balance and spending. |
| `Save` | One atomic versioned account-and-run write, shared by Main and Workshop-only tools. |

The daily amount is 20 Gems, the developer's [v29 reward change](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026). It opens after the first run and pays once per UTC day, without missed-day accumulation, ads, purchases or servers.

Research has one default slot and supports up to five. `Progression.start_research` requires wave 30, advances time before purchase and validates every reachable combination of completed/pending jobs before charging, so completion order cannot break the account. The 1.2 catalogue supplies real ids, prices, durations and effects. Completed effects flatten by sorted id so reload cannot reorder arithmetic. Active runs keep their frozen build.

## Saves

- The pre-rebuild `number_go_up_save.json` stays untouched.
- Version 1 is backed up before migration. Permanent progress survives, with newly introduced wave rewards paid once. Old best wave establishes reached; only best minus one is proven cleared.
- Version 2 holds Workshop, progression and active run together. A current save that would drop declared progress is protected from writes. Future schemas remain at their original path with a visible recovery notice.
- Version 3 (D146) adds Cards to progression. Version 2 is backed up byte for byte and migrates to an empty collection; `check_migration.gd` checks a version-1 or version-2 copy.
- Battle snapshots, replay commands and Coin parts use bounded object-free Variant bytes in base64, checksummed before decoding. Decimal JSON is a readable view, not the exact battle authority.
- New snapshots bank every earned Coin in the same save; resume derives its banked total from exact state.
- Legacy battles still replay in slices. Changed rules/data or damaged runs end through the existing recovery path, keeping banked Coins. A structurally sound changed-rules record also preserves its per-tier reached/cleared record and pays newly reached milestones once. Damaged records cannot grant those unlocks, inflate Workshop bests or pay Number milestones; banked Coins and previous permanent records remain. New snapshots bind to a rules version and enemy/Workshop data signature.
- Snapshot version 2 and combat rules version 2 include the Lock's tuning, hold flag and time, scheduled directions, and the experimental Divider hold/release state. Bump the combat rules version when changing rules that can alter continuation; a prior declared version cannot silently claim equivalent combat. Unversioned legacy records must match their replay's results before adoption.
- Settings remain separate. Reset clears all progress, with the discarded account kept in the activity log.

## Supported limits

These are implementation limits, not balance clamps: invalid effects are rejected before spending.

- Generated data covers waves 1–6,500 and tiers 1–3. Only Tier 1 is selectable until 1.4. Clearing the last generated wave ends safely with an explanatory message instead of farming plateaued stats.
- `import_tower_enemies.mjs package --waves N` can expand from 6,500 to 100,000, rejecting non-finite series before writing. Expansion requires regeneration and benchmarking.
- Stat/rule results are limited to 1e30 to reserve room for compound maths; Attack Speed to 900, Range to 1e6, and Orbs/Multishot/Bounce targets to 128. Existing Workshop maxima lie below them. Raise limits only after performance measurement.
- Replay/snapshot time is bounded to a week; payloads to 30 MB, fields to 2,048 enemies and 100,000 projectiles. Validation checks ranks, tuning, references and finite values. Measuring intervals/wave thresholds must be whole and at most 100,000; general growth switches are at most 1e6 and Divider/Lock values at most 1e12. Zero is valid for disabled Lock, Divider rates and refill duration; positive hit sizes/speeds and intervals are required.
- Gem/count saves support whole values through 2^53−1. UTC supports year 9999, zero/backwards/repeated time and full long-job catch-up. This is a local device clock.
- Coins are compensated doubles, not arbitrary precision. A thousand one-Coin awards beside 1e20 survive saving and spending. The full Workshop costs about 2.626e20 Coins.

## Proof and commands

- `bash run_tests.sh`: battle and foundation suites. Old/current/malformed/future saves, one-time rewards, exact Coin parts, invalid/large boundaries, clock rollback, paid jobs, frozen builds, effects and nine exact seeded tier continuations.
- `bash run_godot.sh --headless --path . --quit`: scene/script boot.
- `tools/check_migration.gd -- --file <version-1-save-copy.json>` (or a version-2 copy, D146): copies its input into scratch `user://`, verifies every permanent field and expected new rewards, exact backup, active replay when present, current-schema reload and no duplicate rewards. For an intentionally incompatible sound active copy, add `--expect-recovery`: it requires incompatibility and drives actual Main recovery, checking banked Coins, ranks, records, unlocks and one-time rewards/logging. The default still fails incompatible replays. Neither mode edits its input; run through `run_godot.sh` as always.
- `tools/check_scaling.gd -- --hours N`: state size, restore/replay latency, horizon and 600-tick exact continuation; a measurement rather than a gate.
- `sim_runs.gd -- --careers 40 --buy core`: includes wave rewards. `--legacy-progression` measures the previous economy. Twenty fresh even-bought runs print byte-identically to current `main` at its accepted 104-roll pacing (D135).
- `capture_battle.gd`: Home, wave milestones, claimed daily state, Workshop and battles. The shorter Home emblem keeps claim/navigation inside the portrait screen.
- Independent adversarial review and final evidence: HANDOVER.md.

No phone/web performance, closed-game battle simulation, notifications or shipped Labs/Weapons catalogue is claimed. Cards were built on these foundations later (D146): equipped cards enter the frozen starting build as stat and rule effects, and save version 3 holds the collection.

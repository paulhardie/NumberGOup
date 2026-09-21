# Decisions

**Status:** Accepted choices log for Number Go Up.
**Use:** Grep by ID (for example `grep -n "^## D004" docs/DECISIONS.md`); never read the whole file during routine work.

Rules:

- IDs are permanent and never reused once cited.
- Entries are appended in acceptance order and dated.
- A superseded entry stays in place, names its replacement, and keeps its history.
- Only accepted choices belong here. A recommendation in conversation is not a decision until the owner accepts it.

---

## D001 — Replace percentage tax with two absolute axes

- **Status:** Accepted (2026-09-21)
- **Context:** The prototype deducted a percentage of current Number per wave, so weak and strong builds lost the same fraction and production growth did not extend survival. The Tower's structure separates an enemy health pool from an enemy attack.
- **Decision:** A Tax encounter has absolute Liability (depleted one-for-one by Number production) and absolute Collection (deducted from Number at each wave boundary while Liability remains).
- **Consequences:** Production is both offence and survival; balance lives in `TaxBalanceProfile`; Number reaching zero ends the run.
- **Revisit when:** Playtest shows a single axis dominates, or a third axis is proposed (for example mitigation separate from Number).

## D002 — Explicit tiers with smaller reward steps than pressure steps

- **Status:** Accepted (2026-09-21)
- **Context:** Tiered difficulty needs an honest jump without making the hardest tier automatically the best farm.
- **Decision:** Author Tiers 1–3 only. Tier 2 and 3 apply exactly 20× and 60× Tier 1 Liability and Collection from wave 1, with rewards of 1.8× and 2.6×. Tiers unlock by clearing wave 100 of the preceding tier.
- **Consequences:** Higher tiers are a difficulty choice first; reward ratios stay honest at equal pressured waves; later rows stay out of the save and UI until authored.
- **Revisit when:** The three-tier horizon is cleared, or playtest shows a tier is never worth entering.

## D003 — Retreat ends a run; active runs freeze offline

- **Status:** Accepted (2026-09-21)
- **Context:** The prototype let closure stop tax while Number kept growing, creating a pause-and-grow exploit.
- **Decision:** Retreat ends and resets the run, banking earned Coins. An active run freezes exactly while the app is away, and offline time is never injected into a run.
- **Consequences:** No pause state exists; Number production happens only during active play; death and retreat can share reset machinery.
- **Revisit when:** A future design requires genuine mid-run saving and can prove it cannot become a growth exploit.

## D004 — Workshop is permanent; Number is run-only

- **Status:** Accepted (2026-09-21)
- **Context:** A run-scoped Workshop reset every attempt, which made permanent progress only Knowledge/Insight and left Coins with little long-term purpose. The Tower keeps a permanent Workshop baseline separate from in-run cash upgrades.
- **Decision:** The four Workshop bays are bought with Coins between runs and permanently raise every later run's baseline. Number and lifetime production exist only during an active run and reset on every ending.
- **Consequences:** Coin rewards fund permanent power; Workshop purchases are locked during runs; a fresh run starts from `starting_number_flat` plus permanent effects, never from banked Number; a future temporary in-run upgrade layer must have its own name and resource.
- **Revisit when:** Between-run choices stop feeling meaningful, or an in-run layer is designed and needs the boundary restated.

## D005 — One ordered modifier pipeline for all future rules

- **Status:** Accepted (2026-09-21)
- **Context:** Laws, Violations, perks, challenges and tier conditions will each want to adjust encounter numbers, and per-system special cases inside `GameState` would make stacking unpredictable.
- **Decision:** All rule modifications pass through `RuleModifierPipeline` with stages applied in order: flat → additive → multiplicative → cap_max → cap_min, each applied once.
- **Consequences:** Stacking is documented and testable; new systems provide modifiers, not branches in state code.
- **Revisit when:** A rule needs an effect the five stages cannot express; extend the pipeline stage list with a decision rather than bypassing it.

## D006 — Deterministic run seeds and saved RNG state

- **Status:** Accepted (2026-09-21)
- **Context:** Randomised-only RNG made balance failures hard to reproduce and saves non-deterministic.
- **Decision:** Every run stores a seed; the save stores the RNG state; a loaded active encounter resumes with identical remaining Liability and identical random outcomes.
- **Consequences:** Runs are reproducible for testing and debugging; balance simulation uses fixed seeds.
- **Revisit when:** Run-scoped random content (offers, drops) is added and needs its own stream separation.

## D007 — Save schema V4 with explicit migrations

- **Status:** Accepted (2026-09-21)
- **Context:** The permanent Workshop and run-only Number changed what a save must contain.
- **Decision:** Save schema V4 stores the permanent Workshop, active encounter and RNG state. V1/V2/V3 saves migrate forward without losing declared permanent progress. Banked pre-V4 Number retires because Number is run-only.
- **Consequences:** `SaveDataV4` owns the shape; older schemas stay readable for migration only; migration writes the upgraded save immediately.
- **Revisit when:** A new permanent system adds saved state; bump the schema and extend migration rather than widening V4 silently.

## D008 — What survives a reset

- **Status:** Accepted (2026-09-21)
- **Context:** The reset boundary needs to be unambiguous for players and for future systems.
- **Decision:** Workshop ranks, Coins, Knowledge, Insight ranks, Shield Matrix rank, tier records and highest Number survive every run ending. Number, lifetime production, momentum, critical chain and the active encounter reset. Research Focus survives death and retreat and clears on Prestige.
- **Consequences:** "Start over, a bit stronger" is the loop; no future layer may blur which side of the line it lives on.
- **Revisit when:** A new permanent or temporary layer is proposed; state its side of the boundary explicitly.

## D009 — The Tower is a shape reference, not a content source

- **Status:** Accepted (2026-09-21)
- **Context:** The research in `TOWER_SCALING_FOUNDATION.md` drew on public SDK data, wikis and reference calculators.
- **Decision:** Borrow the architecture (two axes, explicit tiers, milestone spine, smaller reward steps), but author Number Go Up's own coefficients, names, pacing and content. Exact reference constants are evidence, not transplants.
- **Consequences:** No copied tables, names, art or extracted data; coefficients stay inspectable in `TaxBalanceProfile`.
- **Revisit when:** A new reference game is studied; apply the same clean-room boundary.

## D010 — Grace waves pay repeatable Coins

- **Status:** Accepted (2026-09-21)
- **Context:** With a permanent Coin-funded Workshop, a first run that earned nothing until wave 21 would leave a new player with no visible progress.
- **Decision:** Tier 1 grace waves pay 1 Coin per wave and 5 on boss waves, plus the existing milestone bonus at wave 10.
- **Consequences:** A representative first failure banks 48 Coins, enough for the first two Workshop ranks; grace is onboarding, not empty time.
- **Revisit when:** First-run pacing is retuned, or grace rewards are found to trivialise early permanent progression.

## D011 — Product direction: simple surface, deep systems

- **Status:** Accepted (2026-09-21)
- **Context:** The owner wants a very simple game with incredibly deep systems to carry it forward, using The Tower and tech-tree games as the main inspirations.
- **Decision:** [`GAME_VISION.md`](GAME_VISION.md) owns the product ambition, pillars and anti-goals. New systems are admitted by the vision's tests and must keep the run loop the game rather than skipping it.
- **Consequences:** Feature proposals are judged against the vision before implementation; currency count stays minimal; no live-operations scaffolding before the core run is proven fun.
- **Revisit when:** The vision's pillars or reference set change; update the vision document first, then this entry.

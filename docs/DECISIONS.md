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

- **Status:** Accepted (2026-09-21). The one-for-one production rule and its "production is both offence and survival" consequence are superseded by D012; the two absolute axes stand.
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

## D012 — Output beats the wave before it becomes Number

- **Status:** Accepted (2026-09-21). Supersedes D001's one-for-one production rule. Implemented (2026-09-21) with balance profile `tax-foundation-v2`: Liability and Collection halved, pressured wave Coins ×0.65.
- **Context:** Every unit produced raised Number and also depleted Liability, so production healed the player while stuck on a wave. Attack did Defense's job: a max-Attack Tier 1 run survived 102 Collection hits over 46 minutes. Pillar 2 had nothing to stand on, and the Number rose whether the player was winning or losing.
- **Decision:** Output applies to the active wave's remaining Liability first; only output beyond it is added to Number. A wave that outlasts its timer still deals its Collection and keeps its remaining Liability, as today. `lifetime_generated` keeps counting all output.
- **Consequences:** Collection hits become real events, Defense gets a job Attack cannot do, and the Number rises only while the player is ahead. Measured in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md): on the v1 curves the first run was unchanged (wave 21, 48 Coins), but Tier 1 wave 100 moved out of reach at the same investment and Tier 2 turned harsh for builds below the unlock level. D012 therefore shipped together with the v2 retune, which restores wave 100 for the same build in 45 minutes rather than 73, with 82 hits rather than 194. On its own it does not make Defense an equal axis; that needs new Defense stats and tuning where the hit decides the fight.
- **Revisit when:** The retune cannot meet the first-run and Coin-rate targets together, or playtest shows a Number sitting flat through a wave reads as failure rather than pressure.

## D013 — The Workshop has four categories: Attack, Defense, Utility, Ultimates

- **Status:** Accepted (2026-09-21). Not yet implemented.
- **Context:** All twelve Workshop upgrades served production; Defense existed only as Shield Matrix and Brace, outside the Workshop. With two checks per wave, each needs a shelf, and the owner wants the Workshop to be a large part of the game, as it is in The Tower.
- **Decision:** The Workshop is organised as Attack (beat the wave inside its timer), Defense (survive the hits when you can't), Utility (get more from every run) and Ultimates (milestone-unlocked abilities that fire on their own). The Output, Speed, Chance and Logic bays retire into these categories and Shield Matrix becomes the Defense stat Armor. Every stat carries a one-line player-facing reason to buy it. The stat list, presentation and strategy set live in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).
- **Consequences:** Retiring bays is a save schema V5 migration covering `selected_bay`, `focus` (Research Focus discounts by bay today), the bay unlock gates and `tax_resistance_rank`, with no loss of ranks; upgrade ids stay stable. Research Focus retargets from a bay to a category. Vision pillar 8 changes from four bays to four categories.
- **Revisit when:** A category has no stat worth buying at some stage of the game, or a fifth shelf is proposed.

## D014 — Player-facing vocabulary: Wave HP, Hit, Armor

- **Status:** Accepted (2026-09-21). Only the run screen's damage-rate line uses it so far.
- **Context:** Tax phrasing (Liability, Collection, Compliance, Shield Matrix) made the two checks harder to read than they need to be. The owner wanted plain words that make every Workshop stat's purpose obvious.
- **Decision:** Player-facing text uses Wave, Wave HP (shown as the ring), Damage, Beaten, Hit, Warm-up wave, Brace and Armor, mapped term by term in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md). The Number is never called health on screen. Code names and save keys keep their current names.
- **Consequences:** A UI string pass replaces the tax wording. Renaming classes is a separate mechanical change, and renaming a save key would need a migration; neither is implied.
- **Revisit when:** Playtest shows a term being misread, or a new mechanic needs a word the set lacks.

## D015 — The Rig: the same four categories inside a run, bought with Number

- **Status:** Accepted (2026-09-21) for the shape the owner directed — Attack, Defense, Utility and Ultimate on the run screen, as The Tower places them. The resource (Number) and the cost rule are this decision's recommended resolution of the vision's open question and are flagged in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) until confirmed. Not implemented.
- **Context:** A run contains one decision today — Brace, at a flat 30% — and tapping. D012 made the Number an honest scoreboard that rises only while the player is ahead, but gave them nothing to do with being ahead. The vision has held an open question since D004: when a temporary in-run upgrade layer arrives, what is it called and what does it spend?
- **Decision:** The Rig is a run-scoped upgrade layer with the same four categories and the same stat catalogue as the Workshop, bought with Number during a run and lost when the run ends. Prices are quoted against the current wave's HP rather than in absolute Number, so they scale across tiers and depth without per-tier data. Rig ranks are uncapped and limited by cost growth alone. Brace becomes the Defense tab's first row; Shield leaves the run screen and becomes Armor in the Workshop under D013. The Rig grants no Coins, no Knowledge and no record, and opens no new RNG stream.
- **Consequences:** Pillar 3's "distinct name and resource" is satisfied by Number, which is already the run-only resource, so no fourth currency is added (pillar 4). Attack and Defense compete for one pool inside the run, which is pillar 2 as a moment-to-moment choice. Rig ranks are run state: saved with the active run under D006 and D007, cleared with every ending under D008, and part of the save schema V5 bump that D013's category migration already requires. A player can spend themselves to death; the panel warns against the incoming hit and sells anyway, because the contract is that the number is visible before it kills you, not that the game refuses the decision. Free Upgrade is "every Nth purchase" rather than a roll, so D006's seed reproducibility is untouched.
- **Revisit when:** The balance targets for the Rig cannot be met together — in particular if the Rig lets a fresh permanent build reach waves that previously needed Workshop investment, which would make the meta loop optional.

## D016 — The bottom bar carries what is actionable now

- **Status:** Accepted (2026-09-21). Not implemented.
- **Context:** The dock is five icons — NUMBER, WORKSHOP, LABS, CARDS, MORE — on the one strip of thumb-reachable space a portrait phone has. Three of them cannot be acted on during a run, because permanent purchases are locked while a run is live. Meanwhile Research Focus is chosen once per Prestige and Insight is a single repeatable row, and between them they hold two of the five seats.
- **Decision:** During a run the bar is the four categories (Attack, Defense, Utility, Ultimate) and the dock is hidden; between runs it is RUN, WORKSHOP and MORE. Research Focus, Insight and Prestige move into one Knowledge sheet opened from the Knowledge chip already on screen and from MORE, and the Coins chip opens the Workshop: a currency is the door to its own spend. The run-over screen offers both doors at the moment the currency lands.
- **Consequences:** The four category names are learned once and appear in both lenses. The run screen gets simpler, not busier: Brace moves into the Defense tab and Shield off the screen entirely, so the strip above the bar loses two text actions. The `highest_number` gates at 10 / 1,000 / 110,000 stop gating dock icons and gate rows inside the Knowledge sheet instead, which retires the matching Open item in [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md). `NavDock` gains a second configuration rather than a second class.
- **Revisit when:** A later layer (Breakthroughs, Laws) needs a permanent seat, or playtest shows players cannot find Research Focus at all.

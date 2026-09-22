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

- **Status:** Accepted (2026-09-21). Implemented (2026-09-21): the four categories, the Armor row and the category-shaped Research Focus ship with save schema V5 (D017).
- **Context:** All twelve Workshop upgrades served production; Defense existed only as Shield Matrix and Brace, outside the Workshop. With two checks per wave, each needs a shelf, and the owner wants the Workshop to be a large part of the game, as it is in The Tower.
- **Decision:** The Workshop is organised as Attack (beat the wave inside its timer), Defense (survive the hits when you can't), Utility (get more from every run) and Ultimates (milestone-unlocked abilities that fire on their own). The Output, Speed, Chance and Logic bays retire into these categories and Shield Matrix becomes the Defense stat Armor. Every stat carries a one-line player-facing reason to buy it. The stat list, presentation and strategy set live in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md).
- **Consequences:** Retiring bays is a save schema V5 migration covering `selected_bay`, `focus` (Research Focus discounts by bay today), the bay unlock gates and `tax_resistance_rank`, with no loss of ranks; upgrade ids stay stable. Research Focus retargets from a bay to a category. Vision pillar 8 changes from four bays to four categories.
- **Revisit when:** A category has no stat worth buying at some stage of the game, or a fifth shelf is proposed.

## D014 — Player-facing vocabulary: Wave HP, Hit, Armor

- **Status:** Accepted (2026-09-21). Implemented (2026-09-22) across the run screen, hit feedback, tap floats and the stats drawer.
- **Context:** Tax phrasing (Liability, Collection, Compliance, Shield Matrix) made the two checks harder to read than they need to be. The owner wanted plain words that make every Workshop stat's purpose obvious.
- **Decision:** Player-facing text uses Wave, Wave HP (shown as the ring), Damage, Beaten, Hit, Warm-up wave, Brace and Armor, mapped term by term in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md). The Number is never called health on screen. Code names and save keys keep their current names.
- **Consequences:** The UI string pass replaced the tax wording. Renaming classes is a separate mechanical change, and renaming a save key would need a migration; neither is implied.
- **Revisit when:** Playtest shows a term being misread, or a new mechanic needs a word the set lacks.

## D015 — The Rig: the same four categories inside a run, bought with Number

- **Status:** Accepted (2026-09-21) for the shape the owner directed — Attack, Defense, Utility and Ultimate on the run screen, as The Tower places them — and for Number as the resource, confirmed by the owner the same day. Implemented (2026-09-22): run-scoped ranks in `GameState`, prices in `TaxBalanceProfile`, a 3× effect multiplier, combined defensive ceilings, saved with the active run and cleared by every ending, plus the always-open in-run panel. Targets 7–9 pass; early and mid builds not profiting from the Rig is the open playtest question (see [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md)).
- **Context:** A run contains one decision today — Brace, at a flat 30% — and tapping. D012 made the Number an honest scoreboard that rises only while the player is ahead, but gave them nothing to do with being ahead. The vision has held an open question since D004: when a temporary in-run upgrade layer arrives, what is it called and what does it spend?
- **Decision:** The Rig is a run-scoped upgrade layer with the same four categories and the same stat catalogue as the Workshop, bought with Number during a run and lost when the run ends. Prices are quoted against the current wave's HP rather than in absolute Number, so they scale across tiers and depth without per-tier data. Rig ranks are uncapped and limited by cost growth alone. Brace becomes the Defense tab's first row; Shield leaves the run screen and becomes Armor in the Workshop under D013. The Rig grants no Coins, no Knowledge and no record, and opens no new RNG stream.
- **Consequences:** Pillar 3's "distinct name and resource" is satisfied by Number, which is already the run-only resource, so no fourth currency is added (pillar 4). Attack and Defense compete for one pool inside the run, which is pillar 2 as a moment-to-moment choice. Rig ranks are run state: saved with the active run under D006 and D007, cleared with every ending under D008, and part of the save schema V5 bump that D013's category migration already requires. A player can spend themselves to death; the panel warns against the incoming hit and sells anyway, because the contract is that the number is visible before it kills you, not that the game refuses the decision. Free Upgrade is "every Nth purchase" rather than a roll, so D006's seed reproducibility is untouched.
- **Revisit when:** The balance targets for the Rig cannot be met together — in particular if the Rig lets a fresh permanent build reach waves that previously needed Workshop investment, which would make the meta loop optional.

## D016 — The bottom bar carries what is actionable now

- **Status:** Accepted (2026-09-21). Implemented (2026-09-22): the Workshop and Rig use their own fixed category strips; the dock is hidden during a run, while the between-runs bar, Knowledge sheet and run-over doors remain in place. Refined the same day by [D018](#d018--multi-buy-and-the-reference-workshop-layout), which settles the strip as a fixed bottom bar with an always-open panel rather than a sheet that opens and closes.
- **Context:** The dock is five icons — NUMBER, WORKSHOP, LABS, CARDS, MORE — on the one strip of thumb-reachable space a portrait phone has. Three of them cannot be acted on during a run, because permanent purchases are locked while a run is live. Meanwhile Research Focus is chosen once per Prestige and Insight is a single repeatable row, and between them they hold two of the five seats.
- **Decision:** During a run the bar is the four categories (Attack, Defense, Utility, Ultimate) and the dock is hidden; between runs it is RUN, WORKSHOP and MORE. Research Focus, Insight and Prestige move into one Knowledge sheet opened from the Knowledge chip already on screen and from MORE, and the Coins chip opens the Workshop: a currency is the door to its own spend. The run-over screen offers both doors at the moment the currency lands.
- **Consequences:** The four category names are learned once and appear in both lenses. The run screen gets simpler, not busier: Brace moves into the Defense tab and Shield off the screen entirely, so the strip above the bar loses two text actions. The `highest_number` gates at 10 / 1,000 / 110,000 stop gating dock icons and gate rows inside the Knowledge sheet instead, which retires the matching Open item in [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md). `NavDock` gains a second configuration rather than a second class.
- **Revisit when:** A later layer (Breakthroughs, Laws) needs a permanent seat, or playtest shows players cannot find Research Focus at all.

## D017 — Save schema V5 for the four Workshop categories

- **Status:** Accepted (2026-09-21). Implemented (2026-09-21).
- **Context:** D013 retires the four bays, moves the Shield Matrix rank into the Workshop as Armor, and retargets Research Focus from a bay to a category. Three saved keys carried the old shape: `workshop.selected_bay`, `focus`, and `tax_resistance_rank` as a field of its own. D007 requires a schema bump and an explicit migration rather than widening V4 silently.
- **Decision:** Save schema V5 keeps every V4 key and meaning except three. `workshop.selected_category` replaces `workshop.selected_bay`; `focus` holds a category id; and `tax_resistance_rank` disappears, because Armor is an ordinary Workshop rank inside `purchased` under the stable id `tax_resistance`. V1 through V4 migrate forward: the Armor rank moves without loss, a retired bay maps to the category that inherited its upgrades, and a live run resumes with identical remaining Liability and RNG state. V2, V3 and V4 become read-only migration sources, so only V5 has a writer.
- **Consequences:** No rank, Coin, Knowledge, Insight or record is lost, and migration rewrites the save in V5 shape immediately. Because Armor is now a Workshop rank it counts toward the Workshop level, so a save holding Armor reaches later rows slightly sooner — never later. Output, Speed and Chance focuses all become Attack and keep every row they had; a Logic focus becomes Utility and keeps one of its three, because Logic's rows split across three categories and no mapping can keep them together. The balance simulator reproduces every documented baseline row unchanged.
- **Revisit when:** Another permanent system adds saved state — the Rig's run-scoped ranks (D015) are the next one, and they belong in the active-run block rather than a new schema of their own.

## D018 — Multi-buy, and the reference Workshop layout

- **Status:** Accepted (2026-09-21) on owner direction, from the reference layout they supplied. Implemented (2026-09-22) in both lenses: Workshop and Rig multi-buy quote and spend the same sequence of ranks.
- **Context:** The owner supplied The Tower's Workshop and in-run screens as the layout they want. Two things in them are not in D013 or D016: the four category buttons are a **fixed strip at the bottom with the panel above them always open**, rather than a sheet the player opens and closes, and each category carries a **buy multiplier** so a ladder can be climbed without one tap per rank.
- **Decision:** The four category buttons are a pinned bottom strip in both lenses — above the nav dock in the Workshop, flush at the bottom in a run, where no dock shows. The panel above them is always open. Cards are compact and two to a row: the stat's name opens a detail panel holding the description and the current and max rank with their values, and the value-and-cost box buys. Each category carries its own `x1 · x5 · x10 · MAX` multiplier. Ranks are priced one at a time and summed, so a press costs exactly what the same ranks cost individually and exactly what it quoted; Workshop `MAX` stops at the row cap, while uncapped Rig `MAX` takes every rank the current Number can afford. Card values are derived from each row's declared effect rather than authored a second time.
- **Consequences:** A permanently open panel takes the lower part of the run screen, so the ring stage must shrink to about the top half when the Rig lands. That is closer to pillar 1's line than the sheet [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) first proposed, and the compact card — no description, detail behind a tap — is what keeps it on the right side. Presets, Respec, the Upgrade/Enhance split and the reference's per-category colours are deliberately not adopted; this HUD carries one accent by an earlier choice. The multiplier is presentation state and is not saved. Multi-buy also makes the Workshop's shortness visible: 51 ranks across 13 rows collapse into roughly thirteen presses, which is the open question this decision opens in the design document.
- **Revisit when:** The rank ladders are deepened, which is what would make `x10` and `MAX` load-bearing rather than convenient.

## D019 — Deep rank ladders: multiply the cap, divide the step

- **Status:** Accepted (2026-09-22) on owner direction. Implemented (2026-09-22).
- **Context:** Multi-buy (D018) made the Workshop's real size visible. Thirteen Coin-funded rows held 51 ranks between them — three to ten each, at cost growth of 1.55 to 2.00 — which `MAX` collapsed into about thirteen presses. D013's context says the owner wants the Workshop to be a large part of the game, as it is in The Tower, whose ladders run to hundreds of levels per stat. A ladder of 51 is climbed once rather than returned to.
- **Decision:** Every ladder is rebuilt to roughly 20× its length with its per-rank effect divided by the same factor, so **the value at maximum rank is exactly what the shallow ladder reached**. Cost growth flattens to 1.038–1.078, and each row's Coins-to-max is designed rather than inherited from its old base and growth. Category gates move from 0 / 2 / 5 / 8 to 0 / 12 / 30 / 60 and Research Focus from 12 to 120, chosen to hold the old *Coin* pacing rather than the old rank counts. Burst is the one row that cannot scale: it sets a tick interval, so it runs six ranks, one tick shorter each, to the same floor of every sixth tick.
- **Consequences:** 51 ranks become 906 for 86,007 Coins against 85,635 — the Workshop buys decisions, not hours, and the whole build-matrix baseline in [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) reproduces exactly: the same wave, minutes, hits and Coins on every row, with peak Number under 0.1% adrift on float residue in the per-rank multipliers. The first failed run now funds twelve ranks instead of two, on the same 48 Coins. Two long-standing distortions retire with it: Cushion was 30% of the Workshop's price for a stat that does nothing on Tier 1, and Tap Damage was 0.2% of it for a stat used all game. Small stat values needed decimals on screen, because the Number formatter rounds to whole units and a rank worth 0.05 read as zero. A test asserts every cap still lands on its old value, so a later rank-count change that moves one fails rather than retuning in silence.
- **Revisit when:** The Workshop should take *longer* as well as hold more choices. That is a different dial — the per-row Coin targets — and it would move the balance baseline this decision deliberately preserved.

## D020 — Defense becomes a build: Siphon, Recoil, tier-scaled Cushion, Brace Cost, Second Wind

- **Status:** Accepted (2026-09-22). Implemented (2026-09-22).
- **Context:** D012 gave Defense a job no Attack stat could do, but left it with one stat that did it. Armor shrank the hit and Cushion did nothing on the tier most players play, so "Defense" was a single number wearing a category's name, and pillar 2 — one build cannot trivially solve both checks — had nothing to stand on.
- **Decision:** Five stats, each working on a different part of being stuck. **Siphon** banks a share of the damage a wave absorbs, so a wave you cannot beat stops being a slow death sentence; it never reduces what the wave takes. **Recoil** deals a share of every hit back to the wave that landed it, turning being hit into progress; a braced boundary deals none, because no hit landed. **Cushion** is priced in the tier's hits rather than in absolute Number, its face value times that tier's pressure multiplier. **Brace Cost** buys the Brace price down from 30% toward a floor of 15%, never to free. **Second Wind** lets one hit that would end a run leave a share of that run's peak Number instead, once per run. Their caps — 25%, 50%, tier-scaled, 15%, 25% — come from the sizes the earlier measurements showed to matter, where Siphon at 10% moved nothing.
- **Consequences:** Defense holds six rows, 460 ranks and 60,008 Coins against Attack's 60,009, which is what makes a Defense Research Focus worth the same as an Attack one: a 25% discount is worth a quarter of what the category costs, so the categories are balanced by Coin cost rather than by row count. Balance target 5 is met — maxed Attack alone reaches Tier 1 wave 90 and maxed Defense alone reaches 25, so wave 100 needs both, and the cheapest route is Attack plus Armor. Armor and Recoil both reach 100 by different routes, 82 hits over 45 minutes against 58 over 39. Two run-scoped fields join the active-run block rather than a new schema, as [D017](#d017--save-schema-v5-for-the-four-workshop-categories) said the next run-scoped system should: the run's own peak Number, distinct from the permanent `highest_number`, and whether Second Wind is spent. A save written before them resumes with an unspent Second Wind. One Must invariant changes with this: Number reaching zero no longer always ends the run.
- **Revisit when:** A Defense stat stops being bought at all, or Recoil's speed advantage over Armor makes Armor the trap rather than the cheap route.

## D021 — Boss Damage, and Utility pays in Coins and Knowledge

- **Status:** Accepted (2026-09-22). Implemented (2026-09-22).
- **Context:** Step 4a made Defense a build, which left two gaps. Bosses end runs and no stat answered them specifically. And Utility held one row, so a Research Focus on it was worth an eighth of a focus on Attack, which is the lopsidedness D019's notes flagged.
- **Decision:** **Boss Damage** multiplies produced damage on boss waves only, to ×2 at its cap. It is read through one `_damage_multiplier()` that taps, ticks and the displayed rate all share, so a boss wave cannot show one number and deal another. **Coin Bonus** lifts everything a beaten wave pays, milestone bonuses included, because a milestone is a wave beaten and one rule reads better than two; it is floored per wave rather than rounded, because "+50% Coins" that sometimes pays +100% reads as a bug. **Knowledge Bonus** lifts what a run ending grants, applied inside `get_prestige_knowledge_gain()` so death and voluntary Prestige cannot disagree. The three categories are then sized so their Coin totals match: Attack 68,008, Defense 60,008, Utility 67,990.
- **Consequences:** The Workshop holds 20 rows, 1,466 ranks and 196,006 Coins. That growth is new content, not repricing: every row that existed before step 4 still costs what it did. Research Focus is a genuine three-way choice, balanced by Coin cost rather than by row count, which is the fix D019's notes asked for and explicitly not a per-category discount scale. Measured, Utility behaves as its category promised — it never wins a wave, reaching the same wave 96 with and without it, and pays 49% more Coins and one more Knowledge for doing so. Balance target 2 needs reading with care now: it measures the D012 retune at equal builds, and Coin Bonus is meant to lift Coins per minute. **Balance target 5 is met but closer than it was:** Boss Damage moved maxed Attack's solo reach from wave 90 to 96, and wave 100 is the line that target defends, so another Attack row of that size would break it.
- **Revisit when:** An Attack row pushes a pure-Attack build to Tier 1 wave 100, which would make Defense optional and empty pillar 2; or Coin Bonus makes farming a comfortable tier strictly better than pushing a hard one.

## D022 — The run-over screen names what the run was lost to

- **Status:** Accepted (2026-09-22) on owner direction. The heading, cause, two gaps and doors implemented (2026-09-22).
- **Context:** [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) planned this screen as "What would have saved you": two counterfactual numbers, `2.4× more damage` and `hits 35% smaller`. The owner asked for the opposite framing.
- **Decision:** The screen names the cause, not the cure. It reads `LOST TO`, then the wave and whether a boss landed it, then the size of the hit that emptied the Number. Step 6 added the two gaps underneath (2026-09-22) in the same voice — how far short Attack fell against that wave's HP and Defense against its hit — as facts rather than as prescriptions. The smaller gap carries the accent, pointing at the category to open next without saying so in words.
- **Consequences:** A counterfactual reads as a lecture and quietly tells the player what to buy; a cause tells them what happened and leaves the conclusion to them. It also fits the vision's "every number that kills you was visible before it did" more exactly, because naming the number that did it is a fact about the run rather than advice about the next one. `RunSummary` carries the killing hit, the boss flag and the two gaps, since `_reset_run_state` wipes the encounter and the run Number before the screen can read them; a retreat records none of them, having been lost to nothing.
- **Revisit when:** Playtest shows players cannot tell which category to open next without being told.

## D023 — A Rig rank is worth three Workshop ranks, and the defensive effects get combined ceilings

- **Status:** Accepted (2026-09-22) on owner direction from the target-8 recommendation. Implemented (2026-09-22); the multiplier is the simulator's tuning dial.
- **Context:** The Rig's first measurement (D015's core) priced one rank at roughly one wave's HP and gave it one Workshop rank's effect. Measured, the Rig was a net loss at every build: fresh 21→21, early 29→23, mid 50→40, attack max 96→94, defense-only 25→22. The Number a rank spends was the buffer absorbing the next 60–100 hits, while the rank's effect added a few percent of damage. Balance target 8 gates the panel, and only two levers move value per Number: more ranks (cheaper) or more effect per rank. Cheaper ranks were measured and rejected — k=0.2 with 1.15 growth turned the game into a runaway (mid reached wave 204, top builds never died and took zero hits). So the effect per rank is the lever.
- **Decision:** One Rig rank grants three Workshop ranks' worth of its effect (`RIG_EFFECT_MULTIPLIER`, per category, mutable so the simulator can sweep it). Because the Rig is uncapped and stacks on top of the Workshop's caps, the combined defensive effects gain ceilings: Armor never reduces a hit below 25% of its base, Siphon never banks more than half the damage dealt, and Recoil never returns more than the hit itself. Armor's ceiling is enforced through the modifier pipeline's `cap_min` stage; Siphon and Recoil clamp where the effect is applied. Burst is exempt from the multiplier: its ranks are tick-interval steps, so it stays one-for-one and keeps its floor of every sixth tick.
- **Consequences:** At the swept value (M=3) target 8 is met — attack max 96→103, attack max + armor 100→109, everything maxed 110→120 — and target 7 still holds (fresh 21→21, one rank affordable). M=2 fails (97 and 107); M=5 and M=8 overshoot (everything maxed 160 and 204+), so 3 is the smallest passing value and the sweep keeps the choice honest. Target 9 holds at every M: purchases stop in the last ten minutes as cost growth outruns income. **Early and mid builds still cannot profit from the Rig** under the simulator's policy — their budget buys too few ranks to beat the buffer they spend — which is an open playtest question, not a target failure. The Workshop's own card values are unchanged; the Rig's panel must show its own per-rank value.
- **Revisit when:** Playtest shows early or mid players cannot profit from the Rig at all, or the Rig needs to headline: the multiplier is one value in `TaxBalanceProfile`, and `run_balance.sh` prints the sweep.

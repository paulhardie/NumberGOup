# COMPARISON DOC

**Status:** Living research and sequencing plan. It records comparison evidence and proposed investigation; it does not approve a feature or replace an accepted decision in [`DECISIONS.md`](DECISIONS.md).

**Reference build:** *The Tower: Idle Tower Defense* v29.0.3, current as checked 22 September 2026. [The official v29 notes](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026) and [the current App Store version history](https://apps.apple.com/us/app/the-tower-idle-tower-defense/id1575590830?platform=mac) are the version anchors. The public [TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) and current community references support the feature inventory where official notes do not describe an older system in full.

## Purpose

Answer one product question rigorously: **what does the current Tower have that Number Go Up does not, once artwork and spatial tower-defence play are excluded?**

The aim is not parity. Number Go Up keeps its single Number, visible causality, deterministic runs, and original Wave/Hit rules. This document identifies useful *system roles* and converts selected ones into original candidates only after their player problem, lifecycle, save boundary, balance role and verification are known.

## Boundaries

Included:

- permanent, run-scoped and long-term progression;
- player choices, loadouts, research, challenge structures and automation;
- records, explanations and other player-facing quality of life;
- future live-product foundations, recorded as deferred work rather than implied scope.

Excluded:

- tower placement, projectiles, range, enemy pathing, walls, targeting, enemy rosters and other spatial-defence mechanics;
- art direction, Tower names, coefficients, UI identity, skins and theme collection;
- random drops, rarity ladders, gacha/banners and copied loot economies unless a later decision explicitly changes that boundary.

The existing product guardrails still apply: no new currency without a distinct job, no pause-and-grow, and no events, dailies or tournaments before the core run is proven fun ([`GAME_VISION.md`](GAME_VISION.md)).

## Current comparison

| System role | The Tower currently has | Number Go Up currently has | Position |
| --- | --- | --- | --- |
| Temporary upgrade layer | Player-facing in-run cash upgrades | Rig rules, costs, saving, balance targets and an always-open run panel | **Implemented 22 September 2026; playtest next** |
| Rare major abilities | Nine Ultimate Weapons with their own upgrades and research | Four original Ultimates designed; **no active Ultimate content** | Build after the Rig |
| Permanent baseline | Broad Workshop, Enhancements, respecs and presets | 20 Workshop rows, 1,466 ranks, multi-buy and Research Focus | Deep enough for now; do not add an enhancement layer yet |
| Timed research | Labs with queues, slots, durations, speed-ups and many system-specific lines | Research Focus and Insight only; no timed research tree | Investigate in full before choosing any shape |
| Configured run power | Cards, slots, levels, Masteries and presets | No equip/loadout system | Investigate after the core run is playable |
| Equipment | Modules, slots, unique effects, substats, rerolls and shards | No equivalent | Study the *loadout role*, not the random-loot implementation |
| Temporary choice offers | Perks, trade-offs, bans and auto-pick | No offers; deterministic RNG and modifier pipeline are ready | Candidate after the Rig |
| Permanent tree | Vault Power, Harmony and Enemy trees | Breakthroughs, Laws and Violations reserved but empty | Strong candidate for Number Go Up's deep long-term web |
| Challenge layer | Dissonant Runs restrict an upgrade category for a tier-specific reward | Modifier-pipeline hooks but no challenge content | Candidate after base tiers and builds are proven |
| Progression spine | About two dozen tiers and broad milestone tracks | Three tiers; four Coin/record milestones per tier | Extend only when milestone rewards can change play |
| Automation | Bots, Bot+ and configuration tools | No active automation; Auto-Brace is deferred | Later; automate solved repetition only |
| Player knowledge | Encyclopedia, battle history, detailed reports, records and profiles | Stats/settings drawer, tier records and a loss summary | Quality-of-life candidate before system count grows |
| Live service | Missions, events, seasons, tournaments, guilds, Guardians and stores | Local-save solo game | Explicitly deferred |

The reference scope is confirmed by the official v28/v29 notes: Dissonance, Bot+, event Relics, global presets, the rebuilt Vault, tournaments and continuing Module content are live systems, not historical possibilities. [v28](https://www.techtreegames.com/post/v28-patch-notes) · [v29](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026).

## First Lab triage

**No timed-Lab system earns implementation now.** Number Go Up has an accepted, unpresented Rig and no active Ultimates; adding a queue of passive research before those choices are playable would hide the core decision under another progression surface.

| Outcome | What the completed Lab pass shows | Number Go Up reading | Timing |
| --- | --- | --- | --- |
| Build around original Ultimates | 40 Ultimate Weapon Labs deepen a small number of major abilities rather than adding a broad new stat family | Later give Surge, Bulwark, Breach and Windfall a few meaningful modifiers; never copy Tower abilities or coefficients | After the four Ultimates work in real runs |
| Build around temporary choices | Perk Labs cover choice cadence, option count, bans, trade-offs and automation | A deterministic, opt-in choice layer could make the Rig's spending decision more textured; it must not become random rewards or a fifth currency | After players understand the Rig |
| Build around challenge conditions | Battle Condition Labs consistently adjust a stated rule in exchange for a bounded outcome | Future tier conditions can change Liability/Collection through the existing modifier pipeline, with visible rules rather than enemy-stat transplants | After tiers ask for different builds |
| Improve player explanation | More Round Stats is a Lab whose value is understanding a run, not more power | Expand the loss summary/records only when the current screen cannot explain why a run ended; this needs no Lab shell | Small quality-of-life candidate |
| Wait on configuration | Card Presets, Global Presets and Workshop Respec reduce the friction of maintaining several real builds | Preserve this as a later Protocol/Routine requirement; do not add presets before players have builds worth saving | After a proven loadout layer |
| Do not take a research engine yet | Lab Speed and Lab Coin Discount only improve a timed-research machine that Number Go Up does not need today | Timed research remains a question, not a destination. It needs a distinct strategic job that Workshop, Research Focus and a future tree cannot already do | Reassess after Rig and Ultimates |
| Exclude direct content | Attack, Defense, Utility, Enemy and Wall lines are mainly Tower combat stats; Modules bring drops, rarity, rerolls and shards; Bots and daily systems assume longer live-service loops | Keep the player problem only where it survives the boundary; reject direct stat, loot and live-service imports | Not planned |

The complete evidence table is [the Lab inventory](TOWER_LAB_INVENTORY_2026-09-22.md). It is the audit trail for the table above, not a feature backlog.

## Investigation log

### 22 September 2026 — Lab catalogue audit started

- **Coverage source selected:** the public [TheTowerSDK Lab catalogue](https://github.com/TmRxJD/TheTowerSDK/tree/main/src/data/labs) provides player-facing names, categories, levels, coin costs and durations; its generated research table provides the in-game research index, description and tier/milestone unlock data. This is community-maintained evidence, so every final recommendation still needs a source date and a current-build cross-check where it affects scope.
- **Coverage checkpoint complete:** [the dated Lab inventory](TOWER_LAB_INVENTORY_2026-09-22.md) records all 233 named research lines across 16 categories. The generated table has 260 index slots; the 27 unnamed entries are explicitly treated as placeholders rather than silently omitted Labs.
- **First reconciliation finding:** 227 named Labs resolve to a public cost/time curve once legacy keys are reconciled; six still do not. Those six are an evidence gap, never a reason to infer zero cost or duration.
- **What this confirms already:** Labs are not only stat multipliers. The first group includes research speed/cost, bulk buying, richer history, saved configurations and respec access. Those system roles deserve their own classification, even where the Tower's combat-facing effect is excluded.
- **Not yet decided:** no Lab is marked for Number Go Up adoption or implementation. The next pass is the full line-by-line catalogue and dependency map.

## Plan

### 1. Finish the already accepted run loop

1. **Done — build the Rig panel from the existing domain core.**
   - It shows one category at a time, exact Number costs, effect values and the incoming-Hit warning.
   - Next is a playtest of the documented early and mid-game concern: the simulator currently finds the Rig weaker than hoarding at those investment levels.
   - It added no second run currency, randomness or separate upgrade catalogue.

2. Implement the four original Ultimates.
   - Preserve the accepted milestone unlocks: Surge, Bulwark, Breach and Windfall.
   - Add explicit cooldown/save/reset contracts and deterministic tests before tuning their permanent and Rig levels.

### 2. Complete reference-system research before selecting new scope

This is an investigation phase, not permission to implement Labs, Cards, Modules or Perks wholesale. Each reference item receives a row in an evidence matrix with:

- exact reference source and version;
- Tower's player problem and system dependencies;
- its reset, save, RNG, offline and currency boundaries;
- Number Go Up analogue or original gameplay opportunity;
- classification: **adopt a structural pattern**, **adapt into original content**, **build gameplay around the problem**, or **exclude**;
- required decision, foundational code, migration risk and acceptance test.

#### 2a. Full Lab inventory — required before a Labs decision

**We will examine every current Tower Lab, not a representative sample.** The output must include every individual research line in the current catalog, including its category, unlock condition, levels, costs, duration, slot/queue interactions, source of acceleration, and what it actually changes for the player.

The first coverage pass is in [the dated Lab inventory](TOWER_LAB_INVENTORY_2026-09-22.md): it records every named Lab's identity, category, maximum level, unlock boundary, cost/time-source status and provisional Number Go Up reading. The next pass adds player problem, dependencies and the six unresolved cost/time curves before any implementation decision.

The inventory will cover at least:

- Main, Attack, Defense and Utility research;
- Ultimate Weapon, Card, Perk and Module research;
- Bot, Enemy, Battle Condition, Dissonant Echo, Second Wind and Wall research;
- Lab-speed, Lab-cost, slot, queue, auto-research, history and rush mechanics.

For each Lab, the question is not merely “should we take it?” It is also: **what Number Go Up mechanic could this research make interesting?** A Lab may become an original Breakthrough, a Law interaction, an Ultimate modifier, a Rig tension, a tier condition, an automation unlock, or a reason not to build the equivalent at all.

Completion standard:

1. No named Lab is omitted without a recorded reason.
2. We distinguish Tower-specific combat research from transferable player problems.
3. We identify duplicated permanent multipliers and reject them rather than adding passive noise.
4. We propose at most one small, original Lab-shaped vertical slice only after the inventory and an explicit decision.

#### 2b. Complete Card inventory

Review every Card, slot rule, upgrade/mastery route and preset mechanic. Separate:

- temporary-versus-permanent value;
- interesting trade-offs versus generic percentage bonuses;
- manual, automatic and conditional activation;
- Tower-combat dependencies that cannot cross the boundary.

Output: a proposed deterministic `Protocol`/`Routine` loadout shape, if one is justified, with no packs, copies, rarity or random acquisition.

#### 2c. Complete Module inventory

Review every Module type, slot, main effect, unique effect, substat family, upgrade path, Assist Module and acquisition loop. Keep the useful question—how does a player assemble a build from a small number of meaningful pieces?—separate from the Tower's merging, rerolls, shards and featured banners.

Output: either an original, deterministic equipment/loadout proposal or a documented rejection. Random loot is not the default outcome.

#### 2d. Complete Perk, Vault, Bot, Dissonance and Relic inventories

- **Perks:** each offer type, trade-off, choice cadence, ban/priority rule and the modifier it changes.
- **Vault:** every branch's player problem, unlock currency, respec rule and configuration effect.
- **Bots:** each bot's decision, automation role, upgrade path and why it is not merely another multiplier.
- **Dissonance:** every restriction/reward pair and its tier-specific persistence.
- **Relics:** every source and passive effect, marked carefully as likely collection bloat unless it creates a new decision.

Map viable content to Number Go Up's existing vocabulary: Breakthroughs for durable discoveries, Laws and Violations for stated rules and exceptions, Protocols/Routines for configured behaviour, and challenges for opt-in restrictions through the modifier pipeline.

### 3. Choose one proven next layer

After the inventories, compare the candidates against the active product needs rather than feature count:

| Candidate | It earns a place only if it solves… | Earliest sensible point |
| --- | --- | --- |
| Timed Research | a long-term choice that Workshop ranks cannot express | Rig and Ultimates are playable |
| Protocol/Routine loadout | meaningful run-to-run build changes | several viable build paths exist |
| Perks | interesting within-run decisions beyond spending Number | Rig choices are understood |
| Breakthrough/Law tree | permanent strategic branching | a first branch has observable interactions |
| Challenge conditions | replaying tiers with a different build constraint | base tier roles differ in practice |
| Presets/respec | configuration friction, not hypothetical complexity | players maintain more than one real build |

No implementation begins until its owner document, save impact, deterministic-test plan and success measure are accepted in a new decision.

### 4. Defer until the game has earned them

- random Modules, rarity, merges, rerolls, banners, shards and other loot pressure;
- new currency proliferation, premium shortcuts and collectible passive-bonus piles;
- events, dailies, tournaments, seasons, leaderboards, guilds, Guardians, chat and commerce;
- account, cloud-save and server-authority work, unless Number Go Up is explicitly moved from a local game to a connected product;
- Tower spatial combat, visual identity and its literal terminology.

## Evidence and verification rules

- Prefer official patch notes and current in-game/account evidence; use community references for catalogue detail and label them as such.
- Record a source date/version next to every value, unlock and formula. Tower changes often.
- A reference feature is evidence, not a requirement. Never copy a coefficient, label, content list, art, UI or random-acquisition loop into Number Go Up.
- Before a selected system is built, document its permanent/run/offline/save/RNG boundaries and test them, including old-save migration where state changes.
- Keep this document current after each investigation or decision. Move accepted product intent to [`DECISIONS.md`](DECISIONS.md), not here.

## Immediate next action

Complete the dependency and player-problem pass for the Main, Perk and Battle Condition groups, and cross-check the six missing cost/time curves. Do not propose a Number Go Up Lab system until that evidence is complete and the Rig and Ultimates can be played.

# Number Go Up — Game vision

Status: living document, last revised 21 September 2026.
Companion documents: [`README.md`](../README.md) for the current build, [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) for the researched encounter foundation, [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) for the Workshop categories and the wave rule they rest on.

## Guiding principle

**Make a very simple game, with incredibly deep systems to carry it forward.**

The simplicity is the surface: one verb, one number, one run button. The depth is underneath: a permanent, inspectable web of unlocks and tradeoffs that keeps changing how the simple surface plays.

## One sentence

Number Go Up is a portrait-first, local-save idle game that hides a deep permanent progression web behind a single obvious action: make the Number bigger.

## The ambition

Two influences define the target:

- **The Tower** for encounter structure. Difficulty is two independent checks — can your production clear the requirement, and can your Number survive the hit. Campaign tiers are explicit, mostly reward-neutral difficulty choices rather than strict upgrades, and milestones form the unlock spine.
- **Tech-tree games** for progression structure. Permanent progress is a branching graph: every unlock is legible, changes how earlier systems behave, and compounds with the rest of the tree.

The finished game should be:

- **simple to learn** — a new player understands tap, run, retreat and die without a tutorial;
- **deep to master** — builds, breakpoints, tiers and automation priorities reward planning;
- **honest** — every number that kills you was visible before it did;
- **testable** — systems are deterministic enough to simulate, diff and assert against.

## Core fantasy

Making Number go up is the whole game. Output beats the wave first and only the overflow becomes Number (D012), so Number is score, health and ammunition at once, and every spend is a real decision rather than busywork.

## Design pillars

1. **Simple surface, deep systems.** The main screen never grows into a spreadsheet. Depth lives in menus, trees and numbers the player chooses to inspect.
2. **Two honest axes.** Every encounter has a production check (Liability) and a survival check (Collection). One build cannot trivially solve both.
3. **Run power and permanent power are separate.** Number exists only during a run. Workshop ranks, Coins, Knowledge, Insights and records survive every run ending. Any future temporary layer gets a distinct name and resource instead of blurring this line.
4. **One currency per layer.** Number, Coins and Knowledge are sufficient for the tiered foundation. A new currency has to earn its place by enabling a system the others cannot.
5. **One modifier pipeline.** Laws, Violations, challenges, perks and battle conditions all enter through the shared ordered pipeline. No system gets a special case inside the state machine.
6. **Visible causality.** If a number changed, the player can find out why: inspectable costs, damage, records and summaries over hidden multipliers.
7. **No risk-free growth.** Retreat ends and resets a run. Active runs freeze exactly while away. Waiting, closing the app or banking a run cannot farm a head start.
8. **Legibility over feature count.** Four Workshop categories (Attack, Defense, Utility, Ultimates), one research choice, three tiers. New systems must fit the vocabulary before they fit the code.

## The loops

| Loop | Duration | Player action | Feedback |
| --- | --- | --- | --- |
| Moment | seconds | Tap, or let production tick | Liability falls; once the wave is beaten, Number rises |
| Wave | 15 seconds | Clear Liability before the Collection hit | Clear, collect or die; boss every tenth wave |
| Run | minutes | Start from the permanent baseline, push waves, retreat or die | Coins, Knowledge, run summary, tier record |
| Meta | between runs | Spend Coins in the Workshop, Knowledge on Insight, pick a Research Focus | Every later run starts stronger |
| Spine | long term | Climb waves, claim milestones, unlock tiers, extend the tree | Tier unlocks and new systems |

The run loop is the game. The meta loop exists to make the next run different, not to skip the run loop.

## Where the depth comes from

- **Workshop categories.** Attack beats waves inside the timer, Defense survives the ones it can't, Utility compounds the meta and Ultimates spike at milestones; the interesting builds combine them ([`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md)).
- **Research Focus.** A one-time discount that nudges a build direction without locking alternatives.
- **Tier choice.** Higher tiers multiply pressure faster than rewards, so farming and pushing are different decisions.
- **Milestones and records.** Waves 10/25/50/100 give the run a visible spine; per-tier bests make progress comparable run to run.
- **Automation as a mastered-repetition remover.** Automation should remove decisions the player has already solved, never make the decisions for them.
- **Future tree layers.** Breakthroughs, Laws and Violations are reserved in the taxonomy and must arrive as graph content through the modifier pipeline, not as new special cases.

## Anti-goals

- No currency inflation. Adding a fourth currency needs a system that cannot work without it.
- No live-operations scaffolding (events, dailies, tournaments) before the core run is proven fun.
- No pausing an active run while Number keeps growing, in any form.
- No hidden formulas or per-system exceptions buried in `GameState`.
- No permanent-vs-temporary ambiguity: a layer either survives resets or it does not.
- No copied Tower coefficients, labels or content. Tower data is a validation reference for shape only.

## How the current foundation serves this

| Vision element | Implemented today | Grows into |
| --- | --- | --- |
| Two honest axes | Absolute Liability and Collection per encounter | More encounter patterns, boss modifiers, conditions |
| Permanent progression | Coin-funded Workshop, Knowledge/Insight, Shield Matrix | Research tree, Breakthroughs |
| Run lifecycle | Start from baseline, retreat-as-reset, frozen offline | Temporary in-run layer with its own resource |
| Tiered difficulty | Tiers 1–3 with records and wave-100 unlocks | More tiers behind the same unlock spine |
| Shared rules | Ordered modifier pipeline | Laws, Violations, challenges, battle conditions |
| Vocabulary | `ProgressionTaxonomy` and reserved layer names | Card loadouts, Perks, Modules |
| Verifiability | Economy tests, deterministic seeds, balance simulator | Golden-value and regression gates per layer |

## Definition of done for the foundation

The foundation is locked when:

- a new player can start a run, understand what is happening, die, and explain why;
- retreat, death, app suspension and offline return cannot be turned into pause-and-grow;
- a saved active run resumes identically, including RNG outcomes;
- migration preserves every declared permanent currency and rank;
- the test suite and balance simulator cover the contracts above and run headless;
- one documented, reproducible balance baseline exists that later changes are measured against.

## Open questions

- When a temporary in-run upgrade layer arrives, what is it called and what does it spend?
- Is voluntary Prestige distinct enough from death, in both reward policy and player intent?
- Does the long-term tree branch by Workshop category, by tier, or by encounter pattern?
- At what point does a second automation axis (choosing, not just ordering) become earned depth rather than solved busywork?

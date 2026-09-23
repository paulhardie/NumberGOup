# Game invariants

**Status:** Behavioural contract. Testable where possible.
**Authority:** Owner instruction > accepted decisions in [`DECISIONS.md`](DECISIONS.md) > this document > implementation. Current behaviour is evidence, not automatically intended behaviour.

`Must` items are contracts: a change that breaks one is a defect unless a decision supersedes it. `Should` items are expected behaviour that needs a reported reason to change. `Open` items are explicitly not contracts yet — changing them is allowed, but must be deliberate.

## Must — run lifecycle and permanence

- Number exists only during an active run. Tapping, production ticks and offline time grant nothing outside a run.
- Permanent progress — Workshop ranks (Armor among them), Coins, Knowledge, Insight ranks, Lab ranks, Lab slots and in-progress research, Gems, Card levels and the Active set, and tier records — survives death, retreat and Prestige.
- Research Focus persists through death and retreat and clears only on Prestige. It names one of the four Workshop categories.
- Workshop purchases are unavailable during an active run; permanent power is chosen between attempts. Armor is a Workshop rank, so the run screen's shortcut to it obeys the same lock.
- Starting a Lab is unavailable during an active run, like a Workshop purchase (D024), but a line already researching keeps its real-time clock regardless of run state or whether the app is open. A rank that finishes during a run counts from the next run (D031): a run's power never changes with the wall clock.
- Retreat ends and resets the run. It is never a pause.
- An active run freezes exactly while the app is away; offline time cannot become run progress in any form.
- The wave clock advances only during an active run.

## Must — encounter contracts

- During a run, every unit produced is added to Number and also damages the active wave's remaining Liability (D037). Liability floors at zero, and lifetime production counts each unit once.
- A beaten wave gives way to the next once it has been on screen for the profile's minimum beat (2.5 seconds), never before (D037).
- A Rig rank costs `k` × 5 seconds of the player's steady income (passive rate plus one tap a second, without the boss bonus) × 1.4 per rank of that row already owned (D039). A harder wave never raises a Rig price by itself, and a bulk press costs exactly what the same ranks cost bought singly.
- Collection is an absolute value deducted from Number at each wave boundary while Liability remains. An ordinary wave then moves on, paying its Coins times the share of its HP cleared (floored) and setting no record or Gem (a checkpoint it carried pays once a later wave is beaten); a boss wave stays until beaten and hits at every boundary (D037). Number reaching zero ends and resets the run, unless an unspent Second Wind restores a share of the run's peak Number, which it may do at most once per run (D020).
- Tier 2 and Tier 3 apply exactly 20× and 60× Tier 1 Liability and Collection at equal pressured waves; reward multipliers are 1.8× and 2.6×. These are the profile's ratios; what a player is paid may differ, because Coin Bonus lifts it.
- Boss waves multiply Liability (3×), Collection (1.5×) and reward (5×) independently.
- Each tier's milestone checkpoints pay once per tier record: Gems at every checkpoint, and the Coin bonus at 10/25/50/100 (D030). A checkpoint a record has already passed is paid on load, never twice.
- Every boss wave beaten pays one Gem, every run (D030).
- Tier 2 and Tier 3 unlock only by clearing wave 100 of the preceding tier.
- Tier 1 runs one set of rules from wave 1 (D040): Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) with the milestone steps; a Hit is 20% of its wave's HP at wave 1, rising evenly to 60% by wave 30 and 60% after; bosses are ×3 HP and ×1.5 Hit and stay until beaten (D037); Coins are 0.65 × the wave, ×5 on a boss. No ordinary wave is more than half again as tough as the one before. A Tier 1 run starts with 50 Number. Doing nothing, including no Rig purchases, must end, and must earn clearly less than tapping once a second (under three quarters of its Coins, and under the 48-Coin warm-up payout).
- Every run produces a flat 1 a second from its first second, which upgrades do not raise (D033).

## Must — rules and persistence

- Every rule that changes Liability or Collection passes through the ordered modifier pipeline: flat → additive → multiplicative → cap_max → cap_min, each stage applied once.
- Loaded ranks and levels are whole, never negative and never past their row's cap; ranks under a retired id are kept but count for nothing.
- Save data is versioned with explicit migrations. Migration preserves every declared permanent currency and rank; pre-V4 banked Number retires because Number is run-only. A new saved field bumps the version (D028).
- A save the loader cannot read, or one written by a newer build, is never written over: an unreadable save is moved aside intact and the backup loads, and a newer save pauses saving (D028). A load happens whole or not at all.
- A saved active encounter resumes with identical remaining Liability, RNG state, tick phase and crit chain, so the resumed run produces exactly what the saved one would have; matching run seeds reproduce outcomes.
- `ScientificNumber` values stay finite and non-negative; subtraction floors at zero; balance evaluation cannot overflow ordinary floats.
- `user://number_go_up_save.json` is the live save, with its `.bak` backup beside it; tests must never leave `res://.number_go_up_test_save.json` or any file derived from it behind.

## Should — expected behaviour

- Upgrade costs and ranks are legible before purchase. A multi-buy press costs exactly what the same ranks cost one at a time, and exactly what it quoted.
- A Workshop row's value at its maximum rank is a contract, not a consequence of its rank count: changing a cap without dividing the per-rank effect to match is a retune and needs a decision.
- The first failed Tier 1 run funds permanent Workshop progress. The opening's Coin payout depends on how far the player gets and which one-time checkpoints they first claim; later runs retain every Workshop rank bought with it.
- UI presents and reports; it mutates domain state only by calling `GameState` methods.
- Every Workshop row belongs to exactly one of the four categories (Attack, Defense, Utility, Ultimates) and opens at its own Workshop level: 0, 12, 30 or 60. Retired bays gated each row at the same level the row itself required, so their removal moved nothing; D019 then moved the levels to hold the same Coin pacing across deeper ladders.
- Brace spends 30% of current Number, less whatever Brace Cost has bought, never below a 15% floor, and blocks exactly the next Collection hit. A blocked boundary deals no Thorns, because no hit landed (D038).
- A run ending explains itself: the summary states the tier, wave, Coins and Knowledge earned. A run lost to a hit also names the hit and the two gaps — the wave HP Attack left and the Number shortfall against the hit — while a retreat or Prestige records no hit and no gaps. Prestige replaces the previous run's summary and names its Knowledge gain.
- Highest Number and tier records persist across runs for stats and dock unlocks.

## Open — not yet contracts

- **Prestige versus death.** Both share reset machinery. Today death can grant Knowledge while voluntary retreat grants none; whether Prestige needs a distinct reward policy is unsettled (see decisions D003 and D008).
- **Dormant momentum.** No upgrade definition grants `momentum_per_tick`, so momentum stacks never rise. The mechanic is either awaiting a card or dead code.
- **Migration automation remnants.** `automation_enabled`, `workshop.automation_targets`, `has_automation()` and `get_auto_slot_count()` exist only to migrate V1/V2 saves. Automation is not an active system.
- **Unused offline cap.** `OFFLINE_CAP_SECONDS` is unused while `apply_offline()` always returns an empty award.
- **Unlock thresholds** are keyed to `highest_number` at 10 / 1,000 / 110,000. Since D016 they gate the Workshop tab and the rows inside the Knowledge sheet rather than dock icons. The values are presentation, not balance.

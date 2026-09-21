# Game invariants

**Status:** Behavioural contract. Testable where possible.
**Authority:** Owner instruction > accepted decisions in [`DECISIONS.md`](DECISIONS.md) > this document > implementation. Current behaviour is evidence, not automatically intended behaviour.

`Must` items are contracts: a change that breaks one is a defect unless a decision supersedes it. `Should` items are expected behaviour that needs a reported reason to change. `Open` items are explicitly not contracts yet — changing them is allowed, but must be deliberate.

## Must — run lifecycle and permanence

- Number exists only during an active run. Tapping, production ticks and offline time grant nothing outside a run.
- Permanent progress — Workshop ranks (Armor among them), Coins, Knowledge, Insight ranks and tier records — survives death, retreat and Prestige.
- Research Focus persists through death and retreat and clears only on Prestige. It names one of the four Workshop categories.
- Workshop purchases are unavailable during an active run; permanent power is chosen between attempts. Armor is a Workshop rank, so the run screen's shortcut to it obeys the same lock.
- Retreat ends and resets the run. It is never a pause.
- An active run freezes exactly while the app is away; offline time cannot become run progress in any form.
- The wave clock advances only during an active run.

## Must — encounter contracts

- During a run, every unit produced damages the active wave's remaining Liability first; only output beyond it is added to Number (D012). Liability floors at zero, and lifetime production counts all output.
- Collection is an absolute value deducted from Number at each wave boundary while Liability remains. Number reaching zero ends and resets the run.
- Tier 2 and Tier 3 apply exactly 20× and 60× Tier 1 Liability and Collection at equal pressured waves; reward multipliers are 1.8× and 2.6×.
- Boss waves multiply Liability (3×), Collection (1.5×) and reward (5×) independently.
- Milestones at waves 10/25/50/100 are claimable at most once per tier record.
- Tier 2 and Tier 3 unlock only by clearing wave 100 of the preceding tier.
- Tier 1 waves 1–20 are grace waves: no Liability or Collection, with repeatable Coin rewards (1 per wave, 5 on boss waves).

## Must — rules and persistence

- Every rule that changes Liability or Collection passes through the ordered modifier pipeline: flat → additive → multiplicative → cap_max → cap_min, each stage applied once.
- Save data is versioned with explicit migrations. Migration preserves every declared permanent currency and rank; pre-V4 banked Number retires because Number is run-only.
- A saved active encounter resumes with identical remaining Liability and identical RNG state; matching run seeds reproduce outcomes.
- `ScientificNumber` values stay finite and non-negative; subtraction floors at zero; balance evaluation cannot overflow ordinary floats.
- `user://number_go_up_save.json` is the live save; tests must never leave `res://.number_go_up_test_save.json` behind.

## Should — expected behaviour

- Upgrade costs and ranks are legible before purchase.
- The first failed run funds at least one permanent Workshop rank.
- UI presents and reports; it mutates domain state only by calling `GameState` methods.
- Every Workshop row belongs to exactly one of the four categories (Attack, Defense, Utility, Ultimates) and opens at its own Workshop level: 0, 2, 5 or 8. Retired bays gated each row at the same level the row itself required, so their removal moved nothing.
- Brace spends 30% of current Number and blocks exactly the next Collection hit.
- A run ending explains itself: the summary states the tier, wave, Coins and Knowledge earned.
- Highest Number and tier records persist across runs for stats and dock unlocks.

## Open — not yet contracts

- **Prestige versus death.** Both share reset machinery. Today death can grant Knowledge while voluntary retreat grants none; whether Prestige needs a distinct reward policy is unsettled (see decisions D003 and D008).
- **Dormant momentum.** No upgrade definition grants `momentum_per_tick`, so momentum stacks never rise. The mechanic is either awaiting a card or dead code.
- **Migration automation remnants.** `automation_enabled`, `workshop.automation_targets`, `has_automation()` and `get_auto_slot_count()` exist only to migrate V1/V2 saves. Automation is not an active system.
- **Unused offline cap.** `OFFLINE_CAP_SECONDS` is unused while `apply_offline()` always returns an empty award.
- **Dock unlock thresholds** are keyed to `highest_number` at 10 / 1,000 / 110,000. The values are presentation, not balance.

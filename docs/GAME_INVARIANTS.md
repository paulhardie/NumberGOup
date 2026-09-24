# Game invariants

**Status:** Behavioural contract. Testable where possible.
**Authority:** Owner instruction > accepted decisions in [`DECISIONS.md`](DECISIONS.md) > this document > implementation. Current behaviour is evidence, not automatically intended behaviour.

`Must` items are contracts: a change that breaks one is a defect unless a decision supersedes it. `Should` items are expected behaviour that needs a reported reason to change. `Open` items are explicitly not contracts yet — changing them is allowed, but must be deliberate.

## Must — run lifecycle and permanence

- Number exists only during an active run. Tapping, production ticks and offline time grant nothing outside a run.
- Permanent progress — Workshop ranks (Armor among them), Coins, Knowledge, Insight ranks, Lab ranks, Lab slots and in-progress research, Gems, Card levels and the Active set, and tier records — survives death, retreat and Prestige.
- Research Focus persists through death and retreat and clears only on Prestige. It names one of the four Workshop categories.
- Workshop purchases are unavailable during an active run; permanent power is chosen between attempts. Armor is a Workshop rank, so it obeys the same lock.
- Starting a Lab is unavailable during an active run, like a Workshop purchase (D024), but a line already researching keeps its real-time clock regardless of run state or whether the app is open. A rank that finishes during a run counts from the next run (D031): a run's power never changes with the wall clock.
- Retreat ends and resets the run. It is never a pause.
- An active run freezes exactly while the app is away; offline time cannot become run progress in any form.
- The wave clock advances only during an active run.

## Must — encounter contracts

- During a run, every unit produced is added to Number and also damages the active wave's remaining Liability (D037). Liability floors at zero, and lifetime production counts each unit once.
- A beaten wave gives way to the next once it has been on screen for the profile's minimum beat (2.5 seconds), never before (D037).
- An ordinary wave is a group (D057): 3 members at wave 1, one more every 11 waves, at most 20; a boss is one. Members share the wave's HP and Hit evenly, so their totals are the wave's. Damage strikes the front living member (members at the Number first, carried ones first of all), and what passes its HP is lost. Members arrive in order, the front at 6 seconds and the last at 15, evenly spaced. A member that reaches the Number lands its share of the Hit, after Guard and Armor on its wave's whole Hit, then stays and hits again until beaten (D058): to wave 30 it instead hits once and leaves, its HP uncleared (D059); from wave 31 it stays, hitting every 15 seconds and easing to `MEMBER_HIT_SECONDS` (5) by wave 50. An ordinary wave whose own members are all beaten, before or after landing, counts as beaten after the minimum beat; one with a member alive when its 15-second clock runs out passes, paying for the share cleared, and its living members carry into the next wave, in front. A boss holds its wave until beaten and hits every 15 seconds. A Brace blocks every hit, the pile's included, until the wave's clock ends. A save written under D059 resumes each member's HP, state and clock exactly; an older D058 V10 active save is reconciled to the D059 opening on load (D060).
- The wave's numbers on screen (D050, D051, D057) are presentation: each member's place is its own arrival clock, it reaches the Number exactly when its share of the Hit lands, a boss that has landed stays there, and nothing about it (or the motes) feeds back into a rule or the run's random stream. Motes delay only the shown HP, never the damage. The wave shows its raw Hit, and the working shown at contact (D052) comes from the same pipeline as the Hit, so its parts always add up to what landed.
- A run rank (run Upgrades, D045) costs `k` × 5 seconds of the player's steady income (passive rate plus one tap a second, without the boss bonus) × 1.4 per rank of that row already owned (D039), less Discount, never below a tenth of that price. A harder wave never raises a run price by itself, and a bulk press costs exactly what the same ranks cost bought singly, including a press of Discount itself.
- Tap Damage and Damage (Damage per Second before D054) run to 6,000 ranks and Guard to 5,000 (D047). Ranks 1–100 keep their step, so an owned rank never loses value (since D055 a Damage step is per shot at 2.5 times the shots, the same damage a second); past 100 a rank is worth more along the row's depth curve, and never less than the rank before it. A row keeps its old prices up to its old cap, and past it each rank costs the row's deep growth more than the last. A Workshop multi-buy quotes exactly the ranks and price that single presses would.
- A row's Workshop ranks and run ranks together never pass its max rank, and one run rank is worth two Workshop ranks, except Burst's, which is one step (D044).
- Run Upgrades spend Cash, never Number (D042). Cash exists only during a run: it flows at the same steady income run prices are quoted in, whether or not the player taps; a beaten wave adds 10 + 5 × the wave (×3 on a boss) and a missed wave that share of it cleared; a run starts with 12.5 seconds of its opening income. Every ending clears it. Run Upgrades sell all 21 Workshop rows; a Cushion rank bought in a run adds its starting Number, at the run rank's worth and the tier's Cushion scale, to the current Number at once.
- Collection is an absolute value deducted from Number, a member's share at a time: when it reaches the Number and at every hit after while it stays (D057, D058); a boss's at every 15-second boundary until beaten (D037). An ordinary wave still standing when its clock runs out moves on, paying its Coins times the share of its own HP cleared (floored) and setting no record or Gem (a checkpoint it carried pays once a later wave is beaten). Number reaching zero ends and resets the run, unless an unspent Second Wind restores a share of the run's peak Number, which it may do at most once per run (D020).
- Tier 2 and Tier 3 apply exactly 20× and 60× Tier 1 Liability and Collection at equal pressured waves; reward multipliers are 1.8× and 2.6×. These are the profile's ratios; what a player is paid may differ, because Coin Bonus lifts it.
- Boss waves multiply Liability (3×), Collection (1.5×) and reward (5×) independently.
- Each tier's milestone checkpoints pay once per tier record: Gems at every checkpoint from wave 10 to 5,000, and the Coin bonus at 10/25/50/100/250/500/750/1,000/2,500/5,000 (D030, D043). A checkpoint a record has already passed is paid on load, never twice.
- Every boss wave beaten pays one Gem, every run (D030).
- Tier 2 and Tier 3 unlock only by clearing wave 100 of the preceding tier.
- Tier 1 runs one set of rules from wave 1 (D040): Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) with the milestone steps; the Hit follows its own curve, 1.7 × (0.08 w^2.10 + 0.4 w + 1.0) with the same milestone steps, not a share of Wave HP (D043, D046); bosses are ×3 HP and ×1.5 Hit and stay until beaten (D037); Coins are 0.65 × the wave, ×5 on a boss. Below wave 100, no ordinary wave's HP or Hit is more than 1.6× the ordinary wave before it; the ×1.5 milestone at wave 100 is the deliberate tier gate. A run saved under an older balance profile resumes with its active wave rebuilt on the current curve, keeping the share already cleared. A Tier 1 run starts with 50 Number. Doing nothing, including no Rig purchases, must end, and must earn clearly less than tapping once a second (under three quarters of its Coins).
- Every run produces a flat 1 a second from its first second, which upgrades do not raise (D033).

## Must — rules and persistence

- Every rule that changes Liability or Collection passes through the ordered modifier pipeline: flat → flat_reduce → additive → multiplicative → cap_max → cap_min, each stage applied once.
- A Hit never drops below 10% of its base size after Guard and Armor together (WORKSHOP_EXPANSION); Guard takes a flat amount off every Hit, priced in the tier's Hit pressure, applied before Armor.
- Loaded ranks and levels are whole, never negative and never past their row's cap; ranks under a retired id are kept but count for nothing.
- Save data is versioned with explicit migrations. Migration preserves every declared permanent currency and rank; pre-V4 banked Number retires because Number is run-only. A new saved field bumps the version (D028).
- A save the loader cannot read, or one written by a newer build, is never written over: an unreadable save is moved aside intact and the backup loads, and a newer save pauses saving (D028). A load happens whole or not at all.
- A current-rules saved active encounter resumes with identical remaining Liability, RNG state, tick phase and crit chain, so the resumed run produces exactly what the saved one would have; matching run seeds reproduce outcomes. Loading a D058 V10 active save under D059 removes earlier opening-wave pile members, turns an opening member that already hit into a departed member with uncleared HP, gives approaching opening members one Hit only, and updates waves 31–49 to their eased repeat clocks (D060). Number and Hits already paid remain as saved.
- `ScientificNumber` values stay finite and non-negative; subtraction floors at zero; balance evaluation cannot overflow ordinary floats.
- Card pulls level up one unmaxed card. Maxed cards are excluded from the pull pool; if all cards are maxed, pulling is disabled and no Gems can be spent.
- `user://number_go_up_save.json` is the live save, with its `.bak` backup beside it; tests must never leave `res://.number_go_up_test_save.json` or any file derived from it behind.

## Should — expected behaviour

- Upgrade costs and ranks are legible before purchase. A multi-buy press costs exactly what the same ranks cost one at a time, and exactly what it quoted.
- A Workshop row's value at its maximum rank is a contract, not a consequence of its rank count: changing a cap without dividing the per-rank effect to match is a retune and needs a decision.
- The first failed Tier 1 run funds permanent Workshop progress. The opening's Coin payout depends on how far the player gets and which one-time checkpoints they first claim; later runs retain every Workshop rank bought with it.
- UI presents and reports; it mutates domain state only by calling `GameState` methods.
- Every Workshop row belongs to exactly one of the four categories (Attack, Defense, Utility, Ultimates) and opens at its own Workshop level: 0, 12, 30 or 60. Retired bays gated each row at the same level the row itself required, so their removal moved nothing; D019 then moved the levels to hold the same Coin pacing across deeper ladders.
- Brace spends 30% of current Number, less whatever Brace Cost has bought, never below a 15% floor, and blocks every hit until the wave's clock ends: a boss's next boundary, or every hit of the ordinary wave's clock, the pile's included (D057, D058). A blocked Hit deals no Thorns, because no hit landed (D038).
- A run ending explains itself: the summary states the tier, wave, Coins and Knowledge earned. A run lost to a hit also names the hit and the two gaps — the wave HP Attack left and the Number shortfall against the hit — while a retreat or Prestige records no hit and no gaps. Prestige replaces the previous run's summary and names its Knowledge gain.
- Highest Number and tier records persist across runs for stats and dock unlocks.

## Open — not yet contracts

- **Prestige versus death.** Both share reset machinery. Today death can grant Knowledge while voluntary retreat grants none; whether Prestige needs a distinct reward policy is unsettled (see decisions D003 and D008).
- **Dormant momentum.** No upgrade definition grants `momentum_per_tick`, so momentum stacks never rise. The mechanic is either awaiting a card or dead code.
- **Migration automation remnants.** `automation_enabled`, `workshop.automation_targets`, `has_automation()` and `get_auto_slot_count()` exist only to migrate V1/V2 saves. Automation is not an active system.
- **Unused offline cap.** `OFFLINE_CAP_SECONDS` is unused while `apply_offline()` always returns an empty award.
- **Unlock thresholds** are keyed to `highest_number` at 10 / 1,000 / 110,000. Since D016 they gate the Workshop tab (and since D048 the Cards and Labs seats, at the same 10) and the rows inside the Knowledge sheet rather than dock icons. The values are presentation, not balance.

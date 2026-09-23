# Handover

**Last updated:** 23 September 2026. D044–D046 are merged to `main`; branch `codex/labs-cards-visibility` makes the existing Labs and Cards visible as labelled Workshop entrances. No progression or save rule changed on that branch.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## Where the game is

`main` plus branch `codex/labs-cards-visibility` plays like this (seed 7 simulator figures for D046, Godot 4.7.2, balance profile `tax-foundation-v10`; nothing below has been checked on a phone):

- **The core loop (D037, D038):** everything you produce is Number and also damages the wave. A beaten wave gives way to the next after 2.5 seconds. A missed ordinary wave hits once and moves on, paying Coins for the share you cleared. Bosses, every 10th wave, stay and hit every 15 seconds until you beat them. Guard cuts the Hit by a flat amount before Armor's percentage.
- **Labs and Cards (D024, D027):** both systems already work. The Workshop now has full-width labelled entrances to their existing sheets, with a short note explaining Coin research and Gem-pulled active Cards. The small-phone capture showed that the former icon-only entrances were easy to miss.
- **Run Upgrades (the Rig in code; D042, D044, D045):** during a run all 21 Workshop rows can be raised with run-only Cash; Number is never spent on them.
  - A row's Workshop ranks and run ranks together stop at its max rank, so a Workshop-maxed row shows MAX and sells nothing. A run rank is worth two Workshop ranks (Burst's is one step).
  - Cash flows at the priced income (passive rate plus one tap a second, whether or not you tap). A beaten wave adds 10 + 5 × the wave, ×3 on a boss; a missed wave adds the share it cleared. A run starts with 12.5 seconds of its opening income.
  - Prices: about 5 seconds of income, ×1.4 per run rank of that row. Discount lowers them.
- **Difficulty (D043):** Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) and the Hit = 1.7 × (0.08 w^2.10 + 0.4 w + 1) (D046), both with the milestone steps. Bosses are ×3 HP and ×1.5 Hit. Tiers 2 and 3 multiply by 20 and 60. Milestones run from wave 10 to 5,000.
- **Where builds land (two taps a second):**

  | Build | Not buying run ranks | Buying run ranks |
  | --- | --- | --- |
  | Fresh | wave 20, 86 Coins | wave 24, 186 Coins |
  | Early Workshop | wave 30 | wave 40 |
  | Mid Workshop | wave 55 | wave 60 |
  | Max Attack | wave 100 (dies at the boss) | wave 105 (buys Defense) |
  | Max Attack + Armor | wave 110 | wave 112 |
  | Everything maxed | wave 120 | wave 120 (nothing to buy) |

  A career from a fresh save (`tools/career_simulator.gd`, 40 runs) reaches wave 100 in 7.3 hours without run ranks and 5.2 with them.
- **Balance targets ([`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md)):** 1, 3, 4, 5, 7, 9 and 10 hold; 5 holds on all ten measured seeds. 8 is restated by D044 and holds. 2 still fails by design since D037.

## Open decisions for the owner

1. **Save schema V9.** `cash` and `run_cash_earned` widened V8 instead of bumping it, which D028 rules out. Recommended: bump to V9 with a V8 migration, together with coin gates' `workshop_unlocks` if those are accepted.
2. **The Tower parity plan and coin gates** ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#tower-parity-plan-and-coin-gates--proposed-23-september-2026)): the gate model, the measured ladder (first gates 100, 250, 500; since D046, a player who never buys run Upgrades doesn't reach wave 100 within 40 gated runs), the starter rows, run Upgrades selling only unlocked rows, each new mechanic, and three primitives (movable Hit timer, wave queue, difficulty counter).
3. **Tier unlock wave:** still 100 (`TIER_UNLOCK_WAVE`).
4. **Coins per minute (balance target 2):** above target since D037. Accept and restate, or bring Coins down.
5. **The Workshop ladders** ([`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md)): 5,000-rank core rows, bands per tier, `data/workshop/` as the single source.
6. **Still open from before:** Bounty, Finisher, Streak, Payback and Auto Tap; the Tiers 1–10 proposal ([`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md)); the play-folder sync rule on branch `claude/sync-play-checkout`; enemy-growth suppression ([`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md)).

## Next steps, in order

1. **Owner:** decide coin gates and save V9; then **agent:** build them together as the parity plan's step 1. High risk: saves, economy.
2. **Agent:** the ordered player-stat pipeline (parity plan step 2), which almost every new row needs. Medium–high risk: touches every stat.
3. **Agent:** the combat HUD pass in [`src/ring_arc.gd`](../src/ring_arc.gd) and [`src/main.gd`](../src/main.gd) (D041; [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md)). Medium risk: presentation.

## Known issues and risks

- **Lab research is unreachable past about rank 20.** Each rank takes 1.55× longer and costs 1.7× more. Needs its own pass with the Gem economy.
- **Run ranks are Workshop-sized.** Late in a run a flat Tap Damage or Damage per Second rank adds very little.
- **The wave 100 boss** doubles in one step: the ×1.5 milestone lands on the boss's ×3. It's the tier gate, left as is.
- **Cash counts a tap a second even when you're idle**, so an idle player buying run ranks keeps pace with a light tapper.
- **`run_cash_earned` is saved but nothing reads it**, and `tools/balance_simulator.gd` still carries the unused `_rig_reserve`.
- **`src/game_data.gd.uid`** is not committed, though the other scripts' `.uid` files are.
- **No independent review** has run on D042–D046's economy diffs; this environment's agents are only spawned when the owner asks.

## Working notes

- **The owner plays from `~/NumberGOup-main`.** It must end on merged `main`. When a game is running from it, work in a separate worktree.
- **Labs/Cards visibility branch verification:** `bash run_tests.sh` passed with normal macOS certificate access; a headless main-scene boot passed; windowed captures at 320×568 and 390×844 show both labelled buttons; a windowed pointer press opened each matching sheet at 320×568. A real phone/Web build was not checked. No save or economy source changed.
- **Every economy change** needs `bash run_tests.sh`, `bash run_balance.sh` before and after, the career simulator for anything that changes pacing, and an independent review of the diff ([`QUALITY_GATES.md`](QUALITY_GATES.md)).
- **`tools/export_workshop.gd`** regenerates `data/workshop/current.*` from the live game. Rerun it after any catalogue or profile change.

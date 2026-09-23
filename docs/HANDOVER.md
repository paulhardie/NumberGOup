# Handover

**Last updated:** 23 September 2026, after a review of D042 and D043: Cash now flows at the income Rig prices are quoted in, and the docs describe Cash and the new Hit curve.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## Where the game is

`main` plays like this (seed 7 simulator figures, Godot 4.7.2, balance profile `tax-foundation-v8`; nothing below has been checked on a phone):

- **The core loop (D037, D038):** everything you produce is Number and also damages the wave. A beaten wave gives way to the next after 2.5 seconds. A missed ordinary wave hits once and moves on, paying Coins for the share you cleared. Bosses, every 10th wave, stay and hit every 15 seconds until you beat them. Leech and Thorns are boss-fight stats. Guard cuts the Hit by a flat amount before Armor's percentage.
- **The Rig spends Cash (D042):** all 21 Workshop rows can be bought during a run with run-only Cash; Number is never spent on it.
  - Cash flows at the Rig's priced income (passive rate plus one tap a second, whether or not you tap). A beaten wave adds 10 + 5 × the wave, ×3 on a boss; a missed wave adds the share it cleared. A run starts with 12.5 seconds of its opening income.
  - A Cushion rank bought in a run adds its Number at once. Discount lowers Rig prices, from Workshop and Rig ranks alike.
  - Prices are unchanged from D039: about 5 seconds of income, ×1.4 per rank owned.
- **Difficulty (D043):** Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) and the Hit = 1.5 × (0.08 w^2.10 + 0.4 w + 1), both with the milestone steps. Against D040 the Hit is 12–18% larger in the first five waves and 17–25% smaller from wave 30 on. Bosses are ×3 HP and ×1.5 Hit. Tiers 2 and 3 multiply by 20 and 60. Milestones run from wave 10 to 5,000; ten of them pay Coins.
- **Where builds land (two taps a second):**

  | Build | Hoarding | Playing the Rig |
  | --- | --- | --- |
  | Fresh | wave 20, 86 Coins | wave 30, 232 Coins |
  | Early Workshop | wave 33 | wave 47 |
  | Mid Workshop | wave 60 | wave 70 |
  | Max Attack | wave 103 | **wave 130** |
  | Max Attack + Armor | wave 116 | wave 158 |
  | Everything maxed | wave 128 | wave 170 |

  The representative first run reaches the wave 20 boss with 106 Coins. One tap a second buying Rig ranks reaches wave 29 with 231 Coins; an idle player buying Rig ranks reaches wave 20 with 102.
- **Balance targets ([`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md)):** 5 (wave 100 needs Defense) holds for Workshop builds only; **max Attack playing the Rig reaches wave 130 with no Defense.** 7 (the Rig cannot replace the Workshop) is borderline: fresh + Rig reaches wave 30, where early Workshop builds stopped before D042. 10's idle clause fails for an idle player who buys the opening Rig ranks (first hit at 73 seconds). 2 still fails by design since D037.

## Open decisions for the owner

1. **Rig strength under Cash.** The ×3 Rig rank worth (D023) was set so a rank beat the Hit buffer it spent; Cash removed that cost. Re-sweep the multiplier, prices and Cash rate against targets 5 and 7, or restate those targets. Lowering the multiplier alone is not enough: at ×2, max Attack + Rig still reaches wave 120.
2. **Save schema V9 for Cash.** `cash` and `run_cash_earned` widened V8 instead of bumping it, which D028 rules out; an older build would load a mid-run save and write it back without Cash. Recommended: bump to V9 with a V8 migration.
3. **Tier unlock wave:** still 100 (`TIER_UNLOCK_WAVE`). Decide what should unlock Tier 2 as ladders and content grow.
4. **Coins per minute (balance target 2):** rewards came up about 1.5–1.8× when beaten waves stopped waiting out their timers (D037), and D042 roughly doubles early-run Coins again. Accept and restate the target, or bring Coins down.
5. **The Workshop ladders** ([`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md), with data in [`data/workshop/`](../data/workshop/)): 5,000-rank core rows, a band of ranks per tier, dropping Breakthroughs from pacing, and making `data/workshop/` the Workshop's single source.
6. **Still open from before D042:** the Workshop expansion rows ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)), the Tiers 1–10 proposal ([`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md)), the play-folder sync rule on branch `claude/sync-play-checkout`, and enemy-growth suppression ([`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md)).
7. **`AGENTS.md` law 4** still says the Rig spends Number (D015). It is a working rule, so it changes only on owner instruction.

## Next steps, in order

1. **Owner:** decide open decision 1; then **agent:** re-sweep and retune with `run_balance.sh` before and after. High risk: economy.
2. **Agent:** implement the combat HUD pass in [`src/ring_arc.gd`](../src/ring_arc.gd) and [`src/main.gd`](../src/main.gd): an outer ring for the 15-second Hit timer around the inner Wave HP ring, clearing to `BEATEN · NO HIT`, and an encounter line reading `HIT: X (-Y% ARMOR) IN Zs · W HP LEFT` (D041; [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md)). Medium risk: presentation and touch.
3. **Owner with new players:** watch a fresh 10–20-minute run. Check whether players can read the two rings and explain why a clean clear avoided a Hit.

## Known issues and risks

- **Lab research is unreachable past about rank 20.** Each rank takes 1.55× longer and costs 1.7× more, so maxing Damage Research would take about 425 years. Needs its own pass with the Gem economy.
- **Rig ranks are Workshop-sized.** Late in a run a flat Tap Damage or Damage per Second rank adds very little. The percentage Boosts in the tier proposal would fix it.
- **The wave 100 boss** doubles in one step: the ×1.5 milestone lands on the boss's ×3. It's the tier gate, left as is.
- **`run_cash_earned` is saved but nothing reads it**, and `tools/balance_simulator.gd` still carries the unused `_rig_reserve` from Number-priced Rig play.
- **`src/game_data.gd.uid`** is not committed, though the other scripts' `.uid` files are; a fresh import creates it.

## Working notes

- **The owner plays from `~/NumberGOup-main`.** It must end on merged `main`. When a game is running from it (`Godot --path /Users/paulhardie/NumberGOup-main`), work in a separate worktree. After a merge, check `git -C ~/NumberGOup-main status -sb` reads `## main...origin/main`.
- **Every economy change** needs `bash run_tests.sh`, `bash run_balance.sh` before and after, and an independent review of the diff ([`QUALITY_GATES.md`](QUALITY_GATES.md)).
- **`tools/export_workshop.gd`** regenerates `data/workshop/current.*` from the live game. Rerun it after any catalogue or profile change.

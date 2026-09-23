# Handover

**Last updated:** 23 September 2026, after D042 (Cash economy & 21-row Workshop parity) and D043 (decoupled Wave Attack curve & 5,000-wave milestones) committed and pushed to `main` (commit `dfbac69`).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## Where the game is

`main` plays like this (seed 7 simulator figures; verified with Godot 4.7.2):

- **The core loop (D037, D038):** everything you produce is Number and also damages the wave. A beaten wave gives way to the next after 2.5 seconds. A missed ordinary wave hits once and moves on, paying Coins for the share you cleared. Bosses, every 10th wave, stay and hit every 15 seconds until you beat them. Siphon became Leech and Recoil became Thorns: both are boss-fight stats. Guard cuts the Hit by a flat amount before Armor's percentage.
- **In-run Cash & Rig parity (D042):**
  - Upgrades during a run spend **Cash**, completely separating in-run upgrades from the **Number** health pool. Purchasing upgrades never endangers player survival.
  - **100% Workshop parity:** all 21 Workshop rows (11 Attack, 7 Defense, 3 Utility) can be purchased in the Rig during an active run, matching *The Tower*.
  - Cash is earned continuously per second based on steady income rate, plus bonuses on wave clears (2× income rate, 6× on bosses). Runs start with an opening Cash buffer (`starting_cash()`) enabling 1–2 immediate purchases.
  - Cash is strictly run-scoped and resets on run conclusion; mid-run saves preserve `cash` and `run_cash_earned` in `SaveDataV8`.
- **Decoupled difficulty & 5,000-wave milestones (D043):**
  - **Wave HP:** $4 \times (0.05 w^{2.13} + 0.8 w + 1.5) \times \text{milestones}$.
  - **Wave Hit:** $1.5 \times (0.08 w^{2.10} + 0.4 w + 1.0) \times \text{milestones}$ (independent curve; not tied to HP).
  - Bosses are ×3 HP and ×1.5 Hit.
  - **5,000-wave depth:** Waves can run indefinitely. Milestones extend to wave 5,000 with checkpoints at:
    - All milestones: 10, 20, 25, 30, 40, 50, 60, 75, 90, 100, 150, 200, 250, 350, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000.
    - Coin milestones: 10, 25, 50, 100, 250, 500, 750, 1000, 2500, 5000.
  - Tiers 2 and 3 multiply the same curve by 20 and 60.
- **Where builds land (profile v8, seed 7):**

  | Build | Result |
  | --- | --- |
  | First run (two taps a second) | wave 20 boss, ~102 Coins |
  | Fresh run + Rig | wave 30, ~8.9 minutes, 234 Coins |
  | Mid Workshop + Rig | wave 70, ~16.2 minutes, 1,632 Coins |
  | Max Attack (solo, no defense) | wave 103, ~19.7 minutes, 3,808 Coins |
  | Max Attack + Armor | wave 116, ~26.0 minutes, 4,264 Coins |
  | Max Attack + Armor + Rig | wave 150, ~35.3 minutes, 6,811 Coins |
  | Tier 2, all Defense | wave 50 |

- **Balance targets:** 5 (wave 100 needs Defense) holds strongly (max Attack dies at wave 103 boss; adding Armor reaches 116).

## Open decisions for the owner

1. **Combat HUD presentation:** implementing the concentric dual ring (Wave HP inner ring, 15s Hit timer outer ring) and dynamic mitigation telemetry readout (`[ HIT: 340 (-38% ARMOR) IN 4.2s ]`).
2. **Tier unlock wave threshold:** currently 100 (`TIER_UNLOCK_WAVE = 100`). Decide what wave should unlock Tier 2 as ladders and content grow.
3. **Coins per minute (balance target 2):** rewards came up about 1.5–1.8× when beaten waves stopped waiting out their timers (D037). Accept and restate the target, or bring Coins down.
4. **The Workshop ladders** ([`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md), with data in [`data/workshop/`](../data/workshop/)): 5,000-rank core rows, a band of ranks per tier, dropping Breakthroughs from pacing, and making `data/workshop/` the Workshop's single source.

## Immediate next steps for incoming agent

1. **Implement the combat HUD pass (Item 2):**
   - In [`src/ring_arc.gd`](../src/ring_arc.gd): Add a concentric outer arc (radius ~0.37, thickness ~3.0px) representing the 15-second Hit timer ticking clockwise towards 12 o'clock, while the inner ring (radius ~0.31, thickness ~7.0px) tracks Wave HP cleared. When a wave is cleared, the timer ring snaps away cleanly (`BEATEN · NO HIT`).
   - In [`src/main.gd`](../src/main.gd): Update `encounter_label` to show dynamic mitigation readout: `[ HIT: X (-Y% ARMOR) IN Zs · W HP LEFT ]` when active, and `BEATEN · NO HIT` when cleared.
   - Reference: [`docs/COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md) and D041.
2. **Owner with new players:** watch a fresh 10–20-minute run. Check whether players can read the inner vs outer ring and explain why a clean clear avoided a Hit.
3. **Agent:** build a GDScript career simulator on the real rules before tuning new combat or progression systems.

## Known issues and risks

- **Lab research is unreachable past about rank 20.** Each rank takes 1.55× longer and costs 1.7× more, so maxing Damage Research would take about 425 years. Needs its own pass with the Gem economy.
- **Rig ranks are Workshop-sized.** Late in a run a flat Tap Damage or Damage per Second rank adds very little. The percentage Boosts in the tier proposal would fix it.
- **The wave 100 boss** doubles in one step: the ×1.5 milestone lands on the boss's ×3. It's the tier gate, left as is.

## Working notes

- **The owner plays from `~/NumberGOup-main`.** It must end on merged `main`. When a game is running from it (`Godot --path /Users/paulhardie/NumberGOup-main`), work in a separate worktree. After a merge, check `git -C ~/NumberGOup-main status -sb` reads `## main...origin/main`.
- **Every economy change** needs `bash run_tests.sh`, `bash run_balance.sh` before and after, and an independent review of the diff ([`QUALITY_GATES.md`](QUALITY_GATES.md)).
- **`tools/export_workshop.gd`** regenerates `data/workshop/current.*` from the live game. Rerun it after any catalogue or profile change.

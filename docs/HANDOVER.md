# Handover

**Last updated:** 23 September 2026, after adding Card duplicate protection and moving Workshop data to JSON.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## Where the game is

`main` plays like this (seed 7 simulator figures; nothing below has been checked on a phone yet):

- **The core loop (D037, D038):** everything you produce is Number and also damages the wave. A beaten wave gives way to the next after 2.5 seconds. A missed ordinary wave hits once and moves on, paying Coins for the share you cleared. Bosses, every 10th wave, stay and hit every 15 seconds until you beat them. Siphon became Leech and Recoil became Thorns: both are boss-fight stats.
- **Rig prices (D039):** a rank costs about 5 seconds of your steady income, ×1.4 for each rank of that row you already own. A fresh run's first ranks cost about 10 Number, and harder waves never raise prices by themselves.
- **Tier 1 difficulty (D040):** one curve from wave 1, no warm-up.
  - Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5), with milestone steps every 10, 50 and 100 waves.
  - A Hit is 20% of its wave's HP at wave 1, rising to 60% by wave 30.
  - Bosses are ×3 HP and ×1.5 Hit.
  - Coins are 0.65 × the wave, ×5 on a boss.
  - Tiers 2 and 3 multiply the same curve by 20 and 60.
- **Card duplicate protection:** maxed cards are excluded from the pull pool, and pulls are disabled once the catalogue is complete, preventing wasted Gems.
- **Data layer:** Workshop and Knowledge catalogues load from canonical JSON in `res://data/` via `GameData`.
- **Where builds land:**

  | Build | Result |
  | --- | --- |
  | First run, two taps a second | the wave 20 boss, about 106 Coins |
  | Early / mid Workshop | wave 30 / wave 50 |
  | Max Attack, Workshop only | dies at the wave 100 boss |
  | + Armor / + all Defense | wave 110 / wave 120 |
  | Tier 2, all Defense | wave 50 |

- **Balance targets:** 5 (wave 100 needs Defense) holds for Workshop builds again. 2 (Coins per minute) fails by design since D037; see the open decisions.

## Open decisions for the owner

1. **Coins per minute (balance target 2):** rewards came up about 1.5–1.8× when beaten waves stopped waiting out their timers (D037). Accept and restate the target, or bring Coins down.
2. **The Workshop ladders** ([`WORKSHOP_LADDERS.md`](WORKSHOP_LADDERS.md), with data in [`data/workshop/`](../data/workshop/)): seven decisions, including 5,000-rank core rows, a band of ranks per tier, dropping Breakthroughs from pacing, and making `data/workshop/` the Workshop's single source.
3. **The Workshop expansion** ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)): each new row (Guard, Payback, Finisher, Streak, Bounty, Interest, Boost Discount, Free Boost) and the Auto Crank → Auto Tap job.
4. **The Tiers 1–10 proposal** ([`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md)): parts are superseded (D037 took Rush; D039 took income pricing). The ×10 ladder, square-root Knowledge and Toll tiers still need decisions, judged against "keep it simple".
5. **The play-folder sync rule** for `AGENTS.md` is on branch `claude/sync-play-checkout`, not merged. The Mac's auto-updater already behaves that way.

## Next steps, in order

1. **Owner:** play a first run on the merged build, watching the wave 10 and 20 bosses. Boss HP is 3.5–3.7× the wave before, and every early build in the simulator ends on a boss. If they feel like walls, the smallest dial is the boss HP multiplier: grow it from ×2 to ×3 over the first few bosses.
2. **A GDScript career simulator** on the real game: runs back to back, Workshop buying and tier unlocks, reporting hours per tier. `tools/career_model.py` still models the pre-D037 rules, so its hour figures are shapes only. Low risk (a tool).
3. **Payback**, the next Defense row ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)): refund a share of damage taken during a boss fight upon victory. Medium risk (economy/run state).

## Known issues and risks

- **Lab research is unreachable past about rank 20.** Each rank takes 1.55× longer and costs 1.7× more, so maxing Damage Research would take about 425 years. Needs its own pass with the Gem economy.
- **Rig ranks are Workshop-sized.** Late in a run a flat Tap Damage or Damage per Second rank adds very little. The percentage Boosts in the tier proposal would fix it; re-sweep Rig price growth if effects change (D039 notes less headroom before endless runs).
- **Max Attack plus Rig spending clears wave 100 without Defense** (wave 106).
- **The wave 100 boss** doubles in one step: the ×1.5 milestone lands on the boss's ×3. It's the tier gate, left as is.
- **Balance target 2 fails** (see the open decisions).

## Working notes

- **The owner plays from `~/NumberGOup-main`.** It must end on merged `main`. When a game is running from it (`Godot --path /Users/paulhardie/NumberGOup-main`), work in a separate worktree. After a merge, check `git -C ~/NumberGOup-main status -sb` reads `## main...origin/main`. The auto-updater (`~/.local/bin/ngu-auto-pull.sh`) handles this within five minutes of the game closing and posts a notification; the owner must quit and reopen Godot for new scripts.
- **Every economy change** needs `bash run_tests.sh`, `bash run_balance.sh` before and after, and an independent adversarial review of the diff ([`QUALITY_GATES.md`](QUALITY_GATES.md)). The last four reviews each found real issues.
- **`tools/export_workshop.gd`** regenerates `data/workshop/current.*` from the live game. Rerun it after any catalogue or profile change.

# Handover

**Last updated:** 24 September 2026, after building D050 (each wave drawn as a body that reaches the Number when its Hit lands) on branch `claude/game-changes-review-fbili3`, not merged. D044–D049 are merged to `main` (PRs #48 and #49).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## Where the game is

`main` plus the D050 branch plays like this (seed 7 simulator figures, Godot 4.7.2, balance profile `tax-foundation-v10`; nothing below has been checked on a phone):

- **The core loop (D037, D038):** everything you produce is Number and also damages the wave. A beaten wave gives way to the next after 2.5 seconds. A missed ordinary wave hits once and moves on, paying Coins for the share you cleared. Bosses, every 10th wave, stay and hit every 15 seconds until you beat them. Guard cuts the Hit by a flat amount before Armor's percentage.
- **The Workshop (D047):** Tap Damage and Damage per Second run to 6,000 ranks and Guard to 5,000, on The Tower's Damage and Defense Absolute curves; ranks 1–100 keep their old values and prices. Tick Speed (×5.95), Crit Chance (80%), Crit Damage (×16.2 over 150), Double Tick and Armor (50% over 125), Thorns (100% over 200), Second Wind (30%), Coin Bonus (×2.5 over 300) and Cushion (150 ranks) reach Tower-like maxima. No tier bands. Each row keeps its old prices to its old cap; past it a deep-row rank costs 1.00075× the last and an extended capped row 1.02×. The whole Workshop costs 37.0 million Coins.
- **The wave as a body (D050, on the branch):** each standing wave is a pill showing its remaining HP that travels from just outside the ring to the Number on the 15-second clock, arriving exactly as the Hit lands. A clean clear shatters it ("BEATEN · NO HIT"), a Hit slams it into the Number, and a boss's body eases back to the edge after each Hit. Presentation only; with Reduce Motion the body holds at the edge.
- **The look (D049):** minimal and number-first: a near-black ground, borderless surfaces, Geist for words and Geist Mono for every number (bundled, OFL), gold Coin and blue Gem icons. The base canvas is now 390 × 844, so phones draw it at the designed size. The approved design lives on a canvas: https://claude.ai/artifact/8pB4uLUkva6kbnBRZ3PBXv (row "Instrument · refined").
- **Between runs (D048, restyled by D049):** Coins, Gems and Knowledge across the top; a ring of the tier's highest wave against the next goal (the next tier's gate, else the next milestone) with a dot per milestone; ‹ TIER › with its rewards; the last run; Milestones, Total Coin bonus, Knowledge and Stats as a list; BATTLE. The bottom bar is Battle · Workshop · Cards · Ultimates · Labs · More; Cards and Labs (D024, D027) open their sheets above the bar. Ultimates is a SOON seat; Modules, Perks and Challenge runs are one "coming later" line.
- **The run screen (D032, restyled by D049):** the outer ring is how much of the wave is cleared and a thin inner ring the time to its hit; a key under it names both beside Brace. The Upgrades sheet rests on the category strip at the foot, and the space between Brace and the sheet is deliberately empty: the owner has plans for the upper half.
- **Run Upgrades (the Rig in code; D042, D044, D045):** during a run all 21 Workshop rows can be raised with run-only Cash; Number is never spent on them.
  - A row's Workshop ranks and run ranks together stop at its max rank. A run rank is worth two Workshop ranks (Burst's is one step); on a deep row that is two ranks further along the depth curve.
  - Cash flows at the priced income (passive rate plus one tap a second, whether or not you tap). A beaten wave adds 10 + 5 × the wave, ×3 on a boss; a missed wave adds the share it cleared. A run starts with 12.5 seconds of its opening income.
  - Prices: about 5 seconds of income, ×1.4 per run rank of that row. Discount lowers them.
- **Difficulty (D043, D046):** Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) and the Hit = 1.7 × (0.08 w^2.10 + 0.4 w + 1), both with the milestone steps. Bosses are ×3 HP and ×1.5 Hit. Tiers 2 and 3 multiply by 20 and 60. Milestones run from wave 10 to 5,000.
- **Where builds land (two taps a second):**

  | Build | Not buying run ranks | Buying run ranks |
  | --- | --- | --- |
  | Fresh | wave 20, 86 Coins | wave 28, 213 Coins |
  | Early Workshop | wave 30 | wave 40 |
  | Mid Workshop | wave 60 | wave 80 |
  | Attack rows at rank 100 | wave 200 | wave 212 |
  | Every row at rank 100 | wave 220 | wave 252 |
  | Everything maxed | wave 830 (Tier 2: 660, Tier 3: 608) | — |

- **Careers (`tools/career_simulator.gd`, runs capped at 3 hours):** the focused player (cheapest rank in Attack, Defense after a stalled run) buying run ranks reaches wave 100 in **1.4 hours (it was 2.8 before D047)** and maxes the Workshop in **149.9 hours**. Without run ranks the focused player takes 2.3 hours to wave 100 and 164 to max. An even spender (one rank of each row in turn) maxes sooner, in 107.6 hours with run ranks and 111.4 without, because it buys Coin Bonus early; the 150-hour target is the focused player's.
- **Balance targets ([`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md)):** 5 fails again since D047 (Attack alone at rank 100 reaches wave 200) and needs restating against the deep rows, as do 7 and 8; the owner chose not to retune the waves for the Workshop alone. 2 still fails by design since D037.

## Open decisions for the owner

1. **Play-test and merge branch `claude/game-changes-review-fbili3`** (D050, the wave's body). Low risk: presentation only. Then decide whether the rings stay as they are beside it, and when the body's position should become a rule (Knockback, slow, range).
2. **The early-game pacing change.** D047's bigger Tick Speed and Crit steps halve the focused player's time to wave 100. Built as approved. The alternative keeps today's per-rank steps and adds ranks instead (Tick Speed 196, Crit Chance 320, Crit Damage 284 ranks), which keeps the first hours as they were and moves the extra power later.
3. **Research Focus is lopsided.** Its 25% off one category was balanced on equal category totals; Attack now costs 22.4 million, Defense 12.3 million, Utility 2.3 million, and Coin Bonus is nearly all of Utility. Options: give Research Focus a per-category effect, or deepen Utility's prices.
4. **Save V9 clash:** unmerged branch `codex/prestige-run-summary` (persisted run summaries) also adds `src/save_data_v9.gd`. This branch now takes V9 for D047; that branch must rebase onto it and become V10.
5. **The Tower parity plan and coin gates** ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#tower-parity-plan-and-coin-gates--proposed-23-september-2026)): the gate model, the measured ladder, Crit free from the start, the starter rows, run Upgrades selling only unlocked rows, each new mechanic, and three primitives (movable Hit timer, wave queue, difficulty counter). Gates would add `workshop_unlocks`, so they need their own save version after V9.
6. **Past a maxed Workshop:** wave 5,000's Wave HP is about 10^40 against the maxed Workshop's 10^11; Labs, Cards, Ultimate Weapons and higher tiers are meant to close it (owner direction), and none are sized yet.
7. **Tier unlock wave:** still 100 (`TIER_UNLOCK_WAVE`), which a focused player now reaches in 1.4 hours.
8. **Coins per minute (balance target 2):** above target since D037. Accept and restate, or bring Coins down.
9. **Still open from before:** Bounty, Finisher, Streak, Payback and Auto Tap; the Tiers 1–10 proposal ([`TIER_BALANCE_PROPOSAL.md`](TIER_BALANCE_PROPOSAL.md)); the play-folder sync rule on branch `claude/sync-play-checkout`; enemy-growth suppression ([`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md)).

## Next steps, in order

1. **Owner:** play D050 and merge it or ask for changes, including to the rings. **Agent:** then draw Labs, Cards, Milestones and Stats on the design canvas in the Instrument look and build them; they only have the new palette and fonts so far. Low–medium risk.
2. **Owner:** decide the pacing alternative (decision 2). **Agent:** if the alternative is chosen, it is a data change in `data/workshop/upgrades.json` plus a price recalibration. Medium risk.
3. **Owner:** decide coin gates; then **agent:** build them as the parity plan's step 1 with save V10. High risk: saves, economy.
4. **Agent:** the ordered player-stat pipeline (parity plan step 2), which almost every new row needs. Medium–high risk: touches every stat.

## Known issues and risks

- **The wave's body (D050) was checked in screenshots and a scripted run through each beat, not by touch.** On a small phone its path is short (ring edge to Number), and a slam lands among the existing damage float and toast for a moment.
- **D049 has only been checked in screenshots** (`tools/capture_ui.gd` at four sizes, all twelve screens), not by touch on a phone or in a web export. The larger canvas makes every screen about 1.4× bigger on a phone; the untouched sheets (Labs, Cards, Knowledge, Stats) have not been re-laid-out for that and are worth a look. Workshop rows and Upgrades tiles now open their detail only on a hold, so a player who never holds will not find descriptions.
- **Rank counts in the stat detail popup read without thousands separators** ("RANK 3100 / 6000"); the Workshop list now shows "Rank 3,100 / 6,000".
- **Lab research is unreachable past about rank 20.** Each rank takes 1.55× longer and costs 1.7× more. Needs its own pass with the Gem economy.
- **The balance simulator's "max" builds** (`ATTACK_MAX` and friends in `tools/balance_simulator.gd`) still stop at the old caps, so "attack max" there now means rank 100; `-- --maxed-workshop` measures the real maximum.
- **The wave 100 boss** doubles in one step: the ×1.5 milestone lands on the boss's ×3. It's the tier gate, left as is.
- **Cash counts a tap a second even when you're idle**, so an idle player buying run ranks keeps pace with a light tapper.
- **`run_cash_earned` is saved but nothing reads it**, and `tools/balance_simulator.gd` still carries the unused `_rig_reserve`.
- **Independent review of D047 (two passes):** no blockers. Fixed from it: prices now switch at each row's old cap rather than rank 100 (Cushion had become 27% of Defense), the depth curves run in straight lines so no rank is worth less than the one before, the price cache compares the discount exactly, and V9 refuses a save with malformed Cash. Left open: **the Crit Chance card adds nothing once Workshop Crit Chance is maxed** (80% is also the ceiling), and Coin Bonus's last ranks (45,143 Coins) are the dearest in the Workshop.

## Working notes

- **The owner plays from `~/NumberGOup-main`.** It must end on merged `main`. When a game is running from it, work in a separate worktree.
- **Every economy change** needs `bash run_tests.sh`, `bash run_balance.sh` before and after, the career simulator for anything that changes pacing, and an independent review of the diff ([`QUALITY_GATES.md`](QUALITY_GATES.md)).
- **Recalibrating Workshop prices:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 600 --run-cap-minutes 180 --deep-growth G` (and `--capped-growth`) runs a career to max; each takes about 15 minutes here.
- **`tools/export_workshop.gd`** regenerates `data/workshop/current.*` from the live game. Rerun it after any catalogue or profile change.

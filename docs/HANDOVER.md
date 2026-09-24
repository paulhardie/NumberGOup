# Handover

**Last updated:** 24 September 2026, by Claude, handing to Codex. Branch `claude/game-changes-review-fbili3` (head `Fix D058 review findings` plus this handover) carries **D056–D059: a wave is a group of enemies that stay at the Number and pile up, with a gentler opening to wave 30**. It is pushed and **not merged**; no PR is open. D044–D055 and the class-cache fix are merged to `main` (PRs #48–#54).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent (Codex): start here

1. **Read [`AGENTS.md`](../AGENTS.md) first.** It is the working agreement for every agent: UK English, lead with the result, bold every decision, economy and saves are high risk, never touch the owner's real save, never commit to `main`, opening or merging a PR is the owner's call.
2. **Check out the branch and bring it up to date:** `git fetch --all --prune`, `git checkout claude/game-changes-review-fbili3`, then `git status -sb`. If `main` has moved, merge it in (a merge commit, not a rebase).
3. **Prove the baseline before changing anything:**
   - `bash run_tests.sh` must print `PASS: economy tests`. The "Exponent too high" warning comes from a deliberately corrupt save in a test, not a failure.
   - `bash run_godot.sh --headless --path . --quit` must print no errors.
   - `bash run_godot.sh --path . -s res://tools/arena_probe.gd` must print `ARENA PROBE PASS`.
   - `run_godot.sh` defaults to the owner's Mac Godot (`/Users/paulhardie/Downloads/Godot.app`); anywhere else, set `GODOT` to a 4.7.2 binary. On headless Linux, wrap windowed tools in `xvfb-run -a -s "-screen 0 1024x1100x24"`.
   - If classes are "not found", the `.godot` cache is stale: `bash run_godot.sh --headless --path . --import`.
4. **Read the decisions this branch adds:** `grep -n "^## D05[5-9]" docs/DECISIONS.md`, then read D056 to D059 in full. The group build plan is in [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#proposal-a-wave-becomes-a-group--24-september-2026).
5. **Your first task is the independent review of D059** (the last commit touching `src/`): it is an economy change, and `AGENTS.md` requires a review before merge. Review `git diff` of that commit against D059 in `DECISIONS.md`, fix what you find, and re-run the checks. After that, the arena pass (next step 2) is unblocked only if the owner confirms it.

## Where the game is

`main` plus this branch plays like this (Godot 4.7.2, balance profile `tax-foundation-v11`, save V10; nothing below has been checked on a phone or in motion):

- **Waves are groups (D057).** An ordinary wave is 3 enemies at wave 1, one more every 11 waves, at most 20; a boss is one. They share the wave's HP and Hit evenly and walk in as a column: the front reaches the Number at 6 seconds, the last at 15. Shots and taps strike the front living enemy, and damage past its HP is lost.
- **Enemies stay (D058), after a gentler opening (D059).** An enemy that reaches the Number lands its share of the Hit (after Guard and Armor on the whole Hit). To wave 30 it then leaves. From wave 31 it stays and hits again, every 15 seconds at first, easing to every 5 seconds (`MEMBER_HIT_SECONDS`) by wave 50, until beaten. The 15-second clock keeps going: an ordinary wave with an enemy alive at 15 seconds passes, paying Coins for the share cleared, and its survivors carry into the next wave, in front. That growing pile is the ramp. A wave counts as beaten once all its own enemies are dead, even after landing. Bosses hold their wave until beaten and hit every 15 seconds. Brace blocks every hit until the clock ends; Thorns returns part of each hit to the enemy in front.
- **The arena:** the front enemy is the live number, with "hits X" and a countdown once it is at the Number. The others walk in smaller behind it, and those at the Number flank it in red, three rows a side, 18 drawn at most. A boss stays the live number even behind a pile. Motes fly at the front enemy; shots' "-X" folds into one pop every 0.33 s; pile hits fold into one small red pop a frame.
- **Shots (D054, D055):** Damage is per shot and Attack Speed is shots a second, 2.5 before any ranks and 14.9 at rank 100. Multishot fires two visible shots. One mote per shot.
- **The Workshop (D047):** Tap Damage and Damage run to 6,000 ranks and Guard to 5,000; the whole Workshop costs 37.0 million Coins. Run Upgrades (the Rig in code) sell every row for run-only Cash (D042, D044, D045).
- **Difficulty (D043, D046):** Wave HP = 4 × (0.05 w^2.13 + 0.8 w + 1.5) and Hit = 1.7 × (0.08 w^2.10 + 0.4 w + 1), with milestone steps; bosses ×3 HP and ×1.5 Hit; Tiers 2 and 3 ×20 and ×60.
- **Where builds land now** (six seeds, two taps a second, no run Upgrades):

  | Build | Before groups | D058 | D059 (now) |
  | --- | --- | --- | --- |
  | Fresh (no Workshop) | 20 | 17 | 22 |
  | First 48-Coin spend | 20 | 23 | 30 |
  | Early Workshop | 30 | 30 | 37 |
  | Mid Workshop | 60 | 56 | 56 |
  | Attack rows at rank 100 | 200 | 158 | 158 |
  | Attack rows + Armor | 210 | 165 | 165 |

- **A focused career buying run Upgrades** (`tools/career_simulator.gd -- --spend focused --careers today_rig --run-cap-minutes 180`), eight runs measured under D059: first run wave 29 with 239 Coins (28 and 232 before groups), then 36, 40, 48, 54, 64, 77 and 97 by 1.38 hours. Past that, the D058 figures are the latest: wave 200 at about 4.2 hours and wave 300 at about 7.1 (6.2 before). **Time to max the Workshop has not been re-measured since D057**; the 150-hour figure is from before groups.
- **The look and screens (D048, D049, D053):** unchanged from `main`. The design canvas is https://claude.ai/artifact/8pB4uLUkva6kbnBRZ3PBXv.

## Open decisions for the owner

1. **Decided: soften the opening only (D059), built.** To wave 30 enemies hit once and leave; from wave 31 they stay, easing from every 15 seconds to every 5 by wave 50. The measured D058 interval sweep is in D058's evidence. **Left for the owner:** whether the switch at wave 31 feels like a wall in play.
2. **Open the PR for this branch?** Everything is green; D056–D058 are reviewed, D059 is not yet; the owner has not played it.
3. **Tapping and the Damage/Attack Speed split** (step 4 of the group plan): a tap fires a shot worth a share of current Damage, taps past about five a second count half; targets idle 100%, one tap a second +15–20%, three +40–50%, a cap near double. High risk: economy.
4. **Enemy types** (step 3): Fast (2× speed) and Tank (5× HP, half damage, slow) partway through Tier 1, Ranged later. This is what makes Damage and Attack Speed different choices.
5. **Save clash:** unmerged branch `codex/prestige-run-summary` adds its own save version; this branch takes V10, so that one must become V11.
6. **Still open from before:** the D047 pacing alternative; coin gates and the Tower parity plan ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)); Research Focus being lopsided; the tier unlock wave (100); Coins per minute above balance target 2; sizing Labs, Cards and Ultimates past a maxed Workshop; Bounty, Finisher, Streak, Payback and Auto Tap.

## Next steps, in order

1. **Agent (Codex), first:** the independent review of D059, as in "start here" step 5. **Done when:** findings are fixed or answered, `bash run_tests.sh`, the headless boot and `tools/arena_probe.gd` pass, and the review's outcome is added to D059. **Owner:** play the branch, then decide whether to open the PR.
2. **Agent, if the owner confirms:** the arena pass (group step 2). It fixes:
   - members overlapping near the top edge as a wave enters (stagger their start heights or fade them in one by one);
   - the front caption clipping on a narrow screen ("· 9 mor");
   - "-X" pops rising into the header line while a wave is at the top edge.
   Low–medium risk. Verify with `tools/capture_ui.gd` at four sizes and `tools/arena_probe.gd`.
3. **Owner:** decide enemy types (decision 4), then tapping (decision 3). Each is its own decision and build.

## How to measure

- **Quick balance check:** `bash run_balance.sh`, compared with a run on the previous commit. It takes about five minutes. "Hits" now count every member landing and pile hit, so they do not compare with figures from before D057.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants (`FIRST_RUN_SPEND`, `EARLY`, `MID`, `ATTACK_MAX`, `ARMOR`). For seeds 1–6 or 1–12: start a run, then loop `tap()` and two `advance(0.25)` calls until death, and average the waves reached. Delete it afterwards. The hit interval can be swept by setting `state.balance_profile.MEMBER_HIT_SECONDS`, which is a var for this purpose.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 20 minutes. Compare waves against hours with the figures above. Run the previous commit the same way from a separate `git worktree`, not by swapping files.
- **Arena:** `tools/arena_probe.gd` (checks and screenshots) and `tools/capture_ui.gd` (twelve screens at four sizes). Look at the PNGs; never assert pixel equality.
- **Never kill processes with `pkill -f`** in a shared shell; it can kill the shell. Kill by PID.

## Known issues and risks

- **Groups and the pile have only been checked in tests, the arena probe and screenshots**, not in motion or by touch. A big pile bites several times a second (folded into one pop a frame).
- **Save V10** will not load in an older build. A save written by D057's commits (hit once and pass) loads its passed members as gone.
- **The balance simulator's "max" builds** stop at rank 100; `-- --maxed-workshop` measures the real maximum.
- **Balance targets 5, 7 and 8** need restating against D058's figures; target 2 (Coins per minute) still fails by design since D037.
- **The wave 100 boss** doubles in one step (the ×1.5 milestone on the boss's ×3); it is the tier gate, left as is.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20; the stat detail popup's rank counts lack thousands separators.
- **After a pull that adds a script,** a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen. New scripts must be loaded by `preload` path in `main.gd` (see `docs/QUALITY_GATES.md`).

## Handing back to Claude

When you stop, leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed back to Claude.
2. **Record every choice the owner accepted** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D059 onwards). Each entry needs the owner's words, context, the decision, the evidence (the figures you measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md).
3. **Say plainly what ran and what did not.** Test counts, probe results, balance and career figures before and after, and anything you could not check (in motion, on a phone). Do not mark anything done that did not run.
4. **Commit on a branch, never `main`, and push it.** Use this branch while its PR is unmerged; once it merges, start a fresh branch from `main`. Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

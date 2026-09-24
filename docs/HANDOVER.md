# Handover

**Last updated:** 24 September 2026, by Codex, handing back to Claude. Branch `claude/game-changes-review-fbili3` carries **D056–D059 and the independent D059 review**. The review repaired the arena probe but found an unresolved saved-run compatibility issue. The branch is **not merged**, and no PR is open (checked with `gh pr list`). D044–D055 and the class-cache fix are merged to `main` (PRs #48–#54). The owner's playable checkout remains on `main`; review work is in `/private/tmp/ngu-d059-review`.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent (Claude): start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D059 in [`DECISIONS.md`](DECISIONS.md), and the D059 implementation commit `e934e91`. Fetch and check the branch against `origin` before new work. Do not switch the owner's playable `main` checkout to this branch.
2. **D059 has one unresolved review blocker:** a V10 active run saved under D058 has the same `tax-foundation-v11` profile ID as D059. The load path keeps an opening member's `AT_NUMBER` state and positive repeat interval, so it can continue piling after D059. Recommend a narrow load conversion: members from ordinary waves 1–30 that already hit leave with their HP uncleared; those still approaching get a zero repeat interval; members from earlier opening waves do not carry forward. Preserve Number and already-paid Hits. Add old-save and current-save round-trip tests. Automatic approval review rejected this proposed edit as an unapproved high-risk save/encounter mutation. **Get the owner's explicit approval before making that change.**
3. Once approved and repaired, run `bash run_tests.sh`, `bash run_godot.sh --headless --path . --quit`, and `bash run_godot.sh --path . -s res://tools/arena_probe.gd`. Use `run_godot.sh` for every Godot run; it isolates `user://` from the real save. A fresh worktree may need `bash run_godot.sh --headless --path . --import` before tests. Check for a running Godot game before editing scripts, as `AGENTS.md` requires.
4. Keep the arena layout pass separate. Its overlap, narrow caption and rising pop issues remain for the owner to confirm after D059 is safe to play. Do not open or merge a PR without the owner asking.

## Where the game is

`main` plus this branch plays like this on a fresh run (Godot 4.7.2, balance profile `tax-foundation-v11`, save V10; nothing below has been checked on a phone or in motion). **A D058 active save can retain the old early pile after loading; see the review blocker above.**

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

1. **Approve the D059 saved-run repair?** Recommend yes: otherwise a D058 V10 save can keep repeat Hits in the opening even though a fresh D059 run cannot. The trade-off is a deliberate change to an already-active run's enemy states on load; its Number and prior Hits would be retained. Automatic approval review rejected the unapproved edit, so no save handling was changed.
2. **Play and open a PR for this branch?** Recommend play only after decision 1 is implemented and verified. D056–D058 are reviewed; D059's independent review has this blocker. The owner has not played D059, and no PR is open.
3. **Does the wave-31 switch feel like a wall?** Recommend deciding after play: the simulator shows the early run recovering, while the ramp starts abruptly at wave 31 despite the repeat interval easing to five seconds by wave 50.
4. **Tapping and the Damage/Attack Speed split** (step 4 of the group plan): a tap fires a shot worth a share of current Damage, taps past about five a second count half; targets idle 100%, one tap a second +15–20%, three +40–50%, a cap near double. Recommend measuring the tap sweep and career before building; economy risk is high.
5. **Enemy types** (step 3): Fast (2× speed) and Tank (5× HP, half damage, slow) partway through Tier 1, Ranged later. Recommend after the arena pass so each type can be read; this makes Damage and Attack Speed different choices.
6. **Save clash:** unmerged branch `codex/prestige-run-summary` adds its own save version; this branch takes V10, so that one must become V11. Recommend resolving at integration, without altering either branch during D059 review.
7. **Still open from before:** the D047 pacing alternative; coin gates and the Tower parity plan ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)); Research Focus being lopsided; the tier unlock wave (100); Coins per minute above balance target 2; sizing Labs, Cards and Ultimates past a maxed Workshop; Bounty, Finisher, Streak, Payback and Auto Tap.

## Next steps, in order

1. **Owner:** approve or decline the D059 saved-run conversion. **Agent (Claude), if approved:** implement the narrow conversion and old-save fixture, then independently review the final diff. **Done when:** a D058 V10 opening save resumes under D059 without repeat Hits or a carried early pile, a current D059 save resumes exactly, the economy suite, headless boot and arena probe pass, and D059's review entry records the result. High risk: saves and encounter resolution.
2. **Owner:** play D059 after step 1 and decide whether to open its PR. **Done when:** the wave-31 switch, Hits and early Coin pacing feel acceptable in a real game; no local automated check proves that feel. No PR or merge has been requested.
3. **Agent, if the owner confirms:** the arena pass (group step 2). It fixes:
   - members overlapping near the top edge as a wave enters (stagger their start heights or fade them in one by one);
   - the front caption clipping on a narrow screen ("· 9 mor");
   - "-X" pops rising into the header line while a wave is at the top edge.
   Low–medium risk. Verify with `tools/capture_ui.gd` at four sizes and `tools/arena_probe.gd`.
4. **Owner:** decide enemy types, then tapping. Each is its own decision and build after D059 is settled.

## How to measure

- **This review actually ran:** `bash run_tests.sh` → `PASS: economy tests` (the suite prints no test count; its deliberate corrupt-save fixture prints an `Exponent too high` warning); headless boot → exit 0 with no errors; `tools/arena_probe.gd` → `ARENA PROBE PASS` after its fixture and waits were corrected. The windowed probe printed a shader-cache warning but completed; its approach, boss and pile PNGs were inspected. `bash run_balance.sh` completed: seed 7 fresh wave 20/86 Coins, early wave 30/273 Coins, and the simulator's rank-100 Attack build wave 156/9,327 Coins. These single-seed results do not replace D059's six-seed figures. The career simulator was **not** rerun, and neither motion by touch nor a phone was checked.
- **Quick balance check:** `bash run_balance.sh`, compared with a run on the previous commit. It takes about five minutes. "Hits" now count every member landing and pile hit, so they do not compare with figures from before D057.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants (`FIRST_RUN_SPEND`, `EARLY`, `MID`, `ATTACK_MAX`, `ARMOR`). For seeds 1–6 or 1–12: start a run, then loop `tap()` and two `advance(0.25)` calls until death, and average the waves reached. Delete it afterwards. The hit interval can be swept by setting `state.balance_profile.MEMBER_HIT_SECONDS`, which is a var for this purpose.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 20 minutes. Compare waves against hours with the figures above. Run the previous commit the same way from a separate `git worktree`, not by swapping files.
- **Arena:** `tools/arena_probe.gd` (checks and screenshots) and `tools/capture_ui.gd` (twelve screens at four sizes). Look at the PNGs; never assert pixel equality.
- **Never kill processes with `pkill -f`** in a shared shell; it can kill the shell. Kill by PID.

## Known issues and risks

- **D059 save blocker:** D058 V10 saves at waves 1–30 can retain repeating `AT_NUMBER` members because both builds write `tax-foundation-v11`. This was found by tracing save/load and encounter state; the conversion was not run or tested. Automatic approval review rejected the proposed save/encounter edit as an unapproved high-risk compatibility mutation. Ask the owner for explicit approval before that repair.
- **Arena probe:** its D058 comparison failed two frame-timing checks on this Mac. D059 initially failed those and four more because the opening fixture assumed staying members. Its fixture now tests staying members first, switches to D059 for wave 12, and waits elapsed time for the two landing checks; it passes. This is a probe repair, not a gameplay fix. The screenshot of a large pile still shows overlapping numbers and captions, covered by the planned arena pass.
- **Groups and the pile have only been checked in tests, the arena probe and screenshots**, not in motion or by touch. A big pile bites several times a second (folded into one pop a frame).
- **Save V10** will not load in an older build. A save written by D057's commits (hit once and pass) loads its passed members as gone.
- **The balance simulator's "max" builds** stop at rank 100; `-- --maxed-workshop` measures the real maximum.
- **Balance targets 5, 7 and 8** need restating against D058's figures; target 2 (Coins per minute) still fails by design since D037.
- **The wave 100 boss** doubles in one step (the ×1.5 milestone on the boss's ×3); it is the tier gate, left as is.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20; the stat detail popup's rank counts lack thousands separators.
- **After a pull that adds a script,** a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen. New scripts must be loaded by `preload` path in `main.gd` (see `docs/QUALITY_GATES.md`).

## Handing back to Claude

The next decision is the saved-run repair above. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed back to Claude.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D060 onwards). D059 already records the accepted opening and this review's unresolved finding. Each new entry needs the owner's words, context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md).
3. **Say plainly what ran and what did not.** Give test counts only if the suite prints them; report probe results, balance and career figures that were actually measured, and anything not checked (in motion, on a phone). Do not mark the save fix done until it is authorised, implemented and tested.
4. **Commit on a branch, never `main`, and push it.** Use this branch while its PR is unmerged; once it merges, start a fresh branch from `main`. Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

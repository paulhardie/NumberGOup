# Handover

**Last updated:** 24 September 2026, by Claude, handing to the next session (the owner is continuing on the go, probably from a phone or cloud session). **D056–D062 are merged to `main`** (PR #55, `993962f`), and the owner's playable checkout is on that merge. Branch `claude/cloudflare-web-preview` adds **a playable web build on Cloudflare Pages for every pull request**; it is pushed, **not merged, with no PR open**, and its deploy waits on two secrets only the owner can create. Its head is the commit that carries this page.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent (Claude): start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D062 in [`DECISIONS.md`](DECISIONS.md) and the README's Web export section. Fetch and check `main` and `claude/cloudflare-web-preview` against `origin` before new work.
2. **The web preview (this session):** `.github/workflows/web-preview.yml` exports the Web preset on every pull request and push to `main`, uploads it to the Cloudflare Pages project `number-go-up` and edits one comment on the pull request with two links: a branch link that keeps its browser save across pushes, and an exact-commit link with a fresh save. `main` becomes the production site. Pages refuses files over 25 MiB and `index.wasm` is 39.5 MB, so it ships gzipped (10 MB) and `.github/web-preview/_worker.js` serves it back with gzip encoding. The Cloudflare token only reaches the deploy job, which never runs project code; fork PRs skip the deploy, and without the secrets the deploy is skipped with a notice rather than failing.
3. **What ran:** a local export on the Mac through `run_godot.sh` (exit 0; one harmless macOS line, "Could not create ObjectDB Snapshots directory"). The packed folder was served by Cloudflare's local runtime (`wrangler pages dev`): `/index.wasm` came back with `Content-Encoding: gzip` and unpacked to exactly 39,514,754 bytes, the hub loaded with no console errors and BATTLE started a run. The workflow YAML parses. **Nothing has run on GitHub or on real Cloudflare yet**: not the template download and cache, the Linux export, the deploy or the comment.
4. **The next owner actions are adding the secrets and saying whether to open the PR** for `claude/cloudflare-web-preview`; see the open decisions. Once a real preview works, the owner can play D059–D062 from the link on a phone. Use `run_godot.sh` for every Godot run and check for a running Godot game before editing scripts.

## Where the game is

`main` plays like this on a fresh run (Godot 4.7.2, balance profile `tax-foundation-v11`, save V10; nothing below has been checked on a phone or in motion). D060 reconciles active D058 saves to these opening rules on load.

- **Waves are groups (D057).** An ordinary wave is 3 enemies at wave 1, one more every 11 waves, at most 20; a boss is one. They share the wave's HP and Hit evenly and walk in as a column: the front reaches the Number at 6 seconds, the last at 15. Shots and taps strike the front living enemy, and damage past its HP is lost.
- **Enemies stay (D058), after a gentler opening (D059).** An enemy that reaches the Number lands its share of the Hit (after Guard and Armor on the whole Hit). To wave 30 it then leaves. From wave 31 it stays and hits again, every 15 seconds at first, easing to every 5 seconds (`MEMBER_HIT_SECONDS`) by wave 50, until beaten. The 15-second clock keeps going: an ordinary wave with an enemy alive at 15 seconds passes, paying Coins for the share cleared, and its survivors carry into the next wave, in front. That growing pile is the ramp. A wave counts as beaten once all its own enemies are dead, even after landing. Bosses hold their wave until beaten and hit every 15 seconds. Brace blocks every hit until the clock ends; Thorns returns part of each hit to the enemy in front.
- **The arena:** the front enemy is the live number, with "hits X" and a countdown once it is at the Number. The others walk in smaller behind it, and those at the Number flank it in red, three rows a side, 18 drawn at most. A boss stays the live number even behind a pile. Motes fly at the front enemy. D061 shows damage dealt in one fixed half-second total beside the target and routine incoming Hits in one fixed half-second total below TAP. D062 makes a critical amount red and slightly heavier without saying "CRIT". Guarded Hits still work out over the Number, one column at a time. Clears still float "BEATEN".
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
- **The look and screens (D048, D049, D053, D061, D062):** the Instrument layout remains; the combat readouts are quieter and critical numbers share the boss red. The design canvas is https://claude.ai/artifact/8pB4uLUkva6kbnBRZ3PBXv.

## Open decisions for the owner

1. **Set up the web preview: add the secrets and open its PR?** The owner (never an agent) creates a free Cloudflare account, copies the Account ID from Workers & Pages, and makes a custom API token with only **Account · Cloudflare Pages · Edit** on that account. Then `gh secret set CLOUDFLARE_API_TOKEN --repo paulhardie/NumberGOup` and `gh secret set CLOUDFLARE_ACCOUNT_ID --repo paulhardie/NumberGOup`, or GitHub → Settings → Secrets and variables → Actions. Recommend opening the PR straight away: its build job proves the Linux export without secrets, and after the secrets exist a re-run gives it the first link. **Preview links are public to anyone who has them**, like the repo; Cloudflare Access can lock them later.
2. **Does the wave-31 switch feel like a wall?** Recommend deciding after play: the simulator shows the early run recovering, while the ramp starts abruptly at wave 31 despite the repeat interval easing to five seconds by wave 50.
3. **Tapping and the Damage/Attack Speed split** (step 4 of the group plan): a tap fires a shot worth a share of current Damage, taps past about five a second count half; targets idle 100%, one tap a second +15–20%, three +40–50%, a cap near double. Recommend measuring the tap sweep and career before building; economy risk is high.
4. **Enemy types** (step 3): Fast (2× speed) and Tank (5× HP, half damage, slow) partway through Tier 1, Ranged later. Recommend after the arena pass so each type can be read; this makes Damage and Attack Speed different choices.
5. **Save clash:** unmerged branch `codex/prestige-run-summary` adds its own save version; `main` now takes V10, so that one must become V11. Recommend resolving when that branch is next picked up.
6. **Still open from before:** the D047 pacing alternative; coin gates and the Tower parity plan ([`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md)); Research Focus being lopsided; the tier unlock wave (100); Coins per minute above balance target 2; sizing Labs, Cards and Ultimates past a maxed Workshop; Bounty, Finisher, Streak, Payback and Auto Tap.

## Next steps, in order

1. **Owner, then agent:** add the two secrets and open the PR for `claude/cloudflare-web-preview` (or ask an agent to open it); the agent re-runs the workflow and fixes whatever the first real run shows. **Done when:** the PR carries a working link, the game boots from it on a phone, and a save survives a reload there. D028 notes the save's rename-swap has never been checked on the Web export. Low risk (CI only, no game code), but the first real run may need a fix.
2. **Owner:** play D059–D062, from the web link once it exists. **Done when:** the wave-31 switch, Hits, early Coin pacing and combat legibility feel acceptable in a real game; no automated check proves that feel. Already merged, so any change is a new decision.
3. **Agent, when the owner wants the next build:** the arena pass (group step 2). It fixes:
   - members overlapping near the top edge as a wave enters (stagger their start heights or fade them in one by one);
   - the front caption clipping on a narrow screen ("· 9 mor");
   **Done when:** both read clearly in the four-size `tools/capture_ui.gd` set and `tools/arena_probe.gd` still passes. Low–medium presentation risk.
4. **Owner and agent:** decide enemy types (group step 3), then measure the proposed tap contribution and decide tapping (step 4). **Done when:** the owner has accepted each rule with measured effects before its separate build. Do this after the arena is settled; tapping changes the economy and needs its high-risk checks.

## How to measure

- **This review and repair actually ran:** a D058-shaped V10 regression fixture failed four assertions before D060, then `bash run_tests.sh` → `PASS: economy tests` after it (the suite prints no test count; its deliberate corrupt-save fixture prints an `Exponent too high` warning). Headless boot exited 0 without errors; `tools/arena_probe.gd` → `ARENA PROBE PASS`. `bash run_balance.sh` completed after D060 and was byte-identical to the pre-repair D059 run: seed 7 fresh wave 20/86 Coins, early wave 30/273 Coins, and rank-100 Attack wave 156/9,327 Coins. These single-seed results do not replace D059's six-seed figures.
- **D061 presentation check:** the economy suite and headless boot pass; `tools/arena_probe.gd` passes shot, incoming-Hit, guarded-Hit, Reduce Motion and run-end checks. `tools/capture_ui.gd` rendered the fixed readouts at four sizes; all four feedback captures were inspected. The windowed checks printed a shader-cache warning but completed. CI, the career simulator, in-motion touch play and a phone were **not** checked for D061. No balance rule changed.
- **D062 critical style:** headless boot, economy suite and arena probe passed; the probe checked red 600-weight damage text without a "CRIT" word under Reduce Motion. The `run_crit` captures at all four sizes were inspected. No phone, touch play or CI check was done for D062.
- **Quick balance check:** `bash run_balance.sh`, compared with a run on the previous commit. It takes about five minutes. "Hits" now count every member landing and pile hit, so they do not compare with figures from before D057.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants (`FIRST_RUN_SPEND`, `EARLY`, `MID`, `ATTACK_MAX`, `ARMOR`). For seeds 1–6 or 1–12: start a run, then loop `tap()` and two `advance(0.25)` calls until death, and average the waves reached. Delete it afterwards. The hit interval can be swept by setting `state.balance_profile.MEMBER_HIT_SECONDS`, which is a var for this purpose.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 20 minutes. Compare waves against hours with the figures above. Run the previous commit the same way from a separate `git worktree`, not by swapping files.
- **Arena:** `tools/arena_probe.gd` (checks and screenshots) and `tools/capture_ui.gd` (fourteen screens at four sizes, including `run_feedback` and `run_crit`). Look at the PNGs; never assert pixel equality.
- **Web build locally:** `run_godot.sh` moves `HOME`, so link the templates into the scratch home once (`ln -sfn ~/Library/Application\ Support/Godot/export_templates/4.7.2.stable "${TMPDIR:-/tmp}/ngu-home/Library/Application Support/Godot/export_templates/4.7.2.stable"`), then `bash run_godot.sh --headless --path . --export-release Web <scratch>/web/index.html`. To mimic Pages, gzip `index.wasm`, copy in `.github/web-preview/_worker.js` and serve the folder with `npx --yes wrangler@4 pages dev <folder>`. A browser save lives in that origin's storage, never the real save.
- **Never kill processes with `pkill -f`** in a shared shell; it can kill the shell. Kill by PID.

## Known issues and risks

- **Web preview untested on GitHub and Cloudflare:** the first run may trip on the template download, `XDG_DATA_HOME` template discovery on Linux, or wrangler's output file. The build step fails if any file reaches 25 MiB, so a much larger `index.pck` would need the same gzip treatment. The web build installs itself for offline play, so a branch link can need a second reload after a push. The Godot version is pinned in both `verify.yml` and `web-preview.yml`.
- **D060 old-save conversion:** an active D058 V10 run is deliberately reconciled to D059's rule on load. An early carried member leaves and will no longer land future Hits; Number, already-paid Hits, the current wave's uncleared HP and earned currency remain. Synthetic old-save and current-save fixtures pass, but no copy of the owner's real save was loaded for this check.
- **Arena layout remains unfinished:** a large pile still overlaps member numbers and captions, and the front caption clips on a narrow screen. D061 removed the rising routine damage and pile-Hit numbers that added noise; the remaining layout pass is separate.
- **Critical and boss red now match (D062):** critical damage sits beside the enemy while a boss Hit sits at the Number. The owner has not yet checked whether that separation is clear in motion.
- **Groups and the pile have only been checked in tests, the arena probe and screenshots**, not in motion or by touch. A big pile bites several times a second, now shown as one fixed half-second Hit total.
- **Save V10** will not load in an older build. A save written by D057's commits (hit once and pass) loads its passed members as gone.
- **The balance simulator's "max" builds** stop at rank 100; `-- --maxed-workshop` measures the real maximum.
- **Balance targets 5, 7 and 8** need restating against D058's figures; target 2 (Coins per minute) still fails by design since D037.
- **The wave 100 boss** doubles in one step (the ×1.5 milestone on the boss's ×3); it is the tier gate, left as is.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20; the stat detail popup's rank counts lack thousands separators.
- **After a pull that adds a script,** a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen. New scripts must be loaded by `preload` path in `main.gd` (see `docs/QUALITY_GATES.md`).

## Handing back to Claude

D056–D062 are merged, and the web preview is built but waits on the owner's secrets and PR. The next step is the first real preview run; after that, play feedback on D059–D062, then the arena, enemy types and tapping in the order above. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed back to Claude.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D063 onwards). D059 records the opening, D060 the saved-run reconciliation, D061 the fixed combat readouts and D062 the critical style. Each new entry needs the owner's words, context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md).
3. **Say plainly what ran and what did not.** Give test counts only if the suite prints them; report probe results, balance and career figures that were actually measured, and anything not checked (in motion, on a phone).
4. **Commit on a branch, never `main`, and push it.** Use `claude/cloudflare-web-preview` for preview fixes while it is unmerged; start game work on a fresh branch from `main`. Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

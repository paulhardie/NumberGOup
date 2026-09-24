# Handover

**Last updated:** 24 September 2026, by Claude, handing on to the next agent. `claude/codex-handover-if13d2` holds Codex's handover, the Workshop audit, the Tower research and **D063 and D064, built** (D063 in `be0a3de` and `a40d08a`, D064 in `c87ea93`, each with documentation commits after). It is unmerged and has no PR. `main` is still at PR #55 (`993962f`).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D063 in [`DECISIONS.md`](DECISIONS.md), and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Standing owner rule (D063): "If in doubt, copy the way the tower does it", shaped to a game of numbers.** D009 still keeps copied constants out: copy The Tower's rules and structure, and fit our own coefficients to its shape.
3. **What this session did:** audited the Workshop against groups (the audit is in [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md#workshop-audit-against-groups-and-the-pile--proposed-24-september-2026)); researched The Tower's Tier 1 from TheTowerSDK and the owner's own save; then built D063: enemies tank more than they hit, bosses are walls that hit like one enemy, waves keep coming past a boss, The Tower's defence order off each enemy's hit, 4% heat-up per hit, and enemies beaten after their wave still pay their share of its reward. Balance profile `tax-foundation-v12`, save V11.
4. **Then D064 ("copy the tower"):** Thorns deals the enemy that hit a share of its own maximum HP, bosses half, even when Guard or a Brace stops the hit. Tier 1 is now The Tower's turtle, and runs go far deeper (mid + Guard + Thorns: wave 144; a career reaches wave 1,000 in about 30 hours).
5. **Next, by the owner's ordering of "tower-ifying":** enemies per wave with full health each (not a shared total), then enemy types and pay per kill, then distance (reach and crowd control).

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v12`, save V11; nothing below has been played by the owner or checked on a phone).

- **Waves are groups (D057)** of 3 enemies at wave 1, one more every 11 waves, at most 20, sharing the wave's HP and Hit and walking in as a column (the front at 6 seconds, the last at 15). Shots and taps strike the front living enemy; overkill is lost.
- **Enemies stay (D058) after a gentler opening (D059).** To wave 30 an enemy hits once and leaves; from wave 31 it stays and hits again every 15 seconds, easing to 5 by wave 50. An ordinary wave with an enemy alive at 15 seconds passes, paying for the share cleared, and its survivors carry into the next wave in front.
- **The Tower's shape (D063).** A wave's Hit is its HP over a ratio that grows from about 2.4 at wave 1 to 11 at 100 and 1,480 at 1,000. Each hit an enemy lands makes its next 4% stronger. Armor comes off each enemy's hit first, then Guard, down to nothing. A boss (×3 HP) hits like one ordinary enemy of its wave; if it survives its 15 seconds its wave passes and it stays at the Number, the live number in red, in front of later waves. Boss Damage and Leech work on the boss itself. Enemies beaten after their wave passed pay their share of its Coins and Cash, and a boss its Gem and "boss beaten" moment.
- **Thorns (D064)** deals every enemy that hits you a share of its own maximum HP (0.495% a rank, 99% at rank 200), bosses half, whatever Guard or a Brace took off the hit.
- **Where builds land** (six seeds, two taps a second, no run Upgrades, `main` → D063): fresh 20 → 32, first spend 20 → 34, early 30 → 38, mid 50 → 54, rank-100 Attack 156 → 165, + Armor 160 → 170. On D063: early + Guard 55, mid + Guard 68, mid + Armor 57, rank-100 Attack + Guard 167. With D064's Thorns: mid + Thorns 105, mid + Guard + Thorns 144, rank-100 Attack + full Thorns 346.
- **Coins** (`run_balance.sh`, seed 7, today → D063): fresh 86 → 78, 48-Coin spend 106 → 162, early 273 → 251, mid 847 → 996, attack max 9,327 → 10,503, everything maxed 18,679 → 22,867.
- **A focused career buying run Upgrades** (30 runs, with D064): first run wave 36 with 187 Coins (D059: 29 with 239), wave 100 at 1.2 hours, wave 200 at about 2.3, wave 400 at 5.3, wave 1,000 at 30.4; late runs last hours each. Time to max the Workshop is still unmeasured.
- **Shots, Workshop and look** are as before: 2.5 shots a second before Attack Speed (D055); Tap Damage and Damage run to 6,000 ranks (D047); run Upgrades sell every row for Cash (D042–D045); the Instrument layout with fixed combat readouts (D061, D062).

## Open decisions for the owner

1. **How many enemies does The Tower send per wave early on?** Needed for the next build. The SDK is only calibrated from wave 600 (about 143 a wave at 1,000, capped near 155), and guesses about 4 below that. The owner's wave 22 battle report (16.94K damage) implies roughly 20–30 a wave early, and Wave Info showed 16 active. Recommend the owner reads "enemies destroyed" and the current wave from the Stats tab; that one pair settles it.
2. **Thorns now decides Tier 1 (D064).** Recommend keeping The Tower's rule and checking its price and its Workshop level 30 gate against The Tower's unlock order once enemy counts land, rather than weakening it now.
3. **Does D063 feel right in play?** Recommend the owner plays this branch before merge: the wave-31 switch, a boss that stays in the pile, and Guard's "I've stopped dying" moment.
4. **Merge this branch?** It carries D063's game change and save V11, so a merge moves the owner's real save to V11 on first load (a V10 copy is kept). Recommend a PR once the owner has played it.
5. **Later:** the Workshop set proposed in the audit is superseded by rule 2 (copy The Tower's group rows once enemies can be held back); the D047 pacing alternative, coin gates, Research Focus, Labs/Cards/Ultimates sizing and the unmerged `codex/prestige-run-summary` (which must move past save V11) remain open.

## Next steps, in order

1. **Owner:** play the branch, and read enemies destroyed and the current wave from The Tower's Stats tab (open decision 1). **Done when:** the early enemy count is known, and D063 is kept or corrected.
2. **Agent: enemies per wave with full health each.** Copy The Tower: many enemies a wave, each with the wave's full enemy health, spawning through a longer wave (26 seconds plus a 9-second gap), rather than a few enemies sharing one total over 15 seconds. It moves every balance figure, the arena's drawing (18 enemies drawn at most today) and save V11's members, and the pile's frame cost needs a real fix first (see below). **Done when:** a D064 is accepted, and the economy suite, headless boot, arena probe, old-save fixtures, six-seed builds and a focused career pass and are measured. High economy and save risk; review the final diff independently.
3. **Agent: enemy types and pay per kill.** Fast (twice the speed), tank (5× health), ranged; the owner's mix of 85/7/6/2%; Cash per kill and Coins only from non-basic enemies (fast 2, ranged 3 per the owner's table, tank 4, boss 5). This gives Damage and Attack Speed separate jobs. **Done when:** as above, as its own decision.
4. **Agent, after those: distance.** Arrival times that damage and pushback can change, then The Tower's reach and crowd-control rows (Range, Knockback, Orbs, Bounce Shot, Multishot targets), unlocked with Coins as The Tower does. **Done when:** as above.
5. **Agent, any time:** the arena layout pass (entering enemies overlap, the front caption clips on narrow screens). Low–medium risk.

## How to measure

- **What ran for D063:** `bash run_tests.sh` → `PASS: economy tests` (no count printed; a deliberate corrupt-save fixture prints an `Exponent too high` warning). Headless boot clean. `xvfb-run -a -s "-screen 0 1024x1100x24" bash run_godot.sh --path . -s res://tools/arena_probe.gd` → `ARENA PROBE PASS`; its boss and ledger screenshots were inspected. The six-seed figures, `run_balance.sh` against the previous commit, and the 30-run focused career are in D063. **Not run:** `tools/capture_ui.gd`'s four-size captures, CI, a phone, touch play, the owner's real save, and a fully maxed Attack build under D063 (a pile hundreds deep makes it very slow to simulate).
- **On Linux:** download Godot 4.7.2 and check its SHA-512 exactly as `.github/workflows/verify.yml` does, then set `GODOT` to it. `run_balance.sh` needs `GODOT` set on its own command line.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants; for seeds 1–6 run `tap()` and two `advance(0.25)` until death and average the waves. Tag each enemy dictionary with an id to split damage and Hits by pile and first contact. Delete it afterwards.
- **Tower reference figures:** `npm install thetowersdk@0.11.0` in a scratch folder and call `computeWaveBaseHealthRaw`, `computeWaveBaseDamage` and `killsPerWaveFromSpawnContext` from `thetowersdk/mechanics`. Its early-wave enemy counts are a guess; the owner's screens outrank it.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 20 minutes.
- **Never kill processes with `pkill -f`** or a `pgrep -f` pattern that can match your own shell; kill Godot by PID (`pgrep -x godot`).

## Known issues and risks

- **The pile's frame cost grows faster than the pile:** about 0.2 ms of game logic a frame with 100 enemies, 0.9 with 400 and 3.2 with 1,000 (Linux, busy). Several whole-list scans run per shot. Fine for today's piles; a real problem once waves hold dozens of enemies each, so fix it before step 2.
- **Guard at zero from an enemy further back** can show the front enemy's working instead of its own; the Wave label's pulse through the last seconds of a boss wave still keys on the boss wave, not a boss carried into the pile; `best_time` records only when wave 100 itself is beaten (it isn't shown anywhere).
- **`get_effective_collection()`** still takes Guard once off the whole wave's Hit; only the balance simulator's reserve and some tests read it, so its Cash reserve is slightly off.
- **Arena layout remains unfinished:** a large pile overlaps enemy numbers and captions, and the front caption clips on a narrow screen.
- **Balance targets 5, 7 and 8** need restating for D063; target 2 (Coins per minute) still fails by design since D037.
- **`data/workshop/current.json`** is a generated snapshot still on profile v10; regenerate it with `tools/export_workshop.gd` when the Workshop next changes.
- **Save V11** will not load in an older build (D028). The D060 reconciliation for D058 saves still runs on load.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20.
- **After a pull that adds a script** (this branch adds `src/save_data_v11.gd`), a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen.

## Handing on

D063 is built, reviewed and measured; the owner plays it and supplies the early enemy count, then enemies per wave comes next, then enemy types, then distance. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D064 onwards), with the owner's words, context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md), [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md).
3. **Say plainly what ran and what did not.** Report figures actually measured, and anything not checked (in motion, on a phone).
4. **Commit on a branch, never `main`, and push it.** Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

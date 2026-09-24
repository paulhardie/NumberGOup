# Handover

**Last updated:** 24 September 2026, by Claude, handing on to the next agent. `claude/codex-handover-if13d2` holds Codex's handover, the Workshop audit, the Tower research and **D063, D064 and D065, built** (D063 in `be0a3de` and `a40d08a`, D064 in `c87ea93`, the pile's speed-up in `7377280`, D065 in `29ec178`, each with documentation commits after). It is unmerged and has no PR. `main` is still at PR #55 (`993962f`).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D065 in [`DECISIONS.md`](DECISIONS.md), and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026); for Workshop rows, prices and unlock order, [`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Standing owner rule (D063): "If in doubt, copy the way the tower does it", shaped to a game of numbers.** D009 still keeps copied constants out: copy The Tower's rules and structure, and fit our own coefficients to its shape.
3. **This branch so far:** D063 (enemies tank more than they hit, bosses are walls that hit like one enemy, The Tower's defence order, 4% heat-up, late kills still pay), D064 (Thorns is a share of the attacker's maximum HP), then the pile made cheap to run, then D065: many enemies a wave, each with full health, on a 35-second wave.
4. **Next, by the owner's ordering of "tower-ifying":** enemy types and pay per kill, then distance (reach and crowd control), then the arena layout pass, which D065's crowds have made urgent.

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v13`, save V11; nothing below has been played by the owner or checked on a phone).

- **Waves (D065)** last 35 seconds: enemies arrive evenly from 6 to 32 seconds, then a 9-second gap. 20 enemies at wave 1, about 32 by wave 100 and 142 by wave 1,000, at most 220. Each carries the full enemy health (64.5 at wave 22; The Tower's is 63.11). Shots and taps strike the front living enemy; overkill is lost. A beaten wave still gives way after 2.5 seconds (D037).
- **Enemies stay (D058) after a gentler opening (D059).** To wave 30 an enemy hits once and leaves; from wave 31 it stays and hits again on its interval. A wave with enemies alive at 35 seconds passes, paying for the share cleared, and its survivors carry into the next wave in front.
- **The Tower's shape (D063).** Enemies tank far more than they hit (the ratio grows from about 2.4 at wave 1 to 11 at 100). Each hit an enemy lands makes its next 4% stronger. Armor comes off each enemy's hit first, then Guard, down to nothing. A boss wave adds a boss with twenty enemies' health that arrives at 15 seconds and hits like one enemy; it stays in the pile until beaten. Boss Damage and Leech work on the boss itself.
- **Pay:** each enemy beaten pays its share of its wave's Coins and Cash, even after its wave passed; Coins below one carry between kills. A boss pays its Gem and "boss beaten" moment when it falls.
- **Thorns (D064)** deals every enemy that hits you a share of its own maximum HP (0.495% a rank, 99% at rank 200), bosses half, whatever Guard or a Brace took off the hit.
- **Where builds land** (six seeds, two taps a second, no run Upgrades, D064 → D065): fresh 32 → 19, early 38 → 32, mid 54 → 39, mid + Guard 68 → 51, mid + Thorns 105 → 62, mid + Guard + Thorns 144 → 100, rank-100 Attack 109 (+ Guard 109), + full Thorns 346 → 238.
- **A focused career buying run Upgrades** (30 runs, D065): first run wave 30 with 111 Coins, wave 100 at 4.3 hours (D064: 1.2), wave 200 at 9.4, wave 496 at 31.4. Time to max the Workshop is still unmeasured.
- **Shots, Workshop and look** are as before: 2.5 shots a second before Attack Speed (D055); Tap Damage and Damage run to 6,000 ranks (D047); run Upgrades sell every row for Cash (D042–D045); the Instrument layout with fixed combat readouts (D061, D062).

## Open decisions for the owner

1. **How many enemies does The Tower send per wave early on?** D065 guesses 20 at wave 1 (`FIRST_WAVE_MEMBERS`, one setting). Recommend the owner reads "enemies destroyed" and the current wave from The Tower's Stats tab; that one pair settles it.
2. **Should waves be fixed length, as The Tower's are?** Today a strong build strikes enemies before they arrive and moves on 2.5 seconds after beating the wave (D037), so maxed builds run about 24 seconds a wave. Recommend settling it inside the distance step, where arrival becomes a place and unarrived enemies can't be hit; changing D037 on its own would slow strong runs further without the rest of the Tower's shape.
3. **Is the opening now too harsh?** A fresh run dies at wave 19 and a career takes 4.3 hours to wave 100. Recommend the owner plays a fresh run before anyone retunes; enemy types (fast, tank, ranged) will move it again.
4. **Merge this branch?** It carries D063–D065 and save V11, so a merge moves the owner's real save to V11 on first load (a V10 copy is kept). Recommend a PR once the owner has played it.
5. **Workshop pricing and unlocks (from the wiki tables).** The Tower's row prices rise with roughly the square of the level (cheap early, flattening), where ours compound 4.2% a rank; and its rows unlock with Coins in a fixed order, where ours unlock by Workshop level. Recommend folding both into the distance step's Coin-gated unlocks rather than repricing now, since enemy types will move Coin income first.
6. **Later:** the Workshop set proposed in the audit is superseded by rule 2; the D047 pacing alternative, coin gates, Research Focus, Labs/Cards/Ultimates sizing and the unmerged `codex/prestige-run-summary` (which must move past save V11) remain open.

## Next steps, in order

1. **Owner:** play a fresh run on the branch, and read enemies destroyed and the current wave from The Tower's Stats tab (open decision 1). **Done when:** the early enemy count is known, and D065's opening is kept or corrected.
2. **Agent: enemy types and pay per kill.** Fast, tank, ranged, and the protector the owner's screen showed. Health from the owner's screen (fast 1×, ranged 1×, tank 5×, protector 0.6×; the older table in [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) disagrees and the screen wins). The owner's mix is 85/7/6/2%. Pay is Cash per kill, with Coins only from non-basic enemies: fast 2, ranged 3, tank 4, boss 5. Weights already carry each enemy's size, so a tank is a member of weight 5. **Done when:** a D066 is accepted, and the economy suite, headless boot, arena probe, old-save fixtures, six-seed builds and a focused career pass and are measured. High economy and save risk; review the final diff independently.
3. **Agent: the arena layout pass.** 20 or more enemies a wave, each with its number, overlap badly; the front caption clips on narrow screens. Low–medium risk; can run alongside step 2 if one owner holds `main.gd`.
4. **Agent, after enemy types: distance.** Arrival as a position that damage and pushback can change, unarrived enemies out of reach (open decision 2), then The Tower's reach and crowd-control rows (Range, Knockback, Orbs, Bounce Shot, Multishot targets), unlocked with Coins as The Tower does.

## How to measure

- **What ran for D065:** `bash run_tests.sh` → `PASS: economy tests` (no count printed; a deliberate corrupt-save fixture prints an `Exponent too high` warning). Headless boot clean. `xvfb-run -a -s "-screen 0 1024x1100x24" bash run_godot.sh --path . -s res://tools/arena_probe.gd` → `ARENA PROBE PASS`, and its screenshots were inspected (cluttered, see known issues). The six-seed figures, `run_balance.sh` and the 30-run focused career are in D065. **Not run:** `tools/capture_ui.gd`'s four-size captures, CI, a phone, touch play and the owner's real save.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 exactly as `.github/workflows/verify.yml` does, then set `GODOT` to it. `run_balance.sh` needs `GODOT` set on its own command line.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants; for seeds 1–6 run `tap()` and two `advance(0.25)` until death and average the waves. Tag each enemy dictionary with an id to split damage and Hits by pile and first contact. Delete it afterwards. A rank-100 Attack build with Thorns takes several minutes a seed.
- **Tests that need a small wave** set `TaxBalanceProfile.FIRST_WAVE_MEMBERS` (a `var` for that reason) and restore it.
- **Tower reference figures:** `npm install thetowersdk@0.11.0` in a scratch folder and call `computeWaveBaseHealthRaw`, `computeWaveBaseDamage` and `killsPerWaveFromSpawnContext` from `thetowersdk/mechanics`. Its early-wave enemy counts are a guess; the owner's screens outrank it.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 25 minutes now that runs are longer.
- **Never kill processes with `pkill -f`** or a `pgrep -f` pattern that can match your own shell; kill Godot by PID (`pgrep -x godot`).

## Known issues and risks

- **The arena is cluttered:** with 20+ enemies a wave, enemy numbers and captions overlap, and the front caption clips on a narrow screen.
- **Strong builds hit enemies before they arrive** and beat waves early (open decision 2).
- **Guard at zero from an enemy further back** can show the front enemy's working instead of its own; the Wave label's pulse through the last seconds of a boss wave still keys on the boss wave, not a boss carried into the pile; `best_time` records only when wave 100 itself is beaten (it isn't shown anywhere).
- **`get_effective_collection()`** still takes Guard once off the whole wave's Hit; only the balance simulator's reserve and some tests read it, so its Cash reserve is slightly off.
- **Balance targets 5, 7 and 8** need restating for D063–D065; target 2 (Coins per minute) still fails by design since D037.
- **`data/workshop/current.json`** is a generated snapshot still on profile v10; regenerate it with `tools/export_workshop.gd` when the Workshop next changes.
- **Save V11** will not load in an older build (D028), and has grown (`coin_fraction`, member `weight` and `of`) without a bump because it has never shipped; once merged, any further field needs V12. The D060 reconciliation for D058 saves still runs on load.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20.
- **After a pull that adds a script** (this branch adds `src/save_data_v11.gd`), a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen.

## Handing on

D065 is built and measured; the owner plays a fresh run and supplies the early enemy count, then enemy types come next, with the arena layout pass alongside, then distance. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D066 onwards), with the owner's words, context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md), [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md).
3. **Say plainly what ran and what did not.** Report figures actually measured, and anything not checked (in motion, on a phone).
4. **Commit on a branch, never `main`, and push it.** Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

# Handover

**Last updated:** 25 September 2026, by Claude, handing on to the next agent. `claude/codex-handover-if13d2` holds Codex's handover, the Workshop audit, the Tower research and **D063 to D067, built**:
- D063 in `be0a3de` and `a40d08a`, D064 in `c87ea93`, the pile's speed-up in `7377280`, D065 in `29ec178`;
- exact saved numbers in `11451b7`, D066 in `68dcd81` and `10b8027`, The Tower's flat Coins per Wave in `0b3b009`;
- D067 in `ff372a5`, `c3d44d0`, `9888598` and `dd75d95`;
- each with documentation commits.

The branch is unmerged and has no PR. `main` is still at PR #55 (`993962f`).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D067 in [`DECISIONS.md`](DECISIONS.md), and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026). For Workshop rows, prices and unlock order, read [`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Standing owner rule (D063): "If in doubt, copy the way the tower does it", shaped to a game of numbers.** The owner's latest answers repeat it: Coins per Wave, distance and the arena all "the way the tower does it", with numbers instead of squares. D009 still keeps copied constants out: copy The Tower's rules and structure, and fit our own coefficients to its shape.
3. **This branch so far:**
   - **D063:** enemies tank more than they hit, bosses are walls, The Tower's defence order, 4% heat-up.
   - **D064:** Thorns is a share of the attacker's maximum HP.
   - **D065:** many enemies a wave on a 35-second wave.
   - **D066:** enemy types, pay per kill, Coins per Wave.
   - **D067:** distance, reach, fixed-length waves and The Tower's field.
4. **Next:** The Tower's reach and crowd-control rows (Range, Knockback, Orbs, Bounce Shot, Multishot targets), unlocked with Coins in The Tower's order.

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v15`, save V11). Nothing below has been played by the owner or checked on a phone.

- **The field (D067).**
  - The Number sits in the middle of the arena inside a faint ring at its 30 m reach.
  - Enemies set off 60 m out, evenly through the first 26 seconds of a 35-second wave, and walk straight in from their own directions: a basic at 10 m/s (6 seconds), fast 2.4×, tank and boss a third, ranged a half.
  - Production strikes only enemies within reach, nearest first. With nothing in reach it is Number alone.
  - Ranged enemies stop on the ring and fire from there.
  - Every wave runs its whole 35 seconds. At its end it counts as beaten if all of it that came within reach fell; a late tank still walking in carries on.
- **Waves (D065, D066).**
  - 20 enemies at wave 1, about 32 by wave 100 and 142 by wave 1,000, at most 220.
  - The mix is 85% basic, 7% fast, 6% tank and 2% ranged, drawn per run and wave.
  - A tank carries five enemies' health and a boss twenty, but every type hits like one enemy.
- **Enemies stay (D058) after a gentler opening (D059).** Through wave 30 an enemy hits once and leaves; after that it stays and hits on its interval. Survivors carry into the next wave in front.
- **The Tower's shape (D063):** enemies tank far more than they hit, each hit heats the next by 4%, and Armor then Guard come off each enemy's hit.
- **Pay (D066).**
  - Every kill pays as it happens: Coins by type (basics none, then fast, ranged, tank and boss in the owner's 2/3/4/5 ratio), Cash by the enemy's health share, and a boss's Gem.
  - Every wave's end pays one kill-coin unit, The Tower's Coins per Wave base.
  - The Coin-paying types lean gold in the arena, tanks are drawn larger, and the live number's caption names its type.
- **Where builds land** (six seeds, two taps a second, no run Upgrades):

  | Build | Wave | Minutes | Coins |
  |---|---|---|---|
  | Fresh | 20 | 11.3 | 21 |
  | Early | 33 | 19 | 70 |
  | Mid | 40 | 23 | 338 |
  | Mid + Guard + Thorns | 101.7 | 59 | 4,410 |
  | Rank-100 Attack | 111.7 | 65 | 4,917 |
  | Rank-100 Attack + full Thorns | alive at 90 minutes on wave 155 | 90 | — |

- **A focused career buying run Upgrades** (30 runs):
  - First run wave 31 with 54 Coins, wave 50 at 4.4 hours, **wave 100 at 6.7**.
  - The thirtieth run reaches wave 309 at 45.5 hours, at the 180-minute run cap: 308 waves of 35 seconds.
  - Time to max the Workshop is still unmeasured.
- **Shots, Workshop and look** are otherwise as before (D055, D047, D042–D045, D061, D062).

## Open decisions for the owner

1. **The opening's Coins.** A fresh run earns 21 Coins and an early build 70 (D065: 37 and 138). Two things cause it: opening enemies that hit once and leave (D059) never pay, and every wave now spends its first 3 seconds with nothing in reach. The Tower's own answer is that enemies stay at the tower until killed. **Recommend deciding this when the reach rows land:** Range and Orbs change how much an opening build can kill before enemies arrive, so the answer may change.
2. **How many enemies does The Tower send per wave early on?** D065 guesses 20 at wave 1 (`FIRST_WAVE_MEMBERS`, one setting). Recommend the owner reads "enemies destroyed" and the current wave from The Tower's Stats tab.
3. **Merge this branch?** It carries D063–D067 and save V11, so a merge moves the owner's real save to V11 on first load. A V10 copy is kept, and any kills in its active wave are paid on today's rules. Recommend a PR once the owner has played it.
4. **Workshop pricing and unlocks.** The Tower's row prices rise with roughly the square of the level, and its rows unlock with Coins in a fixed order; ours compound 4.2% a rank and unlock by Workshop level. Recommend doing the Coin unlocks with the reach rows, as The Tower's own order introduces them.
5. **Later:**
   - the deep-wave enemy mix;
   - protectors (from Tier 2);
   - The Tower's Coins per Wave Workshop row;
   - the D047 pacing alternative;
   - Research Focus;
   - Labs, Cards and Ultimates sizing;
   - the unmerged `codex/prestige-run-summary`, which must move past save V11.

## Next steps, in order

1. **Agent: The Tower's reach and crowd-control rows.** Build Range (30 m +0.5 m a level), Knockback (chance and force, pushing where an enemy set off, weaker on heavier enemies), Orbs (instant kills at a radius, not bosses), Bounce Shot (chance, targets, range from the struck enemy), Multishot targets, and Damage/Meter if it fits. Unlock them with Coins in The Tower's order ([`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md)); prices and values are ours (D009).
   - **Done when:** a D068 is accepted, and the economy suite, headless boot, arena probe, old-save fixtures, six-seed builds and a focused career pass and are measured.
   - High economy and save risk (new rows, a saved push offset); review the final diff independently.
   - Knockback needs a pushed-distance term on each enemy, with its arrival recomputed after a push.
2. **Owner:** play a fresh run on the branch, and read enemies destroyed and the current wave from The Tower's Stats tab. **Done when:** the early enemy count is settled and the field has been seen in motion.
3. **Agent: arena polish.** Show a large pile's count rather than crowding its ring, and check the boss's live number on the tablet capture, which once showed "48,13" for 48,132. Low risk.

## How to measure

- **What ran for D067:**
  - `bash run_tests.sh` → `PASS: economy tests`. It now runs in seconds; the target cache made the per-shot scans cheap.
  - Headless boot clean.
  - `xvfb-run -a -s "-screen 0 1024x1100x24" bash run_godot.sh --path . -s res://tools/arena_probe.gd` → `ARENA PROBE PASS`. The only error line is ALSA finding no sound card in the container.
  - `tools/capture_ui.gd` at four sizes, inspected.
  - The six-seed builds, `run_balance.sh` and the 30-run career are in D067.
  - Independent reviews of the D066 and D067 diffs; their findings are fixed with regression tests.
  - **Not run:** CI, a phone, touch play and the owner's real save.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 exactly as `.github/workflows/verify.yml` does, then set `GODOT` to it. `run_balance.sh` needs `GODOT` set on its own command line.
- **Across seeds:**
  - Write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants.
  - For seeds 1–6, run `tap()` and two `advance(0.25)` until death, and average the waves and Coins.
  - List the script in `.git/info/exclude` while a job still reads it, and delete it afterwards.
  - Four processes in parallel suit this container, but don't edit `src/` while they run: each probe build starts a fresh Godot and reads the code as it then is.
- **Tests:**
  - Tests not about distance put their wave in reach with `_all_in_reach(state)`.
  - Tests that kill a whole wave use `_beat_wave`, which strikes every enemy wherever it is.
  - Tests that need one enemy type set `balance_profile.ENEMY_MIX` (a `var` for that reason).
- **Tower reference figures:** the wiki is readable through its API (`api.php?action=parse&page=<Page>&prop=text&format=json`). TheTowerSDK is at `npm install thetowersdk@0.11.0`. The owner's screens outrank both.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 45 minutes now that waves are fixed at 35 seconds.
- **Never kill processes with `pkill -f`** or a `pgrep -f` pattern that can match your own shell; kill Godot by PID (`pgrep -x godot`).

## Known issues and risks

- **A large pile still crowds its ring** round the Number, though far less than the old column.
- **The "boss beaten" moment** waits for its wave's clock to end. Its Gem pays when it falls.
- **Guard at zero from an enemy further back** can show the front enemy's working instead of its own. The Wave label's pulse through the last seconds of a boss wave still keys on the boss wave, not a boss carried into the pile. `best_time` records only when wave 100 itself is beaten, and it isn't shown anywhere.
- **`get_effective_collection()`** still takes Guard once off the whole wave's Hit. Only the balance simulator's reserve and some tests read it.
- **Balance targets 5, 7 and 8** need restating for D063–D067; target 2 (Coins per minute) still fails by design since D037.
- **`data/workshop/current.json`** is a generated snapshot still on profile v10. Regenerate it with `tools/export_workshop.gd` when the Workshop next changes.
- **Save V11** will not load in an older build (D028). It has grown without a bump because it has never shipped:
  - the run's `coin_fraction`;
  - each member's `weight`, `of`, `kind`, `paid` and `sets_off`;
  - every number's exact `bits`.

  Once merged, any further field needs V12. `wave_accumulator` is still saved as a plain float.
- **Other small issues:** Cash counts a tap a second even when idle; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20.
- **After a pull that adds a script** (this branch adds `src/save_data_v11.gd`), a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen.

## Handing on

D067 is built, reviewed and measured. The owner plays the field and supplies the early enemy count. The reach and crowd-control rows come next. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape:
   - who is handing to whom and when;
   - the branch and what is on it (merged or not, PR number);
   - where the game is;
   - the owner's open decisions, with a recommendation each;
   - next steps, each with a "done when";
   - how to measure, and known issues;
   - this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D068 onwards). Include the owner's words, the context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit.
3. **Say plainly what ran and what did not.**
4. **Commit on a branch, never `main`, and push it.** Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

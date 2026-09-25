# Handover

**Last updated:** 25 September 2026, by Claude, handing on to the next agent. `claude/codex-handover-if13d2` holds Codex's handover, the Workshop audit, the Tower research and **D063 to D066, built** (D063 in `be0a3de` and `a40d08a`, D064 in `c87ea93`, the pile's speed-up in `7377280`, D065 in `29ec178`, exact saved numbers in `11451b7`, D066 in `68dcd81` with its review fixes after, each with documentation commits). It is unmerged and has no PR. `main` is still at PR #55 (`993962f`).
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), D056–D066 in [`DECISIONS.md`](DECISIONS.md), and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026); for Workshop rows, prices and unlock order, [`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Standing owner rule (D063): "If in doubt, copy the way the tower does it", shaped to a game of numbers.** D009 still keeps copied constants out: copy The Tower's rules and structure, and fit our own coefficients to its shape.
3. **This branch so far:**
   - **D063:** enemies tank more than they hit, bosses are walls that hit like one enemy, The Tower's defence order, 4% heat-up.
   - **D064:** Thorns deals a share of the attacker's maximum HP.
   - The pile made cheap to run.
   - **D065:** many enemies a wave, each with full health, on a 35-second wave.
   - **D066:** The Tower's enemy types, and every kill paying as it happens, plus Coins per Wave.
4. **Next, by the owner's ordering of "tower-ifying":** distance (reach and crowd control), with the arena layout pass alongside; the crowds and the types have made it urgent.

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v14`, save V11; nothing below has been played by the owner or checked on a phone).

- **Waves (D065, D066)** last 35 seconds.
  - **Count:** 20 enemies at wave 1, about 32 by wave 100 and 142 by wave 1,000, at most 220.
  - **Types:** 85% basic, 7% fast, 6% tank, 2% ranged, drawn per run and wave. A tank carries five enemies' health and a boss twenty, but every type hits like one enemy.
  - **Arrivals:** enemies set off over 26 seconds. Basic and ranged take 6 seconds to arrive, fast 2.5, tanks and bosses 18 (a boss arrives at 18), so a late tank can arrive after its wave and be carried into the next.
  - **Targeting:** shots and taps strike the front living enemy; overkill is lost. A beaten wave still gives way after 2.5 seconds (D037).
- **Enemies stay (D058) after a gentler opening (D059).** To wave 30 an enemy hits once and leaves; from wave 31 it stays and hits again on its interval. A wave with enemies alive at 35 seconds passes, and its survivors carry into the next wave in front.
- **The Tower's shape (D063).** Enemies tank far more than they hit, and each hit an enemy lands makes its next 4% stronger. Armor comes off each enemy's hit first, then Guard, down to nothing. A boss stays until beaten; Boss Damage and Leech work on the boss itself.
- **Pay (D066).** Every kill pays as it happens:
  - **Coins** by type: basics none, then fast, ranged, tank and boss, in the owner's 2/3/4/5 ratio, carried in parts of a Coin between payments.
  - **Cash** by the enemy's share of its wave's health.
  - **Gems:** a boss pays its Gem when it falls.
  - **Coins per Wave:** every wave's end, beaten or passed, pays one kill-coin unit, The Tower's base of 1 (the owner's choice: "do what the tower does").
  - **In the arena,** the Coin-paying types lean gold, tanks are larger, and the front enemy's caption names its type.
- **Thorns (D064)** deals every enemy that hits you a share of its own maximum HP (0.495% a rank, 99% at rank 200), bosses half.
- **Where builds land** (six seeds, two taps a second, no run Upgrades, D066; waves as under D065):

  | Build | Wave | Coins |
  |---|---|---|
  | Fresh | 19 | 39.5 |
  | Early | 33 | 134 |
  | Mid | 38.5 | 451 |
  | Mid + Guard + Thorns | 101 | — |
  | Rank-100 Attack | 108.5 | 5,018 |
  | Rank-100 Attack + full Thorns | alive at 90 minutes on wave 226 | — |

- **A focused career buying run Upgrades** (30 runs, D066): first run wave 29 with 93 Coins, wave 50 at 3.4 hours, **wave 100 at 5.5 (D065: 4.3)**, the thirtieth run wave 496 at 32.4 hours (D065: 31.4). Time to max the Workshop is still unmeasured.
- **Shots, Workshop and look** are as before: 2.5 shots a second before Attack Speed (D055); Tap Damage and Damage run to 6,000 ranks (D047); run Upgrades sell every row for Cash (D042–D045); the Instrument layout with fixed combat readouts (D061, D062).

## Open decisions for the owner

1. **The opening's Coins (D066).** With The Tower's flat Coins per Wave, a fresh run earns 24 Coins and an early build 86 (D065: 37 and 138), because opening enemies that hit once and leave (D059) never pay. Distance, built The Tower's way, is where that settles: The Tower's enemies stay at the tower until killed.
2. **How many enemies does The Tower send per wave early on?** D065 guesses 20 at wave 1 (`FIRST_WAVE_MEMBERS`, one setting). Recommend the owner reads "enemies destroyed" and the current wave from The Tower's Stats tab; that one pair settles it.
3. **Should waves be fixed length, as The Tower's are?** Today a strong build strikes enemies before they arrive and moves on 2.5 seconds after beating the wave (D037). Recommend settling it inside the distance step, where arrival becomes a place and unarrived enemies can't be hit.
4. **Merge this branch?** It carries D063–D066 and save V11, so a merge moves the owner's real save to V11 on first load (a V10 copy is kept, and any kills in its active wave are paid on today's rules). Recommend a PR once the owner has played it.
5. **Workshop pricing and unlocks (from the wiki tables).** The Tower's row prices rise with roughly the square of the level (cheap early, flattening), where ours compound 4.2% a rank; and its rows unlock with Coins in a fixed order, where ours unlock by Workshop level. Recommend folding both into the distance step's Coin-gated unlocks.
6. **Later:** the deep-wave enemy mix (The Tower's shifts towards the rarer types; ours holds at the wave 22 screen), protectors (which The Tower sends from Tier 2), the D047 pacing alternative, coin gates, Research Focus, Labs/Cards/Ultimates sizing and the unmerged `codex/prestige-run-summary` (which must move past save V11) remain open.

## Next steps, in order

1. **Owner:** play a fresh run on the branch, and read enemies destroyed and the current wave from The Tower's Stats tab. **Done when:** the early enemy count is settled.
2. **Agent: distance.** Arrival as a position that damage and pushback can change, unarrived enemies out of reach (open decision 3), ranged enemies firing from their range, then The Tower's reach and crowd-control rows (Range, Knockback, Orbs, Bounce Shot, Multishot targets), unlocked with Coins as The Tower does. **Done when:** a D067 is accepted, and the economy suite, headless boot, arena probe, old-save fixtures, six-seed builds and a focused career pass and are measured. High economy and save risk; review the final diff independently.
3. **Agent: the arena layout pass.** 20 or more enemies a wave overlap badly; the front caption clips on narrow screens; a carried walker's drawing should be checked in motion. Low–medium risk; can run alongside step 2 if one owner holds `main.gd`.

## How to measure

- **What ran for D066:**
  - `bash run_tests.sh` → `PASS: economy tests`.
  - Headless boot clean.
  - `xvfb-run -a -s "-screen 0 1024x1100x24" bash run_godot.sh --path . -s res://tools/arena_probe.gd` → `ARENA PROBE PASS`, and its screenshots were inspected (types read; still cluttered). Its only error line is ALSA finding no sound card in the container.
  - The six-seed figures, the Coins per Wave sweep, `run_balance.sh` and the 30-run focused career are in D066.
  - An independent review of the diff; its findings are fixed and have regression tests.
  - **Not run:** `tools/capture_ui.gd`'s four-size captures, CI, a phone, touch play and the owner's real save.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 exactly as `.github/workflows/verify.yml` does, then set `GODOT` to it. `run_balance.sh` needs `GODOT` set on its own command line.
- **Across seeds:** write a throwaway `tools/_something.gd` that preloads `res://tools/balance_simulator.gd` for its build constants.
  - For seeds 1–6, run `tap()` and two `advance(0.25)` until death; average the waves and Coins.
  - Tag each enemy dictionary with an id to split damage and Hits by pile and first contact.
  - Delete it afterwards, or list it in `.git/info/exclude` while a job still reads it.
  - Four processes in parallel suit this container.
- **Tests that need one enemy type** set `balance_profile.ENEMY_MIX = {"basic": 1.0}` (a `var` for that reason); tests that need a small wave set `FIRST_WAVE_MEMBERS`.
- **Tower reference figures:** `npm install thetowersdk@0.11.0` in a scratch folder and call `computeWaveBaseHealthRaw`, `computeWaveBaseDamage` and `killsPerWaveFromSpawnContext` from `thetowersdk/mechanics`. Its early-wave enemy counts are a guess; the owner's screens outrank it.
- **Pacing:** `tools/career_simulator.gd -- --spend focused --careers today_rig --runs 30 --run-cap-minutes 180` takes about 30 minutes.
- **Never kill processes with `pkill -f`** or a `pgrep -f` pattern that can match your own shell; kill Godot by PID (`pgrep -x godot`).

## Known issues and risks

- **The arena is cluttered:** with 20+ enemies a wave, enemy numbers and captions overlap, and the front caption clips on a narrow screen.
- **Strong builds hit enemies before they arrive** and beat waves early (open decision 3). A late tank alone can keep a weaker build's wave from counting as beaten; how often is unmeasured.
- **Guard at zero from an enemy further back** can show the front enemy's working instead of its own. The Wave label's pulse through the last seconds of a boss wave still keys on the boss wave, not a boss carried into the pile. `best_time` records only when wave 100 itself is beaten (it isn't shown anywhere).
- **`get_effective_collection()`** still takes Guard once off the whole wave's Hit; only the balance simulator's reserve and some tests read it, so its Cash reserve is slightly off.
- **Balance targets 5, 7 and 8** need restating for D063–D066; target 2 (Coins per minute) still fails by design since D037.
- **`data/workshop/current.json`** is a generated snapshot still on profile v10; regenerate it with `tools/export_workshop.gd` when the Workshop next changes.
- **Save V11** will not load in an older build (D028). It has grown (`coin_fraction`; member `weight`, `of`, `kind`, `paid`; every number's exact `bits`) without a bump because it has never shipped. Once merged, any further field needs V12. The D060 reconciliation for D058 saves still runs on load.
- **Cash counts a tap a second even when idle**; `run_cash_earned` is saved but unread; the Crit Chance card adds nothing once Workshop Crit Chance is maxed; Lab research is unreachable past about rank 20.
- **After a pull that adds a script** (this branch adds `src/save_data_v11.gd`), a blank grey window means a stale editor cache: quit Godot, delete `~/NumberGOup-main/.godot`, reopen.

## Handing on

D066 is built, reviewed and measured. The owner chose The Tower's flat Coins per Wave; distance comes next, with the arena layout pass alongside. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape: who is handing to whom and when; the branch and what is on it (merged or not, PR number); where the game is; the owner's open decisions with a recommendation each; next steps with a "done when"; how to measure; known issues; and this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D067 onwards), with:
   - the owner's words and the context;
   - the decision;
   - the evidence (the figures measured and how);
   - the consequences, and when to revisit.

   Update any document the change makes stale in the same commit: [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md), [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md), [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md), [`WORKSHOP_EXPANSION.md`](WORKSHOP_EXPANSION.md), [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md).
3. **Say plainly what ran and what did not.** Report figures actually measured, and anything not checked (in motion, on a phone).
4. **Commit on a branch, never `main`, and push it.** Match the existing commit style: a short imperative subject and a body saying what the player will notice and why. Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

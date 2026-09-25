# Handover

**Last updated:** 25 September 2026, by Claude, handing on to the next agent. **D068 (The Tower's Workshop), D069 (Labs, Cards, Knowledge and Gems parked) and D070 (more room in the run arena) are merged to `main`** in PR #59. `claude/beautiful-dirac-6ozaio` carries, on top of `main`, the fixes for PR #59's Codex review (`cb77565`: a knocked-back enemy keeps its wave from being beaten, Stats' Damage / sec leaves Health Regen out, the hub's Coin row is named for what it shows, the arena probe's stream checks are deterministic) and **D071: Cash per kill, The Tower's way** (with Interest capped at $50 a wave), plus a fix so kills paid before a rebuild onto a newer balance profile stay paid, and **D072: enemies stay and hit from wave 1**, as The Tower's do.

The branch is unmerged and has no PR. `claude/codex-handover-if13d2` is stale: everything on it is in `main`.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

0. **A rebuild is proposed** in [`REBUILD_SPEC.md`](REBUILD_SPEC.md) (25 September, `claude/great-tesla-9kfp95`): The Tower's first hours built clean, then the Number added as one twist. Until the owner says go or no, don't start new tuning work below; if they say go, the spec replaces these next steps.
1. Read [`AGENTS.md`](../AGENTS.md), D063–D071 in [`DECISIONS.md`](DECISIONS.md), the [Workshop since D068](WORKSHOP_DESIGN.md#the-workshop-since-d068-the-towers) and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Owner direction:**
   - **"Go full tower for now and get the base built"** (D068), with the Number kept ("Number stays, Tower around it"). D063's standing rule still holds: if in doubt, copy the way The Tower does it, shaped to a game of numbers.
   - **Core loop first** (D069): "leave out cards etc for now until the loop is fun". The Tower launched as the core loop alone (tower, Cash upgrades in a run, Coins for the Workshop); its later layers came once that worked. **Build no new layer** (Ultimate Weapons, Perks, Modules, events, tournaments) and bring back no parked one until the owner says the loop is fun.
3. **What's parked (D069):** Labs, Cards, Knowledge (Insight, Prestige, Research Focus) and Gems. They add nothing and can't be bought, their screens are out of reach (Cards and Labs read SOON), and the save keeps all of their progress. One switch, `GameState.LAYERS_PARKED`, brings them back.
4. **Next:** make runs end for a reason (the first decision below). Cash is fitted (D071).

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v18`, save V12). Nothing below has been played by the owner or checked on a phone.

- **A fresh run is a fresh Tower:** the Number starts at Health 5 and shoots Damage 3 once a second at the nearest enemy within 30 m. A tap fires one more shot. Every shot's damage is Number too (D037).
- **The Workshop** opens Damage, Attack Speed, Critical Chance, Critical Factor, Health and Health Regen from the start. Everything else opens a group at a time for Coins: Range 50, Defense 75, Utility's Cash rows 40, and on up to Super Crit at 100M.
- **Run Upgrades** sell only rows the Workshop has opened, at The Tower's Cash prices ($10, $12, $14… for Damage), one level each. Cash starts at none and comes from kills (D071, The Tower's: $1 plus $1 every ten waves, times basic 1, fast and ranged 2, tank 5, boss 20 as our guess), Cash / Wave and Interest.
- **Pay:** a kill pays its type's Coins times its wave (basic none, fast 2, ranged 3, tank 4, boss 5); a wave's end pays Coins / Wave (1 before any level). Milestones pay their Coin bonuses; the Gems they also pay bank unseen while parked.
- **Enemies stay:** from wave 1 an enemy that reaches the Number stays and hits every 5 seconds until it dies (D072).
- **The field:** enemies set off 100 m out; a basic arrives in 10 seconds, a boss in 30. Orbs circle at 60 m or more. On screen (D070) the Number is set at 40 in the middle of the arena above Brace, enemies set off on the largest oval that fits, and enemy HP reads in whole numbers.
- **Where builds land** (seed 7, two taps a second, after D071 and D072):

  | Build | Result |
  |---|---|
  | Fresh, no run Upgrades | wave 13 in 7.3 min, 445 Coins (wave 33 before D072) |
  | Fresh, buying run Upgrades | **wave 107 in 62 min, 91,000 Coins** (wave 153 before D071) |
  | Early (Damage 20, Attack Speed 10, Health 20, Regen 10) | wave 61 in 35.5 min; buying run Upgrades, alive at 90 min on wave 155 |
  | Mid (Damage 100 and a spread) or more | alive at 90 min on wave 155, mostly never hit |

- **Careers** (12 runs, 90-minute cap, even spending, after D072): never buying run Upgrades reaches wave 20 on run 5 and wave 30 on run 8 (1.6 hours); buying them reaches wave 61 on run 1 and 106 on run 2 (1.6 hours), and **every run from run 3 lasts to the cap** on wave 155.

## Open decisions for the owner

1. **Runs stop ending from the third.** With Cash fitted (D071), the first two runs land near The Tower's pace, but from run 3 every run lasts to the cap. **Every shot is also Number** (D037), so with The Tower's Damage values a strong Attack build banks so much Number that hits stop mattering. **Recommend: bank only a share of what a shot deals, or only what it takes off an enemy, and measure the careers again;** the Number stays (D068) but stops being free health.
2. **A boss's Cash is a guess** (20 basics, D071). **Recommend: read one boss kill's Cash in The Tower** and replace it.
3. **The refund at 15×.** The owner's real save converts once on first load: its old Workshop levels become Coins at their old prices, and all its Coins are multiplied by 15. **Recommend accepting:** 15 is the ratio of both kill pay and first-level prices. The V10/V11 file is kept beside the new save.
4. **Merge this branch?** It carries the review fixes and D071. **Recommend: yes, once CI is green,** after the owner has played a run on it.

## Next steps, in order

1. **Owner:** play a fresh run on the branch, and read one boss kill's Cash in The Tower. **Done when:** the owner has said how the first runs feel.
2. **Agent: make runs end for a reason** (decision 1). **Done when:** the career simulator's buying-run-Upgrades career has runs that end before the cap after run 2, and the suite, probe and captures pass. High economy risk: independent review of the diff.
3. **Agent: The Tower's remaining Workshop rows** (Land Mines and Shockwave first, as the Defense order continues, then Wall, Recovery Packages and Enemy Level Skip). High risk: new mechanics and saved state.

**The core loop is fun when:** Cash is fitted to The Tower's pace, a first run ends sensibly, strong builds still get hit and runs end for a reason, and the owner has played it and says so. Only then does the parked list below start.

## Parked until the loop is fun (D069)

Each needs an owner "go", its own decision, and a retune against The Tower's Workshop, which none of them was balanced against. Unpark by flipping `GameState.LAYERS_PARKED`, or split the switch if they return one at a time.

- **Labs:** timed Coin research and its Gem-bought slots. When they return, settle the Workshop level gate first: save V12 drops old saves to Workshop level 0 (their retired rows became Coins), so an old save's Labs lock again behind level 120 until it rebuys. Carry the old levels as `workshop.legacy_credit`, or restate the gate on The Tower's levels. Also: Lab research is unreachable past about rank 20.
- **Cards:** Gem pulls, levels and the Active set, ideally moved to The Tower's cards.
- **Knowledge:** Insight, Prestige and Research Focus. Prestige has no counterpart in The Tower; decide whether it returns at all.
- **Gems:** only Cards and Lab slots use them; they return with those.
- **Built and shelved (25 September):** Shockwave (100,000 Coins to open) was imported and working, then set aside uncommitted for the wave-1 focus. The Tower's rule, from TheTowerSDK and the wiki: every Shockwave Frequency seconds (20 → 14) the enemies are pushed away by Shockwave Size (0.6 → 2.35, ×10 m), never a boss. Our reading: only enemies in reach, keeping time on the run's clock.
- **Not built, and later still:** Ultimate Weapons, Workshop Enhancements, protectors, Perks, Modules, events and tournaments. Also the unmerged `codex/prestige-run-summary`, which must move past save V12.

## How to measure

- **What ran on this branch (25 September):**
  - `bash run_tests.sh` → `PASS: economy tests`, including new tests for parking, walkers resumed across a profile change and a knockback reload, Lifesteal through a real tap, a wave not beaten while an enemy knocked out of reach lives (and across a reload), Damage / sec without Regen, and The Tower's Cash per kill at its wave steps, types and tiers (D071). The one `WARNING: Exponent too high` is the bad-save test feeding a broken save on purpose.
  - Headless boot clean.
  - `tools/capture_ui.gd` at four sizes with the layers parked: the hub, run, run-over screen, milestones and drawer were inspected; no Gems, Knowledge, Cards or Labs show except the SOON seats.
  - `run_balance.sh` and `tools/career_simulator.gd` run clean; their D071 figures are above.
  - An independent review of the D068 diff: the save conversion's maths, idempotence, backups and data regeneration were verified clean; its should-fix findings are fixed or listed here.
  - **`tools/arena_probe.gd` passes five runs in five.** Its stream checks were flaky: they sampled 40 frames, which a fast display runs before the first mote leaves (once per `MOTE_INTERVAL` of the wave's clock), and a random mix could put a tank first, out of reach. They now use basics, a first enemy tough enough to stand through both checks, and a second of the wave's clock.
  - **Not run:** CI, a phone, touch play and the owner's real save.
- **On Linux:** download Godot 4.7.2 and check its SHA-512 exactly as `.github/workflows/verify.yml` does, then set `GODOT` to it.
- **The Workshop data:** never edit `data/workshop/upgrades.json` by hand. Rerun `tools/import_tower_workshop.py` (its header says how to fetch TheTowerSDK), then `tools/export_workshop.gd` for `current.md`.
- **Tests:**
  - A fixture sets Workshop levels through `state.purchased` and opens groups with `state.workshop_groups`.
  - A test of a parked system sets `state.layers_parked = false` on its own state.
  - Tests not about distance put their wave in reach with `_all_in_reach(state)`.
  - Tests that need every enemy to arrive inside a wave's clock use fast enemies (`ENEMY_MIX = {"fast": 1.0}`): a basic set off last now arrives after 35 seconds.
- **Scratch runs:** the arena probe and captures save to throwaway files under the scratch HOME; if a probe is killed mid-run, delete `enemy_probe_save.json` there before the next run, or it resumes the old run.
- **Never kill processes with `pkill -f`** or a `pgrep -f` pattern that can match your own shell; kill Godot by PID (`pgrep -x godot`).

## Known issues and risks

- **Runs from the third reach the cap:** decision 1 above.
- **A resumed pre-D066 save pays its unpaid kills without the run's own Cash Bonus and Coins / Kill Bonus levels:** `_restore_saved_run` rebuilds the encounter before restoring `rig_ranks`. Only saves from before D066 with unpaid kills are affected.
- **Taps have no rate limit:** every tap is a full shot, so an autoclicker scales output without bound. Intended by D068; a lever to know about.
- **Stale tools:** `tools/workshop_ladders.py` crashes on the regenerated `current.json` (`KeyError: 'faster_cadence'`), though `docs/WORKSHOP_LADDERS.md` names it as the generator of `proposed.json`; `tools/career_model.py` still models the retired Leech and Thorns rows.
- **The Tower's Workshop data is its own table,** redistributed under the SDK's MIT licence: fine privately; publishing needs a decision.
- **Orbs' radius and Knockback's metres are ours**, since The Tower gives no units; both are single constants in `TaxBalanceProfile`. Damage / Meter's top level reads as +59% a metre (×42 at 69.5 m), unverified against the real game.
- **The Tower's Defense % global cap of 98%** is community research, not verified.
- **Save V12** will not load in an older build (D028). Any further field needs V13.
- **Other small issues:** `run_cash_earned` is saved but unread; `knowledge_bonus` and `cost_discount` effects and `BRACE_COST_FLOOR` are no longer fed by anything; `data/workshop/proposed*.json` are old proposals kept as history.

## Handing on

D068 is built, reviewed and measured, D069 has parked everything but the core loop, D071 has fitted Cash to The Tower's, and runs that never end past the second are what stand between the branch and a fun loop. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape:
   - who is handing to whom and when;
   - the branch and what is on it (merged or not, PR number);
   - where the game is;
   - the owner's open decisions, with a recommendation each;
   - next steps, each with a "done when";
   - the parked list, until it is empty;
   - how to measure, and known issues;
   - this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D073 onwards). Include the owner's words, the context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit.
3. **Say plainly what ran and what did not.**
4. **Commit on a branch, never `main`, and push it.** Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

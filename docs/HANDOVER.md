# Handover

**Last updated:** 25 September 2026, by Claude, handing on to the next agent. `claude/beautiful-dirac-6ozaio` holds **D068: The Tower's Workshop in full** (`57d2ba3`, `18cee0a`, `2289229`), the independent review's fixes (`6fcc235`), and **D069: Labs, Cards, Knowledge and Gems parked until the core loop is fun** (`dc1ff25`), with the documentation after them.

The branch is unmerged and has no PR. `main` holds PR #57 (D063–D067, up to `d23d384`); this branch sits on it. The D068 commits were first pushed to `claude/codex-handover-if13d2` after PR #57 had merged; that branch is now stale and its extra commits live here.
**Rule:** this page is the current state and the next steps, nothing else. Whoever hands off **replaces** it; history lives in [`DECISIONS.md`](DECISIONS.md) and git. If it disagrees with the code or a decision, they win.

## For the next agent: start here

1. Read [`AGENTS.md`](../AGENTS.md), D063–D069 in [`DECISIONS.md`](DECISIONS.md), the [Workshop since D068](WORKSHOP_DESIGN.md#the-workshop-since-d068-the-towers) and [The Tower's Tier 1, wave by wave](TOWER_SCALING_FOUNDATION.md#tier-1-wave-by-wave-against-ours--24-september-2026). Fetch and check the branch against `origin` before new work. Don't switch the owner's playable `main` checkout.
2. **Owner direction:**
   - **"Go full tower for now and get the base built"** (D068), with the Number kept ("Number stays, Tower around it"). D063's standing rule still holds: if in doubt, copy the way The Tower does it, shaped to a game of numbers.
   - **Core loop first** (D069): "leave out cards etc for now until the loop is fun". The Tower launched as the core loop alone (tower, Cash upgrades in a run, Coins for the Workshop); its later layers came once that worked. **Build no new layer** (Ultimate Weapons, Perks, Modules, events, tournaments) and bring back no parked one until the owner says the loop is fun.
3. **What's parked (D069):** Labs, Cards, Knowledge (Insight, Prestige, Research Focus) and Gems. They add nothing and can't be bought, their screens are out of reach (Cards and Labs read SOON), and the save keeps all of their progress. One switch, `GameState.LAYERS_PARKED`, brings them back.
4. **Next:** fit the Cash economy to The Tower's (the first decision below).

## Where the game is

This branch plays like this on a fresh run (Godot 4.7.2, profile `tax-foundation-v16`, save V12). Nothing below has been played by the owner or checked on a phone.

- **A fresh run is a fresh Tower:** the Number starts at Health 5 and shoots Damage 3 once a second at the nearest enemy within 30 m. A tap fires one more shot. Every shot's damage is Number too (D037).
- **The Workshop** opens Damage, Attack Speed, Critical Chance, Critical Factor, Health and Health Regen from the start. Everything else opens a group at a time for Coins: Range 50, Defense 75, Utility's Cash rows 40, and on up to Super Crit at 100M.
- **Run Upgrades** sell only rows the Workshop has opened, at The Tower's Cash prices ($10, $12, $14… for Damage), one level each. Cash starts at none and comes from kills (our 10 + 5 × wave a wave), Cash / Wave and Interest.
- **Pay:** a kill pays its type's Coins times its wave (basic none, fast 2, ranged 3, tank 4, boss 5); a wave's end pays Coins / Wave (1 before any level). Milestones pay their Coin bonuses; the Gems they also pay bank unseen while parked.
- **The field:** enemies set off 100 m out; a basic arrives in 10 seconds, a boss in 30. Orbs circle at 60 m or more.
- **Where builds land** (seed 7, two taps a second; D068's figures, unchanged by D069 because none of these builds had Labs, Cards or Insight):

  | Build | Result |
  |---|---|
  | Fresh, no run Upgrades | wave 33 in 18.9 min, 290 Coins |
  | Fresh, buying run Upgrades | **wave 153 in 89 min, 223,000 Coins** |
  | Early (Damage 20, Attack Speed 10, Health 20, Regen 10) | wave 61 in 35.5 min |
  | Mid (Damage 100 and a spread) or more | alive at 90 min on wave 155, mostly never hit |

- **Careers** (20 runs, 120-minute cap): hoarding Cash reaches wave 100 on run 18 (8.7 hours); buying run Upgrades reaches it on run 2 (2.2 hours) and is capped at wave 206 from run 3.

## Open decisions for the owner

1. **Run Upgrades are far too strong.** The Cash a kill pays is still our own figure, and against The Tower's cheap in-run prices it lets a fresh run reach wave 153. **Recommend: read The Tower's Cash earned at a known wave on an early run from a battle report, so the next agent can fit Cash per kill to it.** Until then the game's pacing is not meaningful. Interest has no cap here, which a long run shows (Cash reached 1.8e30 by wave 1,029 in a 10-hour maxed simulation); whether The Tower caps it is unverified and belongs in the same retune.
2. **Every shot is also Number.** With The Tower's Damage values, a strong Attack build banks so much Number that hits stop mattering. **Recommend: judge it after the Cash retune,** since run Upgrades are most of today's excess; if strong builds still never lose, bank only the damage a shot actually deals, or a share of it.
3. **The refund at 15×.** The owner's real save converts once on first load: its old Workshop levels become Coins at their old prices, and all its Coins are multiplied by 15. **Recommend accepting:** 15 is the ratio of both kill pay and first-level prices. The V10/V11 file is kept beside the new save.
4. **Merge this branch?** It carries D068, D069 and save V12. **Recommend: after the Cash retune and the owner's first play.**

## Next steps, in order

1. **Owner:** play a fresh run on the branch and read a Tower battle report's Cash earned for an early run. **Done when:** the next agent has The Tower's Cash for a known wave.
2. **Agent: fit Cash per kill to The Tower's.** Measure with `run_balance.sh` and the career simulator (hoard and rig), and record the choice as the next decision.
   - **Done when:** a fresh run that buys run Upgrades lands near The Tower's first-run reach, and the suite, probe and captures pass.
   - High economy risk: independent review of the diff.
3. **Agent: make runs end for a reason.** Tier 1 is short on walls: once an Attack build outgrows the curve, nothing but the run cap ends a run. Revisit with decision 2 above once Cash is fitted.
4. **Agent: The Tower's remaining Workshop rows** (Land Mines and Shockwave first, as the Defense order continues, then Wall, Recovery Packages and Enemy Level Skip). High risk: new mechanics and saved state.

**The core loop is fun when:** Cash is fitted to The Tower's pace, a first run ends sensibly, strong builds still get hit and runs end for a reason, and the owner has played it and says so. Only then does the parked list below start.

## Parked until the loop is fun (D069)

Each needs an owner "go", its own decision, and a retune against The Tower's Workshop, which none of them was balanced against. Unpark by flipping `GameState.LAYERS_PARKED`, or split the switch if they return one at a time.

- **Labs:** timed Coin research and its Gem-bought slots. When they return, settle the Workshop level gate first: save V12 drops old saves to Workshop level 0 (their retired rows became Coins), so an old save's Labs lock again behind level 120 until it rebuys. Carry the old levels as `workshop.legacy_credit`, or restate the gate on The Tower's levels. Also: Lab research is unreachable past about rank 20.
- **Cards:** Gem pulls, levels and the Active set, ideally moved to The Tower's cards.
- **Knowledge:** Insight, Prestige and Research Focus. Prestige has no counterpart in The Tower; decide whether it returns at all.
- **Gems:** only Cards and Lab slots use them; they return with those.
- **Not built, and later still:** Ultimate Weapons, Workshop Enhancements, protectors, Perks, Modules, events and tournaments. Also the unmerged `codex/prestige-run-summary`, which must move past save V12.

## How to measure

- **What ran on this branch (25 September):**
  - `bash run_tests.sh` → `PASS: economy tests`, including new tests for parking, walkers resumed across a profile change and a knockback reload, and Lifesteal through a real tap. The one `WARNING: Exponent too high` is the bad-save test feeding a broken save on purpose.
  - Headless boot clean.
  - `tools/capture_ui.gd` at four sizes with the layers parked: the hub, run, run-over screen, milestones and drawer were inspected; no Gems, Knowledge, Cards or Labs show except the SOON seats.
  - `run_balance.sh` runs clean.
  - An independent review of the D068 diff: the save conversion's maths, idempotence, backups and data regeneration were verified clean; its should-fix findings are fixed or listed here.
  - **`tools/arena_probe.gd` fails one check here:** "live shots leave as motes: 24 ticks, peak 0". It fails the same way on `2289229`, before any of this session's changes, so it is not caused by them. The likely cause is the probe's timing: it assumes enemies are in reach eight seconds in, which D068's 100 m set-off may have broken. Not fixed.
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

- **Run Upgrades and Cash** are the balance problem above.
- **Knockback can turn a pass into a beaten wave:** an enemy pushed just outside reach as the clock ends counts as not in reach, so the wave is beaten while it lives (D067's rule, newly reachable through knockback).
- **Taps have no rate limit:** every tap is a full shot, so an autoclicker scales output without bound. Intended by D068; a lever to know about.
- **Two readouts mislead:** the hub's "Total Coin bonus" is the multiplier on a kill's Coins, not on every Coin; Stats' "DAMAGE / SEC" includes Health Regen.
- **Stale tools:** `tools/workshop_ladders.py` crashes on the regenerated `current.json` (`KeyError: 'faster_cadence'`), though `docs/WORKSHOP_LADDERS.md` names it as the generator of `proposed.json`; `tools/career_model.py` still models the retired Leech and Thorns rows.
- **The Tower's Workshop data is its own table,** redistributed under the SDK's MIT licence: fine privately; publishing needs a decision.
- **Orbs' radius and Knockback's metres are ours**, since The Tower gives no units; both are single constants in `TaxBalanceProfile`. Damage / Meter's top level reads as +59% a metre (×42 at 69.5 m), unverified against the real game.
- **The Tower's Defense % global cap of 98%** is community research, not verified.
- **Save V12** will not load in an older build (D028). Any further field needs V13.
- **Other small issues:** `run_cash_earned` is saved but unread; `knowledge_bonus` and `cost_discount` effects and `BRACE_COST_FLOOR` are no longer fed by anything; `data/workshop/proposed*.json` are old proposals kept as history.

## Handing on

D068 is built, reviewed and measured, D069 has parked everything but the core loop, and the Cash economy is the one thing standing between the branch and a playable pace. Keep this handover as the current state, and leave the repository able to answer the next session's questions without this conversation.

1. **Replace this page. Never append to it.** Keep its shape:
   - who is handing to whom and when;
   - the branch and what is on it (merged or not, PR number);
   - where the game is;
   - the owner's open decisions, with a recommendation each;
   - next steps, each with a "done when";
   - the parked list, until it is empty;
   - how to measure, and known issues;
   - this section, addressed to the next agent.
2. **Record any new choice the owner accepts** as the next `D0NN` entry in [`DECISIONS.md`](DECISIONS.md) (D070 onwards). Include the owner's words, the context, the decision, the evidence (the figures measured and how), the consequences, and when to revisit. Update any document the change makes stale in the same commit.
3. **Say plainly what ran and what did not.**
4. **Commit on a branch, never `main`, and push it.** Do not open or merge a PR unless the owner asks.
5. **Tell the owner,** in the chat, the branch name, the head commit and the one decision you need from them next.
6. **Leave no scratch files** (`tools/_*.gd`, save files, screenshots) in the repository.

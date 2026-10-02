# Handover

**Last updated:** 2 October 2026, by Claude.
- `main` is at `48a8241`, which takes in everything through the card test series (D146, D147, PR #136) and the shared Cards and Workshop helpers in Palette (PR #137).
- The branch `claude/berserker-super-tower` (D148) builds Berserker and Super Tower as measure-only candidates, with the results in [CARDS.md](CARDS.md). Nothing a player sees changes.
- It isn't in the owner's game until merged; the play folder follows `origin/main` through `com.paulhardie.ngu-sync`.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. The next free ID is **D149**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth.
- **Enemies:** the five base enemies read as ours (D145).
- **Cards (D146, D147):** they open at Tier 1 wave 20 (the dock shows them then, and the run pays 10 Gems). Eleven of The Tower's cards are built, laid out as a grid with a card's details on tap, and save version 3 holds the collection.
- **Candidates:** nine measure-only cards (Slow Aura, Critical Coin, Compound, Remainder, Unequal, Interest, Factor, and now Berserker and Super Tower) can be equipped in `sim_runs.gd` and are never drawn.

**What the card tests have found** (CARDS.md has the numbers):
- **Tier 1's walls are its boss waves, and they test killing power alone.** Cards that kill faster or buy killing power move them (Damage, Attack Speed, Cash, Fortress at level 7). Health, Regen, the defence cards and our Number cards don't, at any level.
- **Super Tower works** (D148). At level 1 it is a Damage card between levels 1 and 2, and a 40-run career with it earns +87% Coins against Damage's +61%. At level 7 it is worth less than flat Damage of the same average, and it can't be lined up with a boss. It is a strong killing card, not a second strategy.
- **Berserker does nothing at The Tower's numbers** (D148). A Tier 1 run absorbs a few hundred damage, so 0.8–1.4% of it is about 3 Damage.
- **At about 30 times its share it works, and a tank build wins.** A build with no Defense Absolute, the worst alone (wave 19 at 4,000 Coins, against the turtle's 31), reaches wave 50 with it, past the turtle with the card (41). That is the second strategy the walls were missing. Runs are volatile (11–68).

## Checked, and not checked (D148)

- **Tests:** `bash run_tests.sh` passed, 4,730 tower checks and 231 foundation checks, exit 0. New ones cover:
  - each rule with and without its card, Berserker's cap and Super Tower's 15-on, 15-off beat;
  - neither drawing a random number;
  - a battle saved mid-burst and off-burst continuing exactly, with Berserker's bonus carried.
- **Inert without the cards:** 20 fresh `--buy even` runs on this branch printed byte-identically to `main`'s. A 40-run career with Berserker at The Tower's numbers matches the no-card career in every wave and Coin.
- **Measurements:** 10 seeds a line, three builds at levels 1 and 7, flat-Damage comparisons, three 40-run careers and the scaled Berserker runs. The committed `--berserker-scale` and `tank` plan reproduced one of the scratch measurements they replaced, line for line.
- **Not checked:**
  - **an independent review of this diff** (the card test series had one);
  - Tier 2;
  - more than 10 seeds a line;
  - a scale between ×10 and ×30 for Berserker;
  - a tank career (a career buying as `--buy health` plateaus at wave 11 and never opens Cards);
  - the card readings against the wiki, whose page wouldn't load for the session (what "round", "absorbed", the cap and the cooldown mean are ours, in `Guesses`);
  - owner play.

## Open decisions for the owner

1. **Which cards to make drawable next?**
   - **Factor** (ours, rare): a boss arrives with less health. A modest card, safe for Coins.
   - **Super Tower** (The Tower, epic): I'd make this drawable as The Tower has it. It needs no rescale and moves walls like Attack Speed does. Trade-off: at level 1 it beats the common Damage card, because its average is ×1.75 against ×1.5, so one epic at 3% odds becomes the best early card.
   - **Berserker:** not at The Tower's numbers, which do nothing. If you want a tank strategy to exist, I'd make it **ours, rescaled** (shares in the tens of percent), after a finer sweep (×15, ×20, ×30) and a way to test a tank career. Trade-off: it is volatile, and a tank player has to reach wave 20 by some other build before Cards open for them.
   - **Park** the rest: Slow Aura, Critical Coin, Compound, Remainder, Unequal and Interest.
2. **Changing cards mid-run:** I'd still keep them fixed for the run.
3. **Still open from before:**
   - play the D145 enemies and the Lock;
   - sign off 1.0;
   - the D131 digit rewards;
   - the speed switch;
   - the Mac sync waiting on a saved battle;
   - the AGENTS.md modifier-law wording;
   - publishing Tower-derived data.

## Next steps, in order

1. **Owner:** merge the Berserker and Super Tower PR (measuring only), then reach wave 20 on the fresh save to see Cards in their grid.
2. **Owner:** answer decision 1. A yes to Super Tower means moving it into `Cards.EFFECTS` and deciding `RunConfig.RULES_VERSION` with a saved-battle fixture; a yes to Berserker means choosing its numbers and recording the pick as D149.
3. **Agent:** an independent review of the D148 diff, then the finer Berserker sweep, whichever the owner wants first.

## Known issues and limits

- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

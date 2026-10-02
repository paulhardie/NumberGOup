# Handover

**Last updated:** 2 October 2026, by Claude.
- `main` is at `848e44b`, which takes in everything through D146 (Cards, PR #134).
- [PR #135](https://github.com/paulhardie/NumberGOup/pull/135) (`claude/cards-grid`, D147) lays Cards out as a grid with a card's details on tap.
- [PR #136](https://github.com/paulhardie/NumberGOup/pull/136) (`claude/card-tests`) is the card test series: measure-only candidate cards, the measuring options and the results in [CARDS.md](CARDS.md). Nothing a player sees changes.
- Neither is in the owner's game until merged; the play folder follows `origin/main` through `com.paulhardie.ngu-sync`.
- The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID. D147 is on #135, so the next free ID is **D148**. The public version stays **0.9**.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth.
- **Enemies:** the five base enemies read as ours (D145).
- **Cards (D146):** they open at Tier 1 wave 20 (the dock shows them then, and the run pays 10 Gems). Eleven of The Tower's cards are built, and save version 3 holds the collection.
- **Grid:** #135 lays the cards out as a grid.

**The card test series (#136, CARDS.md)** measured:
- the built cards on three builds, at levels 1 and 7;
- pairs of cards;
- careers with one card from wave 20;
- seven measure-only candidates: Slow Aura, Critical Coin, Compound, Remainder, Unequal, Interest and Factor.

**The finding: Tier 1's walls are its boss waves, and they test killing power alone.**
- **When runs die:** right after a boss wave. Traced, the Number goes from about 300 to 0 within about 8 seconds of the wave-30 boss reaching it, with wave 31 arriving.
- **What moves the wall:** cards that kill faster or buy killing power (Damage, Attack Speed, Cash, Fortress at level 7).
- **What doesn't, at any level:** Health, Regen, the defence cards and our Number cards.
- **Damage dominates.** One level-1 Damage card from wave 20 takes a 40-run career from wave 24 to wave 31.
- **Coin pace stays sane.** No card multiplies Coins beyond its own share; the rest earn more only by reaching further.

## Checked, and not checked (#136)

- **Tests:** `bash run_tests.sh` passed, 4,709 tower checks and 217 foundation checks, exit 0. New tests cover:
  - every candidate's rule, with and without its card;
  - that the combat random stream moves only with Critical Coin;
  - that candidates are never drawn and an equipped candidate never reaches a real run.
- **Inert without the cards:** 20 fresh `--buy even` runs on this branch printed byte-identically to `main`'s, after the last rule change.
- **Measurements:** the series is above and in CARDS.md, 10 seeds a line. One traced pair of turtle runs (a scratch script, not a tool) showed the boss-wave collapse.
- **Review:** an independent review of the candidate code found ten points; six were fixed. Of the rest:
  - the run-rules version stays put, because candidates never reach the game;
  - Slow Aura's per-tick rule lookup is cheap at today's effect counts.
  - Factor and the career change came after that review and have only my own read.
- **Not checked:**
  - Interest (no build opens it);
  - Tier 2;
  - more than 10 seeds a line;
  - owner play.

## Open decisions for the owner

1. **Should Tier 1 stay a pure killing-power check at its boss waves?** Today it makes every non-damage card a dead slot. I'd keep the boss walls, which are The Tower's, but give defence a route into killing power. Berserker (damage from damage absorbed) is the card that does that, so the cheapest test of whether a second strategy can exist is to prototype it next. The other way, softening the pile-up at the Number, would move every benchmark.
2. **Which cards to make drawable next?**
   - **Factor** (ours, rare): a boss arrives with less health. It's the only candidate that moved a wall (+2 to +4 waves at level 7) and it's safe for Coins.
   - **Park** the rest: Slow Aura, Critical Coin, Compound, Remainder, Unequal and Interest.
   - **Prototype next:** Berserker and Super Tower.
3. **Changing cards mid-run:** I'd still keep them fixed for the run.
4. **Still open from before:**
   - play the D145 enemies and the Lock;
   - sign off 1.0;
   - the D131 digit rewards;
   - the speed switch;
   - the Mac sync waiting on a saved battle;
   - the AGENTS.md modifier-law wording;
   - publishing Tower-derived data.

## Next steps, in order

1. **Owner:** merge #135 (the grid) and #136 (the test series; it's measuring only), then reach wave 20 on the fresh save to see Cards.
2. **Owner:** answer decisions 1 and 2. A yes to Berserker means prototyping it and Super Tower as measure-only cards, sweeping them like the rest, and recording the pick as D148.
3. **Agent, small:** move the Cards and Workshop screens' shared bar and card helpers into Palette.

## Known issues and limits

- **A first-sight card only shows past the player's best wave.**
- **Unbuilt cards are hidden, not shown locked.**
- **The Cards screen refreshes only on its own changes.**
- **Wave 10 pays 10 Coins against the SDK's 25,** pending a reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

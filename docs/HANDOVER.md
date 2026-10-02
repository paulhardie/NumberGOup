# Handover

**Last updated:** 1 October 2026, by Claude. `main` is at `5edd068`, which takes in everything through D145 (PR #133: the five base enemies). The branch `claude/cards` adds **D146: Cards, with their menu, collection, save and measuring**. Its pull request goes to `main`, and it isn't in the owner's game until merged. The play folder follows `origin/main` through `com.paulhardie.ngu-sync`. The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID, and the next free one is **D147**. The public version stays **0.9**. Cards (1.1) were built ahead of 1.0's sign-off, at the owner's word.

## Where the game is

Tier 1 and every Workshop group work.
- **The Number is the tower.** Flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth.
- **Enemies:** the five base enemies read as ours (D145).
- **Look:** the UI is premium minimal throughout.

**Cards (D146) are built.** [CARDS.md](CARDS.md) owns the detail.
- **Opening:** the dock shows Cards from Tier 1 wave 20.
- **Getting them:** a draw costs 20 Gems, with The Tower's rarity odds among the built cards (82% common, 18% rare today). Copies level a card to 7, and slots are bought with Gems.
- **Using them:** cards are equipped for the next run. A run takes the cards equipped when it starts.
- **Built:** eleven of The Tower's cards: Damage, Attack Speed, Health, Health Regen, Range, Cash, Coins, Critical Chance, Extra Defense, Fortress and Free Upgrades. The rest wait for the rules they need.
- **Saving:** save version 3 holds the collection. A version-2 save (the owner's) migrates to an empty collection after a byte-exact `.v2-backup.json`.
- **Testing:** Settings → Testing has +◆ 500.
- **Measuring:** `sim_runs.gd --cards ID:LEVEL,...` and `--card-sweep LEVEL`.

## Checked, and not checked (D146)

- **Tests:** `bash run_tests.sh` passed, 4,676 tower checks and 217 foundation checks, exit 0. The headless boot printed no errors. New tests cover:
  - Cards opening at wave 20, Gem prices, and draws never charging without a card;
  - every built card drawable to 80 copies, with the real odds shown;
  - levels by copies, slots capped at the built cards, and the loadout;
  - card effects reaching a run's frozen build and surviving resume;
  - the version-3 round trip, and the version-2 migration with its backup;
  - damaged or impossible Cards protected rather than trimmed;
  - the screen's draw, equip and slot.
- **Migration:** `check_migration.gd` (now able to take a version-2 copy) passed 19 checks on a version-2 save written by `main`'s own code. It had 30 runs, wave 37, research done, Gems and an active battle. Everything was kept, the backup was byte-exact and the battle resumed.
- **Runs without cards:** 20 fresh runs are unchanged, median wave 6 (4–7).
- **First card sweep:** recorded in CARDS.md. At a wave-21 build, Damage at level 1 is worth eight waves. Health, Regen and the defence cards don't move the wall even at level 7.
- **Screenshots:** `cards` and `cards_drawn` were captured and checked by eye.
- **Review:** an independent review of the diff found ten points and nine were fixed. The one left: the Cards and Workshop screens share copied bar and card helpers.
- **Not checked:**
  - the owner's real save (only a copy made by the same code);
  - owner play;
  - phone layout.

## Open decisions for the owner

1. **Run the card test series, and pick what to build next.** CARDS.md lists The Tower's unbuilt cards, with what each needs, and six candidates of our own (Compound, Remainder, Unequal, Carry the One, Interest, Absolute). I'd start by sweeping two more builds, a turtle and a later Workshop, and pairs of cards. Then I'd prototype two of ours as `--cards` candidates.
2. **Changing cards mid-run.** The Tower allows it, except while a boss lives. Ours freezes cards at the run's start. I'd keep that until the test series says otherwise, since it keeps runs deterministic and simple.
3. **Play the D145 enemies and the Lock.**
4. **Sign off 1.0, or name what's missing.**
5. **Earlier open items, still standing:**
   - the D131 digit rewards;
   - the speed switch;
   - the Mac sync waiting on a saved battle;
   - the AGENTS.md modifier-law wording;
   - publishing Tower-derived data.

## Next steps, in order

1. **Owner:** merge, then open the game once on the laptop. The save migrates to version 3 and keeps a `.v2-backup.json` beside it. Then try Cards: they open at wave 20, and Testing gives Gems.
2. **Agent, on instruction:** the card test series (CARDS.md, "Measuring" and "Candidates of our own").
3. **Agent, small:** move the shared bar and card helpers into Palette for both screens.

## Known issues and limits

- **A first-sight card only shows past the player's best wave**, so a save past wave 10 never sees the boss card.
- **The Cards screen refreshes only on its own changes.** Gems can't change while it's open today. If they ever can, it must listen.
- **Unbuilt cards are hidden, not shown locked.** The Tower shows the whole table; ours lists only what a draw can give.
- **Wave 10 pays 10 Coins in our table against the SDK's 25,** pending a reference reading.
- **Settings → Testing can grant Coins and Gems and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update,** keeping banked Coins and permanent progress ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

# Handover

**Last updated:** 1 October 2026, by Claude. `main` is at `0ec21fa`, which takes in everything through D144 (PR #132: the first tank on wave 5). The branch `claude/enemy-identities` adds **D145: the five base enemies read as ours**. Its pull request goes to `main`, and it isn't in the owner's game until it's merged. The play folder follows `origin/main` through `com.paulhardie.ngu-sync`. The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md); grep it by ID, and the next free one is **D146**. The public version stays **0.9** until the owner signs it off. After that come Cards (1.1), the Labs catalogue (1.2), Ultimate Weapons (1.3) and selectable tiers (1.4).

## Where the game is

Tier 1 and every Workshop group work. The Number is the tower: flat enemies subtract from it, Dividers divide it, and the Lock (from wave 35) holds its growth. A run starts with no Cash and rolls its spawns 104 times a wave (D135). The UI is our own premium-minimal style: Inter everywhere, chips, a lit Battle button (D137–D143). The range ring is 4.5% white in battle, and Home has none.

The owner is focusing on enemies. Since D144, every run's wave 5 brings one tank. D145 gives each base enemy its own reading while keeping The Tower's numbers:

- **Basic:** plain, on purpose. It's the unit the others are read against.
- **Fast:** trails two faint copies of its number while it walks in.
- **Tank:** thins as it's shot. Its mass falls with its health, never below a basic's, so Knockback moves a worn tank further.
- **Boss:** a rival Number, in the Number's own Inter. While it lives the wave line reads "Wave 10 · Boss", and a first-sight card says orbs and shockwaves can't touch it.
- **Divider:** when a ÷ lands, the Number as it stood peels away in violet.

[THE_NUMBER.md](THE_NUMBER.md) section 8 has the table, along with the roster rules and the proposed enemies of our own: the Countdown, the Carrier and the Rounder.

## Checked, and not checked (D145)

- **Tests:** `bash run_tests.sh` passed, 4,676 tower checks and 175 foundation checks, with exit 0. The headless boot printed no errors. New tests cover:
  - the tank's mass at full, half and nearly no health, and Knockback reading it;
  - which weight the tank is drawn at;
  - when the fast trail shows;
  - the boss's font, card and wave title;
  - the ÷ peel, including not for one the Wall takes, and its value from the sim.
- **Measurements:** these are in D145.
  - Fresh runs and the 40-run core career are identical to `main`, run for run.
  - With every row at level 12, Knockback included, 12 seeds averaged 105.3 waves against `main`'s 105.0. Single runs moved up to 8 waves either way.
- **Screenshots:** `capture_battle.gd` ran under xvfb and has a new line-up shot (`battle_base_enemies`). I checked it by eye: the fast trail, a fresh and a worn tank, the boss in Inter, the wave line naming the boss, and the ÷ peel in `battle_divided`.
- **Not checked:** the owner playing it, how it looks on a phone, motion over time (captures are stills), and the boss card in a real first run.

## Open decisions for the owner

1. **Play the D145 enemies,** especially the boss as a rival Number and the trail's length. Both are single constants (`ArenaView.LOOKS.boss`, `TRAIL_SECONDS`), so they're quick to tune.
2. **Keep or tune the Lock after playing past wave 35.** Divider refill stays off (D134).
3. **Leftover UI items:** Home has an empty gap on a fresh save, and Wave Info's table is dense.
4. **Sign off 1.0 after playing, or name what's missing,** before Cards.
5. **Earlier open items, still standing:**
   - the D131 digit rewards;
   - whether the 1×/2×/5× switch stays as a player feature;
   - whether the Mac sync should wait while a battle is saved;
   - the AGENTS.md modifier-law wording;
   - publishing Tower-derived data before a public release.

## Next steps, in order

1. **Owner:** merge the D145 PR and play a fresh save to wave 10 or later. It's a small check, and it settles the look of the base five in motion.
2. **Owner and agent:** pick the next enemy from THE_NUMBER section 8. The Countdown is the proposal, around wave 15.
3. **Agent, on instruction:** the UI leftovers above, or read one fresh Tower wave at ×1 to settle the spawn count.

## Known issues and limits

- **A first-sight card only shows past the player's best wave.** A save already past wave 10 never sees the boss card, as with the Lock and the tank; no "seen" list is saved.
- **A tank killed in one shot pops in its thinnest cut.**
- The music test prints audio "leaked" warnings, and `capture_battle.gd`'s timed shots are seeded, not exact moments. The shockwave ring can cross the Number.
- **Wave 10 pays 10 Coins in our table against the SDK's 25.** This waits on a reference reading.
- **Settings → Testing can grant Coins and wipe progress.** It must go before a public release.
- **Older snapshot or combat-contract runs can end on update.** Banked Coins and permanent progress stay ([SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md)).

## Handing on

Replace this page rather than appending to it. Keep accepted choices in DECISIONS and contracts in their owning documents. Protect the real save, use `run_godot.sh`, and report only checks that actually ran. Commit and push on a feature branch with an open PR to `main`. Check a PR is still open before pushing to its branch. Merging is the owner's call.

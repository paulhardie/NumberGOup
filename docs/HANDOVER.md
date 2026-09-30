# Handover

**Last updated:** 30 September 2026, by Codex. Current `main` through `48ba170` includes the scaling foundations (D126, PR #121), the Lock (D133), the off-by-default Divider refill experiment (D134), and the accepted 104 spawn rolls (D135, PR #123). This worktree adds D136: milestone-owned bar reveals, copied-save migration proof, frozen measuring builds and safe recovery across combat contracts.

**Branch:** `codex/scaling-foundations`, in the attached worktree. PR #121 is already merged; this follow-up requires its own PR to `main`. The follow-up is not in the owner's game until they merge it. The play folder follows `origin/main` through `com.paulhardie.ngu-sync`. The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. Accepted choices live in [DECISIONS.md](DECISIONS.md). The public version remains **0.9** until owner sign-off: Cards 1.1, the Labs catalogue 1.2, Ultimate Weapons 1.3 and selectable tiers 1.4. Cards wait on the owner's current wall/roster discussion.

## Where the game is

Tier 1 and every Workshop group work. The Number is the tower; flat enemies subtract, Dividers divide, and the Lock holds growth while it stands in range. The Lock comes on top from wave 35; bought Health still lands. [THE_NUMBER.md](THE_NUMBER.md) section 8 owns our roster direction. D135's 104 spawn rolls are preserved; D134's slow Divider refill stays off.

**The scaling foundations and follow-up are built:**

- `Progression` owns per-tier reached/cleared records, one-time known wave rewards, Gems, daily claims and research. The generated milestone table owns both bars' reveal points: Battle immediately, Workshop after one run, Cards at Tier 1 wave 20, Labs at 30. Bars and domain gates evaluate the same tier records. Number rewards remain separate; D107's clear-wave-100 tier gate is unchanged.
- **Save version 2** migrates version 1 with an exact backup and known new rewards paid once. Permanent progress that a current schema cannot preserve, and future schemas, are protected from writes. New active battles restore exact state; unversioned legacy records still replay when their result matches.
- **Snapshot/combat contract version 2** includes Lock/held-loss state and frozen known measuring switches. Prior declared contracts recover through the existing end-run path. A sound changed-rules run keeps its reached/cleared record, unlocks, peak and earned milestones. A damaged run keeps banked Coins and previous permanent records; untrusted wave/peak values cannot award progress. Optional replay fields are checked before conversion.
- Shared stat/rule pipelines, recorded mid-run effects, damage/kill attribution and stable cooldown ids provide later systems' entry points. Starting tuning is applied before wave 1, so experimental Lock/refill runs also replay correctly.
- Paid real-time research jobs persist and advance while closed; an active battle keeps its starting build. Clock rollback grants no extra time. No Labs catalogue or screen has been shipped.
- Compensated, losslessly saved Coins retain tiny rewards at large balances. Effect validation rejects unsupported values before purchase. Clearing the generated wave-6,500 horizon ends safely rather than farming plateaued values.

Contracts and limits: [SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md). This work adds no Cards/Weapons/Perks/Modules catalogue, tournaments, server or offline battle earnings. Unknown later reward amounts remain absent.

## Checked, and not checked

**High risk:** saves, economy, clocks and exports. All Godot checks ran through `run_godot.sh` with fresh scratch homes.

- Fresh import, `bash run_tests.sh` and headless boot passed: **4,315 tower + 175 foundation = 4,490 checks**, exit 0 with no script/parse/error lines. Existing ObjectDB exit warnings remain (24 tower, 13 foundation/boot); no leak fix is claimed.
- The **latest real version-1 save copy** passed 16 migration checks: its rank, opened groups, Coins, bests and run count were unchanged, with an exact backup and current-schema reload. It had no active run and earned no retroactive wave reward. No real-save gameplay run or raw save commit was used.
- The **older progressed wave-39 copy** passed 28 checks through `check_migration.gd --expect-recovery`. All 23 ranks, groups and banked Coins survived; migration added the expected 10 Coins/10 Gems. Actual Main recovery retained Tier 1 reached 39/cleared 38 and Labs; one earned Number milestone added 250 Coins. Final balance was 955.619999999879 Coins, 10 Gems, 3 runs. It was counted/logged once, the active record cleared, and re-observing could not pay twice. Both input copies and backups remained byte-identical.
- Boundary fixtures cover old/current/malformed/future schemas, protected writes, Coin precision, invalid spending, clock rollback, long research catch-up, paid/duplicate/combined jobs and completion order. Recovery tests reject malformed optional enemies/RNG/peak fields and prevent a damaged wave-6,500/peak-1e300 record from inflating bests or paying rewards.
- Nine seeded tier-1–3 snapshots continue byte-identically for 600 ticks. Focused tests also resume a real scheduled Lock while Divider loss is held, replay its frozen wave-one tuning, and continue exactly. Existing manual Lock/held-loss fixtures remain. Starting/mid-run effects and decimal-shifting values retain exact report/snapshot state.
- Tests move Cards/Labs reveal rows to waves 21/31 and prove both bars and domain gates follow; a Tier 2 record cannot reveal a Tier 1 system.
- **Twenty fresh `--buy even` runs print byte-identically to current `main`**, median wave 6, range 4–7. D135 owns the pacing/balance measurements; older 208-roll career figures are historical and are not claimed as current.
- `check_scaling.gd --hours 1`, after D135: all groups at level 25, seed 7, reached wave 103 at 108,001 ticks, alive. Snapshot 131,071 bytes; restore 4.79 ms versus replay 9.92 s; result matched and the next 600 ticks were exact. One local timing, not a device benchmark. Full Workshop cost about 2.626e20 Coins; horizon HP about 7.020e24, Attack about 4.245e10.
- `capture_battle.gd` exited 0. Home, wave Milestones, daily-claimed state and the Lock were inspected at 540 × 960; balance, claims and navigation fit. This proves the captured states, not manual play.
- The progression generator reproduces its output byte-identically. Final diff/path/decision checks preserve all accepted records on `main`; D136 is appended. Independent review passed the same 4,490 checks, boot and both copied-save probes; the source guards have no remaining actionable findings. Final owning-document sign-off and PR CI are checked at hand-off.
- **Not checked:** owner play, real-window close/reopen, phone/web behaviour, a full week of simulation, SDK regeneration beyond wave 6,500, or unpublished reward rows. The real save was not used for gameplay verification. No authoritative clock server exists.

## Open decisions for the owner

1. **Sign off 1.0 after playing, or name what's missing.** Recommend checking the Number's growth, fresh pacing, rewards and close/reopen before Cards. This follow-up changes no accepted battle balance.
2. **Keep or tune the Lock after playing past wave 35?** Recommend playing it first. Leave Divider refill off and keep its existing replacement slot; the measurements moved no wall. The Countdown is the proposed next enemy, on the owner's word.
3. **Design D131's digit typefaces, small permanent bonuses and a UI of our own.** Values and presentation remain to be discussed; digit rewards never replace wave system gates.
4. **Keep the 1×/2×/5× switch as a player feature?** Recommend keeping it based on the owner's use; the spec still calls it a testing tool.
5. **Make the Mac sync job wait while a battle is saved?** Recommend a small follow-up: incompatible rule/data updates can still end an active run. The sync job is unchanged.
6. **Accept the lighter rebuild process, and update AGENTS.md's modifier-law wording?** Recommend the lighter process and naming `StatStack`/`RunRules` instead of removed `GameState`. Working rules were not changed here.
7. **Decide Tower-derived data publication before public release.** Source/licence context remains in reference/importer documents. Idle battle policy and servers remain D089's later choice.
8. **Choose remaining design-canvas proposals/elite appearance.** Recommend reviewing current captures before changing colour/motion; phone shader/music performance is unmeasured.

## Next steps, in order

1. **Owner:** merge the follow-up PR, then play preserved progress and close/reopen a new battle. Small play check; removes the gap between automated proof and actual experience. Do not reset real progress to test migration.
2. **Owner/agent, on instruction:** settle the Lock/next roster enemy and D131 digit rewards, then remaining 1.0.x reference readings before Cards. A whole early Tower wave at ×1 would help resolve the spawn count; Coins are D135's remaining pace lever.
3. **Owner/agent:** test phone/web performance before calling it ready there. This remains unmeasured.

## Known issues and limits

- **Older snapshot/combat-contract active runs can end on update.** Banked Coins and previous permanent progress remain; structurally sound records preserve earned tier progress too. The latest copied owner save had no active run. Compatible new snapshots resume directly.
- **Settings → Testing can grant Coins and wipe progress.** It must be hidden/removed before public release. Reset logs the discarded permanent account and keeps settings.
- Lock's first-sight card only appears past the previous best; existing bests above 35 can skip it. No seen-list save key was introduced.
- Wave-10's reference reward is 10 Coins while the SDK says 25; the existing table uses 10 pending reference reading. No value was silently changed. Enemy mix is held past wave 100; early HP and the successful spawn-roll count remain reference uncertainties.
- Local UTC handles rollback, but forward clock changes are not server-verified. Missed daily claims do not accumulate.
- Generated content ends at wave 6,500/tier 3. Numeric/computational limits are explicit; Coins are compensated doubles, not arbitrary precision.
- Managed-worktree reports identify the commit as `unknown` because the existing reader expects a `.git` directory. The play checkout has one; worktree provenance is a separate follow-up.
- The Wall at six digits sits close to the range ring. Crowd/layout drawing improvements are preserved; no phone or manual elite-motion claim is made.

## Handing on

Replace this page; accepted choices stay in decisions and contracts in their owning documents. Keep the real save protected, use `run_godot.sh`, and report actual evidence. Commit/push on a feature branch with an open PR to `main`; merging is the owner's call. D136 is this follow-up's new record; no accepted `main` record was rewritten.

# Handover

**Last updated:** 30 September 2026, by Codex. This branch includes `main` through `a50e59e` (D127–D132's drawing changes and Workshop/Divider measurements). D126 implements the scaling foundations authorised by the owner after the whole-game audit. Final independent review approved the diff with no actionable findings.

**Branch:** `codex/scaling-foundations`, in the attached worktree. Not merged. The owner's play folder remains `~/NumberGOup-main`, kept on `origin/main` by `com.paulhardie.ngu-sync`; this work is not in their game until they merge its pull request. The pre-rebuild game is commit `f4f1e95`.

## Start here

Read `AGENTS.md`, this page and the Roadmap in [REBUILD_SPEC.md](REBUILD_SPEC.md). Fetch and inspect the checkout before editing. The accepted choices live in [DECISIONS.md](DECISIONS.md), not in old handovers. The game stays **0.9** until the owner signs off 1.0 (D079). Cards are 1.1, the Labs catalogue 1.2, Ultimate Weapons 1.3 and selectable tiers 1.4.

## Where the game is

Tier 1 and the whole Workshop work, with the Number as the tower, Dividers, the Tower-derived spawning/enemy rules, progressive disclosure, the 50-Coin first-run welcome, Number milestones and the existing presentation/music. The battle remains governed by `BattleSim`; generated enemy and Workshop data remain their number authorities. D126 leaves their default balance intact.

**The new foundations are built:**

- Permanent progression owns per-tier reached/cleared records, known early wave milestones, Gems, daily claims and research. Wave and Number rewards each pay once. Daily claims give 20 Gems after the first completed run, once per UTC day. The clear-wave-100 tier gate remains D107's choice.
- **Save version 2** migrates version 1 with a backup and retroactive one-time wave rewards. Future schemas and current saves that would lose declared progress are protected from writing. New active runs restore a complete lossless snapshot rather than replaying every tick; legacy records retain replay. Incompatible battle rules/data use the existing end-run recovery and retain banked Coins.
- Frozen run configurations include tier, Workshop, starting stat/rule effects and a rules version. Shared stat/rule pipelines, recorded mid-run effects, damage/kill attribution and stable cooldown ids give the later systems their entry points.
- Paid research jobs advance on the real-time clock while the game is closed. Completed effects belong to the permanent account; an active run keeps its frozen build. Clock rollback earns no extra time. This is the jobs/clock primitive; no Labs catalogue or screen has been shipped.
- Compensated, losslessly saved Coins retain small awards beside large balances. Invalid or impractical effect values are rejected before purchase. Battles end cleanly at the generated wave-6,500 horizon rather than silently holding enemy values forever. The importer accepts an explicit extended horizon after its values are checked.

Contracts, authorities and limits: [SCALING_FOUNDATIONS.md](SCALING_FOUNDATIONS.md). Research prices, durations, Cards, weapons, Perks, Modules, tournaments, servers and offline battle are not introduced by this pass. Later reward amounts without checked evidence remain absent.

## Checked, and not checked

**High-risk change:** saves, economy, clocks and exports.

- After integrating current `main`, fresh scratch-home import, `bash run_tests.sh` and headless main-scene boot passed: **4,192 tower checks + 117 foundation checks = 4,309**; both suites exited 0 with no script/error lines. Exit-time ObjectDB warnings remain (24 tower, 2 foundation, 13 boot); no leak fix is claimed.
- Fixtures cover old/current/malformed/future saves, backups, protected current progress, migration rewards once, Gems/spending bounds, Coin precision and decimal-parser drift, clock rollback, long elapsed research, duplicate/combined jobs, every reachable completion-order build, stable effect order and malformed records.
- Nine seeded snapshot continuations across tiers 1–3 restore and remain byte-identical after 600 further ticks. Frozen builds and starting/mid-run effects replay, including complete Workshop/input comparisons. A demonstrably decimal-shifting effect round-trips through report JSON, replay and exact direct screen resume. Invalid rank/tuning/timer state and corrupt snapshots are rejected.
- Ten fresh `--buy even` seeded runs print byte-identically to the pre-change output (median wave 3, range 1–6). The 40-run `--buy core` career and `--legacy-progression` comparison both first pass wave 10 on run 12, reach wave 21 on run 20, and finish with best wave 28 after about 6 game hours. Wave-10's extra 10 Coins changes some spending and Number results, as expected; this is not a claim that every career result is identical.
- `tools/check_scaling.gd -- --hours 1`: all groups at level 25, seed 7, reached wave 103 at 108,001 ticks. Snapshot 105,215 bytes; restore 2.76 ms versus replay 13.64 s. Replay matched and the next 600 ticks were exact. Timing is one local measurement, not a device benchmark. Full Workshop cost about 2.626e20 Coins; generated horizon HP about 7.020e24, Attack about 4.245e10.
- `capture_battle.gd` exited 0; Home, wave Milestones and daily-claimed captures were inspected at 540 × 960. The bottom bar, Gem balance, rewards and claimed state are visible. Automated screen checks exercise fresh/progressed state and save/resume.
- A scratch exported record with a mid-run rule effect prints correctly in `read_report.gd --run 1` and matches replay in its table. The progression generator reproduced its output byte-identically. Enemy importer syntax and rejection of a too-short horizon were checked.
- Independent adversarial review approved the final diff after resolving persistence, malformed-save, effect-boundary, completion-order and report-reader findings. The reviewer independently ran scratch import, both final suites (4,309 checks), headless boot and diff checks, all exiting 0 without error lines. CI status belongs to the PR checks.
- **Not checked:** the owner's real save (deliberately untouched), owner play or real-window close/reopen, phone/web behaviour, a full week of simulation, regeneration past wave 6,500 against the SDK, or unpublished reward rows. No authoritative clock server exists.

## Open decisions for the owner

1. **Sign off 1.0 after playing the current build, or name what is missing.** Recommend judging the Number's growth, the wave-10 wall, the welcome and the new rewards/resume before starting Cards. No balance curve is silently changed here.
2. **Keep the 1×/2×/5× switch as a player feature?** Recommend keeping it: the owner's reports show substantial use of ×5. The spec still calls it a testing tool.
3. **Make the Mac sync job wait while a battle is saved?** Recommend it as a small follow-up: snapshots avoid replay delay, but a rules/data change can still end an active run on update. The sync job is unchanged.
4. **Accept the lighter rebuild process** in the spec? Recommend yes; it remains open.
5. **Update AGENTS.md's modifier-law wording?** Recommend naming `StatStack` and `RunRules`; the law still names the removed `GameState`. Its working rules have not been changed by this pass.
6. **Decide how to publish Tower-derived data before a public release.** Its current source/licence context remains in the reference/importer documents.
7. **Choose the remaining design-canvas proposals and elite appearance.** Recommend reviewing the existing Protector/elite captures before changing their colours, and trying the heavier Number from the design brief if the current digit changes still feel too small. Elites stay at Tier 1 wave 500 unless the owner changes that choice.
8. **Idle battle policy and servers remain D089's later choice.** This pass supplies real-time research, not unattended battle earnings.
9. **Design the digit rewards and enemy roster before choosing their content.** D131 accepts digit milestones for typefaces/Number identity with small permanent bonuses, while wave milestones open systems; those bonus amounts and presentation are not designed. D132 finds no need to tune Dividers for the Workshop wall, and leaves whether they should affect outcomes to the roster discussion. Recommend keeping current rules until those choices are concrete.

## Next steps, in order

1. **Owner:** merge the foundation PR, then play the preserved progress, wave/daily rewards and close/reopen a battle. Small play check; removes the gap between local verification and the owner's experience. Do not reset real progress just to test migration. Done when the owner has seen it and signed off 1.0 or named the missing pieces.
2. **Owner/agent:** settle D131's digit rewards and the enemy roster discussion, and finish the remaining 1.0.x reference readings before Cards 1.1. The open readings are the early HP discrepancy, actual enemies per spawn/wave and the mix beyond wave 100 in [TOWER_RULES.md](TOWER_RULES.md). On the owner's word, implement Cards using the new primitives; do not invent prices/effects or reopen accepted combat choices. D130/D132's Workshop wall evidence makes Coins the pace lever, not Divider tuning.
3. **Owner/agent:** test a phone/web build before calling the presentation or long-run performance ready there; this remains unmeasured.

## Known issues and risks

- **Settings → Testing can grant Coins and wipe all progress.** It remains a development tool and must be hidden/removed before public release. Reset logs the discarded permanent account, including Gems/jobs, and keeps settings.
- **A pre-D126 active run may end through the existing recovery path after this update.** Permanent progress and banked Coins remain. Later incompatible rules/data still end active runs; compatible snapshot saves resume directly.
- The enemy mix is held at wave 100's beyond it; early HP screens are 2–9% below the SDK while waves 50/100 match. The SDK's successful-roll spawn count and the owner's evidence differ. These are reference/balance uncertainties, not fixed by adding foundations.
- The clock is local UTC; rollback is handled, but a forward clock change is not server-verified. No accumulated daily claims are granted for missed days.
- Numeric/stat/computational and snapshot limits are explicit in the foundation contract. Coins are compensated doubles, not arbitrary precision. Larger generated horizons need data regeneration and measurement.
- Generated enemy content currently ends at wave 6,500 and tier 3. Content beyond that is not claimed as implemented.
- Activity reports from a managed Git worktree identify the commit as `unknown` because the existing reader expects a `.git` directory. The owner's play checkout has that directory; extending worktree provenance is a separate small follow-up.
- The Wall with a six-digit Number sits close to the range ring. D127/D128 now make overlapping crowds readable and D129 folds the upgrade panel; their rules and tests are preserved. Phone shader/music performance and elite motion have not been manually played in this pass.

## Handing on

Replace this page with the next current state. Decisions stay with decisions, intent with the spec and contracts with their owning documents. Keep the real save protected, use `run_godot.sh`, and report actual evidence. Commit on a feature branch, push it and keep an open PR to `main`; merging belongs to the owner. The latest accepted decision is D132; the foundation pass is D126.

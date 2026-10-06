# Frozen rebuilt-save fixtures (#173)

These are synthetic accounts, never player saves. The JSON files are committed
bytes: the test copies them to a unique scratch `user://` directory and calls the
real `Save` loader and writers. It never regenerates a fixture. Every Godot run
uses `run_godot.sh`; the generation and verification scratch root was
`/private/tmp/ngu-173-runtime` (via `TMPDIR`). Godot was 4.7.2.

## Provenance and the contracts guarded

| File | Source | What it guards |
|---|---|---|
| `v1.json` | Real v1 writer at `478dcac9683c3fa93a8bb18f42d357928ccaae88`, immediately before D126's schema-2 implementation | Ranks, opened groups, peak, run count and Coins; byte-exact backup; conservative reached/cleared records and one-time migration rewards. |
| `v2.json` | Real v2 writer at `5edd0681facf029197616ace0118c40dc95bcf4f`, immediately before D146's Cards implementation | Coins including exact parts, Gems, multi-tier records, claims, daily/clock and research; byte-exact backup; one free empty Card slot. |
| `v3-pre-d158.json` | Real v3 writer and battle screen at `8bdf1cf7796540edc90960e3f235943b496e19f4`, immediately before D158 changed new-run rules | Owned/equipped Cards and slots plus permanent account fields; frozen active Cash-rules snapshot, independent replay, actual screen resume and 600-tick continuation. |
| `v3-current.json` | Real v3 writer and battle screen at `f408d34be6e2a38ebd1dad49ff849d1dfc999249` | Same permanent fields; active Number-as-Cash battle retains its rules and resumes exactly. “Current” means this source commit, not a file refreshed whenever main moves. |
| `v4-current.json` | Real schema-4 writer and battle screen from merged main `032845fa4dce3113761077aca67c66e963c43591` | Best Number earned 1,500 survives alongside peak 180 and all schema-3 account progress; newly played Number-as-Cash battle resumes and matches its frozen continuation. |
| `v3-fresh.json` | Real v3 writer at `f408d34be6e2a38ebd1dad49ff849d1dfc999249` | Zero Coins/records/runs, empty Cards and research, free groups and one Card slot. |
| `v3-large-coins.json` | Real v3 writer at `f408d34be6e2a38ebd1dad49ff849d1dfc999249`, after setting Coins to `1e20` and adding one Coin 1,000 times | The exact Coin remainder survives load/save/reload: spending `1e20` leaves exactly 1,000. |
| `future.json` | Hand-edited copy of `v3-current.json`, version changed to 99 | Notice and disabled writes, including Workshop-only writes; original bytes stay at the original path. |
| `non-integer-version.json` | Hand-edited copy of `v3-current.json`, version changed to 2.5 | A fractional schema is unreadable, not rounded into a supported version; original bytes are moved aside. |
| `truncated.json` | Hand-made partial JSON ending inside Workshop | Broken JSON is moved aside byte for byte; a fresh account saves and reloads without overwriting the recovery copy. |
| `missing-workshop.json` | Hand-edited copy of `v3-current.json`, Workshop removed | Missing account data follows unreadable-file recovery and retains the bytes. |
| `nan-string.json` | Hand-edited copy of `v3-current.json`, Coins changed to the string `NaN`, exact `coin_parts` removed | Invalid declared permanent Coins cannot silently become zero; writes are blocked and the original retained. |
| `huge-string.json` | Same, with the string `1e9999` | A numeric-looking out-of-range string cannot silently replace permanent Coins. |
| `empty.json` | Hand-made zero-byte file | Empty-file recovery keeps even an empty original and allows a fresh account to round trip. |
| `missing-progression.json` | Hand-edited copy of `v3-current.json`, progression removed | Recognised damaged schema stays in place with a notice and disabled writes. |
| `unknown-rank.json` | Hand-edited copy of `v3-current.json`, `retired_row: 5` added to ranks | Unsupported declared permanent ranks cannot be silently dropped. |
| `damaged-cards.json` | Hand-edited copy of `v3-current.json`, Damage copies changed from 8 to 81 | Invalid owned Card progress cannot be silently trimmed. |

The hand-edited damaged accounts omit the active record to keep each fault
focused; `future.json` retains it to check that a future run is never exposed.

## Generation and hand checks

Historical projects were exported with `git archive <source-commit>` into
separate temporary directories, imported headless, then run headless with a
one-off generator through their own `run_godot.sh`. Their source was unchanged.
No generator is part of the suite: rerunning today's serializer would defeat
the frozen-byte contract.

The common progressed Workshop has 1,234.5 Coins, Health rank 3, Damage rank 4,
Attack Speed rank 2, the two free groups, best wave 100, peak Number 180, and
seven finished runs. Those literal values were checked in each output.

For schema 2 and 3, the generator observed Tier 1 reached 101 / cleared 100 and
Tier 2 reached 10 / cleared 9, then set the final account balances to 1,234.5
Coins and 300 Gems. It set daily day 1, clock 100,000, and a synthetic completed
research id `fixture_lab` at level 2 with no effects or pending jobs. This id is
valid saved research data, not a shipped Lab. Claims are the known Tier 1
10/20/30/40/50/80/90/100 and Tier 2 10 rewards. Schema 3 additionally owns Damage
8 and Coins 1, with two slots equipped in the order Coins, Damage.

The two schema-3 active-run generators attached the historical/current `BattleScreen`
to the tree, disabled automatic processing, restarted with seed 173 and called
`_process(0.1)` 120 times before obtaining `run_state()`. The pre-D158 tuning was
empty (normal Cash rules); the current tuning was `RunConfig.game_tuning()`.
Both resulting snapshots have 408 ticks, Tier 1 wave 1, two kills and four live
enemies. Neither has banked Coins yet. The permanent balance was explicitly
restored to 1,234.5 before writing. Old build metadata reads `unknown` because
the historical project was an archive, not a Git checkout; the source commit
above is its provenance. The snapshots themselves are genuine writer output.

Continuation oracles were measured separately by those same original source
commits: restore the frozen snapshot, call `step()` 600 times, then capture its
digest. The pre-D158 digest is
`0d230094679a2530020b39d2b988fba7bcbdcf1fe791ff6071f40edb0f1aee57`;
the current-source digest is
`ada1fa4059a8a470e407c52b5fdee5f8f63df74ef367570546419659b7917888`.
After D164 merged during this task, `v4-current.json` was written by that
merged production source in the isolated issue checkout. Its generator loaded
the synthetic `v3-current.json`, set best Number earned to 1,500, played a new
seed-173 battle with the same 120 manual processing calls, and saved with the
real schema-4 writer. Its peak remains 180. Its independently measured further
600-tick digest is
`91b51b0c423f766c9d560011510e36b69f8c0e1231bef97ab19f4517e9874401`.
No fixture was rewritten; a new supported schema received its own file.

The suite compares the actual resumed screen to these literals, so a regression
shared by two restores in today's code cannot make continuation pass.

For schema 1, reached wave 100 is not proof of cleared 100: migration preserves
1,234.5 Coins and adds exactly 1,660 Coins and 45 Gems from the eligible newly
introduced wave rewards, giving **2,894.5 Coins**, reached 100 / cleared 99 and
no Tier 2 unlock. The test's migration oracle is literal, not calculated by the
current reward implementation. Repeating the saved records must pay nothing.

Assertions compare declared fields recursively, allowing additional optional
fields in a later build (including D164's `best_earned`). They also check all
fields of the loaded account through a round trip. They never require that a
save has no extra keys, or change a file under `src/`.

## Verification and limits

Risk: verification tooling only; production save, gameplay and balance code are
unchanged. Scope: this folder, `tests/save_fixture_tests.gd` and its `.uid`, and
one suite name in `run_tests.sh`. The runner applies its existing exit-status
and error-line gate to the new suite too.

Run `bash run_tests.sh` after importing the project, then the headless boot
through `run_godot.sh`. Recovery warnings for the four unreadable files are
expected. They are not script or engine errors.

These fixtures do not prove migration of the owner's real save, compatibility
with every historical combat/data signature, or recovery of an incompatible
battle. They guard the declared synthetic values and two compatible real
snapshots; frozen research has no pending jobs or effect payloads, and D164 owns the
semantics of the added earned-Number field. Other generated boundary/recovery
tests remain in the existing suites. A real-copy probe remains `tools/check_migration.gd` through the wrapper.

Final verification results are recorded in PR #178. The complete baseline
and headless boot were rerun after integrating merged main `032845f` and adding
its current schema-4 fixture. Existing suites and boot emit ObjectDB leak
warnings; the fixture suite emits only the expected unreadable-file warnings.
The earlier 16-file suite also passed 2,900 checks against an isolated archive
of earned-ladder commit `084e9df52517e66b3a14543381ade6ec1ff3a385`, including its
schema-4 migration, with archive tracked bytes checked against that commit.
This is compatibility evidence, not a balance rerun or proof of D164's reward
semantics.

Independent read-only review found one test-proof gap: using two restores by
today's code as the continuation oracle could share a regression. The final
suite uses the original-build literal digests above instead. The reviewer
rechecked and confirmed that finding resolved; no confirmed defects remained.

No production defect was found while loading these fixtures. If a future
fixture reveals one, keep the bytes and report the defect for a separate
owner-approved fix; do not change the loader as part of this task.

# The Tower — current systems and Number Go Up comparison

**Reference snapshot:** 23 September 2026. The latest released Tower build found in the developer's notes is **v29.0.3 (10 September 2026)** [S1]. The [14 September developer update][S9] discusses a future v29.1 and later modules; those plans are **not** counted as released systems here. This is a structural inventory of the live game's major loops, not an exact balance database or a claim that we have played every late-game system.

**Purpose and authority:** Use this page to ask what a Tower system *does for the player*, what comparable role Number Go Up already serves, and where the foundation is still thin. [`GAME_VISION.md`](GAME_VISION.md), accepted [`DECISIONS.md`](DECISIONS.md) and current code govern our game. D009 requires original names, coefficients, pacing and content. [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) holds detailed wave research; [`TOWER_WORKSHOP_REFERENCE.md`](TOWER_WORKSHOP_REFERENCE.md) holds the wiki's Workshop, Ultimate Weapon and Enhancement tables (read 24 September 2026); [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md) owns the immediate combat proof. A low score here is not an instruction to build the Tower system.

## How the closeness ratings work

Ratings compare **player-facing function and supporting rules**, not visual similarity, amount of content, or overall game quality. They are dated editorial judgements against the current checkout, not percentages of completion.

| Rating | Meaning |
| --- | --- |
| **0/4** | No playable equivalent. A reserved name or generic hook alone does not count. |
| **1/4** | A specific supporting primitive exists, but the player cannot yet use the comparable loop. |
| **2/4** | A playable, narrower version exists; a major choice, feedback or progression link is missing. |
| **3/4** | The comparable role works end to end, with meaningful differences in breadth or maturity. |
| **4/4** | The role is broadly mature and validated in our own design; this never requires copying Tower content. |

**Fit** is separate: **Core** = supports our accepted vision; **Investigate** = a test could justify it; **Defer** = depends on later needs; **Outside** = contrary to present scope. A **0/4 · Outside** row is a deliberate product boundary, not a defect. Section scores summarise the central role in that section rather than averaging unrelated rows.

## 1. The battle and the run — **2/4**

The Tower's visible radial defence combines enemy movement, range, projectiles, orbs, knockback, wall, damage and mitigation. Enemies include simple, advanced, elite and fleet groups; v29's Vault names Basic/Fast/Tank, Boss/Ranged/Protector, Elites and Fleets [S2]. Fleets can make a tournament wave wait for a kill rather than a timer [S2], and v28.3 changed Fleet counterplay and added tier conditions [S3]. Those are examples of *different decisions during a fight*, not a prescription for spatial simulation in our game.

| Tower system | What it does | Number Go Up today, and why the score | Fit |
| --- | --- | --- | --- |
| Escalating waves and two survival checks | Enemy health tests damage; attacks test survival. | **3/4** — Wave HP and Hit are separate, with authored tier curves and boss multipliers. The HP/time contest has not been validated with new players. [NG: `tax_encounter.gd`, `tax_balance_profile.gd`, D037–D041] | Core |
| Distinct enemies and boss encounters | Enemy behaviours change which defence works; bosses and Fleets can change wave progression [S2][S3]. | **1/4** — ordinary waves and standing bosses differ, but there is no enemy roster or enemy-specific counterplay. [NG: `game_state.gd` wave resolution] | Investigate |
| Readable contact and combat feedback | Stats, hit text, battle reports and an in-game encyclopedia explain effects [S4][S5]. | **2/4** — Wave HP ring and exact Hit line exist; a separate time meter and clear/no-Hit feedback remain planned. No fresh-player comprehension result. [NG: D041, `COMBAT_FEEL_PLAN.md`] | Core |
| Run ending, resume and reports | A run records its outcome; Tower has had to preserve complex cooldown states on resume [S10]. | **3/4** — death, retreat, Prestige, frozen offline run, run summary, deterministic active-run restoration and V1–V8 migrations exist. Tower's pause and live-account behaviour is intentionally different. [NG: `game_state.gd`, `save_data_v8.gd`] | Core |
| In-run economy and purchases | Cash and temporary upgrades let a run develop independently of permanent Workshop ranks. | **2/4** — the Rig spends Number and resets each run; its cost competes directly with the Hit buffer. Meaningful mid-run build choices still need playtesting. [NG: `game_state.gd`, D015/D039] | Core |
| Free upgrades and automated choice | Automatic purchases or free ranks remove solved repetition and alter which stats grow. | **1/4** — automation targets exist, but no Tower-like free-upgrade pool or evolving candidate selection. [NG: `workshop_state.gd`, `game_state.gd`] | Investigate |
| Perks and temporary rule changes | Choices during a run reshape that attempt; v28 still refers to perk effects [S4]. | **1/4** — the ordered modifier pipeline exists, but there is no playable Perk choice. [NG: `rule_modifier_pipeline.gd`] | Investigate |
| Enemy Level Skip and wave acceleration | Enemy Level Skip changes pressure growth; Wave Skip/Intro Sprint change progression. Skip ordering interacts with a battle condition [S6], and v29 changed tournament sprint behaviour [S2]. | **0/4** — no enemy-growth suppression or wave skip. Our chance-based versus earned-suppression question is only a candidate in `COMBAT_FEEL_PLAN.md`. | Investigate |

**Foundation read:** The clearest gap is the *felt fight*, not a missing radial physics engine. The existing rule already lets a clean clear prevent a Hit. First prove that players see the HP and time races and can predict the exact loss; then judge whether a new counterplay rule adds a choice. The user-supplied Gemini architecture note is useful as a list of possible Tower mechanics, but its exact formulas, implementation prescriptions and performance claims have not been independently verified and are not adopted here.

## 2. Permanent build layers — **2/4**

The Tower compounds a broad Workshop with timed Labs, equipped Cards and Modules, special weapons, Bots, Guardians and late Vault choices. v29 explicitly connects these through presets and the Vault, while moving Module levels onto slots and leaving substats on individual Modules [S2][S7]. Its breadth is a mature-game state, not a sensible starting checklist.

| Tower system | What it does | Number Go Up today, and why the score | Fit |
| --- | --- | --- | --- |
| Workshop and enhancements | Coins improve the permanent baseline; later enhancement layers extend existing stats [S3]. | **2/4** — 21 loaded rows in Attack, Defense and Utility, permanent Coin purchases and multi-buy. Ultimates is reserved; ladder expansion and balance are open. [NG: `data/workshop/upgrades.json`, `WORKSHOP_LADDERS.md`] | Core |
| Labs and research slots | Time-gated, Coin-funded research competes for slots and improves other systems; v29 uses a Lab to unlock presets [S2]. | **2/4** — four research lines, real-time completion, one starting slot and four more Gem-funded slots exist. Late ranks are currently unreachable on sensible timescales. [NG: `lab_research.gd`, `data/labs/research.json`, `HANDOVER.md`] | Core |
| Cards, active slots and mastery | A limited equipped collection changes builds; v29 adds a Cells card and describes its Mastery [S2]. | **2/4** — six Gem-pulled cards, four Active slots, rank growth and duplicate protection. No Mastery, presets or settled Gem economy. [NG: `card_collection.gd`, `data/cards/cards.json`, D027] | Core |
| Modules and substats | Four Module types and individual substats add equipment choices; v29 levels slots, and swaps are restricted during a run [S7]. | **0/4** — no equipment inventory, substats or module rolls. Cards already supply a small equipped-build layer. | Defer |
| Ultimate Weapons and cooldown overlap | Special powers interact with enemies, Labs, Modules and each other; sync/resume matters [S5][S10]. | **0/4** — an Ultimates category is reserved, but there is no comparable capstone power or cooldown system. A label is not a playable layer. | Defer |
| Bots | Separate timed effects and upgrades; v28 added Bot+ and synchronised pathing [S4]. | **0/4** — no comparable autonomous effect layer. | Defer |
| Guardians and Guild progression | v26 Guilds introduced Guardians alongside contribution, chests and a rotating store [S8]. | **0/4** — no Guardian or social progression layer. | Outside |
| Relics and collectible bonuses | Persistent rewards from milestones and events; v28 expanded the Event Store's older Relics [S4]. | **1/4** — milestone rewards exist, but no relic collection or collection-driven bonus. | Defer |
| Presets and respec | Store build configurations for different purposes; v29 Lab unlocks Card, Workshop, Bot, Module and Guardian presets, plus a global selector [S2]. | **0/4** — Cards have one manually edited Active set; no named preset or general respec. Add only if switching builds becomes costly. [NG: D027] | Defer |
| Vault / late-game trees | Harmony, Power and Enemy trees add decisions across established systems; v29 reworked them [S2]. | **0/4** — our Knowledge/Insight is original permanent progression, not a Vault equivalent. No cross-system late tree exists. | Defer |

**Foundation read:** Our Workshop, Labs and Cards already establish the permanent-versus-run boundary. The next structural issue is whether their purchases meaningfully change a *visible* wave contest. Adding Modules or a Vault before that would multiply complexity without proving the loop.

## 3. Campaign, goals and challenge variants — **2/4**

Tower tiers offer different pressure, rewards and unlocks. v28.3 added Tiers 22–24 with Fleet-specific conditions [S3]. v28 introduced Dissonant Runs, where one Workshop tab is disabled in exchange for a tier-specific boost, and late Overheat pressure to limit very long runs [S4]. These are examples of extending familiar runs after players have learned them.

| Tower system | What it does | Number Go Up today, and why the score | Fit |
| --- | --- | --- | --- |
| Tier choice and scaling | Explicit difficulty/reward choice with tier-specific gates. | **2/4** — three tiers with distinct pressure/reward multipliers and wave-100 unlocks; no broad late-tier challenge catalogue. [NG: `tax_balance_profile.gd`, `tier_definition.gd`] | Core |
| Records and milestones | Wave achievements make pushing legible and open rewards or systems. | **2/4** — per-tier records and thirteen one-time Gem checkpoints per tier; some also pay Coins. Unlock spine exists but few new play styles open from it. [NG: `game_state.gd`, D030] | Core |
| Battle conditions and enemy counters | Rules vary by tier or tournament and support counter-builds [S3]. | **1/4** — the modifier pipeline can stack rules, but no player-facing condition content exists. [NG: `rule_modifier_pipeline.gd`] | Investigate |
| Dissonance / restricted builds | Voluntary restriction changes how a familiar tier plays and pays [S4]. | **0/4** — no optional build-restriction mode or corresponding reward. | Defer |
| Overheat / very-long-run control | Late-wave conditions push otherwise endless runs towards an outcome [S4]. | **0/4** — no such late-run system; current runs do not yet justify it. | Defer |
| Battle reports and learning tools | In-run stats, end reports and encyclopedia descriptions help explain deep interactions [S4][S5]. | **2/4** — run summary, lost-to explanation and stats exist, but effect provenance and a searchable rules reference are limited. [NG: `main.gd`, `HANDOVER.md`] | Core |

## 4. Scaling and balance architecture — **2/4**

**Source boundary:** Tower developer notes confirm tier additions, battle conditions and Enemy Level Skip interactions [S3][S4][S6], but they do not publish a complete current formula set. The more detailed wave and tier shapes below are an **unofficial reconstruction** from [TheTowerSDK's wave model][S11], [tier profile][S12] and [enemy-type modifiers][S13], consulted on 23 September 2026. Its repository `main` can change; the exact values in [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) are version-sensitive research evidence, not verified current developer constants.

The useful shape is `wave body × milestone steps × later compound growth × tier table × encounter modifiers`. The SDK models enemy health and attack with **different wave bodies and growth chains**. Tower's later pressure is not one constant percentage applied to the player's current resources. Our [`TaxBalanceProfile`](../src/tax_balance_profile.gd) likewise creates absolute Wave HP and Hit values, and since D043 **each has its own polynomial body**, sharing the milestone steps, so damage checks and survival checks can be tuned separately (D046 set the Hit's scale against balance target 5). There is no later compound growth yet, so this is still not full scaling equivalence.

| Scaling axis | Tower reference, with evidence level | Number Go Up now, and why the score | Fit |
| --- | --- | --- | --- |
| Enemy health across waves | The SDK reconstructs a wave body with milestone and compound growth [S11]. **Community model**, not an official formula. | **3/4** — Wave HP is a polynomial body with ×1.08 every 10 waves, ×1.2 every 50 and ×1.5 every 100; log-space calculation supports large values. Deep waves lack a real career playthrough. The polynomial's terms match the early SDK example in the older research after our ×4 scale; see the provenance note below. [NG: `tax_balance_profile.gd`] | Core |
| Enemy attack across waves | The SDK reconstructs a separate attack body and milestone chain [S11]. **Community model**. | **3/4** — the Hit has its own body, 1.7 × (0.08 w^2.10 + 0.4 w + 1), with the same milestone steps as Wave HP (D043, D046); it runs at roughly 27% of ordinary Wave HP at wave 1 and about 51–57% from wave 30. Defence modifies the effective Hit. No separate later growth chain. [NG: D043, D046, `tax_balance_profile.gd`] | Core |
| Tier pressure versus reward | SDK tables show explicit, irregular tier pressure jumps and much smaller Coin reward steps [S12]; v28.3 confirms Tiers 22–24 exist [S3]. **Community numbers; developer-confirmed tier expansion.** | **3/4** — three authored tiers use pressure 1×/20×/60× on both axes and reward 1×/1.8×/2.6×. The same wave body applies in each tier. Later tiers are proposals, not live content. [NG: `tier_definition.gd`, `TIER_BALANCE_PROPOSAL.md`] | Core |
| Enemy and boss modifiers | The SDK applies enemy-type health/attack modifiers after base wave stats [S13]; developer notes document different Fleet behaviour [S3]. **Mixed source confidence.** | **2/4** — every tenth wave is a boss with ×3 Wave HP, ×1.5 base Hit and ×5 wave Coins; bosses stand and hit repeatedly. No broader enemy-type modifier table exists. [NG: `tax_balance_profile.gd`, `game_state.gd`] | Core |
| Wave timing and run length | Tower pacing can change with skips, sprint and late Overheat [S2][S4][S6]. **Developer-confirmed systems, not a single timing formula.** | **2/4** — ordinary waves have a 15-second Hit boundary; clears advance after at least 2.5 seconds, misses hit once and move on, bosses stand. Run-length control is limited to these rules and the current curve. [NG: D037, `game_state.gd`] | Core |
| Rewards and farming | Tier Coin multipliers grow more slowly than pressure in the SDK [S12]; Tower also has multiple specialist resource loops [S2][S4]. **Community multiplier table; developer-confirmed resource layers.** | **2/4** — base Coins are `round(0.65 × wave × tier reward × boss factor)`, with partial Coins on missed ordinary waves and milestone bonuses. Current Coins-per-minute target fails after faster clears; reward tuning is open. [NG: `tax_balance_profile.gd`, `game_state.gd`, `HANDOVER.md`] | Core |
| Permanent and run upgrade costs | Tower's Workshop, Labs and other systems each have their own investment ladders [S2][S4]; this reference does **not** assert a universal Tower cost formula. | **2/4** — Workshop rows have authored price ladders, Rig ranks cost roughly five seconds of current income then grow ×1.4 per row rank, and Labs have separate Coin/time growth. Long Workshop ladders and late Lab reachability are open balance questions. [NG: `data/workshop/upgrades.json`, `lab_research.gd`, D039] | Core |
| Suppressing future pressure | Enemy Level Skip changes whether an enemy level increase applies; developer notes confirm its ordering relative to Skip Decay [S6]. Exact chance and cumulative formula are **not established here**. | **0/4** — no suppression rule or saved skip counters. Compare chance-based and earned variants only after the visible fight is tested; neither is accepted balance. [NG: `COMBAT_FEEL_PLAN.md`] | Investigate |
| Numeric range and measurement | Tower reaches very large tier/wave values in community models [S11][S12]; exact current extremes need game-version checks. | **2/4** — `ScientificNumber`, log-space Wave HP and a GDScript balance simulator exist. A full real-rules career model and player-observed pacing are still missing. [NG: `scientific_number.gd`, `tax_balance_profile.gd`, `HANDOVER.md`] | Core |

**Current Number Go Up calibration, not Tower values.** The safe `run_balance.sh` measurement on this branch printed profile `tax-foundation-v7` (display-rounded values):

| Tier and wave | Wave HP | Base Hit | Wave Coins |
| --- | ---: | ---: | ---: |
| Tier 1, wave 1 | 9 | 2 | 1 |
| Tier 1, wave 50 boss | 5,276 | 1,583 | 163 |
| Tier 1, wave 100 boss | 55,475 | 16,643 | 325 |
| Tier 2, wave 100 boss | 1.11M | 332,852 | 585 |
| Tier 3, wave 100 boss | 3.33M | 998,556 | 845 |

The same measurement's representative seed-7 first run ended at the wave-20 boss after 337.5 seconds with 106 Coins. These are simulator/profile checks, **not** a phone playtest or proof of a balanced career. The current open question is whether coupling Hit to HP and the larger boss steps create interesting Attack-versus-Defense choices once players can read the contest. Changing that coupling, a tier multiplier, reward rate or skip rule would be a separate balance decision with high-risk verification.

**Coefficient provenance needs a decision.** [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md#what-the-towers-curve-actually-looks-like) quotes an early SDK health body of `0.05 × wave^2.13 + 0.8 × wave + 1.5`. The live [`TaxBalanceProfile`](../src/tax_balance_profile.gd) uses those same written terms inside a ×4 scale, despite its comment saying the coefficients are deliberately ours. Git history shows both expressions in the tiered foundation commit `0f88c38`; it does not record an independent derivation. This establishes an overlap, **not** why it happened or whether the SDK expression is current Tower behaviour. Before changing or defending those constants under D009, decide whether to author a replacement and test it against the current first-run and build baselines. This document does not authorise a balance change.

## 5. Currencies and compounding economy — **2/4**

Tower resources split by job. Cash is a run resource; Coins buy persistent baseline/research; Gems open options; Cells, Stones, Medals, Keys and shards support additional research, specialist, event, tournament, Vault and equipment loops. The released developer notes confirm these named resources and their links to current systems [S2][S4]. This table is **not** a complete earning-rate or spend-price ledger, and the Gemini note's Cell acceleration formula is unverified.

| Tower resource role | Number Go Up today, and why the score | Fit |
| --- | --- | --- |
| Run spend versus survival | **3/4** — Number buys Rig ranks, funds survival and rises from output. Its dual role is intentionally unlike Tower cash. [NG: D015/D037] | Core |
| Repeatable permanent earnings | **2/4** — Coins pay for Workshop and Labs; boss/wave payouts work, but Coins per minute and long ladders are open balance decisions. [NG: `game_state.gd`, `HANDOVER.md`] | Core |
| Option currency | **2/4** — Gems come from bosses and per-tier milestones and pay for Cards/Lab slots; broader supply and price policy remain unsettled. [NG: D027/D030] | Core |
| Long-term knowledge layer | **2/4** — Knowledge/Insight and Prestige are our own persistent layer; this is a design difference, not a direct Tower-currency match. [NG: `game_state.gd`, `GAME_VISION.md`] | Core |
| Specialist/live resources | **0/4** — no Cells, Stones, Medals, Keys or Module shards. Their dependent systems are absent or outside scope, so copying these resources has no current value. | Outside / Defer |

**Dependency rule:** A new currency must have a distinct decision, earning route, sink, reset boundary, save contract and player-facing explanation. Currency count is not a measure of depth.

## 6. Live operation, social and commercial layers — **0/4**

Tower's events, daily missions, tournaments, Guilds, stores and account services make a released live game operate over months. v29 added a Mythic tournament league and adjusted rewards and Fleet waves [S2]; v26 Guilds introduced contribution, chests, store and Guardians [S8]. v29.0.3 still fixes cross-device/run-stat and Vault-respec issues [S1], evidence of the maintenance load these layers carry.

| Tower system | Number Go Up today, and why the score | Fit |
| --- | --- | --- |
| Events, missions and rotating rewards | **0/4** — no calendar or event system. Milestones give long-term goals without a schedule. | Outside for now |
| Tournaments and leagues | **0/4** — no competitive service, ranked rewards or battle-condition schedule. | Outside for now |
| Guilds, Guardians and shared rewards | **0/4** — no account/social backend or cooperative economy. | Outside for now |
| Ads, purchases, premium passes and remote account | **0/4** — local-save game with no store or account service. The absence is deliberate, not missing foundation for the current loop. | Outside for now |

## What this comparison means for our next move

1. **Prove combat comprehension first.** The 2/4 battle score is primarily a presentation and playtest gap: show remaining Wave HP, time to the next Hit and the exact effective loss together. Test whether a clean clear reads as a prevented attack (`COMBAT_FEEL_PLAN.md`, D041).
2. **Then test a consequential counterplay choice.** If players understand the existing rule but still feel passive, compare earned versus chance-based enemy-growth suppression, or a narrower encounter choice. Measure run length, reward rate, Attack/Defense value, and deterministic resume before accepting a rule.
3. **Only then deepen the permanent ladder.** Make existing Workshop, Rig, Labs and Cards improve a visible combat outcome. Their balance and reachability issues are more immediate than Tower's missing endgame layers.

## Evidence and maintenance

**Developer sources (released unless stated otherwise):**

[S1]: https://www.techtreegames.com/post/v29-0-3-patch-notes-september-10-2026 "v29.0.3 patch notes, 10 September 2026"
[S2]: https://www.techtreegames.com/post/v29-patch-notes-august-25-2026 "v29 patch notes, updated 26 August 2026"
[S3]: https://www.techtreegames.com/post/v28-3-patch-notes "v28.3 patch notes, 29 June 2026"
[S4]: https://www.techtreegames.com/post/v28-patch-notes "v28 patch notes, 7 April 2026"
[S5]: https://www.techtreegames.com/post/v28-1-patch-notes "v28.1 patch notes, encyclopedia and descriptions"
[S6]: https://www.techtreegames.com/post/v27-5-1-update "v27.5.1 patch notes, Enemy Level Skip ordering"
[S7]: https://techtreegames.zendesk.com/hc/en-us/articles/55088947675547-Modules-Changes-with-v29 "Official v29 Modules help article"
[S8]: https://www.techtreegames.com/post/tower-tea-july-6-2026 "Developer Guild retrospective, 6 July 2026"
[S9]: https://www.techtreegames.com/post/tower-tea-september-14-2026 "Developer update, 14 September 2026; future items distinguished above"
[S10]: https://www.techtreegames.com/post/v28-0-6-patch-notes "v28.0.6 resume fixes"
[S11]: https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/waves/base-empirical-scaling.ts "Unofficial SDK wave reconstruction, consulted 23 September 2026"
[S12]: https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/waves/scaling-regression-profile.ts "Unofficial SDK tier and reward profile, consulted 23 September 2026"
[S13]: https://github.com/TmRxJD/TheTowerSDK/blob/main/src/mechanics/enemies/type-mults.ts "Unofficial SDK enemy-type modifiers, consulted 23 September 2026"

**Evidence limits:** Developer patch notes establish the features and changes stated there, not every evergreen rule, current numeric value or early unlock. [`TheTowerSDK`](https://github.com/TmRxJD/TheTowerSDK) and calculators in [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) are qualified community evidence for formulas and need a pinned version before numeric use. The supplied Gemini research is an unverified secondary interpretation. Our ratings come from the checked-in Godot code and accepted decisions; they have not been validated by a fresh phone playtest. This is a current-state reference, not implementation approval.

**Update rule:** On a relevant Tower release, verify what shipped from developer notes, move unreleased items into the snapshot only after release, update the affected system rows and their source links, then rescore against the *current* Number Go Up checkout. Keep future proposals in their owning design documents. Do not import Tower's terminology, coefficients, art, layouts or full currency stack into our game.

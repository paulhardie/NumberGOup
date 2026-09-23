# The Tower — systems and structure reference

**Snapshot:** 23 September 2026, through the developer's v29 notes (updated 26 August 2026). This is a map of system *roles*, not a complete rules database or a Number Go Up feature backlog. Recheck dated sources before relying on a specific mechanic; a live game's systems change.

**Authority:** [`GAME_VISION.md`](GAME_VISION.md) and accepted [`DECISIONS.md`](DECISIONS.md) govern our game. This document supplies reference evidence and design questions. D009 requires our own names, coefficients, pacing and content. [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) holds the narrower wave and tier research, including its historical implementation notes; [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md) owns the current player-experience proof.

## The compounding structure

The Tower combines several time scales. A run tests a build against increasing enemy pressure. Run earnings improve a permanent baseline. Milestones open further choices, and later systems modify earlier ones. The useful pattern is that an unlock changes *which decision matters next*, rather than merely adding another multiplier.

| Time scale | Tower structure | Design job | Number Go Up reading |
| --- | --- | --- | --- |
| Seconds to waves | Enemies, health, attack, bosses and other enemy types; timed or kill-gated waves | Make offensive output and survival matter during play | Existing Wave HP, Hit, boss and Rig contest; D041 first makes the threat legible. No spatial tower defence is implied. |
| One run | In-run cash upgrades, free upgrades, perks and wave skips | Allow temporary adaptation and sometimes alter how quickly pressure grows | The Number-funded Rig is our temporary layer. A future run choice needs an observable effect and an explicit reset boundary. |
| Between runs | Workshop, Labs, Cards, Modules, Ultimate Weapons, Bots and Guardians | Make several long-term investments compound and compete | Workshop, Labs and Cards exist in our own forms. Other layers are reference roles only; each must earn a distinct job. |
| Across tiers | Difficulty choice, wave records, milestones, relics and later tier conditions | Give the player a reason to farm, push and revisit builds | Tiers 1–3, records and milestones exist. More tier content follows proof that the current wave contest works. |
| Mature game | Presets, Vault, events, tournaments, guilds and monetised currencies | Serve complex build switching, competition and ongoing operation | Presets are useful only once build switching is a real burden. Live-service layers are outside the current product direction. |

The [developer's v29 notes](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026) show how mature layers connect: Labs unlock presets for several systems; the Vault changes those systems; modules now level their *slots* while item substats remain on the item. That is a useful dependency example, **not** an instruction to add these layers.

## System map and what it teaches us

The Tower facts in this table are grounded in the developer sources below unless marked as a qualified community account. “Our reading” is an authored design interpretation, not a claim about The Tower's intent. “Status” describes Number Go Up as of this snapshot; it does not approve future work.

| Tower system or group | Structural role in The Tower | Our reading and status |
| --- | --- | --- |
| Waves, enemy types and bosses | Increasing health/attack pressure; enemy types make different defences matter. v29 also describes Fleet waves that advance on a kill condition in tournaments. | **Built in part:** Wave HP, Hit, bosses and two build axes. First make the existing clear-before-Hit fight readable; new enemy types need a new player decision, not just another colour. |
| Tiers, records and milestones | Players choose the pressure/reward setting and pursue visible checkpoints. Later tiers add battle conditions. | **Built in part:** three tiers, records, milestone Gems and unlocks. The tier curve is ours; see the [scaling research](TOWER_SCALING_FOUNDATION.md). |
| Run cash and free upgrades | Temporary growth can rescue or redirect a run without becoming permanent power. | **Adapted:** the Rig spends Number and resets each run. Do not add a second temporary currency just to match the reference. |
| Workshop | Permanent, broad baseline that makes the next attempt stronger. | **Built:** Coin-funded permanent rows. Keep its contrast with the Rig and make purchases visibly change the next run. |
| Labs | Long-horizon research unlocks and improves other systems, including presets and enemy counters. | **Built in part:** our timed Labs exist. Further research needs reachable duration/costs and an actual consumer; the current late-rank timing is a known risk in [handover](HANDOVER.md). |
| Cards and mastery | A limited equipped set adds configurable power; advanced investment extends existing cards. | **Built in part:** Cards, Active slots and pulls exist. Mastery and presets remain separate future decisions, with duplication and Gem economy constraints. |
| Perks and run modifiers | In-run choices change the shape of one attempt. | **Candidate:** a choice could add counterplay once the current wave is readable. Any rule must use the modifier pipeline and save/replay contract. |
| Enemy Level Skip and wave skips | Pressure growth or wave progression can be altered. [v27.5.1](https://www.techtreegames.com/post/v27-5-1-update) confirms Enemy Level Skip ordering interacts with a skip-decay condition. | **Candidate, not approved:** compare chance-based and earned growth suppression in [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md). The reference does not determine our trigger, probability, cap or reward policy. |
| Modules and equipment | Equipped items and substats make build choice wider; v29's slot levelling reduces switching friction. | **Deferred:** an equipment layer needs a distinct decision beyond Cards and a migration plan for owned items. No module system is needed for the combat proof. |
| Ultimate Weapons, Bots and Guardians | Specialised, longer-term effects can interact with core stats and timing. | **Deferred as separate systems:** evaluate a specific missing combat role first. Adding several overlapping multipliers would hide the wave contest. |
| Relics and collections | Long-term achievements and event rewards supply persistent bonuses. | **Deferred:** a reward must change a meaningful choice, and its source and permanence must be legible. Our milestones already carry the first reward spine. |
| Presets and respec | Reduce the cost of switching builds for different run goals. In v29, Labs unlock preset types and a global preset combines them. | **Deferred:** introduce only when manual build switching becomes a measured problem. Changing equipment and preset state would need saved, explicit ownership. |
| Dissonant runs, battle conditions and Overheat | Optional restrictions and late-run pressure reshape familiar tiers. [v28](https://www.techtreegames.com/post/v28-patch-notes) describes disabling a Workshop tab for a tier-specific bonus and late-wave skip decay. | **Possible later tier design:** use a visible rule and trade-off only after base tiers teach the player what changed. Route through the modifier pipeline. |
| Vault and very late trees | Adds a further investment layer across existing systems. v29 reorganises Harmony/Power and adds an enemy tree. | **Defer:** its value depends on mature underlying systems; it is not a foundation primitive for the current game. |
| Events, missions, tournaments, guilds and stores | Recurring goals, competition, social play and additional currency sinks. | **Outside current scope:** these require service, scheduling, moderation or commerce decisions. The local run must be fun first (D011). |

## Resource and unlock flow

The Tower uses different resources to separate run decisions, permanent growth and mature-game activities. Developer [v29](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026) and [v28](https://www.techtreegames.com/post/v28-patch-notes) notes refer to cash, Coins, Gems, Stones, Cells, Medals, Keys and module shards; this is a role summary, not a full source/sink ledger.

| Reference role | Examples in The Tower | Number Go Up boundary |
| --- | --- | --- |
| Spend during one attempt | Cash and temporary upgrades | Number funds the Rig and is also the survival buffer; every spend has a visible cost. |
| Improve the next attempt | Coins for Workshop and research | Coins fund permanent Workshop progress. Our Knowledge, Labs and other existing resources follow their own accepted rules. |
| Open and configure options | Gems for Cards, slots and other choices | Gems already fund Cards and Lab slots. Do not introduce another currency without a distinct, tested purpose. |
| Support later specialist and service loops | Stones, Cells, Medals, Keys and shards | Reference only. Their Tower sinks depend on systems and operations we have not built or approved. |

This exposes a useful dependency order: **readable run → meaningful run choice → satisfying permanent purchase → milestone that opens a new choice**. A later system should name the resource it consumes, its reset boundary, its unlock, and the decision it adds before it is put on a roadmap.

## Design lessons to test, not copy

1. **A fight needs a visible alternative outcome.** In our rules, beating Wave HP before the boundary already prevents a Hit. Make HP remaining, time to Hit and the effective Hit readable together, then test whether players perceive that as fighting back (D041).
2. **Offence and survival should create different choices.** Two pressure axes permit an Attack build to clear faster and a Defense build to survive misses. Measure both at the same tier and wave before adding another stat.
3. **A growth-suppression upgrade changes future encounters, not today's damage.** It may be a satisfying counter to scaling, but could merely lengthen runs. Test its effect on decisions, run length, rewards and deterministic resume before accepting it.
4. **New layers should interact with established layers in a way the player can explain.** A deeper tree is useful when it opens a choice; a bare multiplier or new currency is insufficient evidence.
5. **Complexity has a maintenance cost.** The Tower's [v28 resume fixes](https://www.techtreegames.com/post/v28-0-6-patch-notes) cover cooldown synchronisation across Bots, Guardians and Ultimate Weapons. For our game, every new timed or random layer increases save, resume and explanation work.

## Source and update discipline

- **Developer evidence:** [v29 patch notes](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026) for current presets, Modules, Vault, Cards and tournament structure; [v28 patch notes](https://www.techtreegames.com/post/v28-patch-notes) for Dissonance, Bots, Overheat, relics and events; [v28.1 notes](https://www.techtreegames.com/post/v28-1-patch-notes) for the in-game encyclopedia's Workshop, Ultimate Weapons, Cards, Modules, Enemies and Other categories; [v27.5.1](https://www.techtreegames.com/post/v27-5-1-update) for Enemy Level Skip ordering. Patch notes establish described changes, not every evergreen rule or exact formula.
- **Qualified community evidence:** [TheTowerSDK](https://github.com/TmRxJD/TheTowerSDK) and the other references in [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md) can help inspect wave shapes. They are version-sensitive, unofficial, and need a pinned version plus independent checks before numeric use.
- **Our decisions:** D009 and D011 set the originality and product boundaries; D041 and [`COMBAT_FEEL_PLAN.md`](COMBAT_FEEL_PLAN.md) set the immediate validation order. A row in this reference is never approval to implement it.
- **Maintenance:** when a Tower update is relevant to a proposed design, check the latest developer notes, date the affected claim, update only the affected rows, and record whether the claim is developer-stated, community-reconstructed or our interpretation. Do not treat this snapshot as a live catalogue.

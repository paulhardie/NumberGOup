# Growth layers: what grows the tower once the Workshop flattens

**Status (6 October 2026): a design note. Nothing here is built, and only the two owner directions in section 1 are decided (D161).** It answers the owner's question "are we happy for the Workshop to be 'solved' at one point, as in The Tower, with growth coming from Labs, Ultimate Weapons and so on?", and sets out what has to be true before Labs (1.2), Ultimate Weapons (1.3) and tiers (1.4) are built, so each is sized against the one before. Everything in sections 5 to 7 is a recommendation for the owner to change.

## 1. The owner's directions (6 October 2026)

1. **The Workshop is allowed to flatten.** Growth then comes from other layers (Labs, Ultimate Weapons, tiers), as it does in The Tower.
2. **We are not bound to The Tower's Workshop rows.** We can add rows of our own, and larger Coin sinks over time. This relaxes D068 ("the game's Workshop is these rows"); it does not remove The Tower as the reference, and the generated rows stay generated (`data/workshop/upgrades.json`, never edited by hand).

## 2. What the data says

All from `data/workshop/upgrades.json` and the harness, not from memory.

- **The Workshop is already built to flatten, and does so early.** A row's price climbs far faster than its gain. Damage: level 10 adds +12.4% for 570 Coins; level 100 adds +1.75% for 81,000 (2.5M Coins in all to reach it); level 500 adds +0.39% for 5.0M a level (770M in all); level 1,000 adds +0.20% for 24M. Health and Defense Absolute fall the same way (Health +18.5% at level 10, +3.8% at 100, +0.55% at 500). **Past about level 100 a row is a slow burn.**
- **Nobody will "finish" it.** Maxing all 48 rows costs about 2.6 × 10²⁰ Coins; two rows alone (the enemy level skips) are 1.2 × 10²⁰ each, and 20 rows cost over a billion apiece. A 1M-Coin build is around level 46 of rows that go to 6,000, and a run earns about 900 Coins there. So "solved" is not a state a player reaches in Tiers 1 to 3. What does arrive is the point where the next Coin buys little.
- **The Tower answers with more sinks at larger scales, not by stopping.** Workshop Enhancements open at 5B Coins and add ×0.01 a level to a row, the last costing 330 quadrillion (400 levels to ×5). Labs multiply a row's increments and raise its maximum (Damage ×3.00 after 50 days of research). Ultimate Weapons cost a separate currency, Power Stones (9,705 for all nine, ~245,000 to max them). Tier Coin bonuses climb from 1.0 to about 103 at Tier 24 so income keeps pace with the sinks.
- **In a run, the shop barely stops mattering** (THE_NUMBER.md 13.3): it adds 25 to 37% of a run's waves even at 1M Coins, because run upgrades stack on Workshop levels. "Strong enough not to need upgrades" will not come from Workshop depth.
- **The peak Number measures the Health row in most strong builds** (THE_NUMBER.md 15). With an empty shop there is nothing to spend the Number on, so it only goes up and the peak finally measures play. That makes the flat Workshop good for the Number's hook at the top and is why the reward question (earned or peak) is separate from this note.

## 3. The principle: each layer has one job, one clock and one relationship to the Number

A layer that just multiplies the same stats again is a second Workshop with a timer. Each layer should answer a different question, spend a different resource or clock, and make the Number go up in its own way.

| Layer | Spends | Job (what it changes) | The Number's part |
|---|---|---|---|
| **Workshop** (built) | Coins | The tower's raw stats, and the Number a run starts with (Health row) | Start size; flattens past about level 100 a row |
| **Run upgrades** (built, D158) | The Number | Stats for this run only | The cost the Number pays to grow stronger |
| **Cards** (built, D146) | Gems, copies | The shape of a run: a few chosen modifiers | Modifies income or defence |
| **Labs** (1.2) | Coins and real time | **How the run economy works:** the shop's prices, free levels at the start, Interest, the Lock. Plus The Tower's own "multiply a Workshop row's increments" Labs, as the sink for Coins past level 100 | Makes the run shop cheaper or unnecessary |
| **Ultimate Weapons** (1.3) | a permanent currency (open, section 6) | **Active and automatic powers** on cooldowns | Powers that bite the Number's threats or pay it |
| **Tiers** (1.4) | Play (clearing the wave) | **The Number's scale:** enemy ×20, ×60 and Coin bonus up | Where the Number runs away, as the owner wants |
| **Workshop II** (later) | Coins at billions and up | Our version of The Tower's Enhancements: the next sink once rows flatten | Multipliers on rows or new rows |

## 4. The handover: each layer should be the best use of the next unit

The rule of thumb is a **sink ladder on a log scale**: roughly one new sink per three orders of magnitude of Coins, opening before the one beneath it stops being worth buying.

| Coins a player has in total | Best use | Open by |
|---|---|---|
| up to about 10⁶ | The first ~100 levels of each Workshop row | The start |
| 10⁶ to 10⁹ | Labs (Coins and real time); row levels past 100 | Tier 1 wave 30 (Labs, The Tower's) |
| 10⁹ to 10¹² | Workshop II multipliers; Lab chains | A late Tier milestone |
| beyond | New rows and Workshop II depth, added as income reaches them | Tiers 4 and up |

Two guards, which a trial can check: **no layer should make the one before it pointless** (Labs that cheapen the run shop to zero would delete run upgrades, which the owner wants optional, not gone), and **income must keep pace with the next sink** (tier Coin bonuses are how The Tower does it, and they are already in the data).

## 5. Our own additions: candidates, not decisions

Each is aimed at a problem measured above. None is built. Where a mechanism already exists in the code it is named.

- **Head Start (a Workshop row or Lab):** a run begins with some levels of run upgrades already bought. **The mechanism exists** (`free_levels`, which never raises a price). It lets a strong build start the way a deep run would end, and it is the cleanest answer to "strong enough not to need the shop".
- **Run Discount (a Lab):** run upgrades cost less, down to a floor, not to zero.
- **Interest depth (a Lab or row):** a bigger Interest cap on the Number. Interest is already on the Number and already capped.
- **Lockpick (a Lab, or a weapon):** a standing Lock lets a share of its held Number through, or dies sooner. This answers the Thorns turtle against the Lock (HANDOVER open decision 5).
- **Number-themed weapons:** a Golden Tower that pays a multiple of kill income for a short while (The Tower has one), a Vault Door that opens a Lock, a Divider Shield. Chosen by what threatens the Number, not copied from the nine.
- **Workshop II:** rows or multipliers that cost Coins at 10⁹ and up, opening when the sink beneath them is spent.

## 6. Open design questions for the owner

1. **Which currency pays for Ultimate Weapons?** The Tower uses Power Stones, a third permanent currency. We have Coins and Gems. A new currency is one more thing to earn, show and explain; Gems are already scarce and spent on Cards and Lab slots. I'd **reuse Gems until the weapons are designed**, and only add a currency if their pricing can't fit.
2. **Do Labs mostly change the run's rules, or mostly multiply Workshop rows?** The Tower's are the second. I'd lead with the first (Head Start, Run Discount, Lockpick) and add the row multipliers as the Coin sink later, so Labs have a job the Workshop can't do.
3. **Where do our own rows live?** The Workshop data is generated from TheTowerSDK and never edited by hand (D068). Our own rows need their own authority, for example a hand-authored `data/workshop/ours.json` that `TowerData` merges, entering the stat stack like any row (AGENTS laws 1 and 3). **This is a foundation gap to settle before the first own row, not before Labs.**
4. **How is the ladder in section 4 sized?** It is a shape, not numbers. The Coins a run earns (about 900 at 1M budget) and the tier bonuses decide where each sink must open; that wants a measurement once Labs exist, not a guess now.

## 7. What this implies for the sequence

1. **Labs (1.2) is the layer that matters next,** and its first catalogue should be the run-economy Labs (Head Start, Run Discount, Interest depth, Lockpick), because they answer the owner's arc and need no new currency.
2. **The Coins-from-the-Number question comes first or alongside** (HANDOVER open decision 1): it decides what a run's reward is worth, which every sink's price is measured against.
3. **Tiers (1.4) do the scaling,** so Workshop II and any new sink can be sized against tier Coin bonuses once Tier 2 exists.
4. **Don't build Workshop II, our own rows or a new currency yet.** They have no consumer (AGENTS law 8) until Labs and a second tier show where the Workshop actually flattens in play.

**Not checked:** how far a real player gets before the Workshop flattens (the measurements here are bots and the price table, and the owner's play is the test that matters); Ultimate Weapons as The Tower balances them (the wiki's numbers are in [TOWER_WORKSHOP_REFERENCE.md](TOWER_WORKSHOP_REFERENCE.md), not played).

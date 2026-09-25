# The Tower's Workshop, row by row

Reference tables for The Tower's permanent upgrades: every Attack, Defense and Utility Workshop row, the Ultimate Weapons, and the late-game Workshop Enhancements. Since [D068](DECISIONS.md#d068--the-towers-workshop-in-full-around-the-number) the game's Workshop is these rows, with every level's value and price taken from TheTowerSDK's table into `data/workshop/upgrades.json` (the wiki's per-100-level tables here agree with it). This page stays the readable reference and the source of the unlock order and prices, which the SDK's table lacks.

**Source:** the community wiki, [Workshop Upgrades](https://the-tower-idle-tower-defense.fandom.com/wiki/Workshop_Upgrades), [Attack Upgrades](https://the-tower-idle-tower-defense.fandom.com/wiki/Attack_Upgrades), [Defense Upgrades](https://the-tower-idle-tower-defense.fandom.com/wiki/Defense_Upgrades), [Utility Upgrades](https://the-tower-idle-tower-defense.fandom.com/wiki/Utility_Upgrades), [Ultimate Weapons](https://the-tower-idle-tower-defense.fandom.com/wiki/Ultimate_Weapons) and each row's own page, read on 24 September 2026. The owner supplied the links. The pages block ordinary automated fetches, so the tables were read through the wiki's MediaWiki API (`api.php?action=parse&page=<Page>&prop=text&format=json`). Wiki figures are community-maintained and can lag the game; the owner's own screens outrank them, as they do for [`TOWER_SCALING_FOUNDATION.md`](TOWER_SCALING_FOUNDATION.md).

Numbers use The Tower's suffixes: K, M, B, T, then q (quadrillion), Q (quintillion), s (sextillion). "Cost" is the Coin price of that level; "total" is Coins spent to reach it.

## What matters for Number Go Up

1. **The Tower prices rows polynomially, not geometrically.** A 99-level row starts at 30–60 Coins and ends near 120K: its price climbs about ×24 over the first 10 levels, then more slowly, roughly with the square of the level (a little steeper). Damage, Health and Defense Absolute grow about as level^2.24 from level 200 to 5,000; Damage and Health then jump about ×5,900 over their last 1,000 levels. Ours grows a fixed 4.2% a rank (×62 over 100 ranks, and ×5,200 by rank 6,000 once D047's 0.075% a rank takes over). So The Tower's early levels are cheap and its prices flatten, while ours start dear and keep compounding. Any repricing should copy that shape rather than a new growth rate.
2. **Rows unlock with Coins in a fixed order, not by Workshop level.** Every tab opens with free rows, then each purchase unlocks the next group: 40 → 100 → 800 → 5K → 1.5M → 1B on Utility, and 50 → 400 → 1,500 → 10K → 100M → 500B on Attack. Ours gates rows by Workshop level (0, 12, 30 and 60). This is the "Coin-gated unlocks" already on the distance step's list.
3. **Most caps already match The Tower's.** Attack Speed ×5.95, Crit Chance 80%, Defense % (our Armor) 49.5–50%, Thorns 99%, Coins per kill ×2.49 (our Coin Bonus ×2.5), Damage 6,000 ranks and Defense Absolute (our Guard) 5,000 ranks all line up. Crit Factor has 150 levels in both, reaching 16.2× there.
4. **Where we differ most:**
   - **Health is a 6,000-level core row** in The Tower, level for level with Damage (Health 21.6K at level 100 against Damage's 1.05K). Our nearest, Cushion, is 150 ranks.
   - **Health Regen is also 6,000 levels**, and we have no counterpart.
   - **Lifesteal tops out at 4.46%** over 80 levels. Our Leech reaches 25% (100 × 0.25%). Before copying, check whether the two count against the same basis.
   - **Utility is mostly Cash:** Cash Bonus, Cash per Wave, Interest and Free Upgrades. The other Utility rows are Coins per Wave, Recovery Packages and Enemy Level Skip. We have none of these. Our Utility tab holds Discount and Knowledge Bonus, which have no Tower counterpart.
5. **Reach and crowd control are the Attack and Defense rows we lack:** Range, Damage/Meter, Multishot Targets, Bounce Shot, Knockback, Orbs, Shockwave, Land Mines and Wall. That is the distance step.
6. **Workshop Enhancements and Ultimate Weapons are late-game.** Enhancements open for 5B Coins and add 1% a level multiplicatively. Ultimate Weapons cost Power Stones, a separate currency. Neither is Tier 1 pacing; they matter only when Labs, Cards and Ultimates get sized.

## Attack

Unlock order: Damage, Attack Speed and Critical Chance/Factor free → Range and Damage/Meter 50 → Multishot 400 → Rapid Fire 1,500 → Bounce Shot 10,000 → Super Crit 100M → Rend Armor 500B.

| Row | Levels | Start → max | Per level | L1 cost | Max-level cost | Total to max |
|---|---|---|---|---|---|---|
| Damage | 6,000 | 6 → 71.11M | grows | 30 | 5.10T | 816.09T |
| Attack Speed | 99 | 1.00 → 5.95 | +0.05 | 30 | 118.80K | 3.60M |
| Critical Chance | 79 | 1% → 80% | +1% | 50 | 59.18K | 1.41M |
| Critical Factor | 150 | 1.2× → 16.2× | +0.1× | 50 | 26.24B | 259.20B |
| Range | 79 | 30m → 69.5m | +0.5m | 50 | 61.40K | 1.46M |
| Damage/Meter | 200 | 0 → 5.9% | shrinks to L70, then +0.0002% | 50 | 28.36T | 315.60T |
| Multishot Chance | 99 | 0 → 49.5% | +0.5% | 60 | 142.00K | 4.26M |
| Multishot Targets | 7 | 2 → 9 | +1 | 450 | 350.00K | 529.95K |
| Rapid Fire Chance (×4 fire) | 85 | 0 → 34% | +0.4% | 120 | 108.05K | 2.79M |
| Rapid Fire Duration | 99 | 0.6s → 5.55s | +0.05s | 120 | 152.79K | 4.63M |
| Bounce Shot Chance | 85 | 0 → 68% | +0.8% | 200 | 125.58K | 3.23M |
| Bounce Shot Targets | 7 | 1 → 8 | +1 | 700 | 650.00K | 970.70K |
| Bounce Shot Range | 60 | 2.0m → 8.0m | +0.1m | 200 | 1.23T | 3.81T |
| Super Crit Chance | 100 | 0 → 20% | +0.2% | 50.00K | 355.49B | 5.63T |
| Super Crit Mult | 120 | 1.2× → 13.2× | +0.1× | 30.00K | 28.70T | 214.50T |
| Rend Armor Chance | 299 | 0.1% → 30% | +0.1% | 600.00M | 19.83q | 418.97q |
| Rend Armor Mult | 299 | 0.001× → 0.3× (stacks to 800%) | +0.001× | 600.00M | 19.83q | 418.97q |

Attack Speed's price curve, as the model for a 99-level row:

| Level | 1 | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 99 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Value | 1.05 | 1.5 | 2.0 | 2.5 | 3.0 | 3.5 | 4.0 | 4.5 | 5.0 | 5.5 | 5.95 |
| Cost | 30 | 725 | 3.11K | 7.56K | 14.33K | 23.61K | 36.62K | 51.80K | 73.47K | 95.81K | 118.80K |
| Total | 0 | 2.94K | 21.70K | 75.43K | 186.28K | 378.51K | 687.05K | 1.13M | 1.77M | 2.62M | 3.60M |

## Defense

Unlock order: Health and Health Regen free → Defense % and Defense Absolute 75 → Thorns 500 → Lifesteal 2,000 → Knockback 5,000 → Orbs 15,000 → Shockwave 100,000 → Land Mines 400,000 → Death Defy 1.5M → Wall 500M.

| Row | Levels | Start → max | Per level | L1 cost | Max-level cost | Total to max |
|---|---|---|---|---|---|---|
| Health | 6,000 | 10 → 6.71B | grows | 30 | 4.68T | 748.26T |
| Health Regen (per second) | 6,000 | 0 → 10.17B | grows | 30 | 388.00B | 74.83T |
| Defense % | 99 | 0 → 49.5% | +0.5% | 50 | 90.73K | 2.77M |
| Defense Absolute | 5,000 | 1 → 80.21M | grows | 50 | 797.45M | 1.23T |
| Thorns (% of enemy max HP, bosses half) | 99 | 0 → 99% | +1% | 60 | 75.55K | 2.33M |
| Lifesteal | 80 | 0 → 4.46% | ≈ +0.056% | 60 | 61.32K | 1.48M |
| Knockback Chance | 80 | 0 → 80% | +1% | 80 | 66.33K | 1.60M |
| Knockback Force | 40 | 0.4 → 6.08 | +0.142 | 80 | 14.01K | 184.33K |
| Orb Speed (turns a minute) | 38 | 0.4 → 6.10 | +0.15 | 125 | 29.73K | 342.98K |
| Orbs | 4 | 0 → 4 | +1 (3K, 20K, 120K, 350K) | 3.00K | 350.00K | 493.00K |
| Shockwave Size | 35 | 0.6 → 2.35 | +0.05 | 250 | 59.60K | 600.13K |
| Shockwave Frequency | 40 | 20s → 14s | −0.15s | 250 | 85.60K | 973.74K |
| Land Mine Chance | 50 | 0 → 30% | +0.6% | 500 | 1.26M | 15.46M |
| Land Mine Damage (% of Damage) | 200 | 100% → 2,100% | +10% | 500 | 217.61T | 2.45q |
| Land Mine Radius | 50 | 0.5 → 1.50 | +0.02 | 500 | 19.82B | 77.52B |
| Death Defy | 75 | 0 → 30% | +0.4% | 1.00K | 110.50M | 1.72B |
| Wall Health (% of Health) | 1,800 | 20% → 200% | +0.1% | 8.00M | 23.48T | 3.21q |
| Wall Rebuild | 300 | 1,200s → 600s | −2s | 16.00M | 923.56B | 40.37T |

Mechanics notes from the same pages:
- **Defence order:** Defense % first, then Defense Absolute, down to zero (100 × (1 − 0.25) − 50 = 25). Defense % is capped at 98% from all sources. Effective HP = (Health + Defense Absolute) / (1 − Defense %).
- **Heat-up:** each hit an enemy lands makes its next ×1.04, as D063 copied.
- **Thorns:** fires without the Tower taking damage, doesn't trigger Lifesteal, and protectors cut it by 60% for enemies in their range.
- **Orbs:** they kill most enemies outright, but not bosses, elites or protected enemies.
- **Knockback:** it weakens at higher waves because enemy mass grows.

## Health, Damage and the other long rows, level by level

| Level | Damage | cost | Health | cost | Health Regen | Defense Absolute | total to reach (all four) |
|---|---|---|---|---|---|---|---|
| 1 | 6 | 30 | 10 | 30 | 0 | 1 | 0 |
| 100 | 1.05K | 80.73K | 21.56K | 77.22K | 269 | 1.02K | 2.4–2.5M |
| 200 | 3.64K | 643.07K | 143.01K | 610.35K | 1.41K | 5.99K | 31–33M |
| 300 | 7.77K | 1.59M | 431.24K | 1.50M | 3.87K | 17.16K | 134–141M |
| 500 | 20.65K | 5.00M | 1.73M | 4.70M | 17.68K | 74.22K | 723–767M |
| 1,000 | 79.80K | 23.60M | 11.44M | 22.03M | 1.12M | 538.72K | 6.8–7.3B |
| 2,000 | 521.19K | 111.49M | 75.44M | 103.33M | 23.32M | 3.65M | 64–69B |
| 3,000 | 2.34M | 276.51M | 227.37M | 255.24M | 98.77M | 12.92M | 237–256B |
| 4,000 | 8.85M | 526.73M | 497.34M | 484.82M | 256.36M | 36.44M | 600–651B |
| 5,000 | 29.05M | 868.32M | 912.65M | 797.45M | 523.23M | 80.21M (max) | 1.23–1.34T |
| 6,000 | 71.11M | 5.10T | 6.71B | 4.68T | 10.17B | — | 75–816T |

Health, Health Regen and Defense Absolute share one price curve to level 5,000, and Damage's runs 5–9% dearer. Health outgrows Damage throughout: ×20 at level 100, ×140 at 1,000 and ×94 at 6,000. Health Regen's final level costs 388B against Health's 4.68T, so its total is a tenth.

## Utility

Unlock order: Cash Bonus and Cash/Wave 40 → Coins/Kill and Coins/Wave 100 → Free Upgrades 800 → Interest 5,000 → Recovery Packages 1.5M → Enemy Level Skip 1B.

| Row | Levels | Start → max | Per level | L1 cost | Max-level cost | Total to max |
|---|---|---|---|---|---|---|
| Cash Bonus | 149 | 1.00× → 2.49× | +0.01× | 30 | 352.36K | 14.82M |
| Cash per Wave | 149 | 0 → 596 | +4 | 30 | 352.36K | 14.82M |
| Coins per Kill Bonus | 149 | 1.00× → 2.49× | +0.01× | 50 | 467.98K | 19.47M |
| Coins per Wave | 149 | 1 → 150 | +1 | 50 | 467.98K | 19.47M |
| Free Attack / Defense / Utility Upgrade (chance a wave) | 99 each | 0 → 49.5% | +0.5% | 75 / 75 / 100 | 133.9K | 4.05M |
| Interest per Wave (on Cash held, capped at $50 before Labs) | 99 | 0 → 5.94% | +0.06% | 125 | 252.47K | 7.36M |
| Recovery Amount (% of max Health a package) | 300 | 14% → 134% | +0.4% | 1.00K | 21.59B | 1.33T |
| Max Recovery (overheal ceiling) | 500 | 1.0× → 16.5× | +0.031× | 1.00K | 151.17B | 15.77T |
| Package Chance (a wave) | 60 | 6% → 30% | +0.4% | 1.00K | 25.40M | 321.28M |
| Enemy Attack / Health Level Skip | 699 each | 0 → 35% | +0.05% | 300.00M | 4.56Q | 123.43Q |

Notes:
- **Cash per Wave** is paid after the wave's gap and before Interest. Interest is (Cash held + Cash per Wave × Cash Bonus) × Interest %.
- **Free Upgrades** never pick a maxed row.
- **Enemy Level Skip** has been deterministic since V26: 50% skips every other wave.
- **Coins per kill** multiplies with every other kill bonus, such as the tier bonus.

## Ultimate Weapons

These are bought with Power Stones, not Coins. The first costs 5 Stones, then 50, 150, 300, 800, 1,250, 1,750, 2,400 and 3,000 (9,705 for all nine). Each offer is three at random. Each weapon has three stats, upgraded with Stones, and fires on its own cooldown.

| Weapon | Stat 1 (min → max) | Stat 2 | Stat 3 | Stones to max all three |
|---|---|---|---|---|
| Chain Lightning | Damage ×2 → ×7,961 | Quantity 1 → 5 | Chance 5% → 27.5% | 18,375 |
| Smart Missiles | Damage ×10 → ×3,021 | Quantity 5 → 20 | Cooldown 180s → 20s | 39,177 |
| Death Wave | Damage ×2 → ×9,119 | Effect waves 1 → 5 | Cooldown 300s → 50s | 29,391 |
| Chrono Field (slow) | Duration 5s → 40s | Slow 20% → 75% | Cooldown 180s → 60s | 9,946 |
| Inner Land Mines | Damage ×10 → ×3,021 | Quantity 3 → 6 | Cooldown 200s → 50s | 23,042 |
| Golden Tower (Cash and Coins from kills) | Bonus ×5 → ×21 | Duration 15s → 53s | Cooldown 300s → 100s | 27,186 |
| Poison Swamp | Damage ×10 → ×3,021 a second | Duration 30s → 100s | Cooldown 125s → 50s | 34,226 |
| Black Hole | Size 30m → 70m | Duration 15s → 38s | Cooldown 200s → 50s | 9,723 |
| Spotlight (damage bonus in a beam) | Bonus ×8 → ×43 | Angle 30° → 90° | Quantity 1 → 4 | 53,486 |

UW damage = its multiplier × Damage × (1 + Crit Factor × Crit Chance) × (1 + Super Crit Mult × Super Crit Chance × Crit Chance).

Once all nine are owned, Ultimate Weapon Plus abilities open (500 to 3,800 Stones each, ten levels). Each weapon's own page also lists Lab research that extends it, unlocked by tier milestones.

## Workshop Enhancements (late game)

Enhancements unlock after research costing 5B Coins (6d 16h). Each row starts at ×1.00 and adds ×0.01 a level:
- **Most rows:** 400 levels to ×5, at 5B Coins for the first and 330.80Q for the last (15.29s in all). These are Damage, Rend Armor, Critical Factor, Damage/Meter, Super Crit Mult, Health, Health Regen, Defense Absolute, Wall Health and Cash Bonus.
- **Land Mine Damage:** ×0.06 a level instead, reaching ×25.
- **Shorter rows:** Orb Size (200 levels to ×3), Coin Bonus (200 to ×3; it also multiplies the tier bonus, so it counts twice), Free Upgrades (100 to ×2), Packages (300 to ×4) and Enemy Level Skips (60 to ×1.6).
- **Unlock thresholds:** later Defense and Utility enhancements open only once a set amount has been spent in their group, from 50B up to 500T Coins.

## Labs

Labs multiply a Workshop row's increments and raise its maximum. For example, the Damage lab reaches ×3.00 at level 100 after 50 days, and the Health, Health Regen and Defense Absolute labs reach ×4.00. Most are unlocked by tier milestones (Cash, Coins/Kill and Coins/Wave labs at Tier 1 wave 30). Timings and costs for each are on the row pages; they matter when Labs are sized, which is still an open question in [`HANDOVER.md`](HANDOVER.md).

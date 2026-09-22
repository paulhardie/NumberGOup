# Tower Lab inventory — 22 September 2026

**Status:** Working evidence matrix for [COMPARISON DOC](COMPARISON_DOC.md). It covers every *named* research record in this public snapshot; it is not a decision to add Labs or any listed effect to Number Go Up.

## Coverage and source boundary

- **Reference build:** The Tower v29.0.3, as anchored in [the official v29 notes](https://www.techtreegames.com/post/v29-patch-notes-august-25-2026).
- **Inventory data:** the community-maintained [TheTowerSDK research table](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/data/generated/labs-research.generated.ts), [game-UI category map](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/data/generated/labs-categories.generated.ts) and [cost/time catalogue](https://github.com/TmRxJD/TheTowerSDK/blob/main/src/data/labs/catalog.data.ts), checked 22 September 2026.
- **Coverage result:** 233 named research records. The generated research table has 260 index slots and the UI map describes 253 research slots; the remaining slots are unnamed placeholders in this snapshot, not silently omitted Labs.
- **Cost/time result:** 227 named records resolve to a published cost/time curve (including legacy-key aliases); 6 do not. A missing curve is an evidence gap, never a free or zero-duration Lab.
- **Boundary:** the source is community-maintained and version-sensitive. The status in this table is a Number Go Up design reading, not a claim that Tower values are authoritative.

### Cost/time evidence gaps

The following named lines appear in the generated research table but have no matching curve in the public catalogue after alias reconciliation. They remain in the inventory, but their detailed cost/duration, queue and acceleration behaviour must be cross-checked before they inform any progression decision.

| Index | Lab | Product relevance |
| ---: | --- | --- |
| 86 | First Trade-off Choice | A structural Perk candidate; its missing curve must not affect the decision about whether a choice layer is useful. |
| 99 | Black Hole ignore Protector | Tower-specific Ultimate content; not a Number Go Up effect candidate. |
| 135 | Cannon Stats | Module/loot system content; excluded unless a later deterministic loadout earns a separate proposal. |
| 136 | Armor Stats | Module/loot system content; excluded unless a later deterministic loadout earns a separate proposal. |
| 137 | Generator Stats | Module/loot system content; excluded unless a later deterministic loadout earns a separate proposal. |
| 138 | Core Stats | Module/loot system content; excluded unless a later deterministic loadout earns a separate proposal. |

### Provisional readings

| Key | Meaning |
| --- | --- |
| B | Build-around candidate: retain the player problem, create original Number Go Up gameplay later. |
| L | Later: only consider after its prerequisite system has proved useful. |
| R | Research-engine prerequisite: meaningful only if timed research is deliberately chosen. |
| S | Already solved by Number Go Up; do not add a duplicate. |
| X | Exclude direct content: Tower-specific combat, a deferred live-service system or passive-multiplier noise. |

## Complete named Lab inventory

Each row records the source identity, maximum level, unlock boundary and the initial product reading. Present means the companion public catalogue has a cost/time curve for that Lab; it does **not** endorse its price, duration or acceleration model.

### Attack (9)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 0 | Damage (<code>damage</code>) | 100 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 1 | Attack Speed (<code>attack_speed</code>) | 99 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 2 | Critical Factor (<code>critical_factor</code>) | 99 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 3 | Range (<code>range</code>) | 80 | T2 / M2 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 4 | Damage / Meter (<code>damage_meter</code>) | 99 | T3 / M2 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 5 | Super Crit Chance (<code>super_crit_chance</code>) | 50 | T5 / M11 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 6 | Super Crit Mult (<code>super_crit_mult</code>) | 40 | T5 / M11 | Present — legacy key | X — direct Tower combat or passive stat; no direct transplant |
| 131 | Max Rend Armor Multiplier (<code>max_rend_armor_multiplier</code>) | 30 | T13 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 132 | Light Speed Shots (<code>light_speed_shots</code>) | 1 | T7 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |

### Battle Condition (Durations/Reductions) (4)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 206 | Ultimate Weapon Durations (<code>ultimate_weapon_durations</code>) | 10 | T21 / M17 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 207 | Death Defy Down (<code>death_defy_down</code>) | 10 | T21 / M17 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 208 | Energy Shields Down (<code>energy_shields_down</code>) | 10 | T21 / M17 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 209 | Enemy Level Skip Reduction (<code>enemy_level_skip_reduction</code>) | 10 | T21 / M17 | Present | B — optional non-spatial restriction through the modifier pipeline |

### Battle Condition (Enemy Ultimates) (6)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 210 | Fast's Ultimate (<code>fasts_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 211 | Ranged Ultimate (<code>ranged_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 212 | Boss's Ultimate (<code>bosss_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 213 | Basic's Ultimate (<code>basics_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 214 | Tank's Ultimate (<code>tanks_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 215 | Protector's Ultimate (<code>protectors_ultimate</code>) | 10 | T19 / M15 | Present | B — optional non-spatial restriction through the modifier pipeline |

### Battle Condition (Enemy/Spawn Buffs) (4)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 216 | Armored Enemies (<code>armored_enemies</code>) | 20 | T20 / M5 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 217 | Enemy Speed (<code>enemy_speed</code>) | 20 | T20 / M5 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 218 | More Enemies (<code>more_enemies</code>) | 20 | T20 / M5 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 219 | Enemy Attack Speed (<code>enemy_attack_speed</code>) | 20 | T20 / M5 | Present | B — optional non-spatial restriction through the modifier pipeline |

### Battle Condition (Resistances) (5)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 201 | Knockback Resistance (<code>knockback_resistance</code>) | 20 | T19 / M9 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 202 | Thorns Resistance (<code>thorns_resistance</code>) | 20 | T19 / M9 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 203 | Orb Resistance (<code>orb_resistance</code>) | 20 | T19 / M9 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 204 | Plasma Cannon Resistance (<code>plasma_cannon_resistance</code>) | 20 | T19 / M9 | Present | B — optional non-spatial restriction through the modifier pipeline |
| 205 | Death Ray Resistance (<code>death_ray_resistance</code>) | 20 | T19 / M9 | Present | B — optional non-spatial restriction through the modifier pipeline |

### Bots (10)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 102 | Flame Bot - Cooldown (<code>flame_bot_cooldown</code>) | 25 | T5 / M5 | Present | L — automate solved repetition; no Tower bot |
| 103 | Thunder Bot - Cooldown (<code>thunder_bot_cooldown</code>) | 25 | T5 / M6 | Present | L — automate solved repetition; no Tower bot |
| 104 | Golden Bot - Cooldown (<code>golden_bot_cooldown</code>) | 25 | T5 / M7 | Present — legacy key | L — automate solved repetition; no Tower bot |
| 105 | Amplify Bot - Cooldown (<code>amplify_bot_cooldown</code>) | 25 | T5 / M8 | Present — legacy key | L — automate solved repetition; no Tower bot |
| 106 | Flame Bot - Burn Stack (<code>flame_bot_burn_stack</code>) | 5 | T10 / M4 | Present | L — automate solved repetition; no Tower bot |
| 107 | Thunder Bot - Linger Time (<code>thunder_bot_linger_time</code>) | 20 | T10 / M4 | Present | L — automate solved repetition; no Tower bot |
| 108 | Golden Bot - Duration (<code>golden_bot_duration</code>) | 20 | T10 / M4 | Present — legacy key | L — automate solved repetition; no Tower bot |
| 109 | Amplify Bot - Duration (<code>amplify_bot_duration</code>) | 20 | T10 / M4 | Present — legacy key | L — automate solved repetition; no Tower bot |
| 228 | Bot Bot - Cooldown (<code>bot_bot_cooldown</code>) | 25 | T6 / M5 | Present | L — automate solved repetition; no Tower bot |
| 229 | Bot Bot - Duration (<code>bot_bot_duration</code>) | 20 | T10 / M4 | Present | L — automate solved repetition; no Tower bot |

### Card Mastery (32)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 160 | Damage Mastery (<code>damage_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 161 | Attack Speed Mastery (<code>attack_speed_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 162 | Health Mastery (<code>health_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 163 | Health Regen Mastery (<code>health_regen_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 164 | Range Mastery (<code>range_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 165 | Cash Mastery (<code>cash_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 166 | Coins Mastery (<code>coins_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 167 | Slow Aura Mastery (<code>slow_aura_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 168 | Critical Chance Mastery (<code>critical_chance_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 169 | Enemy Balance Mastery (<code>enemy_balance_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 170 | Extra Defense Mastery (<code>extra_defense_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 171 | Fortress Mastery (<code>fortress_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 172 | Free Upgrades Mastery (<code>free_upgrades_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 173 | Extra Orb Mastery (<code>extra_orb_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 174 | Plasma Cannon Mastery (<code>plasma_cannon_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 175 | Critical Coin Mastery (<code>critical_coin_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 176 | Wave Skip Mastery (<code>wave_skip_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 177 | Intro Sprint Mastery (<code>intro_sprint_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 178 | Land Mine Stun Mastery (<code>land_mine_stun_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 179 | Recovery Package Mastery (<code>recovery_package_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 180 | Death Ray Mastery (<code>death_ray_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 181 | Energy Net Mastery (<code>energy_net_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 182 | Super Tower Mastery (<code>super_tower_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 183 | Second Wind Mastery (<code>second_wind_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 184 | Demon Mode Mastery (<code>demon_mode_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 185 | Energy Shield Mastery (<code>energy_shield_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 186 | Wave Accelerator Mastery (<code>wave_accelerator_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 187 | Berserker Mastery (<code>berserker_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 188 | Ultimate Crit Mastery (<code>ultimate_crit_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 189 | Nuke Mastery (<code>nuke_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 200 | Area of Effect Mastery (<code>area_of_effect_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |
| 251 | Cells Mastery (<code>cells_mastery</code>) | 9 | T0 / M0 | Present | L — long-term loadout depth only after original loadouts prove useful |

### Cards (10)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 70 | Second Wind Blast (<code>second_wind_blast</code>) | 4 | T3 / M10 | Present | L — configured-power role after an original loadout exists |
| 71 | Double Death Ray (<code>double_death_ray</code>) | 30 | T3 / M13 | Present | L — configured-power role after an original loadout exists |
| 72 | Extra Orb Adjuster (<code>extra_orb_adjuster</code>) | 1 | T6 / M4 | Present | L — configured-power role after an original loadout exists |
| 73 | Extra Extra Orbs (<code>extra_extra_orbs</code>) | 2 | T6 / M7 | Present | L — configured-power role after an original loadout exists |
| 74 | Energy Shield Extra Hit (<code>energy_shield_extra_hit</code>) | 2 | T4 / M13 | Present | L — configured-power role after an original loadout exists |
| 75 | Super Tower Bonus (<code>super_tower_bonus</code>) | 30 | T8 / M13 | Present | L — configured-power role after an original loadout exists |
| 145 | Recharge Second Wind (<code>recharge_second_wind</code>) | 7 | T14 / M5 | Present | L — configured-power role after an original loadout exists |
| 146 | Recharge Demon Mode (<code>recharge_demon_mode</code>) | 7 | T14 / M5 | Present | L — configured-power role after an original loadout exists |
| 149 | Recharge Nuke (<code>recharge_nuke</code>) | 7 | T14 / M5 | Present | L — configured-power role after an original loadout exists |
| 250 | Recharge Bastion (<code>recharge_bastion</code>) | 7 | T14 / M5 | Present | L — configured-power role after an original loadout exists |

### Defense (16)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 10 | Health (<code>health</code>) | 100 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 11 | Health Regen (<code>health_regen</code>) | 100 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 12 | Defense Absolute (<code>defense_absolute</code>) | 100 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 13 | Defense % (<code>defense</code>) | 50 | T5 / M2 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 14 | Orbs Speed (<code>orbs_speed</code>) | 20 | T3 / M7 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 15 | Land Mine Damage (<code>land_mine_damage</code>) | 20 | T6 / M2 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 16 | Land Mine Decay (<code>land_mine_decay</code>) | 35 | T6 / M2 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 17 | Shockwave Size (<code>shockwave_size</code>) | 20 | T3 / M4 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 18 | Orbs Boss Hit (<code>orbs_boss_hit</code>) | 10 | T6 / M16 | Present — legacy key | X — direct Tower combat or passive stat; no direct transplant |
| 126 | Wall Health (<code>wall_health</code>) | 50 | T8 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 127 | Wall Rebuild (<code>wall_rebuild</code>) | 20 | T8 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 128 | Wall Regen (<code>wall_regen</code>) | 30 | T10 / M6 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 129 | Wall Thorns (<code>wall_thorns</code>) | 20 | T10 / M6 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 130 | Wall Invincibility (<code>wall_invincibility</code>) | 10 | T12 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 144 | Wall Fortification (<code>wall_fortification</code>) | 60 | T14 / M3 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 193 | Garlic Thorns (<code>garlic_thorns</code>) | 10 | T2 / M17 | Present | X — direct Tower combat or passive stat; no direct transplant |

### Enemies (28)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 110 | Basic Enemy Health (<code>basic_enemy_health</code>) | 30 | T9 / M0 | Present — legacy key | B — tier-condition lesson only; no enemy stat transplant |
| 111 | Basic Enemy Attack (<code>basic_enemy_attack</code>) | 30 | T9 / M0 | Present — legacy key | B — tier-condition lesson only; no enemy stat transplant |
| 112 | Fast Enemy Health (<code>fast_enemy_health</code>) | 30 | T9 / M1 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 113 | Fast Enemy Attack (<code>fast_enemy_attack</code>) | 30 | T9 / M1 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 114 | Fast Enemy Speed (<code>fast_enemy_speed</code>) | 30 | T9 / M13 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 115 | Tank Enemy Health (<code>tank_enemy_health</code>) | 30 | T9 / M2 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 116 | Tank Enemy Attack (<code>tank_enemy_attack</code>) | 30 | T9 / M2 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 117 | Ranged Enemy Health (<code>ranged_enemy_health</code>) | 30 | T9 / M3 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 118 | Ranged Enemy Attack (<code>ranged_enemy_attack</code>) | 30 | T9 / M3 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 119 | Boss Health (<code>boss_health</code>) | 30 | T9 / M4 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 120 | Boss Attack (<code>boss_attack</code>) | 30 | T9 / M4 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 121 | Protector Health (<code>protector_health</code>) | 30 | T9 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 122 | Protector Radius (<code>protector_radius</code>) | 30 | T9 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 123 | Protector Damage Reduction (<code>protector_damage_reduction</code>) | 20 | T9 / M14 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 220 | Ray Enemy Attack (<code>ray_enemy_attack</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 221 | Ray Enemy Health (<code>ray_enemy_health</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 222 | Vampire Enemy Attack (<code>vampire_enemy_attack</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 223 | Vampire Enemy Health (<code>vampire_enemy_health</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 224 | Scatter Enemy Attack (<code>scatter_enemy_attack</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 225 | Scatter Enemy Health (<code>scatter_enemy_health</code>) | 30 | T19 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 226 | Ranged Enemy Range (<code>ranged_enemy_range</code>) | 30 | T13 / M7 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 242 | Overcharge Enemy Health (<code>overcharge_enemy_health</code>) | 30 | T23 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 243 | Overcharge Enemy Damage (<code>overcharge_enemy_damage</code>) | 30 | T23 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 244 | Commander Enemy Health (<code>commander_enemy_health</code>) | 30 | T23 / M4 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 245 | Saboteur Enemy Health (<code>saboteur_enemy_health</code>) | 30 | T23 / M3 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 246 | Overcharge Exponent Reducer (<code>overcharge_exponent_reducer</code>) | 30 | T23 / M5 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 247 | Commander Radius (<code>commander_radius</code>) | 30 | T23 / M4 | Present | B — tier-condition lesson only; no enemy stat transplant |
| 248 | Saboteur Attack Speed (<code>saboteur_attack_speed</code>) | 30 | T23 / M3 | Present | B — tier-condition lesson only; no enemy stat transplant |

### Main (23)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 30 | Game Speed (<code>game_speed</code>) | 7 | T0 / M0 | Present | L — pacing quality only; never offline growth |
| 31 | Starting Cash (<code>starting_cash</code>) | 99 | T0 / M0 | Present | X — Tower-specific system or duplicate multiplier |
| 32 | Workshop Attack Discount (<code>workshop_attack_discount</code>) | 99 | T2 / M3 | Present | X — Tower-specific system or duplicate multiplier |
| 33 | Workshop Defense Discount (<code>workshop_defense_discount</code>) | 99 | T2 / M4 | Present | X — Tower-specific system or duplicate multiplier |
| 34 | Workshop Utility Discount (<code>workshop_utility_discount</code>) | 99 | T2 / M5 | Present | X — Tower-specific system or duplicate multiplier |
| 35 | Labs Coin Discount (<code>labs_coin_discount</code>) | 99 | T0 / M0 | Present | R — research-engine prerequisite only |
| 36 | Labs Speed (<code>labs_speed</code>) | 99 | T1 / M10 | Present | R — research-engine prerequisite only |
| 37 | Buy Multiplier (<code>buy_multiplier</code>) | 4 | T2 / M1 | Present | S — bulk purchase already exists |
| 38 | More Round Stats (<code>more_round_stats</code>) | 1 | T1 / M12 | Present | B — richer run history and explanation |
| 39 | Target Priority (<code>target_priority</code>) | 2 | T4 / M10 | Present | X — Tower-specific system or duplicate multiplier |
| 40 | Card Presets (<code>card_presets</code>) | 1 | T1 / M14 | Present | L — presets only when a real loadout exists |
| 41 | Workshop Respec (<code>workshop_respec</code>) | 1 | T4 / M2 | Present | L — respec only after a meaningful irreversible build |
| 148 | Reroll Daily Mission (<code>reroll_daily_mission</code>) | 1 | T4 / M2 | Present | X — dailies are deferred |
| 150 | Workshop Enhancements (<code>workshop_enhancements</code>) | 1 | T12 / M5 | Present | X — duplicate enhancement layer |
| 154 | Enhancement Attack - Coin Discount (<code>enhancement_attack_coin_discount</code>) | 100 | T21 / M5 | Present | X — Tower enhancement discount |
| 155 | Enhancement Defense - Coin Discount (<code>enhancement_defense_coin_discount</code>) | 100 | T21 / M5 | Present | X — Tower enhancement discount |
| 199 | Battle Condition Reduction (<code>battle_condition_reduction</code>) | 10 | T18 / M17 | Present | X — Tower-specific system or duplicate multiplier |
| 227 | Enhancement Utility - Coin Discount (<code>enhancement_utility_coin_discount</code>) | 100 | T21 / M5 | Present | X — Tower enhancement discount |
| 238 | Dissonant Echo - Utility (<code>dissonant_echo_utility</code>) | 20 | T17 / M5 | Present | B — non-spatial challenge condition later |
| 239 | Dissonant Echo - Attack (<code>dissonant_echo_attack</code>) | 20 | T17 / M5 | Present | B — non-spatial challenge condition later |
| 240 | Dissonant Echo - Defense (<code>dissonant_echo_defense</code>) | 20 | T17 / M5 | Present | B — non-spatial challenge condition later |
| 241 | Dissonant Echo - Ultimate Weapons (<code>dissonant_echo_ultimate_weapons</code>) | 20 | T17 / M5 | Present | B — non-spatial challenge condition later |
| 252 | Global Presets (<code>global_presets</code>) | 1 | T11 / M5 | Present | L — global presets after multiple real builds |

### Modules (24)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 134 | Common Drop Chance (<code>common_drop_chance</code>) | 10 | T4 / M6 | Present | L — deterministic loadout role only; never Tower loot |
| 135 | Cannon Stats (<code>cannon_stats</code>) | 50 | T0 / M0 | Missing | L — deterministic loadout role only; never Tower loot |
| 136 | Armor Stats (<code>armor_stats</code>) | 50 | T0 / M0 | Missing | L — deterministic loadout role only; never Tower loot |
| 137 | Generator Stats (<code>generator_stats</code>) | 50 | T0 / M0 | Missing | L — deterministic loadout role only; never Tower loot |
| 138 | Core Stats (<code>core_stats</code>) | 50 | T0 / M0 | Missing | L — deterministic loadout role only; never Tower loot |
| 139 | Reroll Shards (<code>reroll_shards</code>) | 100 | T4 / M6 | Present | L — deterministic loadout role only; never Tower loot |
| 140 | Daily Mission Shards (<code>daily_mission_shards</code>) | 50 | T4 / M6 | Present | L — deterministic loadout role only; never Tower loot |
| 141 | Module Shard Cost (<code>module_shard_cost</code>) | 30 | T10 / M3 | Present — legacy key | L — deterministic loadout role only; never Tower loot |
| 142 | Module Coin Cost (<code>module_coin_cost</code>) | 30 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 143 | Rare Drop Chance (<code>rare_drop_chance</code>) | 10 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 151 | Unmerge Module (<code>unmerge_module</code>) | 1 | T8 / M1 | Present | L — deterministic loadout role only; never Tower loot |
| 152 | Shatter Shards (<code>shatter_shards</code>) | 5 | T16 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 194 | Cannon Effect Bans (<code>cannon_effect_bans</code>) | 4 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 195 | Armor Effect Bans (<code>armor_effect_bans</code>) | 4 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 196 | Generator Effect Bans (<code>generator_effect_bans</code>) | 3 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 197 | Core Effect Bans (<code>core_effect_bans</code>) | 7 | T10 / M3 | Present | L — deterministic loadout role only; never Tower loot |
| 230 | Assist Module Substats - Cannon (<code>assist_module_substats_cannon</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 231 | Assist Module Substats - Armor (<code>assist_module_substats_armor</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 232 | Assist Module Substats - Generator (<code>assist_module_substats_generator</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 233 | Assist Module Substats - Core (<code>assist_module_substats_core</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 234 | Assist Module Bonus - Cannon (<code>assist_module_bonus_cannon</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 235 | Assist Module Bonus - Armor (<code>assist_module_bonus_armor</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 236 | Assist Module Bonus - Generator (<code>assist_module_bonus_generator</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |
| 237 | Assist Module Bonus - Core (<code>assist_module_bonus_core</code>) | 30 | T19 / M4 | Present | L — deterministic loadout role only; never Tower loot |

### Perks (10)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 80 | Unlock Perks (<code>unlock_perks</code>) | 1 | T2 / M10 | Present | B — offer, ban or choice structure after the Rig is understood |
| 81 | Waves Required (<code>waves_required</code>) | 100 | T0 / M0 | Present | B — offer, ban or choice structure after the Rig is understood |
| 82 | Auto Pick Perks (<code>auto_pick_perks</code>) | 1 | T4 / M4 | Present | B — offer, ban or choice structure after the Rig is understood |
| 83 | Standard Perks Bonus (<code>standard_perks_bonus</code>) | 25 | T0 / M0 | Present | B — offer, ban or choice structure after the Rig is understood |
| 84 | Perk Option Quantity (<code>perk_option_quantity</code>) | 2 | T4 / M7 | Present | B — offer, ban or choice structure after the Rig is understood |
| 85 | First Perk Choice (<code>first_perk_choice</code>) | 1 | T2 / M12 | Present | B — offer, ban or choice structure after the Rig is understood |
| 86 | First Trade-off Choice (<code>first_trade_off_choice</code>) | 1 | T2 / M13 | Missing | B — offer, ban or choice structure after the Rig is understood |
| 87 | Ban Perks (<code>ban_perks</code>) | 8 | T5 / M3 | Present | B — offer, ban or choice structure after the Rig is understood |
| 88 | Improve Trade-off Perks (<code>improve_trade_off_perks</code>) | 10 | T2 / M14 | Present | B — offer, ban or choice structure after the Rig is understood |
| 153 | Auto Pick Ranking (<code>auto_pick_ranking</code>) | 32 | T6 / M0 | Present | B — offer, ban or choice structure after the Rig is understood |

### Ultimate Weapon (40)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 50 | Missiles Despawn Time (<code>missiles_despawn_time</code>) | 20 | T7 / M2 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 51 | Missiles Explosion (<code>missiles_explosion</code>) | 1 | T7 / M2 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 52 | Missiles Radius (<code>missiles_radius</code>) | 20 | T0 / M0 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 53 | Chrono Field Duration (<code>chrono_field_duration</code>) | 30 | T7 / M8 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 54 | Chrono Field Damage Reduction (<code>chrono_field_damage_reduction</code>) | 1 | T7 / M8 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 55 | Chrono Field Reduction % (<code>chrono_field_reduction</code>) | 30 | T0 / M0 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 56 | Swamp Radius (<code>swamp_radius</code>) | 30 | T7 / M4 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 57 | Swamp Stun (<code>swamp_stun</code>) | 1 | T7 / M4 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 58 | Swamp Stun Chance (<code>swamp_stun_chance</code>) | 30 | T0 / M0 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 59 | Swamp Stun Time (<code>swamp_stun_time</code>) | 30 | T0 / M0 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 60 | Golden Tower Bonus (<code>golden_tower_bonus</code>) | 25 | T4 / M11 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 61 | Golden Tower Duration (<code>golden_tower_duration</code>) | 20 | T4 / M11 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 62 | Chain Lightning Shock (<code>chain_lightning_shock</code>) | 1 | T7 / M5 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 63 | Shock Chance (<code>shock_chance</code>) | 30 | T0 / M0 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 64 | Shock Multiplier (<code>shock_multiplier</code>) | 14 | T0 / M0 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 65 | Death Wave Health (<code>death_wave_health</code>) | 30 | T3 / M12 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 66 | Death Wave Coin Bonus (<code>death_wave_coin_bonus</code>) | 20 | T3 / M12 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 67 | Inner Mine Blast Radius (<code>inner_mine_blast_radius</code>) | 20 | T7 / M3 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 68 | Inner Mine Rotation Speed (<code>inner_mine_rotation_speed</code>) | 20 | T7 / M3 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 69 | Chrono Field Range (<code>chrono_field_range</code>) | 20 | T7 / M8 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 90 | Missile Amplifier (<code>missile_amplifier</code>) | 25 | T7 / M2 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 91 | Missile Barrage (<code>missile_barrage</code>) | 1 | T8 / M4 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 92 | Missile Barrage Quantity (<code>missile_barrage_quantity</code>) | 6 | T0 / M0 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 93 | Inner Mine Stun (<code>inner_mine_stun</code>) | 1 | T7 / M3 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 94 | Black Hole Damage (<code>black_hole_damage</code>) | 10 | T5 / M10 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 95 | Extra Black Hole (<code>extra_black_hole</code>) | 1 | T5 / M15 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 96 | Black Hole Coin Bonus (<code>black_hole_coin_bonus</code>) | 20 | T5 / M10 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 97 | Spotlight Coin Bonus (<code>spotlight_coin_bonus</code>) | 20 | T7 / M7 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 98 | Spotlight Missiles (<code>spotlight_missiles</code>) | 18 | T3 / M14 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 99 | Black Hole ignore Protector (<code>black_hole_ignore_protector</code>) | 1 | T5 / M13 | Missing | B — original Ultimate modifier after the four Ultimates exist |
| 133 | Black Hole disable Ranged Enemies (<code>black_hole_disable_ranged_enemies</code>) | 1 | T14 / M1 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 147 | Recharge Missile Barrage (<code>recharge_missile_barrage</code>) | 7 | T14 / M5 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 156 | Swamp Rend - Basic Enemies (<code>swamp_rend_basic_enemies</code>) | 30 | T16 / M4 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 157 | Swamp Rend - Additional Enemies (<code>swamp_rend_additional_enemies</code>) | 11 | T16 / M4 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 158 | Chain Thunder (<code>chain_thunder</code>) | 30 | T16 / M5 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 159 | Lightning Amplifier - Scatter (<code>lightning_amplifier_scatter</code>) | 30 | T16 / M5 | Present — legacy key | B — original Ultimate modifier after the four Ultimates exist |
| 190 | Death Wave Cells Bonus (<code>death_wave_cells_bonus</code>) | 20 | T3 / M12 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 191 | Death Wave Damage Amplifier (<code>death_wave_damage_amplifier</code>) | 30 | T3 / M12 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 192 | Death Wave Armor Stripping (<code>death_wave_armor_stripping</code>) | 10 | T3 / M12 | Present | B — original Ultimate modifier after the four Ultimates exist |
| 198 | Inner Land Mine - Chrono Jump (<code>inner_land_mine_chrono_jump</code>) | 10 | T7 / M3 | Present | B — original Ultimate modifier after the four Ultimates exist |

### Utility (12)

| Index | Tower Lab | Max | Unlock | Curve | Provisional Number Go Up reading |
| ---: | --- | ---: | --- | --- | --- |
| 19 | Recovery Package Amount (<code>recovery_package_amount</code>) | 20 | T6 / M10 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 20 | Cash Bonus (<code>cash_bonus</code>) | 99 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 21 | Cash / Wave (<code>cash_wave</code>) | 99 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 22 | Coins / Kill Bonus (<code>coins_kill_bonus</code>) | 99 | T0 / M0 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 23 | Coins / Wave (<code>coins_wave</code>) | 99 | T0 / M0 | Present — legacy key | X — direct Tower combat or passive stat; no direct transplant |
| 24 | Interest (<code>interest</code>) | 99 | T2 / M7 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 25 | Max Interest (<code>max_interest</code>) | 15 | T2 / M7 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 26 | Package After Boss (<code>package_after_boss</code>) | 1 | T3 / M11 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 100 | Recovery Package Max (<code>recovery_package_max</code>) | 20 | T6 / M10 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 101 | Recovery Package Chance (<code>recovery_package_chance</code>) | 20 | T6 / M10 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 124 | Enemy Attack Level Skip (<code>enemy_attack_level_skip</code>) | 20 | T11 / M11 | Present | X — direct Tower combat or passive stat; no direct transplant |
| 125 | Enemy Health Level Skip (<code>enemy_health_level_skip</code>) | 20 | T11 / M11 | Present | X — direct Tower combat or passive stat; no direct transplant |

## What the full pass makes available

- **Most transferable evidence is about structure, not combat coefficients:** Perk choice controls, challenge restrictions, ability-specific modifiers, player-facing history and future configuration presets each solve a player problem that Number Go Up may eventually have.
- **The strongest current fit is not a timed-Lab clone:** the existing Rig and four original Ultimates need to be playable first. Only then can original Ultimate modifiers, deterministic loadouts, opt-in conditions or research be evaluated against a real run.
- **The 6 missing cost/time curves are a hard evidence boundary.** Before any candidate uses a timed queue, a current-build cross-check must establish its level curve, slots, queues, rush/acceleration and offline behaviour.

## Next audit steps

1. Record every named Lab player problem and direct dependency, beginning with the Main, Perks and Battle Condition groups that contain transferable structure.
2. Cross-check the 6 missing cost/time curves against a current build or another dated source; do not infer them from neighbouring Labs.
3. After the Rig and Ultimates have been played, propose at most one original vertical slice with its save, offline, RNG and migration contract.

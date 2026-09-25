#!/usr/bin/env python3
"""Builds data/workshop/upgrades.json from The Tower's Workshop table (D068).

The table is TheTowerSDK's `dist/data/workshop/table.json` (MIT licence, by
TmRxJD), which states every Workshop row's value, Cash price and Coin price at
every level as The Tower's own workshop.json does. Fetch it with:

    npm pack thetowersdk@0.11.0 && tar xzf thetowersdk-0.11.0.tgz
    python3 tools/import_tower_workshop.py package/dist/data/workshop/table.json

Values are converted once, here, into the units the game reads: percentages
become shares, Range becomes metres, and Orb Speed turns a minute. Prices stay
as The Tower states them. The unlock groups and their Coin prices come from
the community wiki's Workshop pages (read 24 September 2026), since the
SDK's table has no unlock order.
"""
import json
import sys

# (id, The Tower's name, title, category, group, unit, description, scale)
ROWS = [
    ("damage", "Damage", "DAMAGE", "attack", "attack_start", "flat", "Damage each shot deals.", 1.0),
    ("attack_speed", "Attack Speed", "ATTACK SPEED", "attack", "attack_start", "per_second", "Shots a second.", 1.0),
    ("critical_chance", "Critical Chance", "CRITICAL CHANCE", "attack", "attack_start", "percent", "Chance a shot is critical.", 0.01),
    ("critical_factor", "Critical Factor", "CRITICAL FACTOR", "attack", "attack_start", "multiplier", "How much a critical shot multiplies its damage.", 1.0),
    ("range", "Range", "RANGE", "attack", "range", "metres", "How far the Number reaches.", 10.0),
    ("damage_per_meter", "Damage / Meter", "DAMAGE / METER", "attack", "range", "per_metre", "Extra damage for every metre between the Number and what it strikes.", 0.01),
    ("multishot_chance", "Multishot Chance", "MULTISHOT CHANCE", "attack", "multishot", "percent", "Chance a shot also fires at other enemies in reach.", 0.01),
    ("multishot_targets", "Multishot Targets", "MULTISHOT TARGETS", "attack", "multishot", "count", "How many enemies a multishot fires at.", 1.0),
    ("rapid_fire_chance", "Rapid Fire Chance", "RAPID FIRE CHANCE", "attack", "rapid_fire", "percent", "Chance a shot starts Rapid Fire: four times as many shots for a while.", 0.01),
    ("rapid_fire_duration", "Rapid Fire Duration", "RAPID FIRE DURATION", "attack", "rapid_fire", "seconds", "How long Rapid Fire lasts.", 1.0),
    ("bounce_shot_chance", "Bounce Shot Chance", "BOUNCE SHOT CHANCE", "attack", "bounce_shot", "percent", "Chance a shot bounces on to the nearest enemy near the one it struck.", 0.01),
    ("bounce_shot_targets", "Bounce Shot Targets", "BOUNCE SHOT TARGETS", "attack", "bounce_shot", "count", "How many times a shot can bounce.", 1.0),
    ("bounce_shot_range", "Bounce Shot Range", "BOUNCE SHOT RANGE", "attack", "bounce_shot", "metres", "How far a shot can bounce.", 5.0),
    ("super_crit_chance", "Super Crit Chance", "SUPER CRIT CHANCE", "attack", "super_crit", "percent", "Chance a critical shot is a super critical.", 0.01),
    ("super_crit_mult", "Super Crit Mult", "SUPER CRIT MULT", "attack", "super_crit", "multiplier", "How much a super critical multiplies a critical.", 1.0),
    ("health", "Health", "HEALTH", "defense", "defense_start", "flat", "The Number every run starts with.", 1.0),
    ("health_regen", "Health Regen", "HEALTH REGEN", "defense", "defense_start", "per_second", "Number regained every second of a run.", 1.0),
    ("defense_percent", "Defense Percent", "DEFENSE %", "defense", "defense", "percent", "Share taken off every hit, before Defense Absolute.", 0.01),
    ("defense_absolute", "Defense Absolute", "DEFENSE ABSOLUTE", "defense", "defense", "flat", "Taken off every hit after Defense %. A hit can reach nothing.", 1.0),
    ("thorns", "Thorns", "THORN DAMAGE", "defense", "thorns", "percent", "Share of its own maximum health dealt back to every enemy that hits (half on a boss).", 0.01),
    ("lifesteal", "Lifesteal", "LIFESTEAL", "defense", "lifesteal", "percent", "Share of the damage shots deal added to the Number again.", 0.01),
    ("knockback_chance", "Knockback Chance", "KNOCKBACK CHANCE", "defense", "knockback", "percent", "Chance a shot pushes its enemy back.", 0.01),
    ("knockback_force", "Knockback Force", "KNOCKBACK FORCE", "defense", "knockback", "flat", "How hard a knockback pushes. Heavier enemies move less.", 1.0),
    ("orb_speed", "Orb Speed", "ORB SPEED", "defense", "orbs", "rpm", "How fast the orbs circle, in turns a minute.", 10.0),
    ("orbs", "Orbs", "ORBS", "defense", "orbs", "count", "Orbs circling the Number. Any enemy but a boss they touch dies.", 1.0),
    ("death_defy", "Death Defy", "DEATH DEFY", "defense", "death_defy", "percent", "Chance a hit that would end the run is ignored.", 0.01),
    ("cash_bonus", "Cash Bonus", "CASH BONUS", "utility", "cash", "multiplier", "Multiplies the Cash kills and waves pay.", 1.0),
    ("cash_per_wave", "Cash / Wave", "CASH / WAVE", "utility", "cash", "flat", "Cash paid as each wave ends.", 1.0),
    ("coins_per_kill", "Coins / Kill Bonus", "COINS / KILL BONUS", "utility", "coins", "multiplier", "Multiplies the Coins kills pay.", 1.0),
    ("coins_per_wave", "Coins / Wave", "COINS / WAVE", "utility", "coins", "flat", "Coins paid as each wave ends.", 1.0),
    ("free_attack_upgrade", "Free Attack Upgrade", "FREE ATTACK UPGRADE", "utility", "free_upgrades", "percent", "Chance each wave raises a run Attack Upgrade for free.", 0.01),
    ("free_defense_upgrade", "Free Defense Upgrade", "FREE DEFENSE UPGRADE", "utility", "free_upgrades", "percent", "Chance each wave raises a run Defense Upgrade for free.", 0.01),
    ("free_utility_upgrade", "Free Utility Upgrade", "FREE UTILITY UPGRADE", "utility", "free_upgrades", "percent", "Chance each wave raises a run Utility Upgrade for free.", 0.01),
    ("interest", "Interest / Wave", "INTEREST / WAVE", "utility", "interest", "percent", "Share of the Cash held paid again as each wave ends.", 0.01),
]

# (id, category, order, Coins to unlock). Order within a category is the order
# The Tower opens them in; a group opens only after the one before it.
GROUPS = [
    ("attack_start", "attack", 0, 0), ("range", "attack", 1, 50), ("multishot", "attack", 2, 400),
    ("rapid_fire", "attack", 3, 1500), ("bounce_shot", "attack", 4, 10000), ("super_crit", "attack", 5, 100000000),
    ("defense_start", "defense", 0, 0), ("defense", "defense", 1, 75), ("thorns", "defense", 2, 500),
    ("lifesteal", "defense", 3, 2000), ("knockback", "defense", 4, 5000), ("orbs", "defense", 5, 15000),
    ("death_defy", "defense", 6, 1500000),
    ("cash", "utility", 0, 40), ("coins", "utility", 1, 100), ("free_upgrades", "utility", 2, 800),
    ("interest", "utility", 3, 5000),
]


def tidy(value):
    """Seven significant figures: the table's own precision, a smaller file."""
    if value == 0:
        return 0
    rounded = float("%.7g" % value)
    return int(rounded) if rounded == int(rounded) and abs(rounded) < 1e15 else rounded


def main(table_path, out_path):
    table = json.load(open(table_path))
    upgrades = []
    for row_id, name, title, category, group, unit, description, scale in ROWS:
        levels = table[name]
        top = max(int(level) for level in levels)
        assert sorted(int(level) for level in levels) == list(range(top + 1)), name
        values = [tidy(levels[str(level)]["value"] * scale) for level in range(top + 1)]
        coins = [tidy(levels[str(level)]["coins"]) for level in range(top)]
        cash = [tidy(levels[str(level)]["cash"]) for level in range(top)]
        assert all(price > 0 for price in coins), name
        upgrades.append({
            "id": row_id, "title": title, "description": description,
            "category": "workshop", "workshop_category": category, "group": group,
            "progression_type": "module", "unit": unit, "max_rank": top,
            "values": values, "coin_prices": coins, "cash_prices": cash,
        })
    out = {
        "version": 2,
        "source": "The Tower's Workshop table via TheTowerSDK 0.11.0 (MIT, TmRxJD), dist/data/workshop/table.json; unlock groups from the community wiki, 24 September 2026. Generated by tools/import_tower_workshop.py (D068).",
        "groups": [{"id": g, "workshop_category": c, "order": o, "unlock_coins": u} for g, c, o, u in GROUPS],
        "upgrades": upgrades,
    }
    with open(out_path, "w") as handle:
        json.dump(out, handle, separators=(",", ":"))
        handle.write("\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "data/workshop/upgrades.json")

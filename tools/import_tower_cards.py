#!/usr/bin/env python3
"""Builds data/cards/cards.json from The Tower's Cards page on the community wiki (D146).

The page states every card's rarity and its value at each of its seven
levels, the Gem price of each card slot, how many copies each level takes,
what a card costs and the odds of each rarity. Fetch its wikitext with:

    curl -s "https://the-tower-idle-tower-defense.fandom.com/api.php?action=parse&page=Cards&prop=wikitext&format=json" \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['parse']['wikitext']['*'])" > cards.txt
    python3 tools/import_tower_cards.py cards.txt

Values are converted once, here, into the units the game reads: percentages
become shares and minutes become seconds. Which card does what in a run is
ours, in src/tower/cards.gd; never edit the JSON by hand.
"""
import json
import re
import sys

# The wiki's name → (id, unit). Units: "multiplier" (×), "share" (a
# percentage, stored as a share), "seconds", "waves", "count", "speed".
CARDS = {
    "Damage": ("damage", "multiplier"),
    "Attack Speed": ("attack_speed", "multiplier"),
    "Health": ("health", "multiplier"),
    "Health Regen": ("health_regen", "multiplier"),
    "Range": ("range", "multiplier"),
    "Cash": ("cash", "multiplier"),
    "Coins": ("coins", "multiplier"),
    "Slow Aura": ("slow_aura", "share"),
    "Critical Chance": ("critical_chance", "share"),
    "Enemy Balance": ("enemy_balance", "multiplier"),
    "Extra Defense": ("extra_defense", "share"),
    "Fortress": ("fortress", "multiplier"),
    "Free Upgrades": ("free_upgrades", "share"),
    "Extra Orb": ("extra_orb", "speed"),
    "Plasma Canon": ("plasma_cannon", "share"),
    "Critical Coin": ("critical_coin", "share"),
    "Wave Skip": ("wave_skip", "share"),
    "Intro Sprint": ("intro_sprint", "waves"),
    "Land Mine Stun": ("land_mine_stun", "seconds"),
    "Recovery Package Chance": ("recovery_package_chance", "share"),
    "Cells": ("cells", "count"),
    "Death Ray": ("death_ray", "seconds"),
    "Energy Net": ("energy_net", "seconds"),
    "Super Tower": ("super_tower", "multiplier"),
    "Second Wind": ("second_wind", "seconds"),
    "Demon Mode": ("demon_mode", "seconds"),
    "Energy Shield": ("energy_shield", "seconds"),
    "Wave Accelerator": ("wave_accelerator", "share"),
    "Berserker": ("berserker", "share"),
    "Ultimate Crit": ("ultimate_crit", "share"),
    "Nuke": ("nuke", "share"),
    "Area of Effect": ("area_of_effect", "share"),
}


def plain(cell):
    """A cell's text without wiki links: [[Cash Bonus|Cash]] → Cash."""
    cell = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", cell)
    return cell.strip()


def number(cell, unit):
    text = plain(cell).replace("sec", "").replace("min", "").replace("+", "").strip()
    is_minutes = "min" in cell
    is_percent = text.endswith("%")
    value = float(text.rstrip("%").strip())
    if is_percent or unit == "share":
        value = value / 100.0 if is_percent else value
    if is_minutes:
        value *= 60.0
    return round(value, 6)


def tables(text):
    """Each fandom table's rows as lists of cells."""
    for block in re.findall(r"\{\|(.*?)\n\|\}", text, re.S):
        rows = []
        for row in block.split("\n|-")[1:]:
            cells = [line[1:] for line in row.strip().split("\n") if line.startswith("|") and not line.startswith("|+")]
            if cells:
                rows.append(cells)
        yield rows


def main(path):
    text = open(path, encoding="utf-8").read()
    slots, cards = [], []
    for rows in tables(text):
        if rows and len(rows[0]) == 2:
            slots = [0 if plain(gems) == "Free" else int(plain(gems)) for _slot, gems in rows]
            continue
        for cells in rows:
            if len(cells) != 10:
                continue
            rarity, name, description = plain(cells[0]), plain(cells[1]), plain(cells[2])
            if name not in CARDS:
                sys.exit("Unknown card on the wiki: %s; add it to CARDS" % name)
            card_id, unit = CARDS[name]
            cards.append({"id": card_id, "name": name, "rarity": rarity.lower(), "unit": unit,
                          "description": description, "values": [number(cell, unit) for cell in cells[3:10]]})
    # Copies: the unlock is one, each later star the stated number more, the
    # unlock counting towards the second star's (so 80 in all, as the wiki says).
    stars = [int(more) for _star, more in re.findall(r"(\d)-[sS]tar: (\d+) copies", text)]
    copies = [1]
    for index, more in enumerate(stars):
        copies.append(more if index == 0 else copies[-1] + more)
    odds = {rarity.lower(): float(share) / 100.0 for rarity, share in re.findall(r"(Common|Rare|[Ee]pic): (\d+)%", text)}
    price = int(re.search(r"bought for (\d+) \[\[Currency/Gems", text).group(1))
    milestones = {}
    for name, tier, wave in re.findall(r"#\s*([A-Za-z ]+?) - (?:Rare|Epic) - Tier (\d+) Wave (\d+)", text):
        milestones[CARDS[name.strip()][0]] = {"tier": int(tier), "wave": int(wave)}
    for card in cards:
        if card["id"] in milestones:
            card["opens_at"] = milestones[card["id"]]
    if len(copies) != 7 or copies[-1] != 80 or len(slots) < 2 or sorted(odds) != ["common", "epic", "rare"]:
        sys.exit("The wiki's page changed shape: copies %s, slots %d, odds %s" % (copies, len(slots), odds))
    data = {"version": 1,
            "source": "The Tower's Cards page on the community wiki (fandom), read 1 October 2026. Generated by tools/import_tower_cards.py (D146).",
            "price_gems": price, "odds": odds, "copies_to_level": copies, "slot_gems": slots, "cards": cards}
    with open("data/cards/cards.json", "w", encoding="utf-8") as out:
        json.dump(data, out, ensure_ascii=False, separators=(",", ":"))
        out.write("\n")
    print("%d cards, %d slots, copies %s" % (len(cards), len(slots), copies))


if __name__ == "__main__":
    main(sys.argv[1])

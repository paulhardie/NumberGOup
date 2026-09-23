"""Expand data/workshop/proposed_spec.json into full ladders and tables.

Writes data/workshop/proposed.json (every rank of every row: Coin price,
Coins to reach it, and the stat value) and data/workshop/proposed.md (the
readable tables that docs/WORKSHOP_LADDERS.md summarises).

Rows marked "copy_current" take their prices and values from
data/workshop/current.json, which tools/export_workshop.gd generates from the
live game, so an unchanged row can never drift from what ships.

This is a design aid for a proposal. The game does not read these files yet.
Run: python3 tools/workshop_ladders.py
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data", "workshop")
TAPS_PER_SECOND = 2.0


def coins(x):
    return max(1, math.ceil(x - 1e-9))


def expand(row, spec, current):
    cls = row["class"]
    stat = row["stat"]
    if row["cost"].get("copy_current"):
        live = current[row["id"]]
        return [(r["cost"], r["value"]) for r in live["ranks"]], live
    if cls in ("core", "long"):
        c = spec["classes"][cls]
        ranks, band, growth = c["ranks"], c["band_size"], c["cost_growth_per_rank"]
    else:
        ranks, band, growth = stat["ranks"], None, row["cost"]["growth"]
    out = []
    total_step = 0.0
    for r in range(1, ranks + 1):
        cost = coins(row["cost"]["first"] * growth ** (r - 1))
        kind = stat["kind"]
        if kind == "growing_step":
            total_step += stat["first_step"] * stat["step_growth_per_band"] ** ((r - 1) / band)
            value = stat["base"] + total_step
        elif kind == "compound":
            value = stat["base"] * stat["growth_per_band"] ** (r / band)
        elif kind == "compound_per_rank":
            value = stat["base"] * stat["per_rank"] ** r
        elif kind == "linear":
            value = stat["base"] + stat["per_rank"] * r
        else:
            value = float(r)
        out.append((cost, value))
    return out, None


def fmt(x):
    if abs(x) >= 1e6:
        return f"{x:.3g}"
    if abs(x) >= 100:
        return f"{x:,.0f}"
    if abs(x) >= 1:
        return f"{x:,.2f}".rstrip("0").rstrip(".")
    return f"{x:.4g}"


def shown(value, unit):
    if unit.startswith("percent"):
        return f"{value * 100:.4g}%"
    if unit == "multiplier":
        return f"×{fmt(value)}"
    if unit == "rank":
        return f"rank {int(value)}"
    return f"+{fmt(value)}"


def main():
    with open(os.path.join(DATA, "proposed_spec.json")) as f:
        spec = json.load(f)
    with open(os.path.join(DATA, "current.json")) as f:
        current = {r["id"]: r for r in json.load(f)["workshop"]}
    tiers = spec["assumptions"]["tiers"]
    income = [spec["assumptions"]["tier_income_first"] * spec["assumptions"]["tier_income_growth"] ** n for n in range(tiers)]

    rows_out = []
    ladders = {}
    for row in spec["rows"]:
        ladder, live = expand(row, spec, current)
        ladders[row["id"]] = ladder
        cumulative = 0
        ranks = []
        for i, (cost, value) in enumerate(ladder, start=1):
            cumulative += cost
            ranks.append([i, cost, cumulative, round(value, 6)])
        entry = {k: row[k] for k in row if k not in ("stat", "cost")}
        entry.update({
            "unit": row["stat"]["unit"],
            "max_rank": len(ladder),
            "first_rank_coins": ladder[0][0],
            "last_rank_coins": ladder[-1][0],
            "coins_to_max": cumulative,
            "value_at_max": round(ladder[-1][1], 6),
            "ranks_columns": ["rank", "cost", "coins_to_here", "value"],
            "ranks": ranks,
        })
        if row["class"] in ("core", "long"):
            band = spec["classes"][row["class"]]["band_size"]
            bands = []
            for n in range(tiers):
                start, end = n * band, (n + 1) * band
                band_cost = sum(c for c, _ in ladder[start:end])
                bands.append({
                    "band": n + 1, "opens_with_tier": n + 1, "last_rank": end,
                    "value_at_end": round(ladder[end - 1][1], 6),
                    "band_coins": band_cost,
                    "share_of_tier_income": round(band_cost / income[n], 4),
                })
            entry["bands"] = bands
        if live is not None:
            entry["unchanged_from_current"] = True
        rows_out.append(entry)

    # Migration: an existing rank must keep at least the value it has today.
    migration = []
    for row in spec["rows"]:
        live = current.get(row["id"])
        if live is None or row["cost"].get("copy_current"):
            continue
        ladder = ladders[row["id"]]
        for old in sorted({10, 25, 50, live["max_rank"]}):
            if old > live["max_rank"]:
                continue
            old_value = live["ranks"][old - 1]["value"]
            new = next((i for i, (_, v) in enumerate(ladder, start=1) if v >= old_value - 1e-9), len(ladder))
            migration.append({"id": row["id"], "old_rank": old, "old_value": old_value, "new_rank": new, "new_value": round(ladder[new - 1][1], 6)})

    # The climb: what a full band buys at each tier, against today's caps.
    by_id = {r["id"]: r for r in rows_out}
    def value_at(row_id, rank):
        return by_id[row_id]["ranks"][rank - 1][3]
    today_damage = (1 + 7.5 + TAPS_PER_SECOND * 6.0) * 1.520875
    climb = []
    for n in range(1, tiers + 1):
        core_rank = n * spec["classes"]["core"]["band_size"]
        long_rank = n * spec["classes"]["long"]["band_size"]
        dps = value_at("generator", core_rank)
        tap = value_at("stronger_tap", core_rank)
        mult = value_at("generator_two", core_rank)
        damage = (1 + dps + TAPS_PER_SECOND * tap) * mult
        band_coins = sum(b["bands"][n - 1]["band_coins"] for b in rows_out if "bands" in b)
        climb.append({
            "tier": n, "core_rank": core_rank, "long_rank": long_rank,
            "damage_per_second": dps, "tap_damage": tap, "damage_multiplier": mult,
            "damage_at_2_taps": round(damage, 3), "vs_today_max": round(damage / today_damage, 3),
            "guard_in_tier_hits": value_at("guard", core_rank),
            "crit_damage": value_at("magnitude_coil", long_rank),
            "boss_damage": value_at("boss_damage", long_rank),
            "band_coins_all_rows": band_coins,
            "tier_income": round(income[n - 1]),
            "band_share_of_income": round(band_coins / income[n - 1], 3),
        })

    out = {
        "generated_by": "tools/workshop_ladders.py from data/workshop/proposed_spec.json",
        "status": spec["status"],
        "assumptions": spec["assumptions"],
        "classes": spec["classes"],
        "climb": climb,
        "migration": migration,
        "rows": rows_out,
    }
    with open(os.path.join(DATA, "proposed.json"), "w") as f:
        json.dump(out, f, separators=(",", ":"))
        f.write("\n")
    with open(os.path.join(DATA, "proposed.md"), "w") as f:
        f.write(markdown(out, spec))
    print(f"WROTE proposed.json and proposed.md: {len(rows_out)} rows, {sum(r['max_rank'] for r in rows_out)} ranks")


def markdown(out, spec):
    L = ["# Workshop ladders: proposed tables", "",
         "Generated by `tools/workshop_ladders.py` from `proposed_spec.json`. Proposed only; `docs/WORKSHOP_LADDERS.md` explains it. Every rank of every row is in `proposed.json`.", ""]
    L += ["## Every row", "",
          "| Category | Row | Class | Ranks | Opens at | First rank | Last rank | Coins to max | At max |",
          "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |"]
    for r in out["rows"]:
        tag = " (new)" if r.get("new") else (" (unchanged)" if r.get("unchanged_from_current") else "")
        L.append(f"| {r['category']} | {r['name']}{tag} | {r['class']} | {r['max_rank']:,} | {r['opens_at']} | {r['first_rank_coins']:,} | {r['last_rank_coins']:,} | {r['coins_to_max']:,} | {shown(r['value_at_max'], r['unit'])} |")
    L += ["", "## Banded rows, band by band", "",
          "Band *n* opens when Tier *n* is unlocked. \"Share\" is the band's Coins against what the career model says a player earns while playing that tier.", ""]
    for r in out["rows"]:
        if "bands" not in r:
            continue
        L += [f"### {r['name']} ({r['class']}, {r['max_rank']:,} ranks)", "",
              "| Band | Ranks to | Value at band end | Band Coins | Share of tier income |",
              "| ---: | ---: | --- | ---: | ---: |"]
        for b in r["bands"]:
            L.append(f"| {b['band']} | {b['last_rank']:,} | {shown(b['value_at_end'], r['unit'])} | {b['band_coins']:,} | {b['share_of_tier_income'] * 100:.1f}% |")
        L.append("")
    L += ["## The climb", "",
          f"Damage assumes {TAPS_PER_SECOND:g} taps a second and every banded row filled to that tier's band; \"vs today\" compares with today's maxed Tap Damage, Damage per Second and Damage Multiplier.", "",
          "| Tier | Core ranks | Damage/sec row | Tap row | Multiplier | Damage/sec at 2 taps | vs today | Guard (× tier Hits) | Band Coins, all rows | Tier income | Share |",
          "| ---: | ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for c in out["climb"]:
        L.append(f"| {c['tier']} | {c['core_rank']:,} | +{fmt(c['damage_per_second'])} | +{fmt(c['tap_damage'])} | ×{fmt(c['damage_multiplier'])} | {fmt(c['damage_at_2_taps'])} | ×{fmt(c['vs_today_max'])} | {fmt(c['guard_in_tier_hits'])} | {c['band_coins_all_rows']:,} | {c['tier_income']:,} | {c['band_share_of_income'] * 100:.0f}% |")
    L += ["", "## Keeping owned ranks", "",
          "Rows whose ladder changes: an owned rank converts to the first new rank worth at least as much.", "",
          "| Row | Owned rank | Worth today | New rank | Worth after |", "| --- | ---: | --- | ---: | --- |"]
    units = {r["id"]: r["unit"] for r in out["rows"]}
    names = {r["id"]: r["name"] for r in out["rows"]}
    for m in out["migration"]:
        L.append(f"| {names[m['id']]} | {m['old_rank']} | {shown(m['old_value'], units[m['id']])} | {m['new_rank']:,} | {shown(m['new_value'], units[m['id']])} |")
    L.append("")
    return "\n".join(L)


if __name__ == "__main__":
    main()

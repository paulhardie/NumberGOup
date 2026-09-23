"""Coarse career model for the Tiers 1-10 balance proposal.

This is a sketch, not the game. It plays whole careers (run after run, Coins
into the Workshop between runs, Knowledge into Insight, tier after tier) with a
per-wave analytic rule instead of ticks, so it can compare *shapes* - hours per
tier, whether later tiers take longer, which systems carry the growth - across
rule sets in well under a second. `docs/TIER_BALANCE_PROPOSAL.md` owns the
reading of its output.

Calibration, both against `run_balance.sh` on `tax-foundation-v4`:
- fresh Tier 1 run: model wave 23, 8.2 min, 56 Coins; simulator 23, 8.3, 56.
- Workshop maxed with no Knowledge: model stalls at Tier 2 wave 37; the
  simulator's attack max + defense max reaches Tier 2 wave 38.

Damage per second against Coins spent is measured from the real Workshop
(2 taps a second, buying the cheapest next Attack rank). Not modelled: crit
randomness, Brace, Second Wind, Labs, Cards, Ultimates, Workshop level gates,
farming a lower tier, or a player who taps less as the game goes on.

It models the D012 wave rule (a stuck wave stays and Siphon/Recoil as they
were), which D037 replaced on 23 September 2026, so its absolute hours are
out of date; its comparisons between rule sets still hold as shapes.
Replace with a GDScript career simulator before tuning real numbers; see the
proposal's build order. Run: python3 tools/career_model.py
"""
import math

# Measured: Coins spent on Attack -> realised damage/sec at 2 taps/s.
MEASURED = [(0, 3.0), (10, 3.5), (25, 4.15), (64, 5.35), (166, 7.1), (419, 9.72),
            (1073, 15.34), (2741, 28.55), (7008, 50.58), (17938, 103.89),
            (28734, 160.22), (41115, 202.92)]
ATTACK_CAP = 41115


def hp_base(w):
    body = 0.05 * w ** 2.13 + 0.8 * w + 1.5
    ml = (w // 10) * math.log10(1.08) + (w // 50) * math.log10(1.2) + (w // 100) * math.log10(1.5)
    return 4.0 * body * 10 ** ml


def hit_base(w):
    body = 0.021 * w ** 2.007 + 0.16 * w + 1.07
    ml = (w // 10) * math.log10(1.06) + (w // 50) * math.log10(1.18) + (w // 100) * math.log10(1.4)
    return 10.0 * body * 10 ** ml


class Rules:
    def __init__(self, name, hp_mult, hit_mult, reward_mult, **kw):
        self.name = name
        self.hp_mult = hp_mult
        self.hit_mult = hit_mult
        self.reward_mult = reward_mult
        self.tiers = len(hp_mult)
        # Workshop Attack: None keeps today's cap; otherwise (band growth per
        # tier unlocked, power exponent on Coins beyond today's cap).
        self.bands = kw.get("bands")
        self.rush_floor = kw.get("rush_floor")        # None: every wave lasts 15 s
        self.knowledge = kw.get("knowledge", "current")
        self.insight = kw.get("insight", "current")
        self.breakthrough = kw.get("breakthrough", 1.0)
        self.rig = kw.get("rig")                      # (waves of damage, growth, damage x per rank)
        self.toll_tiers = kw.get("toll_tiers", set())
        self.attack_share = kw.get("attack_share", 0.7)
        self.damage_scale = kw.get("damage_scale", 1.0)


def workshop_dps(rules, coins, unlocked):
    if rules.bands:
        growth, exponent = rules.bands
        coins = min(coins, ATTACK_CAP * growth ** (unlocked - 1))
    else:
        coins = min(coins, ATTACK_CAP)
        exponent = 0.0
    if coins >= ATTACK_CAP:
        return MEASURED[-1][1] * (coins / ATTACK_CAP) ** exponent
    for (c0, d0), (c1, d1) in zip(MEASURED, MEASURED[1:]):
        if c0 <= coins <= c1:
            if c0 == 0:
                return d0 + (d1 - d0) * coins / c1
            f = math.log(coins / c0) / math.log(c1 / c0)
            return math.exp(math.log(d0) + f * math.log(d1 / d0))
    return MEASURED[-1][1]


def defense(coins):
    """Armor to 40%, then Recoil to 50%, then Siphon to 25%, at roughly D035 prices."""
    armor = 0.4 * min(1.0, coins / 5000.0) ** 0.8
    recoil = 0.5 * min(1.0, max(0.0, coins - 5000.0) / 9000.0) ** 0.8
    siphon = 0.25 * min(1.0, max(0.0, coins - 14000.0) / 9000.0) ** 0.8
    return armor, recoil, siphon


def wave_values(rules, tier, w):
    boss = w % 10 == 0
    if tier == 1 and w <= 20:
        hp = 20.0 * 1.08 ** (w - 1) * (1.4 if boss else 1.0)
        hit = 1.085 ** (w - 1) * (1.4 if boss else 1.0)
        return hp, hit, True, boss
    hp = hp_base(w) * rules.hp_mult[tier - 1] * (3.0 if boss else 1.0)
    hit = hit_base(w) * rules.hit_mult[tier - 1] * (1.5 if boss else 1.0)
    if tier == 1 and w <= 25:
        hit = min(hit, 1.085 ** 19 * 1.4 * 2.0 ** (w - 20))
    return hp, hit, False, boss


def reward(rules, tier, w, warm, boss):
    if warm:
        return 5 if boss else 1
    return max(1, round(0.65 * w * rules.reward_mult[tier - 1] * (5 if boss else 1)))


def run(rules, tier, dps, armor, recoil, siphon, start_number, claimed, cap_seconds=5400.0):
    number = start_number
    t = lifetime = 0.0
    coins = rig_rank = 0
    peak = number
    d = dps
    w = 1

    def ended():
        return dict(wave=w, cleared=w - 1, seconds=t, coins=coins, lifetime=lifetime, peak=peak, rig=rig_rank)

    while t < cap_seconds:
        hp, hit, warm, boss = wave_values(rules, tier, w)
        hit *= 1.0 - armor
        if tier in rules.toll_tiers:
            number -= hit
            if number <= 0:
                return ended()
        dd = d * 2.0 if boss and not warm else d  # Boss Damage at its cap
        if warm:
            lifetime += 15.0 * dd
            if hp <= 15.0 * dd:
                clear = hp / dd
                number += (15.0 - clear) * dd
                t += max(clear, rules.rush_floor) if rules.rush_floor else 15.0
            else:
                number -= hit
                t += 15.0
                if number <= 0:
                    return ended()
        else:
            remaining = hp
            while True:
                lifetime += 15.0 * dd
                if remaining <= 15.0 * dd:
                    clear = remaining / dd
                    number += (15.0 - clear) * dd + siphon * remaining
                    t += max(clear, rules.rush_floor) if rules.rush_floor else 15.0
                    break
                remaining -= 15.0 * dd + recoil * hit
                number += siphon * 15.0 * dd - hit
                t += 15.0
                if number <= 0 or t >= cap_seconds:
                    return ended()
            if w in (10, 25, 50, 100) and w not in claimed:
                coins += round(w * rules.reward_mult[tier - 1] * 2.0)
                claimed.add(w)
        coins += reward(rules, tier, w, warm, boss)
        peak = max(peak, number)
        if rules.rig:
            # Keep two of the next wave's Hits (three on a Toll tier) and spend the rest.
            waves, growth, mult = rules.rig
            reserve = (3.0 if tier in rules.toll_tiers else 2.0) * wave_values(rules, tier, w + 1)[1] * (1.0 - armor)
            while number - waves * 15.0 * d * growth ** rig_rank >= reserve:
                number -= waves * 15.0 * d * growth ** rig_rank
                rig_rank += 1
                d *= mult
        w += 1
    return ended()


def knowledge_gain(rules, lifetime):
    if rules.knowledge == "current":
        return int(4.0 * math.log10(lifetime / 110000.0)) if lifetime > 110000 else 0
    scale, exponent = rules.knowledge
    return int((lifetime / scale) ** exponent) if lifetime > scale else 0


def insight_mult(rules, knowledge):
    if rules.insight == "current":
        return 1.02 ** knowledge
    return 1.0 + rules.insight * knowledge


def career(rules, max_hours=250.0):
    attack = defense_coins = knowledge = runs = 0
    unlocked = 1
    claimed = {t: set() for t in range(1, rules.tiers + 1)}
    hours = 0.0
    log = []
    first = None
    while hours < max_hours:
        tier = unlocked
        dps = workshop_dps(rules, attack, unlocked) * rules.damage_scale
        dps *= insight_mult(rules, knowledge) * rules.breakthrough ** (unlocked - 1)
        armor, recoil, siphon = defense(defense_coins)
        # Cushion: 500 x the tier's Hit pressure at its cap, bought with the Defense share.
        start = 50.0 if tier == 1 else 500.0 * rules.hit_mult[tier - 1] * min(1.0, defense_coins / 30000.0)
        r = run(rules, tier, dps, armor, recoil, siphon, start, claimed[tier])
        runs += 1
        first = first or r
        hours += (r["seconds"] + 10.0) / 3600.0
        spend = int(r["coins"] * rules.attack_share)
        attack += spend
        defense_coins += r["coins"] - spend
        knowledge += knowledge_gain(rules, r["lifetime"])
        if r["cleared"] >= 100:
            log.append(dict(tier=tier, hours=hours, runs=runs, run=r, dps=dps))
            if unlocked == rules.tiers:
                break
            unlocked += 1
    return dict(log=log, hours=hours, runs=runs, first=first, knowledge=knowledge, stuck=unlocked)


def summary(rules, max_hours=250.0, detail=False):
    c = career(rules, max_hours)
    times = [e["hours"] for e in c["log"]]
    gaps = [b - a for a, b in zip([0.0] + times, times)]
    ratio = (gaps[-1] / gaps[1]) ** (1.0 / (len(gaps) - 2)) if len(gaps) > 3 else float("nan")
    at = lambda n: f"{times[n - 1]:6.1f}" if len(times) >= n else "     -"
    status = f"all {rules.tiers} tiers" if len(times) == rules.tiers else f"stuck in T{c['stuck']} at {max_hours:.0f} h"
    print(f"{rules.name:44s} first run W{c['first']['wave']:>3} {c['first']['seconds'] / 60:4.1f} min |"
          f" T1 {at(1)} h | T5 {at(5)} h | T10 {at(10)} h | per-tier growth {ratio:4.2f} | {status}")
    if detail:
        prev = 0.0
        for e in c["log"]:
            r = e["run"]
            print(f"    T{e['tier']:<2} wave 100 at {e['hours']:6.1f} h (+{e['hours'] - prev:5.1f} h), run {e['runs']:4d},"
                  f" that run {r['seconds'] / 60:4.1f} min, {r['rig']} Rig ranks, peak Number {r['peak']:.2g}")
            prev = e["hours"]


def current():
    return Rules("today (T1-3 as shipped)", [1, 20, 60], [1, 20, 60], [1, 1.8, 2.6])


LADDER = [10 ** i for i in range(10)]
HIT_SKEW = [1, 2.0, 0.7, 1, 2.5, 0.7, 1, 3.0, 0.7, 1.5]


def proposal(name="proposal", **kw):
    base = dict(
        hp_mult=LADDER,
        hit_mult=[p * s for p, s in zip(LADDER, HIT_SKEW)],
        reward_mult=[2.5 ** i for i in range(10)],
        bands=(4.0, 0.5),
        rush_floor=3.0,
        knowledge=(1e5, 0.5),
        insight=0.05,
        breakthrough=1.4,
        rig=(1.0, 2.0, 1.2),
        toll_tiers={2, 5, 8},
    )
    base.update(kw)
    return Rules(name, base.pop("hp_mult"), base.pop("hit_mult"), base.pop("reward_mult"), **base)


if __name__ == "__main__":
    tower = [1, 20, 60, 120, 240, 480, 960, 1920, 5760, 40320]
    tower_rewards = [1, 1.8, 2.6, 3.4, 4.2, 5.0, 5.8, 6.6, 7.5, 8.7]
    print("TODAY'S SYSTEMS")
    summary(current(), detail=True)
    summary(Rules("today's systems on The Tower's 10 tiers", tower, tower, tower_rewards), detail=True)
    summary(Rules("today's systems, no Knowledge", tower, tower, tower_rewards, knowledge=(1e99, 1.0)), max_hours=150)
    print("PROPOSAL")
    summary(proposal(), detail=True)
    print("WHAT EACH PIECE DOES (the proposal with one piece removed or changed)")
    summary(proposal("  without Rush", rush_floor=None))
    summary(proposal("  without the new Rig", rig=None))
    summary(proposal("  without Breakthroughs", breakthrough=1.0))
    summary(proposal("  with today's Knowledge and Insight", knowledge="current", insight="current"))
    summary(proposal("  without Toll tiers", toll_tiers=set()))
    print("PLAYERS AND BUILDS")
    summary(proposal("  lighter tapper (60% of the damage)", damage_scale=0.6))
    summary(proposal("  all Coins into Attack", attack_share=1.0))
    summary(proposal("  all Attack, no Toll tiers", attack_share=1.0, toll_tiers=set()))
    summary(proposal("  half Attack, half Defense", attack_share=0.5))

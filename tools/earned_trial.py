#!/usr/bin/env python3
"""Measure Coins following the Number earned (D162) against the pass criteria
written down first in docs/THE_NUMBER.md section 16.5.

For each declared configuration (a share of a run's Coins that follows the Number
earned, and a power) it plays the balance harness's cells through sim_runs.gd:
the Workshop plans buying with the Number and with run upgrades off, Tier 1, 2
and 3 at level 20, fresh runs and two careers, and each cell again as the control
with the option off. Each criterion reads PASS, FAIL or NOT RUN. Measurements are
cached by options and source, so a rerun costs nothing. Bots, not players: a pass
says the numbers hold, not that it is fun. The option only pays Coins, so a seed
plays exactly as its control does, and E7 compares run with run.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402
from number_trial import rows, run_all  # noqa: E402

PLANS = ('core', 'turtle')
BUDGETS = (10000, 100000, 1000000)
FRESH = ('none', 'even', 'core')
CAREERS = ('core', 'grow')
# The harness's career cells (balance_report.scenarios): core plays 50 runs, grow 70.
CAREER_RUNS = {'core': 50, 'grow': 70}
TIERS = (1, 2, 3)
SHARES = (0.25, 0.5, 1.0)
POWERS = (0.8, 1.0)
GRID = tuple((share, power) for power in POWERS for share in SHARES)
# The calibration cell (THE_NUMBER.md 16.2): core Workshop plan, 100K Coins, buying,
# Tier 1. Its median Coins and Number earned, measured 6 October 2026. Declared
# before any option was measured and never retuned.
REFERENCE_COINS = 420.5
REFERENCE_EARNED = 3950.5
INCOME = ('kill_cash', 'wave_cash', 'interest')
LABELS = {1: 'pace', 2: 'paid alike', 3: 'upgrades off', 4: 'tiers', 5: 'Coin rows', 6: 'early game', 7: 'no runaway'}


def scale(power):
    """K, so that at the reference cell the earned part pays its share of that cell's Coins."""
    return REFERENCE_COINS / REFERENCE_EARNED ** power


def name(share, power):
    return f's{share:g}_p{power:g}'


def cells():
    """Every cell the criteria read, as sim_runs options with the option off."""
    rules = dict(balance.GAME_RULES)
    found = {}
    for budget in BUDGETS:
        for build in PLANS:
            base = dict(rules, seeds=4 if (budget, build) == (1000000, 'turtle') else 6, buy='core',
                        **{'workshop-coins': budget, 'workshop-plan': build, 'cap-minutes': 180})
            found[f'buy_{budget}_{build}'] = base
            found[f'off_{budget}_{build}'] = dict(base, **{'upgrades-off': 'true'})
    for tier in TIERS:
        found[f'tier{tier}'] = dict(rules, seeds=2, buy='core', workshop=20, tier=tier, **{'cap-minutes': 10, 'until-wave': 100})
    for policy in FRESH:
        found[f'fresh_{policy}'] = dict(rules, seeds=20, buy=policy, **{'cap-minutes': 10})
    for policy in CAREERS:
        found[f'career_{policy}'] = dict(rules, careers=CAREER_RUNS[policy], buy=policy, **{'cap-minutes': 90})
    return found


def plan(configs=GRID):
    """Every run: each cell as the control and under each configuration."""
    runs = {}
    for cell, base in cells().items():
        runs[f'ctrl.{cell}'] = base
        for share, power in configs:
            runs[f'{name(share, power)}.{cell}'] = dict(base, **{
                'earned-share': share, 'earned-power': power, 'earned-scale': repr(scale(power))})
    return runs


def median(values):
    return balance.upper_median(values) if values else None


def shown(values):
    """Raw values rounded for the report only; every predicate reads the raw ones."""
    return {key: round(value, 3) for key, value in values.items()}


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def coins(result):
    return median([row['coins'] for row in rows(result)])


def per_earned(result):
    """Median Coins per Number earned, run by run."""
    return median([row['coins'] / row['cash'] for row in rows(result) if row['cash'] > 0])


def per_minute(result):
    return median([row['coins'] / (row['game_seconds'] / 60.0) for row in rows(result)])


def interest_share(row):
    gained = row.get('gained_from') or {}
    income = sum(gained.get(source, 0.0) for source in INCOME)
    return gained.get('interest', 0.0) / income if income > 0 else 0.0


def evaluate(results, prefix):
    """The seven criteria of THE_NUMBER.md 16.5 for one configuration, `prefix`, against the
    controls. A criterion whose runs weren't played is absent, not a pass."""
    def have(*cells_wanted):
        return all(f'{p}.{c}' in results for c in cells_wanted for p in ('ctrl', prefix))

    def mine(cell):
        return results[f'{prefix}.{cell}']

    def ctrl(cell):
        return results[f'ctrl.{cell}']

    out = {}
    workshop = [(b, p) for b in BUDGETS for p in PLANS]
    buying = [f'buy_{b}_{p}' for b, p in workshop]
    if have(*buying):
        moved = {c: coins(mine(c)) / coins(ctrl(c)) - 1.0 for c in buying}
        out[1] = verdict(all(abs(v) <= 0.25 for v in moved.values()), f'median Coins against the control {shown(moved)}; each within 0.25')
    if have(*buying, *[f'off_{b}_{p}' for b, p in workshop]):
        gaps = {f'{b}/{p}': per_earned(mine(f'off_{b}_{p}')) / per_earned(mine(f'buy_{b}_{p}')) - 1.0 for b, p in workshop}
        out[2] = verdict(all(abs(v) <= 0.10 for v in gaps.values()), f'Coins per Number earned, off against buying {shown(gaps)}; each within 0.10')
        rates = {f'{b}/{p}': per_minute(mine(f'off_{b}_{p}')) / per_minute(mine(f'buy_{b}_{p}')) for b, p in workshop}
        out[3] = verdict(all(0.70 <= v <= 1.30 for v in rates.values()), f'Coins per game-minute, off over buying {shown(rates)}; each 0.70 to 1.30')
    if have(*[f'tier{t}' for t in TIERS]):
        kept = {}
        for tier in (2, 3):
            theirs = coins(ctrl(f'tier{tier}')) / coins(ctrl('tier1'))
            mine_ratio = coins(mine(f'tier{tier}')) / coins(mine('tier1'))
            kept[f'tier {tier} over tier 1'] = mine_ratio / theirs - 1.0
        out[4] = verdict(all(abs(v) <= 0.15 for v in kept.values()), f'the tier ratio of median Coins against the control\'s {shown(kept)}; each within 0.15')
    if have(*[f'career_{p}' for p in CAREERS]):
        found = coins(mine('career_grow')) / coins(mine('career_core'))
        was = coins(ctrl('career_grow')) / coins(ctrl('career_core'))
        out[5] = verdict(found >= 1.25, f'median Coins per run, the Coins-income career ({CAREER_RUNS["grow"]} runs) over the core one ({CAREER_RUNS["core"]}): {found:.2f} (control {was:.2f}); at least 1.25')
    if have(*[f'fresh_{p}' for p in FRESH]):
        gaps = {}
        ok = True
        for policy in FRESH:
            a, b = coins(mine(f'fresh_{policy}')), coins(ctrl(f'fresh_{policy}'))
            gaps[policy] = (a, b)
            ok = ok and a > 0 and abs(a - b) <= max(0.5 * b, 2.0)
        out[6] = verdict(ok, f'median Coins of fresh runs against the control {gaps}; each within half or 2 Coins, none zero')
    run_cells = [c for c in cells() if not c.startswith('career_')]
    if have(*run_cells):
        worst = {}
        bad = []
        for cell in run_cells:
            theirs = {(row['case'], row['seed'], row['run']): row['coins'] for row in rows(ctrl(cell))}
            highest = 0.0
            for row in rows(mine(cell)):
                control = theirs.get((row['case'], row['seed'], row['run']))
                if control is None:
                    raise ValueError(f'{prefix}.{cell}: a run without its control')
                limit = max(1.5 * control, control + 2.0)
                highest = max(highest, row['coins'] / limit)
                if row['coins'] > limit:
                    bad.append(cell)
            worst[cell] = highest
        shares = {c: median([interest_share(row) for row in rows(mine(c))]) for c in run_cells}
        out[7] = verdict(not bad and max(shares.values()) <= 0.25,
                         f'each run\'s Coins over its same-seed limit, the highest per cell {shown(worst)} (1 or less); '
                         f'median Interest share of income {shown(shares)} (at most 0.25)')
    return out


def post_hoc(results, prefix):
    """Two readings the declared criteria don't make, reported beside them and never counted
    (they were added after the first results, on review; THE_NUMBER.md 16.7). E5 compares a
    70-run career with a 50-run one, so this reads both over the same first 50 runs; E7's
    per-run limit can't be applied to careers, whose Workshop diverges from the control's, so
    this reads each career run against the control's run with the same index."""
    horizon = min(CAREER_RUNS.values())
    names = [f'{prefix}.career_{p}' for p in CAREERS] + [f'ctrl.career_{p}' for p in CAREERS]
    if not all(n in results for n in names):
        return None

    def first(key):
        return sorted(rows(results[key]), key=lambda row: row['run'])[:horizon]

    def ratios(who):
        grow, core = first(f'{who}.career_grow'), first(f'{who}.career_core')
        return (median([r['coins'] for r in grow]) / median([r['coins'] for r in core]),
                sum(r['coins'] for r in grow) / sum(r['coins'] for r in core))
    worst = {}
    for policy in CAREERS:
        control = first(f'ctrl.career_{policy}')
        worst[policy] = max(a['coins'] / max(1.5 * b['coins'], b['coins'] + 2.0) for a, b in zip(first(f'{prefix}.career_{policy}'), control))
    mine, ctrl = ratios(prefix), ratios('ctrl')
    return {'horizon': horizon, 'grow_over_core_median': mine[0], 'grow_over_core_total': mine[1],
            'control_median': ctrl[0], 'control_total': ctrl[1], 'worst_run_over_limit': worst}


def summary(results, prefix):
    found = {}
    for cell in cells():
        key = f'{prefix}.{cell}'
        if key in results and f'ctrl.{cell}' in results:
            found[cell] = {'coins': coins(results[key]), 'control_coins': coins(results[f'ctrl.{cell}']),
                           'per_earned': round(per_earned(results[key]) or 0.0, 4), 'control_per_earned': round(per_earned(results[f'ctrl.{cell}']) or 0.0, 4)}
    return found


def render(configs, results):
    lines = []
    overall = {}
    for share, power in configs:
        prefix = name(share, power)
        out = evaluate(results, prefix)
        exploratory = (share, power) not in GRID
        lines.append(f'share {share:g}, power {power:g}, scale {scale(power):.5f}' + (' (EXPLORATORY: outside the declared grid)' if exploratory else ''))
        for number in range(1, 8):
            found = out.get(number)
            state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
            lines.append(f'  E{number} {LABELS[number]}: {state}' + ('' if found is None else ': ' + found['detail']))
        run = list(out.values())
        result = 'NOT COMPLETE' if len(run) < 7 else 'PASS' if all(v['pass'] for v in run) else 'FAIL'
        overall[prefix] = 'EXPLORATORY' if exploratory else result
        lines.append(f'  Overall: {overall[prefix]}')
        extra = post_hoc(results, prefix)
        if extra:
            lines.append(f"  Post-hoc, not a criterion (first {extra['horizon']} career runs of each): grow over core, median per run "
                         f"{extra['grow_over_core_median']:.2f} (control {extra['control_median']:.2f}), total Coins {extra['grow_over_core_total']:.2f} "
                         f"(control {extra['control_total']:.2f}); each career run against the control's run of the same index, "
                         f"highest over its limit {shown(extra['worst_run_over_limit'])}")
        lines.append('')
    return '\n'.join(lines), overall


def chosen(extra):
    """The declared grid, always, then any exploratory configurations asked for."""
    return GRID + tuple(config for config in (extra or ()) if config not in GRID)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-earned-trial'))
    parser.add_argument('--output', type=Path, help='write the verdicts and the cells\' medians here')
    parser.add_argument('--config', action='append', metavar='SHARE:POWER',
                        help='also measure this configuration (labelled exploratory when outside the declared grid)')
    args = parser.parse_args()
    configs = chosen(tuple(tuple(float(part) for part in text.split(':')) for text in (args.config or ())))
    try:
        results = run_all(plan(configs), args.cache, args.jobs)
        text, overall = render(configs, results)
        print(text)
        if args.output:
            args.output.write_text(json.dumps({'overall': overall,
                                               'verdicts': {name(s, p): evaluate(results, name(s, p)) for s, p in configs},
                                               'post_hoc': {name(s, p): post_hoc(results, name(s, p)) for s, p in configs},
                                               'medians': {name(s, p): summary(results, name(s, p)) for s, p in configs}}, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, ZeroDivisionError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Measure the Number as Cash (D156) against the pass criteria written down
first in docs/THE_NUMBER.md section 13.2.

It plays the balance harness's seeds through sim_runs.gd: each Workshop cell
buying with the Number (bots keeping a reserve), with run upgrades off, and as
today's game for the control, plus fresh runs. Each criterion reads PASS, FAIL
or NOT RUN. Measurements are cached by options and source, so a rerun costs
nothing. Bots, not players: a pass says the numbers hold, not that it is fun.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402
from number_trial import median_wave, rows, run_all  # noqa: E402

PLANS = ('core', 'turtle')
BUDGETS = (10000, 100000, 1000000)
SEEDS = 6
FRESH = ('none', 'even', 'core')
RESERVE = 0.5
INCOME = ('kill_cash', 'wave_cash', 'interest')


def plan(reserve=RESERVE):
    """Every run the six criteria read."""
    runs = {}
    cash = {'number-cash': 'true', 'reserve': reserve}
    for budget in BUDGETS:
        for build in PLANS:
            base = {'seeds': SEEDS, 'buy': 'core', 'workshop-coins': budget, 'workshop-plan': build, 'cap-minutes': 180}
            runs[f'buy_{budget}_{build}'] = dict(base, **cash)
            runs[f'off_{budget}_{build}'] = dict(base, **cash, **{'upgrades-off': 'true'})
            runs[f'ctrl_{budget}_{build}'] = dict(base)
    for policy in FRESH:
        runs[f'fresh_{policy}'] = dict({'seeds': 20, 'buy': policy, 'cap-minutes': 10}, **cash)
    return runs


def median(values):
    return balance.upper_median(values) if values else None


def capped(result):
    return sum(1 for row in rows(result) if row['stop'] == 'time_cap')


def interest_share(row):
    gained = row.get('gained_from') or {}
    income = sum(gained.get(source, 0.0) for source in INCOME)
    return gained.get('interest', 0.0) / income if income > 0 else 0.0


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def evaluate(results):
    """The six criteria of THE_NUMBER.md 13.2. A criterion whose runs weren't
    played is None, not a pass."""
    def have(*names):
        return all(name in results for name in names)

    def wave(name):
        return median_wave(results[name])

    def peak(name):
        return median([row['peak_number'] for row in rows(results[name])])

    out = {}
    small = BUDGETS[0]
    if have(*[f'{kind}_{small}_{p}' for kind in ('buy', 'off') for p in PLANS]):
        adds = {p: wave(f'buy_{small}_{p}') - wave(f'off_{small}_{p}') for p in PLANS}
        out[1] = verdict(all(v >= 3 for v in adds.values()), f'waves buying adds at 10K {adds}; each needs 3 or more')
    if have(*[f'{kind}_{b}_{p}' for kind in ('buy', 'off') for b in BUDGETS for p in PLANS]):
        shares = {p: [round((wave(f'buy_{b}_{p}') - wave(f'off_{b}_{p}')) / wave(f'buy_{b}_{p}'), 3) for b in BUDGETS] for p in PLANS}
        out[2] = verdict(all(s[0] > s[1] > s[2] and s[2] <= 0.10 for s in shares.values()),
                         f'share of waves buying adds at 10K, 100K, 1M {shares}; must fall, ending at 0.1 or less')
    pace = [(b, p) for b in BUDGETS[:2] for p in PLANS]
    if have(*[f'{kind}_{b}_{p}' for kind in ('buy', 'ctrl') for b, p in pace]):
        peaks = {f'{b}/{p}': (round(peak(f'buy_{b}_{p}')), round(peak(f'ctrl_{b}_{p}'))) for b, p in pace}
        out[3] = verdict(all(mine >= theirs for mine, theirs in peaks.values()), f'median peak Number buying against the control {peaks}')
        moved = {f'{b}/{p}': round(wave(f'buy_{b}_{p}') / wave(f'ctrl_{b}_{p}') - 1.0, 3) for b, p in pace}
        out[5] = verdict(all(abs(v) <= 0.25 for v in moved.values()), f'median wave buying against the control {moved}; each within 0.25')
    big = [(b, p) for b in BUDGETS[1:] for p in PLANS]
    every = [f'{kind}_{b}_{p}' for kind in ('buy', 'off') for b in BUDGETS for p in PLANS]
    if have(*[f'{kind}_{b}_{p}' for kind in ('buy', 'off', 'ctrl') for b, p in big], *every):
        caps = {f'{kind}_{b}_{p}': capped(results[f'{kind}_{b}_{p}']) for kind in ('buy', 'off') for b, p in big}
        allowed = {f'{b}_{p}': capped(results[f'ctrl_{b}_{p}']) > 0 for b, p in big}
        bad = [name for name, count in caps.items() if count and not allowed[name.split('_', 1)[1]]]
        shares = {name: round(median([interest_share(row) for row in rows(results[name])]), 3) for name in every}
        out[4] = verdict(not bad and max(shares.values()) <= 0.25,
                         f'runs at the 3-hour cap {caps} (allowed only where the control is: {allowed}); '
                         f'median Interest share of income {shares} (at most 0.25)')
    if have(*[f'fresh_{p}' for p in FRESH]):
        waves = {p: wave(f'fresh_{p}') for p in FRESH}
        caps = {p: capped(results[f'fresh_{p}']) for p in FRESH}
        out[6] = verdict(all(2 <= w <= 10 for w in waves.values()) and sum(caps.values()) == 0,
                         f'median waves {waves} (each 2 to 10); runs at the cap {caps} (none allowed)')
    return out


def summary(results):
    found = {}
    for name, result in sorted(results.items()):
        runs = rows(result)
        entry = {'wave': median_wave(result), 'peak_number': round(median([row['peak_number'] for row in runs]), 1),
                 'cash_earned': round(median([row['cash'] for row in runs]), 1),
                 'stops': {stop: sum(1 for row in runs if row['stop'] == stop) for stop in sorted({row['stop'] for row in runs})}}
        found[name] = entry
    return found


def render(reserve, out):
    lines = [f'Bots keep {reserve} of the run\'s best in reserve' + ('' if reserve == RESERVE else ' (EXPLORATORY: the criteria use 0.5)'), '']
    for number in range(1, 7):
        found = out.get(number)
        state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
        lines.append(f'C{number} {state}' + ('' if found is None else ': ' + found['detail']))
    run = list(out.values())
    overall = 'NOT COMPLETE' if len(run) < 6 else 'PASS' if all(v['pass'] for v in run) else 'FAIL'
    if reserve != RESERVE:
        overall = 'EXPLORATORY'
    lines += ['', 'Overall: ' + overall]
    return '\n'.join(lines), overall


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reserve', type=float, default=RESERVE, help="the bots' reserve, a share of the run's best (the criteria use 0.5)")
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-cash-trial'))
    parser.add_argument('--output', type=Path, help='write the verdicts and every median here')
    args = parser.parse_args()
    try:
        results = run_all(plan(args.reserve), args.cache, args.jobs)
        out = evaluate(results)
        text, overall = render(args.reserve, out)
        print(text)
        if args.output:
            args.output.write_text(json.dumps({'reserve': args.reserve, 'overall': overall, 'verdicts': out,
                                               'medians': summary(results)}, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

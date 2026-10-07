#!/usr/bin/env python3
"""Measure the top-down battle (D167) against the round one on the pass criteria
written first in docs/TOP_DOWN.md section 2.

It plays the same cells both ways under the game's rules: a fresh tower buying
nothing, Workshop budgets of 10,000 and 100,000 Coins spent core, turtle and
blender, and the core (50 runs) and grow (70 runs) careers. Each criterion reads
PASS, FAIL or NOT RUN; how damage and losses split is reported beside them, never
as one. Measurements are cached by options and source. Bots, not players.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402
from number_trial import rows, run_all  # noqa: E402

BUDGETS = (10000, 100000)
PLANS = ('core', 'turtle', 'blender')
CAREERS = {'core': 50, 'grow': 70}
WAYS = ('round', 'top')
LABELS = {1: 'the first minutes', 2: 'Workshop cells', 3: 'careers'}


def cells():
    rules = dict(balance.GAME_RULES)
    found = {'fresh_none': dict(rules, seeds=20, buy='none', **{'cap-minutes': 10})}
    for budget in BUDGETS:
        for plan in PLANS:
            found[f'buy_{budget}_{plan}'] = dict(rules, seeds=6, buy='core', **{'workshop-coins': budget, 'workshop-plan': plan, 'cap-minutes': 180})
    for policy, runs in CAREERS.items():
        found[f'career_{policy}'] = dict(rules, careers=runs, buy=policy, **{'cap-minutes': 90})
    return found


def plan():
    runs = {}
    for way in WAYS:
        for cell, options in cells().items():
            runs[f'{way}.{cell}'] = dict(options, **({'top-down': 'true'} if way == 'top' else {}))
    return runs


def median(values):
    return balance.upper_median(values) if values else None


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def within(mine, theirs, share):
    """`mine` within `share` of `theirs` either way, never by rounding."""
    return theirs > 0 and abs(mine - theirs) <= share * theirs


def first_reaching(result, wave):
    return next((row['run'] for row in sorted(rows(result), key=lambda row: row['run']) if row['wave'] >= wave), None)


def check_ways(results):
    """Every run says which battle it played (its recorded tuning), so a switch the
    simulator ignored can't make both ways read alike and pass."""
    for name, result in results.items():
        wanted = name.startswith('top.')
        for row in rows(result):
            if bool(row.get('start', {}).get('tuning', {}).get('top_down', False)) != wanted:
                raise ValueError(f'{name}: run {row.get("run")} seed {row.get("seed")} played the {"round" if wanted else "top-down"} battle')


def evaluate(results):
    """The three criteria of TOP_DOWN.md section 2; one whose runs weren't played is absent."""
    out = {}
    if 'top.fresh_none' in results:
        fresh = rows(results['top.fresh_none'])
        late = [row for row in fresh if row['wave'] > 5 or row['game_seconds'] > 180.0 or row.get('stop') != 'death']
        out[1] = verdict(bool(fresh) and not late, f'{len(fresh) - len(late)} of {len(fresh)} fresh towers dead by wave 5 inside 180 s')
    wanted = [f'buy_{b}_{p}' for b in BUDGETS for p in PLANS]
    if all(f'{way}.{cell}' in results for way in WAYS for cell in wanted):
        reading, ok = {}, True
        for cell in wanted:
            theirs = median([row['wave'] for row in rows(results[f'round.{cell}'])])
            mine = median([row['wave'] for row in rows(results[f'top.{cell}'])])
            reading[cell] = (mine, theirs)
            ok = ok and within(mine, theirs, 0.20)
        out[2] = verdict(ok, 'median wave top-down against round ' + ', '.join(f'{c}: {m} / {t}' for c, (m, t) in reading.items()) + ' (within 20%)')
    if all(f'{way}.career_{policy}' in results for way in WAYS for policy in CAREERS):
        reading, ok = {}, True
        for policy in CAREERS:
            theirs = first_reaching(results[f'round.career_{policy}'], 30)
            mine = first_reaching(results[f'top.career_{policy}'], 30)
            reading[policy] = (mine, theirs)
            ok = ok and ((mine is None and theirs is None) or (mine is not None and theirs is not None and within(mine, theirs, 0.25)))
        out[3] = verdict(ok, 'first run reaching wave 30 top-down against round ' + ', '.join(f'{p}: {m} / {t}' for p, (m, t) in reading.items()) + ' (within 25%)')
    return out


def shares(result, key):
    """How a cell's runs split `key` (damage_by, lost_to), as shares of the whole."""
    total = {}
    for row in rows(result):
        for name, value in row.get(key, {}).items():
            total[name] = total.get(name, 0.0) + float(value)
    whole = sum(total.values())
    return {name: round(value / whole, 3) for name, value in sorted(total.items(), key=lambda item: -item[1])} if whole > 0 else {}


def reported(results):
    """Beside the criteria, never one: damage by source, losses and Coins, both ways."""
    out = {}
    for cell in cells():
        if all(f'{way}.{cell}' in results for way in WAYS):
            out[cell] = {way: {'damage_by': shares(results[f'{way}.{cell}'], 'damage_by'), 'lost_to': shares(results[f'{way}.{cell}'], 'lost_to'),
                               'coins': median([row['coins'] for row in rows(results[f'{way}.{cell}'])])} for way in WAYS}
    return out


def render(results):
    lines = []
    out = evaluate(results)
    for number in range(1, 4):
        found = out.get(number)
        state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
        lines.append(f'T{number} {LABELS[number]}: {state}' + ('' if found is None else ': ' + found['detail']))
    overall = 'NOT COMPLETE' if len(out) < 3 else 'PASS' if all(v['pass'] for v in out.values()) else 'FAIL'
    lines += [f'Overall: {overall}', '', 'Reported, not criteria:']
    for cell, ways in reported(results).items():
        lines.append(f'  {cell}: ' + ' | '.join(f'{way} coins {ways[way]["coins"]}, damage {ways[way]["damage_by"]}, lost {ways[way]["lost_to"]}' for way in WAYS))
    return '\n'.join(lines), overall


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-topdown-trial'))
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        results = run_all(plan(), args.cache, args.jobs)
        check_ways(results)
        text, overall = render(results)
        print(text)
        if args.output:
            args.output.write_text(json.dumps({'overall': overall, 'verdicts': evaluate(results), 'reported': reported(results)}, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, ZeroDivisionError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

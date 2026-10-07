#!/usr/bin/env python3
"""Measure top-down patrol-line orbs (D168) against today's top-down round orbs
on the criterion written first in docs/TOP_DOWN.md section 6 (O1).

Both ways play top-down under the game's rules, 6 seeds a cell, in the cells
where orbs work: 1,000,000 Coins spent blender_orbs, blender_orbline and spread,
and Tier 2 and 3 with every Workshop row at level 20. O1 reads PASS, FAIL or
NOT RUN; how damage splits, the orbs' share among it, is reported beside it,
never as one. Measurements are cached by options and source. Bots, not players.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402
from number_trial import rows, run_all  # noqa: E402
from topdown_trial import median, shares, within  # noqa: E402

PLANS = ('blender_orbs', 'blender_orbline', 'spread')
TIERS = (2, 3)
WAYS = ('circle', 'line')


def cells():
    rules = dict(balance.GAME_RULES, **{'top-down': 'true'})
    found = {}
    for plan in PLANS:
        found[f'buy_1000000_{plan}'] = dict(rules, seeds=6, buy='core', **{'workshop-coins': 1000000, 'workshop-plan': plan, 'cap-minutes': 180})
    for tier in TIERS:
        found[f'tier_{tier}_level20'] = dict(rules, seeds=6, buy='core', workshop=20, tier=tier, **{'cap-minutes': 30})
    return found


def plan():
    return {f'{way}.{cell}': dict(options, **({'orb-line': 'true'} if way == 'line' else {})) for way in WAYS for cell, options in cells().items()}


def check_ways(results):
    """Every run says which orbs it played (its recorded tuning), so a switch the
    simulator ignored can't make both ways read alike and pass."""
    for name, result in results.items():
        wanted = name.startswith('line.')
        for row in rows(result):
            tuning = row.get('start', {}).get('tuning', {})
            if not tuning.get('top_down', False) or bool(tuning.get('orb_line', False)) != wanted:
                raise ValueError(f'{name}: run {row.get("run")} seed {row.get("seed")} did not play top-down with {"line" if wanted else "round"} orbs')


def evaluate(results):
    """O1 of TOP_DOWN.md section 6; absent if its runs weren't all played."""
    if not all(f'{way}.{cell}' in results for way in WAYS for cell in cells()):
        return {}
    reading, ok = {}, True
    for cell in cells():
        theirs = median([row['wave'] for row in rows(results[f'circle.{cell}'])])
        mine = median([row['wave'] for row in rows(results[f'line.{cell}'])])
        reading[cell] = (mine, theirs)
        ok = ok and theirs is not None and mine is not None and within(mine, theirs, 0.20)
    return {1: {'pass': ok, 'detail': 'median wave, line against round orbs, ' + ', '.join(f'{c}: {m} / {t}' for c, (m, t) in reading.items()) + ' (within 20%)'}}


def reported(results):
    out = {}
    for cell in cells():
        if all(f'{way}.{cell}' in results for way in WAYS):
            out[cell] = {way: {'damage_by': shares(results[f'{way}.{cell}'], 'damage_by'),
                               'waves': sorted(row['wave'] for row in rows(results[f'{way}.{cell}']))} for way in WAYS}
    return out


def render(results):
    found = evaluate(results).get(1)
    state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
    lines = [f'O1 balance where orbs work: {state}' + ('' if found is None else ': ' + found['detail']), '', 'Reported, not criteria:']
    for cell, ways in reported(results).items():
        lines.append(f'  {cell}: ' + ' | '.join(f'{way} waves {ways[way]["waves"]}, orb share {ways[way]["damage_by"].get("orb", 0.0)}' for way in WAYS))
    return '\n'.join(lines), state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-orbline-trial'))
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        results = run_all(plan(), args.cache, args.jobs)
        check_ways(results)
        text, state = render(results)
        print(text)
        if args.output:
            args.output.write_text(json.dumps({'state': state, 'verdicts': evaluate(results), 'reported': reported(results)}, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, ZeroDivisionError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

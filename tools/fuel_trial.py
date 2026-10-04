#!/usr/bin/env python3
"""Measure stage 1 of the Number-first design, the fuel economy (D155),
against the pass criteria written down first in docs/THE_NUMBER.md section 12.

One configuration per run of the tool, or the declared centre and grid with
--grid. It plays the balance harness's seeds through sim_runs.gd, so it
measures exactly what BattleSim plays, and reports each criterion as PASS,
FAIL or NOT RUN. Measurements are cached by options and source, so a rerun
costs nothing. Bots, not players: a pass says the numbers hold, not that it
is fun.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402
from number_trial import median_wave, rows, run_all  # noqa: E402

BUILDS = ('core', 'turtle', 'blender', 'multishot')
BUDGETS = (10000, 100000)
SEEDS = 6
FRESH = ('none', 'even', 'core')
ROWS = ('health_regen', 'health', 'coins_per_kill')
CENTRE = {'price': 1.0, 'bounty': 0.25, 'free': 0.0, 'base': 1.0, 'scale': 1.0, 'hold': True}
# One lever at a time around the centre (THE_NUMBER.md 12.4).
GRID = (('bounty', 0.125), ('bounty', 0.5), ('scale', 10.0), ('hold', False), ('free', 0.5))


def fuel(config, free_shots=False):
    """The sim_runs.gd options for `config`; `free_shots` sets the price to 0."""
    options = {'shot-price': 0.0 if free_shots else config['price'], 'bounty-share': config['bounty'],
               'free-bounty-share': config['free'], 'base-regen': config['base'], 'regen-scale': config['scale']}
    if config['hold']:
        options['hold-doomed'] = 'true'
    options.update(config.get('extra') or {})
    return options


def plan(config):
    """Every run the six criteria read."""
    runs = {}
    for budget in BUDGETS:
        for build in BUILDS:
            base = {'seeds': SEEDS, 'buy': 'core', 'workshop-coins': budget, 'workshop-plan': build, 'cap-minutes': 180}
            runs[f'on_{budget}_{build}'] = dict(base, **fuel(config))
            runs[f'free_{budget}_{build}'] = dict(base, **fuel(config, free_shots=True))
    # The only build that buys Knockback, with it switched off (criterion 4).
    runs['nokb_100000_blender'] = dict(runs['on_100000_blender'], knockback='off')
    for policy in FRESH:
        runs[f'fresh_{policy}'] = dict({'seeds': 20, 'buy': policy, 'cap-minutes': 10}, **fuel(config))
    for row in ROWS:
        for level in (0, 25):
            runs[f'row_{row}_{level}'] = dict({'seeds': SEEDS, 'buy': 'core', 'workshop-coins': BUDGETS[0], 'workshop-plan': 'core',
                                               'cap-minutes': 180, 'row-levels': f'{row}:{level}'}, **fuel(config))
    return runs


def median(values):
    return balance.upper_median(values) if values else None


def arc(row):
    """Waves from the peak to the end; a run the cap stopped has no arc."""
    return 0 if row['stop'] == 'time_cap' else row['wave'] - row['peak_wave']


def printer_share(row):
    """The largest share of the Number's new highs from a source other than
    bounties and bought Health: what would show a printer (10.5)."""
    raised = row.get('raised_by') or {}
    total = sum(raised.values())
    others = [value for source, value in raised.items() if source not in ('bounty', 'health')]
    return max(others) / total if total > 0 and others else 0.0


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def evaluate(results):
    """The six criteria of THE_NUMBER.md 12.3. A criterion whose runs weren't
    played is None, not a pass."""
    def have(*names):
        return all(name in results for name in names)

    cells = [(budget, build) for budget in BUDGETS for build in BUILDS]
    out = {}
    if have(*[f'{kind}_{b}_{k}' for kind in ('on', 'free') for b, k in cells]):
        gained = {f'{b}/{k}': median_wave(results[f'free_{b}_{k}']) - median_wave(results[f'on_{b}_{k}']) for b, k in cells}
        out[1] = verdict(min(gained.values()) >= 2, f'waves free shots add {gained}; each needs 2 or more')
    if have('fresh_none', f'on_{BUDGETS[0]}_core'):
        fresh = median([row['crossing'] for row in rows(results['fresh_none'])])
        core = median([row['crossing'] for row in rows(results[f'on_{BUDGETS[0]}_core'])])
        out[2] = verdict(2 <= fresh <= 10 and core >= fresh + 10,
                         f'median crossing: fresh_none wave {fresh} (2 to 10), 10K core wave {core} (at least {fresh + 10})')
    if have(*[f'on_{b}_{k}' for b, k in cells]):
        arcs = {f'{b}/{k}': median([arc(row) for row in rows(results[f'on_{b}_{k}'])]) for b, k in cells}
        out[3] = verdict(min(arcs.values()) >= 3, f'median waves from the peak to the end {arcs}; each needs 3 or more')
    big = [f'on_{BUDGETS[1]}_{k}' for k in BUILDS if k != 'blender'] + ['nokb_100000_blender']
    if have(*big, *[f'on_{b}_{k}' for b, k in cells]):
        capped = {name: sum(1 for row in rows(results[name]) if row['stop'] == 'time_cap') for name in big}
        knocked = sum(1 for row in rows(results['on_100000_blender']) if row['stop'] == 'time_cap')
        shares = {f'{b}/{k}': round(median([printer_share(row) for row in rows(results[f'on_{b}_{k}'])]), 3) for b, k in cells}
        out[4] = verdict(sum(capped.values()) == 0 and max(shares.values()) <= 0.5,
                         f'runs at the 3-hour cap at 100K {capped} (none allowed; the blender with Knockback on: {knocked}); '
                         f'median largest share of new highs from anything but bounties and bought Health {shares} (at most 0.5)')
    if have(*[f'fresh_{p}' for p in FRESH]):
        waves = {p: median_wave(results[f'fresh_{p}']) for p in FRESH}
        capped = {p: sum(1 for row in rows(results[f'fresh_{p}']) if row['stop'] == 'time_cap') for p in FRESH}
        out[5] = verdict(all(2 <= w <= 10 for w in waves.values()) and sum(capped.values()) == 0,
                         f'median waves {waves} (each 2 to 10); runs at the cap {capped} (none allowed)')
    if have(*[f'row_{r}_{level}' for r in ROWS for level in (0, 25)]):
        lifts = {}
        for row in ROWS:
            low = median([run['peak_number'] for run in rows(results[f'row_{row}_0'])])
            high = median([run['peak_number'] for run in rows(results[f'row_{row}_25'])])
            lifts[row] = round(high / low - 1.0, 3) if low > 0 else None
        out[6] = verdict(all(lift is not None and lift >= 0.1 for lift in lifts.values()),
                         f'median peak Number at level 25 over level 0 {lifts}; each needs 0.1 or more')
    return out


def summary(results):
    """Every scenario's medians, for the record."""
    found = {}
    for name, result in sorted(results.items()):
        runs = rows(result)
        entry = {'wave': median_wave(result), 'peak_number': round(median([row['peak_number'] for row in runs]), 1),
                 'stops': {stop: sum(1 for row in runs if row['stop'] == stop) for stop in sorted({row['stop'] for row in runs})}}
        if runs and 'peak_wave' in runs[0]:
            entry.update({'peak_wave': median([row['peak_wave'] for row in runs]), 'crossing': median([row['crossing'] for row in runs]),
                          'shots_paid': median([row['shots_paid'] for row in runs]),
                          'bounty': round(median([row['gained_from'].get('bounty', 0.0) for row in runs]), 1)})
        found[name] = entry
    return found


def declared(config):
    """Whether `config` is the centre or one of the grid's (THE_NUMBER.md 12.4)."""
    return not config.get('extra') and config in [CENTRE] + [dict(CENTRE, **{lever: value}) for lever, value in GRID]


def render(config, out):
    lines = ['Configuration: ' + json.dumps(config, sort_keys=True)]
    if not declared(config):
        lines.append('EXPLORATORY: outside the declared grid, so it cannot count as a pass.')
    lines.append('')
    for number in range(1, 7):
        found = out.get(number)
        state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
        lines.append(f'C{number} {state}' + ('' if found is None else ': ' + found['detail']))
    run = list(out.values())
    overall = 'NOT COMPLETE' if len(run) < 6 else 'PASS' if all(v['pass'] for v in run) else 'FAIL'
    if not declared(config):
        overall = 'EXPLORATORY'
    lines += ['', 'Overall: ' + overall]
    return '\n'.join(lines), overall


def configurations(args):
    centre = {'price': args.price, 'bounty': args.bounty, 'free': args.free, 'base': args.base, 'scale': args.scale, 'hold': args.hold}
    if args.extra:
        centre['extra'] = dict(item.split('=', 1) for item in args.extra)
    if not args.grid:
        return [centre]
    return [centre] + [dict(centre, **{lever: value}) for lever, value in GRID]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--price', type=float, default=CENTRE['price'])
    parser.add_argument('--bounty', type=float, default=CENTRE['bounty'])
    parser.add_argument('--free', type=float, default=CENTRE['free'], help="the free killers' share of a bounty (at most 0.5)")
    parser.add_argument('--base', type=float, default=CENTRE['base'], help='the starting Regen a second')
    parser.add_argument('--scale', type=float, default=CENTRE['scale'], help='the Health Regen row times this')
    parser.add_argument('--hold', action=argparse.BooleanOptionalAction, default=CENTRE['hold'])
    parser.add_argument('--grid', action='store_true', help='measure the centre and each grid configuration (THE_NUMBER.md 12.4)')
    parser.add_argument('--with', dest='extra', action='append', default=[], metavar='NAME=VALUE',
                        help='another sim_runs.gd option for every run: exploring outside the declared grid, which can never count as a pass')
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-fuel-trial'))
    parser.add_argument('--output', type=Path, help='write each configuration, its verdicts and every median here')
    args = parser.parse_args()
    try:
        record = []
        for config in configurations(args):
            results = run_all(plan(config), args.cache, args.jobs)
            out = evaluate(results)
            text, overall = render(config, out)
            print(text + '\n', flush=True)
            record.append({'config': config, 'overall': overall, 'verdicts': out, 'medians': summary(results)})
        if args.output:
            args.output.write_text(json.dumps(record, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

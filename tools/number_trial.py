#!/usr/bin/env python3
"""Measure the Number-as-capital candidate (D152) against the pass criteria
written down first in docs/THE_NUMBER.md section 10.4.

One configuration per run: the candidate's options, with the Lab stand-ins
(a weak recovery at 10K Coins, the Lab-maxed one at 100K). It plays the balance
harness's own scenarios and seeds through sim_runs.gd, so it measures exactly
what the game plays, and reports each criterion as PASS, FAIL or NOT RUN.
Measurements are cached by options and source, so a rerun costs nothing.
Bots, not players: a pass says the numbers hold, not that it is fun.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_report as balance  # noqa: E402

ROOT = balance.ROOT
BUILDS = ('core', 'turtle')
BUDGETS = (10000, 100000)
CARD_BUILDS = (('early', 2000, 'core'), ('turtle', 4000, 'turtle'), ('later', 40000, 'core'))
CENTRE = {'power': 0.2, 'speed': 1.0, 'fade': 0.0, 'priority': True, 'r_base': 0.5, 'r_max': 1.5}


def candidate(config, recovery, power=True, thieves=True):
    """The sim_runs.gd options for the candidate at `recovery`."""
    options = {}
    if thieves:
        options.update({'thieves': 'true', 'thief-recovery': recovery,
                        'thief-speed': config['speed'], 'thief-fade': config['fade']})
        if config['priority']:
            options['thief-priority'] = 'true'
    if power:
        options['number-power'] = config['power']
    return options


def with_extra(runs, config):
    """Any other sim_runs.gd options for every run (`--with name=value`), for
    exploring beyond the declared grid; a run's own options win."""
    extra = config.get('extra') or {}
    return {name: {**extra, **options} for name, options in runs.items()}


def build_plan(config):
    """The runs that decide criteria 1, 2, 4 (the peak) and 6: four builds, each
    with the candidate on, without its power, without recovery, and with no
    Dividers at all."""
    runs = {}
    for budget in BUDGETS:
        recovery = config['r_base'] if budget == BUDGETS[0] else config['r_max']
        for build in BUILDS:
            base = {'seeds': 4, 'buy': 'core', 'workshop-coins': budget, 'workshop-plan': build, 'cap-minutes': 180}
            runs[f'on_{budget}_{build}'] = dict(base, **candidate(config, recovery))
            runs[f'nopower_{budget}_{build}'] = dict(base, **candidate(config, recovery, power=False))
            runs[f'norecovery_{budget}_{build}'] = dict(base, **candidate(config, 0.0))
            runs[f'nodividers_{budget}_{build}'] = dict(base, **candidate(config, 0.0, thieves=False), **{'divider-share': 0})
    return with_extra(runs, config)


def slow_plan(config):
    """The longer runs behind criteria 3, 4 (the career) and 5."""
    runs = {}
    for policy in ('none', 'even', 'core'):
        runs[f'fresh_{policy}'] = dict({'seeds': 20, 'buy': policy, 'cap-minutes': 10}, **candidate(config, config['r_base']))
    runs['career'] = dict({'careers': 50, 'buy': 'core', 'cap-minutes': 90}, **candidate(config, config['r_base']))
    for name, budget, build in CARD_BUILDS:
        runs[f'cards_{name}'] = dict({'seeds': 10, 'buy': 'core', 'workshop-coins': budget, 'workshop-plan': build,
                                      'card-sweep': 7, 'cap-minutes': 180}, **candidate(config, config['r_base']))
    return with_extra(runs, config)


def measure(options, cache, digest):
    key = hashlib.sha256(json.dumps([digest, options], sort_keys=True, default=str).encode()).hexdigest()[:24]
    path = cache / (key + '.json')
    if path.is_file():
        return json.loads(path.read_text())
    part = cache / (key + '.part')
    command = ['bash', str(ROOT / 'run_godot.sh'), '--headless', '--path', str(ROOT), '-s', 'res://tools/sim_runs.gd', '--']
    for name, value in options.items():
        command.extend(['--' + name, str(value)])
    command.extend(['--json-out', str(part)])
    process = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=3600)
    if process.returncode or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', process.stdout, re.MULTILINE):
        raise ValueError(f'{options} failed:\n{process.stdout[-2000:]}')
    result = json.loads(part.read_text())
    result.pop('options', None)
    balance.validate_measurement(result, options)
    part.unlink()
    path.write_text(json.dumps(result))
    return result


def run_all(runs, cache, jobs):
    cache.mkdir(parents=True, exist_ok=True)
    digest = balance.source_digest()
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = {name: pool.submit(measure, options, cache, digest) for name, options in runs.items()}
        results = {}
        for name, future in futures.items():
            print('measured ' + name, flush=True)
            results[name] = future.result()
    if balance.source_digest() != digest:
        raise ValueError('Simulation sources changed during measurement; rerun')
    return results


def rows(result, case=None):
    return [row for row in result['runs'] if case is None or row['case'] == case]


def median_wave(result, case=None):
    return balance.upper_median([row['wave'] for row in rows(result, case)])


def committed_baseline():
    """The numbers the criteria are written against, from the committed full baseline."""
    data = json.loads((ROOT / 'data/balance/full.json').read_text())
    scenarios = {spec['id']: spec['measurement'] for spec in data['scenarios']}
    career = [row['run'] for row in scenarios['career_core']['runs'] if row['wave'] >= 31]
    return {'fresh': {policy: median_wave(scenarios['fresh_' + policy]) for policy in ('none', 'even', 'core')},
            'career_first_31': min(career),
            'turtle_100k_peak': balance.upper_median([row['peak_number'] for row in scenarios['budget_100000_turtle']['runs']])}


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def ratio(result):
    """The share of what thieves took that came back, per run that was robbed."""
    return [row['thief_recovered'] / row['thief_taken'] for row in rows(result) if row.get('thief_taken', 0) > 0]


def evaluate(results, baseline):
    """The six criteria of THE_NUMBER.md 10.4. A criterion whose runs weren't
    played is None, not a pass."""
    def have(*names):
        return all(name in results for name in names)

    def wave(name, case=None):
        return median_wave(results[name], case)

    cells = [(budget, build) for budget in BUDGETS for build in BUILDS]
    out = {}
    names = [f'{kind}_{budget}_{build}' for kind in ('on', 'nopower', 'norecovery') for budget, build in cells]
    if have(*names):
        power = {f'{b}/{k}': wave(f'on_{b}_{k}') - wave(f'nopower_{b}_{k}') for b, k in cells}
        recovery = {f'{b}/{k}': wave(f'on_{b}_{k}') - wave(f'norecovery_{b}_{k}') for b, k in cells}
        out[1] = verdict(max(power.values()) >= 2 and max(recovery.values()) >= 2,
                         f'waves lost without the power {power}; without recovery {recovery}; each needs a build at 2 or more')
    names = [f'{kind}_{budget}_{build}' for kind in ('on', 'nodividers') for budget, build in cells]
    if have(*names):
        small = {k: wave(f'nodividers_{BUDGETS[0]}_{k}') - wave(f'on_{BUDGETS[0]}_{k}') for k in BUILDS}
        large = {k: wave(f'nodividers_{BUDGETS[1]}_{k}') - wave(f'on_{BUDGETS[1]}_{k}') for k in BUILDS}
        out[2] = verdict(all(v >= 2 for v in small.values()) and all(v <= 1 for v in large.values()),
                         f'waves thieves cost at 10K {small} (each 2 or more), at 100K {large} (each 1 or less)')
    cards = [f'cards_{name}' for name, _, _ in CARD_BUILDS]
    if have(*cards):
        gains = {card: {name: wave(f'cards_{name}', card) - wave(f'cards_{name}', 'no_card') for name, _, _ in CARD_BUILDS}
                 for card in ('health', 'health_regen')}
        out[3] = verdict(all(max(g.values()) >= 1 for g in gains.values()),
                         f'level-7 card gains by build {gains}; each card needs a build at 1 or more')
    peak_ok = None
    if 'on_100000_turtle' in results:
        peak = balance.upper_median([row['peak_number'] for row in rows(results['on_100000_turtle'])])
        peak_ok = (peak <= 3 * baseline['turtle_100k_peak'], f'turtle 100K peak {peak:.0f} against at most {3 * baseline["turtle_100k_peak"]:.0f}')
    if 'career' in results and peak_ok is not None:
        reached = [row['run'] for row in rows(results['career']) if row['wave'] >= 31]
        first = min(reached) if reached else None
        out[4] = verdict(first is not None and 35 <= first <= 60 and peak_ok[0], f'career first reaches wave 31 on run {first} (35 to 60); {peak_ok[1]}')
    fresh = [f'fresh_{policy}' for policy in ('none', 'even', 'core')]
    if have(*fresh):
        moved = {p: wave(f'fresh_{p}') - baseline['fresh'][p] for p in ('none', 'even', 'core')}
        out[5] = verdict(all(abs(v) <= 1 for v in moved.values()), f'median wave against the baseline {moved}, each within 1')
    names = [f'on_{budget}_{build}' for budget, build in cells]
    if have(*names):
        small = {k: balance.upper_median(ratio(results[f'on_{BUDGETS[0]}_{k}'])) if ratio(results[f'on_{BUDGETS[0]}_{k}']) else None for k in BUILDS}
        thefts = {k: balance.upper_median([row['thefts'] for row in rows(results[f'on_{BUDGETS[0]}_{k}'])]) for k in BUILDS}
        large = {k: balance.upper_median(ratio(results[f'on_{BUDGETS[1]}_{k}'])) if ratio(results[f'on_{BUDGETS[1]}_{k}']) else None for k in BUILDS}
        good = (all(v is not None and v <= 0.5 for v in small.values()) and all(v >= 3 for v in thefts.values())
                and all(v is not None and v >= 0.9 for v in large.values()))
        out[6] = verdict(good, f'share recovered at 10K {small} (at most 0.5) with thefts {thefts} (at least 3); at 100K {large} (at least 0.9)')
    return out


def render(config, out):
    lines = ['Configuration: ' + json.dumps(config, sort_keys=True), '']
    if config.get('extra'):
        lines.insert(1, 'EXPLORATORY: outside the declared grid, so it cannot count as a pass.')
    for number in range(1, 7):
        found = out.get(number)
        state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
        lines.append(f'C{number} {state}' + ('' if found is None else ': ' + found['detail']))
    run = [v for v in out.values()]
    overall = 'NOT COMPLETE' if len(run) < 6 else 'PASS' if all(v['pass'] for v in run) else 'FAIL'
    lines.append('')
    lines.append('Overall: ' + overall)
    return '\n'.join(lines), overall


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--power', type=float, default=CENTRE['power'])
    parser.add_argument('--speed', type=float, default=CENTRE['speed'])
    parser.add_argument('--fade', type=float, default=CENTRE['fade'])
    parser.add_argument('--priority', action=argparse.BooleanOptionalAction, default=CENTRE['priority'])
    parser.add_argument('--r-base', type=float, default=CENTRE['r_base'], help='recovery at 10K Coins (the weak start)')
    parser.add_argument('--r-max', type=float, default=CENTRE['r_max'], help='recovery at 100K Coins (Lab-maxed)')
    parser.add_argument('--with', dest='extra', action='append', default=[], metavar='NAME=VALUE',
                        help='another sim_runs.gd option for every run, e.g. divider-share=3: exploring outside the declared grid, which can never count as a pass')
    parser.add_argument('--jobs', type=int, default=3)
    parser.add_argument('--no-slow', action='store_true', help='skip the career, the fresh runs and the card sweeps')
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-number-trial'))
    parser.add_argument('--output', type=Path, help='write the configuration, the verdicts and every median here')
    args = parser.parse_args()
    config = {'power': args.power, 'speed': args.speed, 'fade': args.fade, 'priority': args.priority,
              'r_base': args.r_base, 'r_max': args.r_max}
    if args.extra:
        config['extra'] = dict(item.split('=', 1) for item in args.extra)
    try:
        runs = build_plan(config)
        if not args.no_slow:
            runs.update(slow_plan(config))
        results = run_all(runs, args.cache, args.jobs)
        out = evaluate(results, committed_baseline())
        text, overall = render(config, out)
        print(text)
        if args.output:
            medians = {name: median_wave(result) for name, result in results.items() if 'card-sweep' not in runs[name]}
            args.output.write_text(json.dumps({'config': config, 'overall': overall, 'verdicts': out, 'median_waves': medians}, indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

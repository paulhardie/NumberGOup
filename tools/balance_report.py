#!/usr/bin/env python3
"""Repeatable balance measurements using the game's existing simulator.

No dependencies beyond Python 3.9+. Invalid measurements fail; balance movement
is reported for review. Baselines are only replaced by an explicit record command.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = 1
METRICS = ('wave', 'game_seconds', 'coins', 'coins_per_hour', 'cash', 'peak_number')
# The game's rules since D158: the Number is Cash, a Lock holds the Cash it
# blocks, and the bot keeps half its best Number in reserve (a bot that spends to
# 1 dies to the next hit; a player banks by feel). Every scenario plays them, so
# the baseline measures the game as it is played.
GAME_RULES = {'number-cash': 'true', 'lock-holds-cash': 'true', 'reserve': 0.5}
KNOWN_CARD_FAILURES = {'health', 'health_regen', 'range', 'critical_chance', 'extra_defense', 'free_upgrades'}


def scenarios(suite):
    cases = []
    def add(name, **options):
        cases.append({'id': name, 'options': {**options, **GAME_RULES}})
    for policy in ('none', 'even', 'core'):
        add('fresh_' + policy, seeds=20, buy=policy, **{'cap-minutes': 10})
    for budget in ((10000,) if suite == 'quick' else (10000, 100000)):
        for plan in ('core', 'turtle', 'blender', 'spread'):
            add(f'budget_{budget}_{plan}', seeds=4, buy='core', **{
                'workshop-coins': budget, 'workshop-plan': plan, 'cap-minutes': 180})
    add('career_core', careers=50, buy='core', **{'cap-minutes': 90})
    for tier in (2, 3):
        add(f'tier_{tier}_level20', seeds=2, buy='core', workshop=20, tier=tier,
            **{'cap-minutes': 10, 'until-wave': 100})
    if suite == 'full':
        for policy in ('grow', 'even'):
            add('career_' + policy, careers=70, buy=policy, **{'cap-minutes': 90})
        for name, budget, plan in (('early', 2000, 'core'), ('turtle', 4000, 'turtle'), ('later', 40000, 'core')):
            add('cards_' + name, seeds=10, buy='core', **{'workshop-coins': budget,
                'workshop-plan': plan, 'card-sweep': 7, 'cap-minutes': 180})
    return cases


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def finite_tree(value):
    if type(value) in (int, float):
        return math.isfinite(value)
    if isinstance(value, dict):
        return all(isinstance(k, str) and finite_tree(v) for k, v in value.items())
    if isinstance(value, list):
        return all(finite_tree(v) for v in value)
    return value is None or isinstance(value, (str, bool))


def validate_measurement(result, options):
    if not isinstance(result, dict) or result.get('schema') != SCHEMA:
        raise ValueError('Unsupported measurement schema')
    cards = result.get('built_cards')
    if not isinstance(cards, list) or not cards or any(not isinstance(x, str) for x in cards) or len(cards) != len(set(cards)):
        raise ValueError('Invalid drawable card catalogue')
    if not isinstance(result.get('engine'), str) or not isinstance(result.get('data_signature'), str):
        raise ValueError('Missing engine/data provenance')
    rows = result.get('runs')
    if not isinstance(rows, list) or not rows:
        raise ValueError('Missing run measurements')
    expected = ({('career', index, index) for index in range(1, options['careers'] + 1)}
                if 'careers' in options else
                {(card, seed, 0) for card in (['no_card'] + cards if 'card-sweep' in options else ['run'])
                 for seed in range(1, options['seeds'] + 1)})
    seen = set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('Invalid run row')
        if not isinstance(row.get('case'), str) or type(row.get('seed')) is not int or type(row.get('run')) is not int or not finite_tree(row):
            raise ValueError('Invalid sample identity or non-finite nested state')
        key = (row.get('case'), row.get('seed'), row.get('run'))
        if key not in expected or key in seen:
            raise ValueError(f'Duplicate or unexpected sample: {key}')
        seen.add(key)
        for field in ('wave', 'game_seconds', 'kills', 'cash', 'coins', 'peak_number', 'dividers_spawned', 'dividers_landed'):
            if not number(row.get(field)) or row[field] < 0:
                raise ValueError(f'Invalid {field}: {key}')
        if row['wave'] < 1 or row['game_seconds'] <= 0 or row['dividers_landed'] > row['dividers_spawned']:
            raise ValueError(f'Invalid run bounds: {key}')
        for field in ('wave', 'kills', 'dividers_spawned', 'dividers_landed'):
            if int(row[field]) != row[field]:
                raise ValueError(f'Fractional {field}: {key}')
        if row.get('stop') not in ('death', 'time_cap', 'wave_target', 'data_limit'):
            raise ValueError(f'Unclassified stop: {key}')
        if not isinstance(row.get('killed_by'), str) or (row['stop'] == 'death' and not row['killed_by']):
            raise ValueError(f'Missing death cause: {key}')
        if row['stop'] == 'time_cap' and row['game_seconds'] < options['cap-minutes'] * 60:
            raise ValueError(f'Premature time cap: {key}')
        if row['stop'] == 'wave_target' and ('until-wave' not in options or row['wave'] < options['until-wave']):
            raise ValueError(f'Premature wave target: {key}')
        if row['game_seconds'] > options['cap-minutes'] * 60 + 1 / 30 + 1e-6:
            raise ValueError(f'Exceeded time cap: {key}')
        if not isinstance(row.get('start'), dict) or not isinstance(row.get('reached'), dict):
            raise ValueError(f'Missing frozen build/milestones: {key}')
        for target in (10, 20, 30):
            reached = row['reached'].get(str(target))
            if (row['wave'] >= target) != (reached is not None):
                raise ValueError(f'Missing/spurious milestone {target}: {key}')
            if reached is not None and (not number(reached) or reached <= 0 or reached > row['game_seconds']):
                raise ValueError(f'Invalid milestone time: {key}')
        for field in ('lost_to', 'damage_by'):
            if not isinstance(row.get(field), dict) or any(not isinstance(k, str) or not number(v) or v < 0 for k, v in row[field].items()):
                raise ValueError(f'Invalid {field}: {key}')
        if 'careers' in options and (not number(row.get('permanent_rewards')) or row['permanent_rewards'] < 0):
            raise ValueError(f'Invalid career rewards: {key}')
    if seen != expected:
        raise ValueError(f'Missing {len(expected - seen)} expected samples')


def validate_snapshot(snapshot):
    if not isinstance(snapshot, dict) or snapshot.get('schema') != SCHEMA or snapshot.get('suite') not in ('quick', 'full'):
        raise ValueError('Unsupported baseline schema/suite')
    specs = scenarios(snapshot['suite'])
    results = snapshot.get('scenarios')
    if not isinstance(snapshot.get('provenance'), dict) or any(k not in snapshot['provenance'] for k in ('commit', 'dirty', 'source_sha256')):
        raise ValueError('Missing measurement provenance')
    if not isinstance(results, list) or len(results) != len(specs):
        raise ValueError('Incomplete baseline scenarios')
    for spec, result in zip(specs, results):
        if not isinstance(result, dict):
            raise ValueError('Invalid scenario entry')
        if result.get('id') != spec['id'] or result.get('options') != spec['options']:
            raise ValueError('Scenario definitions changed; record a reviewed new baseline')
        validate_measurement(result['measurement'], spec['options'])


def source_digest():
    digest = hashlib.sha256()
    paths = sorted(p for folder in ('src/tower', 'data/tower', 'data/workshop', 'data/cards')
                   for p in (ROOT / folder).rglob('*') if p.is_file() and p.suffix in ('.gd', '.json'))
    paths.extend([ROOT / 'tools/sim_runs.gd', ROOT / 'tools/balance_report.py'])
    for path in paths:
        digest.update(str(path.relative_to(ROOT)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def capture(suite):
    initial_digest = source_digest()
    collected = []
    with tempfile.TemporaryDirectory(prefix='ngu-balance-') as folder:
        for spec in scenarios(suite):
            print('Measuring ' + spec['id'] + '…', flush=True)
            path = Path(folder) / (spec['id'] + '.json')
            command = ['bash', str(ROOT / 'run_godot.sh'), '--headless', '--path', str(ROOT),
                       '-s', 'res://tools/sim_runs.gd', '--']
            for key, value in spec['options'].items():
                command.extend(['--' + key, str(value)])
            command.extend(['--json-out', str(path)])
            try:
                process = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, timeout=900)
            except subprocess.TimeoutExpired as error:
                raise ValueError(f'{spec["id"]} exceeded 15 real minutes; no baseline written') from error
            if process.returncode or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', process.stdout, re.MULTILINE):
                raise ValueError(f'{spec["id"]} failed:\n{process.stdout}')
            if not path.is_file():
                raise ValueError(f'{spec["id"]} wrote no measurements')
            result = json.loads(path.read_text())
            result.pop('options', None)  # Drop the temporary machine-specific output path.
            validate_measurement(result, spec['options'])
            collected.append(dict(spec, measurement=result))
    if source_digest() != initial_digest:
        raise ValueError('Simulation sources changed during measurement; rerun before recording a baseline')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).strip())
    snapshot = {'schema': SCHEMA, 'suite': suite, 'provenance': {'commit': commit,
                'dirty': dirty, 'source_sha256': source_digest()}, 'scenarios': collected}
    validate_snapshot(snapshot)
    return snapshot


def upper_median(values):
    """Match sim_runs.gd's documented upper middle for even-sized cohorts."""
    return sorted(values)[len(values) // 2]


def value(row, metric):
    return row['coins'] * 3600 / row['game_seconds'] if metric == 'coins_per_hour' else row[metric]


def different(a, b):
    if number(a) and number(b):
        return not math.isclose(a, b, rel_tol=1e-9, abs_tol=1e-8)
    if type(a) != type(b):
        return True
    if isinstance(a, dict):
        return a.keys() != b.keys() or any(different(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) != len(b) or any(different(x, y) for x, y in zip(a, b))
    return a != b


def key(row):
    return row['case'], row['seed'], row['run']


def fmt(n):
    return f'{n:,.2f}' if abs(n) < 1000000 else f'{n:.4g}'


def design_findings(snapshot):
    by_id = {s['id']: s['measurement']['runs'] for s in snapshot['scenarios']}
    findings = []
    fresh = by_id['fresh_none']
    early = all(r['stop'] == 'death' and r['wave'] <= 5 and r['game_seconds'] < 180 for r in fresh)
    findings.append(f'{"MEETS" if early else "FAIL"}: early no-buy benchmark: every seed dies by wave 5 and before 180 game seconds.')
    findings.append('NOT MEASURED: Tier 2 turtle-to-blender pivot; uniform-level tier scenarios are smoke measurements, not strategy validation.')
    for budget in (10000, 100000):
        turtle_id = f'budget_{budget}_turtle'
        if turtle_id not in by_id:
            continue
        rows = [r for plan in ('core', 'turtle', 'blender', 'spread') for r in by_id[f'budget_{budget}_{plan}']]
        if any(r['stop'] != 'death' for r in rows):
            findings.append(f'INCONCLUSIVE: Tier 1 build ordering at {budget:,} Coins includes stopped runs.')
            continue
        turtle = upper_median([r['wave'] for r in by_id[turtle_id]])
        others = {plan: upper_median([r['wave'] for r in by_id[f'budget_{budget}_{plan}']]) for plan in ('core', 'blender', 'spread')}
        wins = all(turtle > wave for wave in others.values())
        findings.append(f'{"MEETS" if wins else "FAIL"}: D149 turtle ordering at {budget:,} Coins: turtle {turtle}; ' +
                        ', '.join(f'{plan} {wave}' for plan, wave in others.items()) + '.')
    if snapshot['suite'] != 'full':
        findings.append('NOT MEASURED: D149 card floor. Run the full suite. Documented known failures: ' +
                        ', '.join(sorted(KNOWN_CARD_FAILURES)) + ' (not accepted as balanced).')
        return findings
    cards = sorted(set().union(*(set(s['measurement']['built_cards']) for s in snapshot['scenarios'] if s['id'].startswith('cards_'))))
    for card in cards:
        effects, censored = [], False
        for build in ('early', 'turtle', 'later'):
            rows = by_id['cards_' + build]
            base = [r for r in rows if r['case'] == 'no_card']
            equipped = [r for r in rows if r['case'] == card]
            if not equipped or any(r['stop'] != 'death' for r in base + equipped):
                censored = True
                continue
            metric = 'coins' if card == 'coins' else 'wave'
            delta = upper_median([r[metric] for r in equipped]) - upper_median([r[metric] for r in base])
            effects.append((build, delta))
        passes = any(delta > 0 if card == 'coins' else delta >= 1 for _, delta in effects)
        state = 'MEETS' if passes else 'INCONCLUSIVE' if censored else 'FAIL'
        known = ' [known failure; still fails]' if card in KNOWN_CARD_FAILURES and state == 'FAIL' else ''
        findings.append(f'{state}: D149 level-7 {card}{known}: ' + ', '.join(f'{build} {delta:+g} {"Coins" if card == "coins" else "waves"}' for build, delta in effects) + '.')
    return findings


def render(current, baseline=None):
    validate_snapshot(current)
    if baseline is not None:
        validate_snapshot(baseline)
        if baseline['suite'] != current['suite']:
            raise ValueError('Cannot compare different suites')
    lines = ['# Balance impact', '', f'Suite: **{current["suite"]}**. Bots, game time; not player enjoyment or real-time performance.',
             'Medians use the upper middle sample, matching sim_runs.gd. Time/wave/data limits are censored outcomes, never deaths.', '',
             f'Current provenance: `{current["provenance"]["commit"]}`; dirty={current["provenance"]["dirty"]}; source `{current["provenance"]["source_sha256"]}`.', '']
    if baseline is not None:
        lines += [f'Baseline provenance: `{baseline["provenance"]["commit"]}`; dirty={baseline["provenance"]["dirty"]}; source `{baseline["provenance"]["source_sha256"]}`.', '']
    lines += ['## Design expectations', ''] + ['- **' + finding.split(':', 1)[0] + ':**' + finding.split(':', 1)[1] for finding in design_findings(current)] + ['',
              'These findings are separate from execution success. Known failures remain failures; movement never updates the baseline automatically.', '', '## Measurements', '']
    changed = False
    for index, scenario in enumerate(current['scenarios']):
        rows = scenario['measurement']['runs']
        before_scenario = baseline['scenarios'][index] if baseline else None
        old = {key(r): r for r in before_scenario['measurement']['runs']} if before_scenario else {}
        now = {key(r): r for r in rows}
        lines += [f'### {scenario["id"]}', '', f'Configuration: `{json.dumps(scenario["options"], sort_keys=True)}`.', '']
        engines = scenario['measurement']['engine']
        if before_scenario and engines != before_scenario['measurement']['engine']:
            lines += [f'**Engine changed:** {before_scenario["measurement"]["engine"]} → {engines}. Review platform/version effects.', '']
        stops = {stop: sum(r['stop'] == stop for r in rows) for stop in ('death', 'time_cap', 'wave_target', 'data_limit')}
        lines += ['Outcomes: ' + ', '.join(f'{n} {s}' for s, n in stops.items()) + '.', '']
        for case in dict.fromkeys(r['case'] for r in rows):
            group = [r for r in rows if r['case'] == case]
            previous = [r for r in old.values() if r['case'] == case]
            lines += [f'**{case}** ({len(group)} samples)', '', '| Metric | Baseline median | Current median | Change | Current min–max |', '|---|---:|---:|---:|---:|']
            for metric in METRICS:
                values = [value(r, metric) for r in group]
                median = upper_median(values)
                before = upper_median([value(r, metric) for r in previous]) if previous else None
                delta = '—' if before is None else fmt(median - before)
                lines.append(f'| {metric} | {"—" if before is None else fmt(before)} | {fmt(median)} | {delta} | {fmt(min(values))}–{fmt(max(values))} |')
            lines.append('')
        if 'careers' in scenario['options']:
            for target in (10, 20, 30):
                def first(samples):
                    seconds = 0
                    for r in sorted(samples, key=lambda sample: sample['run']):
                        if str(target) in r['reached']:
                            return f'run {r["run"]}, {(seconds + r["reached"][str(target)]) / 3600:.3f} game hours'
                        seconds += r['game_seconds']
                    return f'not reached in {len(samples)} runs'
                lines.append(f'- Reach wave {target}: {first(list(old.values())) if old else "no baseline"} → {first(rows)}.')
            total_coins = sum(r['coins'] + r['permanent_rewards'] for r in rows)
            old_coins = sum(r['coins'] + r['permanent_rewards'] for r in old.values()) if old else None
            comparison = f'{fmt(old_coins)} → {fmt(total_coins)} (Δ {fmt(total_coins - old_coins)})' if old_coins is not None else fmt(total_coins)
            lines += [f'- Total earned, including welcome/milestone rewards: {comparison} Coins.', '']
        if baseline is not None:
            added, removed = now.keys() - old.keys(), old.keys() - now.keys()
            changes = [k for k in now.keys() & old.keys() if different(now[k], old[k])]
            changed |= bool(added or removed or changes)
            lines += [f'**Paired impact:** {len(changes)} changed, {len(added)} added, {len(removed)} removed samples.', '']
            if changes or added or removed:
                lines += ['<details><summary>Per-seed changes</summary>', '', '| Case / seed / run | Δ wave | Δ Coins | Δ seconds | Outcome / other changes |', '|---|---:|---:|---:|---|']
                for k in sorted(changes):
                    a, b = old[k], now[k]
                    fields = ', '.join(f for f in b if f not in ('wave', 'coins', 'game_seconds') and different(a.get(f), b[f]))
                    lines.append(f'| {k[0]} / {k[1]} / {k[2]} | {b["wave"]-a["wave"]:+g} | {fmt(b["coins"]-a["coins"])} | {fmt(b["game_seconds"]-a["game_seconds"])} | {a["stop"]} → {b["stop"]}; {fields} |')
                for k in sorted(added):
                    lines.append(f'| {k} | — | — | — | added |')
                for k in sorted(removed):
                    lines.append(f'| {k} | — | — | — | removed |')
                lines += ['', '</details>', '']
    lines += ['**Result:** ' + ('Balance movement detected; review the changes above.' if changed else 'No paired balance movement detected.' if baseline else 'Baseline measurement only; no comparison yet.'), '']
    return '\n'.join(lines), changed


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp')
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True, allow_nan=False) + '\n')
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('record', 'compare'))
    parser.add_argument('--suite', choices=('quick', 'full'), default='quick')
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--output', type=Path, default=Path('/tmp/ngu-balance-current.json'))
    parser.add_argument('--report', type=Path, default=Path('/tmp/ngu-balance-report.md'))
    parser.add_argument('--replace', action='store_true', help='explicitly replace an existing baseline in record mode')
    parser.add_argument('--fail-on-change', action='store_true', help='optional exact-comparison gate; known design failures still appear in the report')
    args = parser.parse_args()
    baseline_path = args.baseline or ROOT / 'data/balance' / (args.suite + '.json')
    try:
        targets = [baseline_path.resolve(), args.output.resolve(), args.report.resolve()]
        if len(set(targets)) != 3:
            raise ValueError('Baseline, current output and report must be different paths')
        if args.mode == 'record' and baseline_path.exists() and not args.replace:
            raise ValueError('Baseline exists; review changes, then use record --replace explicitly')
        if args.mode == 'compare' and args.replace:
            raise ValueError('--replace only applies to record')
        baseline = read_json(baseline_path) if args.mode == 'compare' else None
        if baseline is not None:
            validate_snapshot(baseline)
            if baseline['suite'] != args.suite:
                raise ValueError('Baseline suite does not match --suite')
        current = capture(args.suite)
        report, changed = render(current, baseline)
        write_json(args.output, current)
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report)
        if args.mode == 'record':
            write_json(baseline_path, current)
        print(report, flush=True)
        print(f'Written: {args.report} and {args.output}', flush=True)
        return 1 if changed and args.fail_on_change else 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f'Balance measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

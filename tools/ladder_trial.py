#!/usr/bin/env python3
"""Measure the digit ladder keyed on the Number earned (D163) against the pass
criteria written down first in docs/THE_NUMBER.md section 17.5.

It plays two careers (core and grow, 50 runs each) under today's peak ladder (the
control) and under the earned ladder at each declared reward scale, and the
Workshop cells of section 16.4 once, without the option (the ladder pays between
runs, so a run with a fixed Workshop plays the same either way). Each criterion
reads PASS, FAIL or NOT RUN. Measurements are cached by options and source. Bots,
not players: a pass says the numbers hold, not that it is fun.

Since D164 the earned ladder is the game, with digit 100 at 25 Coins, and the control
asks for the peak ladder. The results in section 17.6 were measured before that, with
digit 100 at 50 in both; run it again and they differ there.
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
CAREERS = ('core', 'grow')
CAREER_RUNS = 50
SCALES = (1.0, 0.5)
# Guesses.MILESTONES (D107, D164): each digit and the Coins it pays at scale 1.
DIGITS = {10.0: 10.0, 100.0: 25.0, 1000.0: 250.0, 10000.0: 2500.0, 100000.0: 10000.0, 1000000.0: 50000.0}
LABELS = {1: 'reachable', 2: 'early digits', 3: 'share', 4: 'no digit dominates', 5: 'not rushed'}


def name(scale):
    return 'ctrl' if scale is None else f'x{scale:g}'


def cells():
    """The Workshop cells, read once without the option."""
    rules = dict(balance.GAME_RULES)
    found = {}
    for budget in BUDGETS:
        for build in PLANS:
            found[f'buy_{budget}_{build}'] = dict(rules, seeds=4 if (budget, build) == (1000000, 'turtle') else 6, buy='core',
                                                  **{'workshop-coins': budget, 'workshop-plan': build, 'cap-minutes': 180})
    return found


def plan(scales=SCALES):
    runs = {f'cell.{cell}': options for cell, options in cells().items()}
    for scale in (None,) + tuple(scales):
        for policy in CAREERS:
            options = dict(balance.GAME_RULES, careers=CAREER_RUNS, buy=policy, **{'cap-minutes': 90})
            options.update({'ladder': 'peak'} if scale is None else {'ladder': 'earned', 'ladder-scale': scale})
            runs[f'{name(scale)}.career_{policy}'] = options
    return runs


def median(values):
    return balance.upper_median(values) if values else None


def verdict(passed, detail):
    return {'pass': passed, 'detail': detail}


def career(results, prefix, policy):
    """A career's runs in order, each with the digits it reached and what they paid, as
    the simulator recorded them, checked against a reading of its peaks (the control) or
    its Number earned, so the tool and the game can't disagree unnoticed."""
    runs = sorted(rows(results[f'{prefix}.career_{policy}']), key=lambda row: row['run'])
    key, pay = ('peak_number', 1.0) if prefix == 'ctrl' else ('cash', float(prefix[1:]))
    best = 0.0
    for row in runs:
        reached = [d for d in DIGITS if best < d <= row[key]]
        best = max(best, row[key])
        paid = sum(DIGITS[d] * pay for d in reached)
        if row.get('digits') != reached or abs(row.get('digits_paid', -1.0) - paid) > 1e-6:
            raise ValueError(f'{prefix}.career_{policy} run {row["run"]}: recorded digits {row.get("digits")} differ from the reading {reached}')
    return runs


def first_run(runs, test):
    return next((row['run'] for row in runs if test(row)), None)


def evaluate(results, scale):
    """The five criteria of THE_NUMBER.md 17.5 for one configuration (scale None is the
    control, the peak ladder). A criterion whose runs weren't played is absent."""
    prefix = name(scale)
    key = 'peak_number' if scale is None else 'cash'
    pay = 1.0 if scale is None else scale
    out = {}
    wanted = [f'cell.buy_{b}_{p}' for b in BUDGETS for p in PLANS]
    if all(c in results for c in wanted):
        reach = {f'{b}/{p}': median([row[key] for row in rows(results[f'cell.buy_{b}_{p}'])]) for b in BUDGETS for p in PLANS}
        top = max(row[key] for c in wanted for row in rows(results[c]))
        ok = all(reach[f'{BUDGETS[0]}/{p}'] >= 1000 and reach[f'{BUDGETS[-1]}/{p}'] >= 10000 for p in PLANS) and top < 1000000
        out[1] = verdict(ok, f'median {"peak" if scale is None else "Number earned"} buying {{{", ".join(f"{k}: {v:.0f}" for k, v in reach.items())}}} '
                             f'(1,000 at 10K and 10,000 at 1M for each plan); highest of any run {top:.0f} (under 1,000,000)')
    have_careers = all(f'{p}.career_{c}' in results for p in (prefix, 'ctrl') for c in CAREERS)
    if not have_careers:
        return out
    arrival, shares, worst, rushed = {}, {}, {}, {}
    for policy in CAREERS:
        runs = career(results, prefix, policy)[:CAREER_RUNS]
        hundred = first_run(runs, lambda row: 100.0 in row['digits'])
        thousand = first_run(runs, lambda row: 1000.0 in row['digits'])
        arrival[policy] = (hundred, thousand)
        paid = sum(row['digits_paid'] for row in runs)
        shares[policy] = paid / (paid + sum(row['coins'] for row in runs))
        highest = 0.0
        for row in runs:
            for digit in row['digits']:
                if digit > 10.0:
                    highest = max(highest, DIGITS[digit] * pay / max(row['coins'], 1e-9))
        worst[policy] = highest
        theirs = first_run(career(results, 'ctrl', policy)[:CAREER_RUNS], lambda row: row['wave'] >= 30)
        mine = first_run(runs, lambda row: row['wave'] >= 30)
        limit = 0.8 * (theirs if theirs is not None else CAREER_RUNS)
        rushed[policy] = (mine, theirs, mine is None or mine >= limit)
    out[2] = verdict(all(h is not None and h <= 10 and t is not None for h, t in arrival.values()),
                     f'first run reaching digit 100 and 1,000 {arrival} (100 by run 10, 1,000 within {CAREER_RUNS})')
    out[3] = verdict(all(0.03 <= s <= 0.20 for s in shares.values()),
                     f'the ladder\'s share of a career\'s Coins { {k: round(v, 4) for k, v in shares.items()} } (0.03 to 0.20)')
    out[4] = verdict(all(v <= 3.0 for v in worst.values()),
                     f'the most a digit after 10 paid against the Coins of the run that reached it { {k: round(v, 3) for k, v in worst.items()} } (at most 3)')
    out[5] = verdict(all(ok for _, _, ok in rushed.values()),
                     f'first run reaching wave 30, against the control\'s { {k: (m, t) for k, (m, t, _) in rushed.items()} } (no earlier than 0.8 of it)')
    return out


def render(scales, results):
    lines, overall = [], {}
    for scale in (None,) + tuple(scales):
        out = evaluate(results, scale)
        title = 'control (the peak ladder, today)' if scale is None else f'earned ladder, rewards x{scale:g}' + (
            '' if scale in SCALES else ' (EXPLORATORY: outside the declared configurations)')
        lines.append(title)
        for number in range(1, 6):
            found = out.get(number)
            state = 'NOT RUN' if found is None else 'PASS' if found['pass'] else 'FAIL'
            lines.append(f'  L{number} {LABELS[number]}: {state}' + ('' if found is None else ': ' + found['detail']))
        run = list(out.values())
        result = 'NOT COMPLETE' if len(run) < 5 else 'PASS' if all(v['pass'] for v in run) else 'FAIL'
        overall[name(scale)] = result if scale is None or scale in SCALES else 'EXPLORATORY'
        lines += [f'  Overall: {overall[name(scale)]}', '']
    return '\n'.join(lines), overall


def chosen(extra):
    """The declared scales, always, then any exploratory ones asked for."""
    return SCALES + tuple(scale for scale in (extra or ()) if scale not in SCALES)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--cache', type=Path, default=Path('/tmp/ngu-ladder-trial'))
    parser.add_argument('--output', type=Path)
    parser.add_argument('--scale', action='append', type=float, help='also measure this reward scale (exploratory unless declared)')
    args = parser.parse_args()
    scales = chosen(args.scale)
    try:
        results = run_all(plan(scales), args.cache, args.jobs)
        text, overall = render(scales, results)
        print(text)
        if args.output:
            args.output.write_text(json.dumps({'overall': overall, 'verdicts': {name(s): evaluate(results, s) for s in (None,) + scales}},
                                              indent=2, sort_keys=True) + '\n')
        return 0
    except (OSError, ValueError, KeyError, TypeError, ZeroDivisionError, subprocess.SubprocessError) as error:
        print(f'Trial measurement failed: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

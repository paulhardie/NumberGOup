"""The Number as Cash's pass criteria (D156) are code, so they are tested: each
has to fail at its boundary, and one whose runs weren't played must not read
as a pass."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('cash_trial', TOOLS / 'cash_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)


def result(wave=30, count=trial.SEEDS, peak=100.0, stop='death', interest=0.0):
    return {'runs': [{'case': 'run', 'seed': index + 1, 'run': 0, 'wave': wave, 'peak_number': peak, 'cash': 50.0, 'stop': stop,
                      'gained_from': {'kill_cash': 100.0, 'wave_cash': 0.0, 'interest': interest}} for index in range(count)]}


def passing():
    """Every run the criteria read, each comfortably passing: buying adds 20%,
    10% then 5% of its waves over upgrades off, and keeps the control's pace."""
    out = {}
    for budget, buy, off in ((10000, 40, 32), (100000, 60, 54), (1000000, 100, 95)):
        for build in trial.PLANS:
            out[f'buy_{budget}_{build}'] = result(wave=buy, peak=200.0)
            out[f'off_{budget}_{build}'] = result(wave=off)
            out[f'ctrl_{budget}_{build}'] = result(wave=buy)
    for policy in trial.FRESH:
        out[f'fresh_{policy}'] = result(wave=5, count=20)
    return out


class CashCriteriaTests(unittest.TestCase):
    def verdicts(self, results):
        return {number: found['pass'] for number, found in trial.evaluate(results).items()}

    def test_the_passing_set_passes_every_criterion(self):
        self.assertEqual(self.verdicts(passing()), {number: True for number in range(1, 7)})

    def test_a_criterion_without_its_runs_is_not_run(self):
        results = passing()
        del results['off_1000000_turtle']
        out = trial.evaluate(results)
        self.assertNotIn(2, out)
        self.assertNotIn(4, out)
        _, overall = trial.render(trial.RESERVE, out)
        self.assertEqual(overall, 'NOT COMPLETE')

    def test_buying_must_add_three_waves_while_weak(self):
        results = passing()
        results['off_10000_turtle'] = result(wave=38)
        self.assertFalse(self.verdicts(results)[1])

    def test_the_need_to_buy_must_fall_to_a_tenth(self):
        results = passing()
        results['off_1000000_core'] = result(wave=89)
        self.assertFalse(self.verdicts(results)[2], '11% at 1M is too much')
        results = passing()
        results['off_100000_core'] = result(wave=48)
        self.assertFalse(self.verdicts(results)[2], 'a share that rises from 10K to 100K')

    def test_the_peak_must_reach_the_controls(self):
        results = passing()
        results['ctrl_100000_core'] = result(wave=60, peak=201.0)
        self.assertFalse(self.verdicts(results)[3])

    def test_a_cap_only_where_the_control_has_one_and_interest_stays_small(self):
        results = passing()
        results['off_1000000_core'] = result(wave=95, stop='time_cap')
        self.assertFalse(self.verdicts(results)[4])
        results['ctrl_1000000_core'] = result(wave=100, stop='time_cap')
        self.assertTrue(self.verdicts(results)[4], 'a cap the control reaches too is the game, not the change')
        results = passing()
        results['buy_10000_core'] = result(wave=40, peak=200.0, interest=40.0)
        self.assertFalse(self.verdicts(results)[4], 'Interest at 40 of 140 is over a quarter')

    def test_the_pace_stays_within_a_quarter(self):
        results = passing()
        results['ctrl_10000_core'] = result(wave=54)
        self.assertFalse(self.verdicts(results)[5])

    def test_fresh_runs_end_between_waves_2_and_10(self):
        for wave, stop in ((11, 'death'), (1, 'death'), (5, 'time_cap')):
            results = passing()
            results['fresh_none'] = result(wave=wave, count=20, stop=stop)
            self.assertFalse(self.verdicts(results)[6], f'wave {wave}, {stop}')

    def test_another_reserve_is_exploratory(self):
        _, overall = trial.render(0.25, trial.evaluate(passing()))
        self.assertEqual(overall, 'EXPLORATORY')

    def test_the_plan_is_the_declared_one(self):
        runs = trial.plan()
        self.assertEqual(runs['buy_10000_core']['reserve'], 0.5)
        self.assertEqual(runs['off_1000000_turtle']['upgrades-off'], 'true')
        self.assertNotIn('number-cash', runs['ctrl_100000_core'])
        self.assertEqual(runs['fresh_even']['seeds'], 20)
        self.assertEqual(runs['buy_1000000_turtle']['seeds'], 6)


if __name__ == '__main__':
    unittest.main()

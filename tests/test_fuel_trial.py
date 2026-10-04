"""Stage 1's pass criteria (D155) are code, so they are tested: each has to
fail at its boundary, and one whose runs weren't played must not read as a pass."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('fuel_trial', TOOLS / 'fuel_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)

CELLS = [(budget, build) for budget in trial.BUDGETS for build in trial.BUILDS]


def result(wave=30, count=trial.SEEDS, peak=100.0, peak_wave=25, crossing=15, stop='death', raised=None):
    return {'runs': [{'case': 'run', 'seed': index + 1, 'run': 0, 'wave': wave, 'peak_number': peak, 'peak_wave': peak_wave,
                      'crossing': crossing, 'stop': stop, 'raised_by': raised if raised is not None else {'bounty': 90.0, 'regen': 10.0},
                      'shots_paid': 100, 'gained_from': {'bounty': 50.0}} for index in range(count)]}


def passing():
    """Every run the criteria read, each comfortably passing."""
    out = {}
    for budget, build in CELLS:
        out[f'on_{budget}_{build}'] = result()
        out[f'free_{budget}_{build}'] = result(wave=32)
    out['nokb_100000_blender'] = result()
    for policy in trial.FRESH:
        out[f'fresh_{policy}'] = result(wave=5, count=20, peak_wave=3, crossing=4)
    for row in trial.ROWS:
        out[f'row_{row}_0'] = result(peak=100.0)
        out[f'row_{row}_25'] = result(peak=110.0)
    return out


class FuelCriteriaTests(unittest.TestCase):
    def verdicts(self, results):
        return {number: found['pass'] for number, found in trial.evaluate(results).items()}

    def test_the_passing_set_passes_every_criterion(self):
        self.assertEqual(self.verdicts(passing()), {number: True for number in range(1, 7)})

    def test_a_criterion_without_its_runs_is_not_run_not_a_pass(self):
        results = passing()
        del results['fresh_none']
        del results['row_health_25']
        out = trial.evaluate(results)
        self.assertNotIn(2, out)
        self.assertNotIn(5, out)
        self.assertNotIn(6, out)
        text, overall = trial.render(dict(trial.CENTRE), out)
        self.assertEqual(overall, 'NOT COMPLETE')
        self.assertIn('C2 NOT RUN', text)

    def test_free_shots_must_add_two_waves_in_every_cell(self):
        results = passing()
        results['free_10000_multishot'] = result(wave=31)
        self.assertFalse(self.verdicts(results)[1])

    def test_the_crossing_has_a_window_and_investment_must_move_it(self):
        results = passing()
        results['fresh_none'] = result(wave=5, count=20, crossing=1)
        self.assertFalse(self.verdicts(results)[2])
        results = passing()
        results['on_10000_core'] = result(crossing=13)
        self.assertFalse(self.verdicts(results)[2], 'a crossing at 13 is only 9 after the fresh 4')
        results['on_10000_core'] = result(crossing=14)
        self.assertTrue(self.verdicts(results)[2])

    def test_a_run_needs_three_waves_after_its_peak_and_a_capped_run_has_no_arc(self):
        results = passing()
        results['on_100000_turtle'] = result(peak_wave=28)
        self.assertFalse(self.verdicts(results)[3])
        results['on_100000_turtle'] = result(peak_wave=27)
        self.assertTrue(self.verdicts(results)[3])
        results['on_100000_turtle'] = result(stop='time_cap', peak_wave=1)
        self.assertFalse(self.verdicts(results)[3])

    def test_no_capped_run_without_knockback_and_no_printer(self):
        results = passing()
        results['on_100000_blender'] = result(stop='time_cap')
        self.assertTrue(self.verdicts(results)[4], "a cap reached only with Knockback on is Knockback's")
        results['nokb_100000_blender'] = result(stop='time_cap')
        self.assertFalse(self.verdicts(results)[4])
        results = passing()
        results['on_100000_multishot'] = result(stop='time_cap')
        self.assertFalse(self.verdicts(results)[4])
        results = passing()
        results['on_10000_turtle'] = result(raised={'bounty': 30.0, 'health': 10.0, 'lifesteal': 60.0})
        self.assertFalse(self.verdicts(results)[4], 'Lifesteal lifting most of the highs is a printer')
        results['on_10000_turtle'] = result(raised={'bounty': 20.0, 'health': 60.0, 'regen': 20.0})
        self.assertTrue(self.verdicts(results)[4], 'bought Health is not a printer')

    def test_fresh_runs_end_between_waves_2_and_10_and_none_is_capped(self):
        for wave, stop in ((11, 'death'), (1, 'death'), (5, 'time_cap')):
            results = passing()
            results['fresh_even'] = result(wave=wave, count=20, stop=stop)
            self.assertFalse(self.verdicts(results)[5], f'wave {wave}, {stop}')

    def test_each_row_must_lift_the_peak_by_a_tenth(self):
        results = passing()
        results['row_coins_per_kill_25'] = result(peak=109.0)
        self.assertFalse(self.verdicts(results)[6])

    def test_exploring_never_passes(self):
        config = dict(trial.CENTRE, extra={'bounty-share': '1'})
        _, overall = trial.render(config, trial.evaluate(passing()))
        self.assertEqual(overall, 'EXPLORATORY')

    def test_the_plan_is_the_declared_one(self):
        runs = trial.plan(dict(trial.CENTRE))
        self.assertEqual(runs['free_10000_core']['shot-price'], 0.0)
        self.assertEqual(runs['on_10000_core']['shot-price'], 1.0)
        self.assertEqual(runs['nokb_100000_blender']['knockback'], 'off')
        self.assertEqual(runs['row_health_25']['row-levels'], 'health:25')
        self.assertEqual(runs['on_100000_turtle']['seeds'], 6)
        self.assertEqual(runs['fresh_none']['seeds'], 20)
        self.assertNotIn('hold-doomed', trial.fuel(dict(trial.CENTRE, hold=False)))
        args = type('Args', (), {'price': 1.0, 'bounty': 0.25, 'free': 0.0, 'base': 1.0, 'scale': 1.0, 'hold': True, 'extra': [], 'grid': True})
        self.assertEqual(len(trial.configurations(args)), 6)


if __name__ == '__main__':
    unittest.main()
